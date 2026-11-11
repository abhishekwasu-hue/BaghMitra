"""Bill photo backup on spray records and expenses (OPEN_QUESTIONS Q136): the same optional
private-bucket backup as scouting photos (Q34), at `<owner_id>/bill-<record_id>.jpg`, off
unless configured, owner-checked, and `bill_photo_key` validated in sync."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any

import httpx
import pytest
from alembic import command
from sqlalchemy import create_engine, inspect
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.account.erase import _photo_keys
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import Expense, SprayRecord
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import make_token
from tests.test_accounts_sync import mutation
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, pull, push
from tests.test_scouting_photos import UPLOAD, FakeStorage

KINDS = ("spray_record", "expense")


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


def _fields(kind: str, plot_id: uuid.UUID) -> dict[str, Any]:
    if kind == "spray_record":
        return {
            "plot_id": str(plot_id),
            "sprayed_on": "2026-11-02",
            "product_name": "Imida 17.8 SL",
            "cost_paise": 240_000,
        }
    return {
        "plot_id": str(plot_id),
        "spent_on": "2026-11-02",
        "category": "other",
        "amount_paise": 150_000,
    }


def record(kind: str, plot_id: uuid.UUID, record_id: uuid.UUID, **kw: Any) -> dict[str, Any]:
    return mutation(kind, record_id, **{**_fields(kind, plot_id), **kw})


async def _record(c: httpx.AsyncClient, headers: dict[str, str], kind: str) -> uuid.UUID:
    plot_id, record_id = uuid.uuid4(), uuid.uuid4()
    results = await push(c, headers, plot_mutation(plot_id), record(kind, plot_id, record_id))
    assert [r["status"] for r in results] == ["applied"] * 2
    return record_id


@pytest.mark.parametrize("kind", KINDS)
async def test_off_by_default_answers_503(
    client: httpx.AsyncClient, auth_headers: dict[str, str], kind: str
) -> None:
    record_id = await _record(client, auth_headers, kind)
    up = await client.post(
        f"/v1/bill-photos/{kind}/{record_id}/upload-url", json=UPLOAD, headers=auth_headers
    )
    down = await client.get(f"/v1/bill-photos/{kind}/{record_id}/url", headers=auth_headers)
    for response in (up, down):
        assert response.status_code == 503
        assert response.json()["error"]["code"] == "photo_backup_not_configured"


@pytest.mark.parametrize("kind", KINDS)
async def test_upload_url_then_key_sync_then_download(
    photo_client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    user_id: uuid.UUID,
    storage: FakeStorage,
    kind: str,
) -> None:
    record_id = await _record(photo_client, auth_headers, kind)
    r = await photo_client.post(
        f"/v1/bill-photos/{kind}/{record_id}/upload-url", json=UPLOAD, headers=auth_headers
    )
    assert r.status_code == 200, r.text
    key = f"{user_id}/bill-{record_id}.jpg"
    assert r.json()["photo_key"] == key
    assert r.json()["max_bytes"] == 2 * 1024 * 1024

    down = f"/v1/bill-photos/{kind}/{record_id}/url"
    r = await photo_client.get(down, headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "photo_not_found"

    plot_id = uuid.uuid4()
    results = await push(
        photo_client,
        auth_headers,
        plot_mutation(plot_id),
        record(kind, plot_id, record_id, bill_photo_key=key),
    )
    assert [x["status"] for x in results] == ["applied"] * 2
    rows = [c for c in (await pull(photo_client, auth_headers))["changes"] if c["entity"] == kind]
    assert [row["data"]["bill_photo_key"] for row in rows] == [key]

    r = await photo_client.get(down, headers=auth_headers)
    assert r.status_code == 200
    assert r.json()["url"] == f"https://store.test/get/{key}?token=t"
    assert storage.calls == [("upload", key, None), ("download", key, 300)]


async def test_a_record_without_a_bill_photo_pulls_a_null_key(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    for kind in KINDS:
        await _record(client, auth_headers, kind)
    rows = [c for c in (await pull(client, auth_headers))["changes"] if c["entity"] in KINDS]
    assert sorted(r["entity"] for r in rows) == sorted(KINDS)
    assert all(r["data"]["bill_photo_key"] is None for r in rows)


@pytest.mark.parametrize("kind", KINDS)
async def test_only_the_owner_and_a_live_record_get_urls(
    photo_client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    storage: FakeStorage,
    kind: str,
) -> None:
    record_id = await _record(photo_client, auth_headers, kind)
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    for path, headers in (
        (f"/v1/bill-photos/{kind}/{record_id}/url", other),
        (f"/v1/bill-photos/{kind}/{uuid.uuid4()}/url", auth_headers),
    ):
        r = await photo_client.get(path, headers=headers)
        assert r.status_code == 404
        assert r.json()["error"]["code"] == "record_not_found"
    up = f"/v1/bill-photos/{kind}/{record_id}/upload-url"
    assert (await photo_client.post(up, json=UPLOAD, headers=other)).status_code == 404
    assert (await photo_client.post(up, json=UPLOAD)).status_code == 401

    delete = mutation(kind, record_id)
    delete.update(op="delete", payload={}, client_updated_at="2026-11-03T07:00:00Z")
    await push(photo_client, auth_headers, delete)
    assert (await photo_client.post(up, json=UPLOAD, headers=auth_headers)).status_code == 404
    assert storage.calls == []


async def test_unknown_kind_and_size_limit(
    photo_client: httpx.AsyncClient, auth_headers: dict[str, str], storage: FakeStorage
) -> None:
    record_id = await _record(photo_client, auth_headers, "expense")
    r = await photo_client.post(
        f"/v1/bill-photos/scouting_record/{record_id}/upload-url",
        json=UPLOAD,
        headers=auth_headers,
    )
    assert r.status_code == 422
    big = await photo_client.post(
        f"/v1/bill-photos/expense/{record_id}/upload-url",
        json={"content_type": "image/jpeg", "size_bytes": 2 * 1024 * 1024 + 1},
        headers=auth_headers,
    )
    assert big.status_code == 413
    assert big.json()["error"]["code"] == "photo_too_large"
    assert storage.calls == []


async def test_a_stored_key_that_is_not_the_derived_one_is_never_signed(
    photo_client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    user_id: uuid.UUID,
    engine: AsyncEngine,
    storage: FakeStorage,
) -> None:
    record_id = await _record(photo_client, auth_headers, "spray_record")
    maker = async_sessionmaker(engine, expire_on_commit=False)
    for planted in (f"{uuid.uuid4()}/bill-{record_id}.jpg", f"{user_id}/{record_id}.jpg"):
        async with maker() as session:
            row = await session.get(SprayRecord, record_id)
            assert row is not None
            row.bill_photo_key = planted
            await session.commit()
        r = await photo_client.get(
            f"/v1/bill-photos/spray_record/{record_id}/url", headers=auth_headers
        )
        assert r.status_code == 404
    assert storage.calls == []


@pytest.mark.parametrize("kind", KINDS)
async def test_sync_bill_photo_key_must_be_the_callers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str], user_id: uuid.UUID, kind: str
) -> None:
    plot_id, record_id = uuid.uuid4(), uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    someone = uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        record(kind, plot_id, record_id, bill_photo_key=f"{someone}/bill-{record_id}.jpg"),
        record(kind, plot_id, record_id, bill_photo_key=f"{user_id}/bill-{uuid.uuid4()}.jpg"),
        record(kind, plot_id, record_id, bill_photo_key=f"{user_id}/{record_id}.jpg"),
        record(kind, plot_id, record_id, bill_photo_key="/data/user/0/bill.jpg"),
    )
    assert [r["error"] for r in results] == [
        "invalid_photo_key",
        "invalid_photo_key",
        "invalid_payload",
        "invalid_payload",
    ]
    ok = await push(
        client,
        auth_headers,
        record(kind, plot_id, record_id, bill_photo_key=f"{user_id}/bill-{record_id}.jpg"),
    )
    assert [r["status"] for r in ok] == ["applied"]


async def test_account_erasure_lists_bill_photo_keys(
    client: httpx.AsyncClient,
    auth_headers: dict[str, str],
    user_id: uuid.UUID,
    engine: AsyncEngine,
) -> None:
    plot_id, spray_id, expense_id = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    keys = [f"{user_id}/bill-{spray_id}.jpg", f"{user_id}/bill-{expense_id}.jpg"]
    await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        record("spray_record", plot_id, spray_id, bill_photo_key=keys[0]),
        record("expense", plot_id, expense_id, bill_photo_key=keys[1]),
    )
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        assert await session.get(Expense, expense_id) is not None
        assert set(await _photo_keys(session, user_id)) == set(keys)


def test_migration_0044_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'b.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))
    command.upgrade(cfg, "0044")
    with engine.connect() as conn:
        for table in ("spray_records", "expenses"):
            columns = {c["name"]: c for c in inspect(conn).get_columns(table)}
            assert columns["bill_photo_key"]["nullable"]
    command.downgrade(cfg, "0043")
    with engine.connect() as conn:
        for table in ("spray_records", "expenses"):
            assert "bill_photo_key" not in {c["name"] for c in inspect(conn).get_columns(table)}
    engine.dispose()
