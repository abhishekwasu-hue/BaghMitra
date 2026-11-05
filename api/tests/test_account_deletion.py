"""`DELETE /v1/me` (S-10 / H6 / R1): every row the grower owns, their photos and (when the
service role key is set) the Supabase sign-in account are erased; a no-PII tombstone stays."""

from __future__ import annotations

import json
import uuid
from collections.abc import AsyncGenerator, AsyncIterator
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import cast

import httpx
import pytest
from alembic import command
from sqlalchemy import create_engine, func, inspect, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.account.auth_admin import AuthAdminError, SupabaseAuthAdmin
from bagmitra_api.account.erase import owner_tables
from bagmitra_api.account.models import AccountDeletion
from bagmitra_api.billing.models import EntitlementSnapshot
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.photos.storage import PhotoStorageError, SignedUrl, SupabaseStorageClient
from bagmitra_api.routers.me import get_auth_admin
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import make_token
from tests.test_accounts_sync import expense, mutation
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, push
from tests.test_scouting_sync import scouting
from tests.test_sync import profile_mutation

SERVICE_KEY = "service-role-key-never-logged"


class FakeStorage:
    def __init__(self, folder: dict[str, list[str]] | None = None) -> None:
        self.folder = folder or {}
        self.deleted: list[str] = []
        self.fail = False

    async def signed_upload_url(self, key: str) -> SignedUrl:  # pragma: no cover
        return SignedUrl(key, 1)

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:  # pragma: no cover
        return SignedUrl(key, expires_in)

    async def list_folder(self, folder: str) -> list[str]:
        if self.fail:
            raise PhotoStorageError("HTTP 503")
        return self.folder.get(folder, [])

    async def delete_objects(self, keys: list[str]) -> None:
        self.deleted += keys


class FakeAuthAdmin:
    def __init__(self, fail: bool = False) -> None:
        self.deleted: list[uuid.UUID] = []
        self.fail = fail

    async def delete_user(self, user_id: uuid.UUID) -> None:
        if self.fail:
            raise AuthAdminError("HTTP 500")
        self.deleted.append(user_id)


def _client(
    settings: Settings,
    engine: AsyncEngine,
    storage: FakeStorage | None,
    admin: FakeAuthAdmin | None,
) -> httpx.AsyncClient:
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_photo_storage] = lambda: storage
    app.dependency_overrides[get_auth_admin] = lambda: admin
    return httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test")


@pytest.fixture
async def api(settings: Settings, engine: AsyncEngine) -> AsyncIterator[httpx.AsyncClient]:
    async with _client(settings, engine, None, None) as c:
        yield c


async def _fill(c: httpx.AsyncClient, user: uuid.UUID) -> uuid.UUID:
    """Rows in many owner tables for `user`; returns a scouting record with a photo."""
    headers = {"Authorization": f"Bearer {make_token(user)}"}
    plot_id, record_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        c,
        headers,
        profile_mutation(user),
        plot_mutation(plot_id),
        expense(plot_id),
        scouting(plot_id, entity_id=record_id, photo_key=f"{user}/{record_id}.jpg"),
        mutation("no_such_entity", uuid.uuid4(), note="rejected"),
    )
    assert [r["status"] for r in results] == ["applied"] * 4 + ["rejected"]
    device = {"token": f"tok-{user}", "platform": "android"}
    assert (await c.post("/v1/me/devices", json=device, headers=headers)).status_code == 204
    prefs = {
        "quiet_start": "22:30",
        "quiet_end": "06:00",
        "weekly_cap": 5,
        "opted_out": [],
        "digest_weekly": True,
    }
    assert (await c.put("/v1/me/feed-preferences", json=prefs, headers=headers)).status_code == 200
    return record_id


async def _add_snapshot(engine: AsyncEngine, user: uuid.UUID) -> None:
    async with async_sessionmaker(engine)() as s:
        s.add(
            EntitlementSnapshot(
                id=uuid.uuid4(),
                subject_type="farmer",
                subject_id=user,
                computed={"plan": "free"},
                valid_until=datetime.now(UTC) + timedelta(days=1),
            )
        )
        await s.commit()


async def _owned_counts(engine: AsyncEngine, user: uuid.UUID) -> dict[str, int]:
    counts: dict[str, int] = {}
    async with async_sessionmaker(engine)() as s:
        for table, column in owner_tables():
            n = await s.scalar(
                select(func.count()).select_from(table).where(table.c[column] == user)
            )
            if n:
                counts[table.name] = int(n)
        n = await s.scalar(
            select(func.count())
            .select_from(EntitlementSnapshot)
            .where(EntitlementSnapshot.subject_id == user)
        )
        if n:
            counts["entitlement_snapshots"] = int(n)
    return counts


async def _tombstones(engine: AsyncEngine) -> list[AccountDeletion]:
    async with async_sessionmaker(engine)() as s:
        return list((await s.scalars(select(AccountDeletion))).all())


def test_owner_tables_cover_every_grower_table() -> None:
    names = {t.name for t, _ in owner_tables()}
    assert {
        "farmers",
        "plots",
        "sync_mutations",
        "push_devices",
        "feed_receipts",
        "feed_preferences",
        "insurance_policies",
        "lab_tests",
        "scouting_records",
        "expenses",
        "plot_risk_alerts",
    } <= names
    assert "account_deletions" not in names


async def test_erases_everything_of_the_caller_only(
    settings: Settings, engine: AsyncEngine, user_id: uuid.UUID
) -> None:
    other = uuid.uuid4()
    storage = FakeStorage({str(user_id): [f"{user_id}/orphan.jpg"]})
    admin = FakeAuthAdmin()
    async with _client(settings, engine, storage, admin) as c:
        record_id = await _fill(c, user_id)
        await _fill(c, other)
        await _add_snapshot(engine, user_id)
        before = await _owned_counts(engine, user_id)
        assert {"farmers", "plots", "sync_mutations", "push_devices", "feed_preferences"} <= set(
            before
        )
        other_before = await _owned_counts(engine, other)

        r = await c.delete("/v1/me", headers={"Authorization": f"Bearer {make_token(user_id)}"})
    assert r.status_code == 200, r.text
    body = r.json()
    assert body == {
        "rows_deleted": sum(before.values()),
        "photos_deleted": 2,
        "sign_in_account_removed": True,
    }
    assert await _owned_counts(engine, user_id) == {}
    assert await _owned_counts(engine, other) == other_before
    assert sorted(storage.deleted) == sorted(
        [f"{user_id}/orphan.jpg", f"{user_id}/{record_id}.jpg"]
    )
    assert admin.deleted == [user_id]
    [tomb] = await _tombstones(engine)
    assert tomb.followup is None
    assert tomb.followup_user_id is None
    assert tomb.rows_deleted == sum(before.values())


async def test_without_the_service_key_a_followup_row_is_left(
    api: httpx.AsyncClient, engine: AsyncEngine, user_id: uuid.UUID
) -> None:
    await _fill(api, user_id)
    r = await api.delete("/v1/me", headers={"Authorization": f"Bearer {make_token(user_id)}"})
    assert r.status_code == 200
    assert r.json()["sign_in_account_removed"] is False
    assert r.json()["photos_deleted"] == 0
    assert await _owned_counts(engine, user_id) == {}
    [tomb] = await _tombstones(engine)
    # Photo backup is off but a key was recorded: the owner checks the bucket too.
    assert tomb.followup == "auth_user,photos"
    assert tomb.followup_user_id == user_id


async def test_a_failing_auth_admin_keeps_the_followup(
    settings: Settings, engine: AsyncEngine, user_id: uuid.UUID
) -> None:
    async with _client(settings, engine, FakeStorage(), FakeAuthAdmin(fail=True)) as c:
        await _fill(c, user_id)
        r = await c.delete("/v1/me", headers={"Authorization": f"Bearer {make_token(user_id)}"})
    assert r.status_code == 200
    assert r.json()["sign_in_account_removed"] is False
    [tomb] = await _tombstones(engine)
    assert tomb.followup == "auth_user"
    assert tomb.followup_user_id == user_id


async def test_storage_failure_touches_nothing(
    settings: Settings, engine: AsyncEngine, user_id: uuid.UUID
) -> None:
    storage = FakeStorage()
    async with _client(settings, engine, storage, FakeAuthAdmin()) as c:
        await _fill(c, user_id)
        before = await _owned_counts(engine, user_id)
        storage.fail = True
        r = await c.delete("/v1/me", headers={"Authorization": f"Bearer {make_token(user_id)}"})
    assert r.status_code == 502
    assert r.json()["error"]["code"] == "photo_storage_unavailable"
    assert await _owned_counts(engine, user_id) == before
    assert await _tombstones(engine) == []


async def test_needs_sign_in_and_is_repeatable(
    api: httpx.AsyncClient, engine: AsyncEngine, user_id: uuid.UUID
) -> None:
    assert (await api.delete("/v1/me")).status_code == 401
    headers = {"Authorization": f"Bearer {make_token(user_id)}"}
    first = await api.delete("/v1/me", headers=headers)
    second = await api.delete("/v1/me", headers=headers)
    assert first.status_code == second.status_code == 200
    assert second.json()["rows_deleted"] == 0
    assert (await api.get("/v1/me", headers=headers)).status_code == 404


async def test_supabase_auth_admin_adapter() -> None:
    seen: list[httpx.Request] = []
    gone = uuid.uuid4()

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if request.url.path.endswith(str(gone)):
            return httpx.Response(404, json={"msg": "User not found"})
        if "fail" in request.url.host:
            return httpx.Response(500)
        return httpx.Response(200, json={})

    user = uuid.uuid4()
    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        admin = SupabaseAuthAdmin(http, base_url="https://p.supabase.co/", service_key=SERVICE_KEY)
        await admin.delete_user(user)
        await admin.delete_user(gone)  # already gone counts as done
        broken = SupabaseAuthAdmin(http, base_url="https://fail.test", service_key=SERVICE_KEY)
        with pytest.raises(AuthAdminError) as info:
            await broken.delete_user(user)
        assert SERVICE_KEY not in str(info.value)
    assert seen[0].method == "DELETE"
    assert str(seen[0].url) == f"https://p.supabase.co/auth/v1/admin/users/{user}"
    assert seen[0].headers["authorization"] == f"Bearer {SERVICE_KEY}"
    assert seen[0].headers["apikey"] == SERVICE_KEY

    def down(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("down")

    async with httpx.AsyncClient(transport=httpx.MockTransport(down)) as http:
        admin = SupabaseAuthAdmin(http, base_url="https://p.supabase.co", service_key=SERVICE_KEY)
        with pytest.raises(AuthAdminError, match="ConnectError"):
            await admin.delete_user(user)


async def test_storage_adapter_lists_pages_and_deletes() -> None:
    seen: list[httpx.Request] = []
    owner = "o"

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        body = json.loads(request.content)
        if request.method == "POST":
            offset = body["offset"]
            if offset == 0:
                return httpx.Response(200, json=[{"name": f"{i}.jpg"} for i in range(1000)])
            return httpx.Response(200, json=[{"name": "last.jpg"}, {"id": None}])
        if body["prefixes"] == ["gone.jpg"]:
            return httpx.Response(400, json={"error": "not_found"})
        return httpx.Response(200, json=[])

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = SupabaseStorageClient(
            http, base_url="https://p.supabase.co", bucket="b", service_key=SERVICE_KEY
        )
        keys = await client.list_folder(owner)
        await client.delete_objects(keys)
        await client.delete_objects(["gone.jpg"])
    assert len(keys) == 1001
    assert keys[0] == "o/0.jpg"
    assert keys[-1] == "o/last.jpg"
    assert str(seen[0].url) == "https://p.supabase.co/storage/v1/object/list/b"
    assert json.loads(seen[0].content) == {"prefix": "o", "limit": 1000, "offset": 0}
    deletes = [r for r in seen if r.method == "DELETE"]
    assert [len(json.loads(r.content)["prefixes"]) for r in deletes] == [1000, 1, 1]
    assert str(deletes[0].url) == "https://p.supabase.co/storage/v1/object/b"


async def test_storage_adapter_list_errors() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if "missing" in request.content.decode():
            return httpx.Response(404)
        if "text" in request.content.decode():
            return httpx.Response(200, content=b"not json")
        return httpx.Response(200, json={"not": "a list"})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = SupabaseStorageClient(
            http, base_url="https://p.supabase.co", bucket="b", service_key=SERVICE_KEY
        )
        assert await client.list_folder("missing") == []
        for folder in ("dict", "text"):
            with pytest.raises(PhotoStorageError):
                await client.list_folder(folder)


async def test_real_auth_admin_dependency_is_built_only_when_configured() -> None:
    off = Settings(supabase_url="https://p.supabase.co")
    gen = cast(AsyncGenerator[object, None], get_auth_admin(off))
    assert await anext(gen) is None
    on = Settings(supabase_url="https://p.supabase.co", supabase_service_role_key=SERVICE_KEY)
    assert on.auth_admin_enabled
    assert SERVICE_KEY not in repr(on)
    gen = cast(AsyncGenerator[object, None], get_auth_admin(on))
    assert isinstance(await anext(gen), SupabaseAuthAdmin)
    await gen.aclose()


def test_migration_0025_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'd.db'}"
    cfg = _config(url)
    command.upgrade(cfg, "head")
    engine = create_engine(_sync_url(url))
    with engine.connect() as conn:
        assert "account_deletions" in inspect(conn).get_table_names()
    command.downgrade(cfg, "0024")
    with engine.connect() as conn:
        assert "account_deletions" not in inspect(conn).get_table_names()
    engine.dispose()
