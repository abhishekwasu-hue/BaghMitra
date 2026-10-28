"""Optional scouting photo backup (OPEN_QUESTIONS Q34): signed URLs for a private bucket,
off unless configured, owner-checked, and `photo_key` validated in sync."""

from __future__ import annotations

import json
import uuid
from collections.abc import AsyncGenerator, AsyncIterator
from pathlib import Path
from typing import cast

import httpx
import pytest
from alembic import command
from sqlalchemy import create_engine, inspect
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.photos.storage import (
    SIGNED_UPLOAD_TTL_SECONDS,
    PhotoNotFoundError,
    PhotoStorageError,
    SignedUrl,
    SupabaseStorageClient,
)
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import make_token
from tests.test_accounts_sync import mutation
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, pull, push
from tests.test_scouting_sync import _scouting, scouting

SERVICE_KEY = "service-role-key-never-logged"


class FakeStorage:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str, int | None]] = []
        self.fail: Exception | None = None

    async def signed_upload_url(self, key: str) -> SignedUrl:
        self.calls.append(("upload", key, None))
        if self.fail:
            raise self.fail
        return SignedUrl(f"https://store.test/upload/{key}?token=t", SIGNED_UPLOAD_TTL_SECONDS)

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:
        self.calls.append(("download", key, expires_in))
        if self.fail:
            raise self.fail
        return SignedUrl(f"https://store.test/get/{key}?token=t", expires_in)


@pytest.fixture
def storage() -> FakeStorage:
    return FakeStorage()


@pytest.fixture
async def photo_client(
    settings: Settings, engine: AsyncEngine, storage: FakeStorage
) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_photo_storage] = lambda: storage
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


async def _record(c: httpx.AsyncClient, headers: dict[str, str]) -> uuid.UUID:
    plot_id, record_id = uuid.uuid4(), uuid.uuid4()
    results = await push(c, headers, plot_mutation(plot_id), scouting(plot_id, entity_id=record_id))
    assert [r["status"] for r in results] == ["applied"] * 2
    return record_id


UPLOAD = {"content_type": "image/jpeg", "size_bytes": 180_000}


async def test_off_by_default_answers_503(
    client: httpx.AsyncClient, auth_headers: dict[str, str], settings: Settings
) -> None:
    assert not settings.photo_storage_enabled
    record_id = await _record(client, auth_headers)
    up = await client.post(
        f"/v1/scouting/{record_id}/photo-upload-url", json=UPLOAD, headers=auth_headers
    )
    down = await client.get(f"/v1/scouting/{record_id}/photo-url", headers=auth_headers)
    for response in (up, down):
        assert response.status_code == 503
        assert response.json()["error"]["code"] == "photo_backup_not_configured"
        assert response.json()["error"]["message"] == "photo backup not configured"


def test_enabled_needs_url_and_key() -> None:
    assert not Settings(photo_storage_url="https://x.supabase.co").photo_storage_enabled
    assert not Settings(photo_storage_service_key=SERVICE_KEY).photo_storage_enabled
    on = Settings(photo_storage_url="https://x.supabase.co", photo_storage_service_key=SERVICE_KEY)
    assert on.photo_storage_enabled
    assert on.photo_storage_bucket == "scouting-photos"
    assert SERVICE_KEY not in repr(on)


async def test_upload_url_then_key_sync_then_download(
    photo_client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    user_id: uuid.UUID,
    storage: FakeStorage,
) -> None:
    record_id = await _record(photo_client, auth_headers)
    r = await photo_client.post(
        f"/v1/scouting/{record_id}/photo-upload-url", json=UPLOAD, headers=auth_headers
    )
    assert r.status_code == 200, r.text
    body = r.json()
    key = f"{user_id}/{record_id}.jpg"
    assert body["photo_key"] == key
    assert body["expires_in"] == SIGNED_UPLOAD_TTL_SECONDS
    assert body["content_type"] == "image/jpeg"
    assert body["max_bytes"] == 2 * 1024 * 1024
    assert body["upload_url"].startswith("https://store.test/upload/")

    # No photo recorded yet: nothing to download.
    r = await photo_client.get(f"/v1/scouting/{record_id}/photo-url", headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "photo_not_found"

    plot_id = uuid.uuid4()
    results = await push(
        photo_client,
        auth_headers,
        plot_mutation(plot_id),
        scouting(plot_id, entity_id=record_id, photo_key=key),
    )
    assert [r["status"] for r in results] == ["applied"] * 2
    rows = _scouting(await pull(photo_client, auth_headers))
    assert [row["data"]["photo_key"] for row in rows] == [key]

    r = await photo_client.get(f"/v1/scouting/{record_id}/photo-url", headers=auth_headers)
    assert r.status_code == 200
    assert r.json() == {
        "url": f"https://store.test/get/{key}?token=t",
        "photo_key": key,
        "expires_in": 300,
    }
    assert storage.calls == [("upload", key, None), ("download", key, 300)]


async def test_only_the_owner_gets_urls(
    photo_client: httpx.AsyncClient, auth_headers: dict[str, str], storage: FakeStorage
) -> None:
    record_id = await _record(photo_client, auth_headers)
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    for path, headers in (
        (f"/v1/scouting/{record_id}/photo-url", other),
        (f"/v1/scouting/{uuid.uuid4()}/photo-url", auth_headers),
    ):
        r = await photo_client.get(path, headers=headers)
        assert r.status_code == 404
        assert r.json()["error"]["code"] == "scouting_record_not_found"
    r = await photo_client.post(
        f"/v1/scouting/{record_id}/photo-upload-url", json=UPLOAD, headers=other
    )
    assert r.status_code == 404
    r = await photo_client.post(f"/v1/scouting/{record_id}/photo-upload-url", json=UPLOAD)
    assert r.status_code == 401
    assert storage.calls == []


async def test_deleted_record_has_no_photo_urls(
    photo_client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    record_id = await _record(photo_client, auth_headers)
    delete = mutation("scouting_record", record_id)
    delete.update(op="delete", payload={}, client_updated_at="2026-11-03T07:00:00Z")
    await push(photo_client, auth_headers, delete)
    r = await photo_client.post(
        f"/v1/scouting/{record_id}/photo-upload-url", json=UPLOAD, headers=auth_headers
    )
    assert r.status_code == 404


async def test_jpeg_only_and_size_limit(
    photo_client: httpx.AsyncClient, auth_headers: dict[str, str], storage: FakeStorage
) -> None:
    record_id = await _record(photo_client, auth_headers)
    url = f"/v1/scouting/{record_id}/photo-upload-url"
    png = await photo_client.post(
        url, json={"content_type": "image/png", "size_bytes": 1000}, headers=auth_headers
    )
    assert png.status_code == 422
    empty = await photo_client.post(
        url, json={"content_type": "image/jpeg", "size_bytes": 0}, headers=auth_headers
    )
    assert empty.status_code == 422
    big = await photo_client.post(
        url,
        json={"content_type": "image/jpeg", "size_bytes": 2 * 1024 * 1024 + 1},
        headers=auth_headers,
    )
    assert big.status_code == 413
    assert big.json()["error"]["code"] == "photo_too_large"
    assert storage.calls == []


async def test_storage_failures_are_mapped(
    photo_client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    user_id: uuid.UUID,
    storage: FakeStorage,
) -> None:
    record_id = await _record(photo_client, auth_headers)
    storage.fail = PhotoStorageError("HTTP 500")
    r = await photo_client.post(
        f"/v1/scouting/{record_id}/photo-upload-url", json=UPLOAD, headers=auth_headers
    )
    assert r.status_code == 502
    assert r.json()["error"]["code"] == "photo_storage_unavailable"

    plot_id = uuid.uuid4()
    key = f"{user_id}/{record_id}.jpg"
    await push(
        photo_client,
        auth_headers,
        plot_mutation(plot_id),
        scouting(plot_id, entity_id=record_id, photo_key=key),
    )
    r = await photo_client.get(f"/v1/scouting/{record_id}/photo-url", headers=auth_headers)
    assert r.status_code == 502
    storage.fail = PhotoNotFoundError("HTTP 400")
    r = await photo_client.get(f"/v1/scouting/{record_id}/photo-url", headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "photo_not_found"


async def test_sync_photo_key_must_be_the_callers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str], user_id: uuid.UUID
) -> None:
    plot_id, record_id = uuid.uuid4(), uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    someone = uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        scouting(plot_id, entity_id=record_id, photo_key=f"{someone}/{record_id}.jpg"),
        scouting(plot_id, entity_id=record_id, photo_key=f"{user_id}/{uuid.uuid4()}.jpg"),
        scouting(plot_id, entity_id=record_id, photo_key=f"{user_id}/{record_id}.png"),
        scouting(plot_id, entity_id=record_id, photo_key=f"{user_id}/../{record_id}.jpg"),
        scouting(plot_id, entity_id=record_id, photo_key="/data/user/0/photo.jpg"),
        scouting(plot_id, entity_id=record_id, photo_path="/data/user/0/photo.jpg"),
    )
    assert [r["error"] for r in results] == [
        "invalid_photo_key",
        "invalid_photo_key",
        "invalid_payload",
        "invalid_payload",
        "invalid_payload",
        "invalid_payload",
    ]
    ok = await push(
        client,
        auth_headers,
        scouting(plot_id, entity_id=record_id, photo_key=f"{user_id}/{record_id}.jpg"),
    )
    assert [r["status"] for r in ok] == ["applied"]


async def test_supabase_adapter_calls() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if "/upload/sign/" in request.url.path:
            return httpx.Response(200, json={"url": "/object/upload/sign/b/o/r.jpg?token=u"})
        if request.url.path.endswith("/missing.jpg"):
            return httpx.Response(400, json={"error": "not_found"})
        if request.url.path.endswith("/down.jpg"):
            return httpx.Response(503)
        return httpx.Response(200, json={"signedURL": "/object/sign/b/o/r.jpg?token=d"})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = SupabaseStorageClient(
            http, base_url="https://p.supabase.co/", bucket="b", service_key=SERVICE_KEY
        )
        up = await client.signed_upload_url("o/r.jpg")
        down = await client.signed_download_url("o/r.jpg", 120)
        with pytest.raises(PhotoNotFoundError):
            await client.signed_download_url("o/missing.jpg", 120)
        with pytest.raises(PhotoStorageError):
            await client.signed_download_url("o/down.jpg", 120)

    assert up == SignedUrl(
        "https://p.supabase.co/storage/v1/object/upload/sign/b/o/r.jpg?token=u", 7200
    )
    assert down == SignedUrl("https://p.supabase.co/storage/v1/object/sign/b/o/r.jpg?token=d", 120)
    first, second = seen[0], seen[1]
    assert first.method == "POST"
    assert str(first.url) == "https://p.supabase.co/storage/v1/object/upload/sign/b/o/r.jpg"
    assert first.headers["authorization"] == f"Bearer {SERVICE_KEY}"
    assert first.headers["apikey"] == SERVICE_KEY
    assert first.headers["x-upsert"] == "true"
    assert str(second.url) == "https://p.supabase.co/storage/v1/object/sign/b/o/r.jpg"
    assert json.loads(second.content) == {"expiresIn": 120}


async def test_supabase_adapter_errors() -> None:
    def broken(request: httpx.Request) -> httpx.Response:
        if request.url.path.endswith("/net.jpg"):
            raise httpx.ConnectError("down")
        if request.url.path.endswith("/list.jpg"):
            return httpx.Response(200, json=[])
        return httpx.Response(200 if "/upload/" not in request.url.path else 400, json={})

    async with httpx.AsyncClient(transport=httpx.MockTransport(broken)) as http:
        client = SupabaseStorageClient(
            http, base_url="https://p.supabase.co", bucket="b", service_key=SERVICE_KEY
        )
        for call in (
            client.signed_upload_url("o/r.jpg"),  # 400 on upload is a storage error
            client.signed_download_url("o/net.jpg", 60),
            client.signed_download_url("o/list.jpg", 60),
            client.signed_download_url("o/empty.jpg", 60),  # no signedURL
        ):
            with pytest.raises(PhotoStorageError) as info:
                await call
            assert not isinstance(info.value, PhotoNotFoundError)
            assert SERVICE_KEY not in str(info.value)


async def test_real_storage_dependency_is_built_only_when_configured() -> None:
    off = Settings()
    gen = cast(AsyncGenerator[object, None], get_photo_storage(off))
    assert await anext(gen) is None
    on = Settings(photo_storage_url="https://p.supabase.co", photo_storage_service_key=SERVICE_KEY)
    gen = cast(AsyncGenerator[object, None], get_photo_storage(on))
    assert isinstance(await anext(gen), SupabaseStorageClient)
    await gen.aclose()


def test_migration_0021_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 's.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))
    command.upgrade(cfg, "0021")
    with engine.connect() as conn:
        columns = {c["name"]: c for c in inspect(conn).get_columns("scouting_records")}
    assert columns["photo_key"]["nullable"]
    command.downgrade(cfg, "0020")
    with engine.connect() as conn:
        columns = {c["name"]: c for c in inspect(conn).get_columns("scouting_records")}
    assert "photo_key" not in columns
    engine.dispose()
