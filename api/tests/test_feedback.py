"""In-app feedback (owner 2026-11-08, "Ho"): a signed-in user sends a problem, a suggestion
or a question with app version and phone model; an optional screenshot is stored without
metadata in the user's own folder (erased with the account); role `feedback_admin` lists
them and marks them seen or done."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.account.erase import owner_tables
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feedback.models import AppFeedback
from bagmitra_api.main import create_app
from bagmitra_api.photos.storage import SignedUrl
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.conftest import JWT_SECRET, make_token
from tests.test_market_link_registration import JPEG

USER = uuid.uuid4()
ME = {"Authorization": f"Bearer {make_token(USER)}"}
_ADMIN_TOKEN = make_token(uuid.uuid4(), app_metadata={"roles": ["feedback_admin"]})
ADMIN = {"Authorization": f"Bearer {_ADMIN_TOKEN}"}
BODY = {
    "client_id": str(uuid.uuid4()),
    "kind": "problem",
    "text": "हवामान कार्ड उघडत नाही",
    "app_version": "0.1.0+12",
    "device": "Redmi Note 12 · Android 14",
}


class Storage:
    def __init__(self) -> None:
        self.objects: dict[str, bytes] = {}

    async def put_object(self, key: str, data: bytes, content_type: str) -> None:  # noqa: ARG002
        self.objects[key] = data

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:
        return SignedUrl(f"https://files.test/{key}", expires_in)


@asynccontextmanager
async def api(engine: AsyncEngine, storage: Storage | None) -> AsyncIterator[httpx.AsyncClient]:
    cfg = Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
    )
    app = create_app(cfg)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    app.dependency_overrides[get_photo_storage] = lambda: storage
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client


async def test_a_user_sends_feedback_once_even_when_the_phone_retries(
    engine: AsyncEngine,
) -> None:
    async with api(engine, None) as client:
        first = await client.post("/v1/feedback", headers=ME, json=BODY)
        again = await client.post("/v1/feedback", headers=ME, json=BODY)  # offline queue retry
        assert (await client.post("/v1/feedback", json=BODY)).status_code == 401
    assert first.status_code == 201, first.text
    assert again.status_code == 201
    assert again.json()["id"] == first.json()["id"]
    async with async_sessionmaker(engine)() as session:
        rows = list(await session.scalars(select(AppFeedback)))
    assert len(rows) == 1
    assert (rows[0].owner_id, rows[0].kind, rows[0].status) == (USER, "problem", "new")


async def test_the_text_kind_and_lengths_are_checked(engine: AsyncEngine) -> None:
    async with api(engine, None) as client:
        for bad in ({"kind": "rant"}, {"text": ""}, {"text": "x" * 2001}):
            res = await client.post("/v1/feedback", headers=ME, json=BODY | bad)
            assert res.status_code == 422, bad


async def test_a_screenshot_is_stored_without_metadata_in_the_users_folder(
    engine: AsyncEngine,
) -> None:
    storage = Storage()
    async with api(engine, storage) as client:
        fid = (await client.post("/v1/feedback", headers=ME, json=BODY)).json()["id"]
        other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
        jpeg = {"Content-Type": "image/jpeg"}
        denied = await client.put(
            f"/v1/feedback/{fid}/screenshot", headers=other | jpeg, content=JPEG
        )
        assert denied.status_code == 404
        res = await client.put(f"/v1/feedback/{fid}/screenshot", headers=ME | jpeg, content=JPEG)
        assert res.status_code == 204, res.text
        listed = (await client.get("/v1/admin/feedback", headers=ADMIN)).json()["feedback"]
    (key,) = storage.objects
    assert key == f"{USER}/feedback-{fid}.jpg"  # erased with the account's folder
    assert b"Exif" not in storage.objects[key]
    assert listed[0]["screenshot_url"] == f"https://files.test/{key}"


async def test_without_photo_storage_the_screenshot_answers_503(engine: AsyncEngine) -> None:
    async with api(engine, None) as client:
        fid = (await client.post("/v1/feedback", headers=ME, json=BODY)).json()["id"]
        res = await client.put(
            f"/v1/feedback/{fid}/screenshot",
            headers=ME | {"Content-Type": "image/jpeg"},
            content=JPEG,
        )
    assert res.status_code == 503


async def test_the_admin_lists_and_marks_feedback(engine: AsyncEngine) -> None:
    async with api(engine, None) as client:
        fid = (await client.post("/v1/feedback", headers=ME, json=BODY)).json()["id"]
        assert (await client.get("/v1/admin/feedback", headers=ME)).status_code == 403
        listed = (await client.get("/v1/admin/feedback", headers=ADMIN)).json()["feedback"]
        assert [(f["id"], f["kind"], f["status"], f["device"]) for f in listed] == [
            (fid, "problem", "new", BODY["device"])
        ]
        res = await client.put(f"/v1/admin/feedback/{fid}", headers=ADMIN, json={"status": "done"})
        assert res.status_code == 200, res.text
        new_only = await client.get("/v1/admin/feedback?status=new", headers=ADMIN)
        assert new_only.json()["feedback"] == []


def test_feedback_rows_are_erased_with_the_account() -> None:
    assert ("app_feedback", "owner_id") in [(t.name, c) for t, c in owner_tables()]
