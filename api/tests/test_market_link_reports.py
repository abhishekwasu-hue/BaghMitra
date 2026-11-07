"""Market linkage L6 for users: report a profile, lot, rating or user with a predefined reason
(no text; optional photos, EXIF stripped), block / unblock, the admin actions about oneself
and the one appeal (spec v1.5 §3A, §4, §4C; Addendum 5; Q82, Q92, Q94)."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta
from typing import Any

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import (
    AdminAction,
    BrokerProfile,
    BuyerProfile,
    MarketDeal,
    MarketLot,
    MarketOffer,
    Rating,
)
from bagmitra_api.market_link.visibility import (
    is_blocked_between,
    not_blocked,
)
from bagmitra_api.photos.storage import SignedUrl
from bagmitra_api.routers.scouting_photos import get_photo_storage
from bagmitra_api.weather.service import get_clock
from tests.conftest import make_token

Maker = async_sessionmaker[AsyncSession]
T0 = datetime(2026, 11, 1, 9, 0, tzinfo=UTC)
ADMIN_ID = uuid.uuid4()
GROWER = uuid.uuid4()
TRADER = uuid.uuid4()
BROKER = uuid.uuid4()
ML = "/v1/market-link"
ADMIN_BASE = "/v1/admin/market-link"
# A JPEG with an EXIF (APP1) segment carrying a GPS-like payload, then image data.
EXIF_JPEG = (
    b"\xff\xd8"
    + b"\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
    + b"\xff\xe1\x00\x0eExif\x00\x00GPS-21"
    + b"\xff\xda\x00\x08\x01\x01\x00\x00\x3f\x00"
    + b"\x12\x34\xff\xd9"
)


def _headers(user: uuid.UUID, *roles: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user, app_metadata={'roles': list(roles)})}"}


ADMIN = _headers(ADMIN_ID, "market_link_admin")


class Clock:
    def __init__(self) -> None:
        self.now = T0

    def __call__(self) -> datetime:
        self.now += timedelta(seconds=1)
        return self.now


class FakeStorage:
    def __init__(self) -> None:
        self.objects: dict[str, bytes] = {}
        self.deleted: list[str] = []

    async def put_object(self, key: str, data: bytes, content_type: str) -> None:  # noqa: ARG002
        self.objects[key] = data

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:
        return SignedUrl(url=f"https://storage.test/{key}", expires_in=expires_in)

    async def list_folder(self, folder: str) -> list[str]:  # noqa: ARG002  # pragma: no cover
        return []

    async def delete_objects(self, keys: list[str]) -> None:
        self.deleted += keys


@pytest.fixture
def maker(engine: AsyncEngine) -> Maker:
    return async_sessionmaker(engine, expire_on_commit=False)


@pytest.fixture
def clock() -> Clock:
    return Clock()


@pytest.fixture
def storage() -> FakeStorage:
    return FakeStorage()


@pytest.fixture
async def ids(maker: Maker) -> dict[str, uuid.UUID]:
    """A trader and a broker profile, a published lot with an introduction and a rating."""
    i = {k: uuid.uuid4() for k in ("buyer", "broker", "lot", "offer", "deal", "rating")}
    async with maker() as s:
        s.add_all(
            [
                BuyerProfile(
                    id=i["buyer"],
                    user_id=TRADER,
                    name="Ramesh Traders",
                    phone="919800000001",
                    district="Nagpur",
                ),
                BrokerProfile(
                    id=i["broker"],
                    user_id=BROKER,
                    name="Suresh",
                    phone="919800000002",
                    district="Amravati",
                ),
                MarketLot(
                    id=i["lot"],
                    owner_id=GROWER,
                    plot_id=uuid.uuid4(),
                    crop="santra",
                    quantity_t=10.0,
                    harvest_from=date(2026, 12, 1),
                    harvest_to=date(2026, 12, 15),
                    basis="per_tonne",
                    status="published",
                    client_updated_at=T0,
                    last_seq=1,
                ),
            ]
        )
        await s.flush()
        s.add(
            MarketOffer(
                id=i["offer"],
                basis="per_tonne",
                rate_paise=2_500_000,
                harvest_date=date(2026, 12, 2),
                lot_id=i["lot"],
                buyer_user_id=TRADER,
                submitted_by=TRADER,
                status="accepted",
            )
        )
        await s.flush()
        s.add(MarketDeal(id=i["deal"], lot_id=i["lot"], offer_id=i["offer"], status="completed"))
        await s.flush()
        s.add(
            Rating(
                id=i["rating"],
                deal_id=i["deal"],
                rater_id=TRADER,
                ratee_id=GROWER,
                ratee_role="grower",
                question_key="produce_matched",
                stars=1,
                tag_ids=[],
            )
        )
        await s.commit()
    return i


def _app(settings: Settings, maker: Maker, clock: Clock, storage: FakeStorage | None) -> FastAPI:
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_clock] = lambda: clock
    app.dependency_overrides[get_photo_storage] = lambda: storage
    return app


@pytest.fixture
async def api(
    settings: Settings, maker: Maker, clock: Clock, storage: FakeStorage, ids: Any
) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=_app(settings, maker, clock, storage))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


async def _report(
    api: httpx.AsyncClient, reporter: uuid.UUID, kind: str, subject: uuid.UUID, reason: str
) -> dict[str, Any]:
    r = await api.post(
        f"{ML}/reports",
        json={"subject_type": kind, "subject_id": str(subject), "reason": reason},
        headers=_headers(reporter),
    )
    assert r.status_code == 201, r.text
    body: dict[str, Any] = r.json()
    return body


async def test_flag_off_hides_every_safety_endpoint(
    settings: Settings, maker: Maker, clock: Clock
) -> None:
    app = create_app(settings)  # market_link_enabled defaults to False
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as c:
        for method, path, h in (
            ("GET", f"{ML}/reports/mine", _headers(GROWER)),
            ("GET", f"{ML}/account-actions", _headers(GROWER)),
            ("GET", f"{ML}/blocks", _headers(GROWER)),
        ):
            assert (await c.request(method, path, headers=h)).status_code == 404


@pytest.mark.parametrize(
    "extra",
    [
        {"text": "he cheated me"},
        {"comment": "x"},
        {"details": "x"},
        {"commission": 2},
        {"aadhaar_no": "1234"},
    ],
)
async def test_report_takes_codes_only(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], extra: dict[str, Any]
) -> None:
    body = {"subject_type": "buyer", "subject_id": str(ids["buyer"]), "reason": "fake_identity"}
    r = await api.post(f"{ML}/reports", json={**body, **extra}, headers=_headers(GROWER))
    assert r.status_code == 422


async def test_report_rules(api: httpx.AsyncClient, ids: dict[str, uuid.UUID]) -> None:
    g = _headers(GROWER)
    bad = {"subject_type": "buyer", "subject_id": str(ids["buyer"]), "reason": "late_payment"}
    assert (await api.post(f"{ML}/reports", json=bad, headers=g)).status_code == 422
    missing = {"subject_type": "broker", "subject_id": str(uuid.uuid4()), "reason": "abuse"}
    assert (await api.post(f"{ML}/reports", json=missing, headers=g)).status_code == 404
    own = {"subject_type": "lot", "subject_id": str(ids["lot"]), "reason": "fake_lot"}
    r = await api.post(f"{ML}/reports", json=own, headers=g)
    assert r.json()["error"]["code"] == "cannot_report_self"
    first = await _report(api, GROWER, "rating", ids["rating"], "fake_rating")
    again = await _report(api, GROWER, "rating", ids["rating"], "fake_rating")
    assert again["id"] == first["id"]
    await _report(api, GROWER, "user", BROKER, "abuse")
    mine = (await api.get(f"{ML}/reports/mine", headers=g)).json()["reports"]
    assert [m["subject_type"] for m in mine] == ["user", "rating"]
    assert (await api.get(f"{ML}/reports/mine", headers=_headers(TRADER))).json() == {"reports": []}


async def test_report_photos_are_stored_without_exif(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], storage: FakeStorage
) -> None:
    report = await _report(api, GROWER, "buyer", ids["buyer"], "impersonation")
    url = f"{ML}/reports/{report['id']}/photos"
    jpeg = {**_headers(GROWER), "Content-Type": "image/jpeg"}
    r = await api.post(url, content=EXIF_JPEG, headers=jpeg)
    assert r.status_code == 200, r.text
    assert r.json()["photo_count"] == 1
    [(key, data)] = storage.objects.items()
    assert key == f"{GROWER}/report-{report['id']}-1.jpg"
    assert b"Exif" not in data
    assert b"GPS" not in data
    assert data.startswith(b"\xff\xd8")
    assert data.endswith(b"\xff\xd9")
    png = {**_headers(GROWER), "Content-Type": "image/png"}
    assert (await api.post(url, content=EXIF_JPEG, headers=png)).status_code == 422
    assert (await api.post(url, content=b"not a jpeg", headers=jpeg)).status_code == 422
    other = {**_headers(TRADER), "Content-Type": "image/jpeg"}
    assert (await api.post(url, content=EXIF_JPEG, headers=other)).status_code == 404
    for _ in range(2):
        assert (await api.post(url, content=EXIF_JPEG, headers=jpeg)).status_code == 200
    assert (await api.post(url, content=EXIF_JPEG, headers=jpeg)).status_code == 409


async def test_report_photo_without_storage_is_503(
    settings: Settings, maker: Maker, clock: Clock, ids: dict[str, uuid.UUID]
) -> None:
    transport = httpx.ASGITransport(app=_app(settings, maker, clock, None))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        report = await _report(c, GROWER, "buyer", ids["buyer"], "abuse")
        r = await c.post(
            f"{ML}/reports/{report['id']}/photos",
            content=EXIF_JPEG,
            headers={**_headers(GROWER), "Content-Type": "image/jpeg"},
        )
    assert r.status_code == 503


async def test_block_and_unblock_hide_users_from_each_other(
    api: httpx.AsyncClient, maker: Maker
) -> None:
    g = _headers(GROWER)
    assert (await api.put(f"{ML}/blocks/{GROWER}", headers=g)).status_code == 422
    for _ in range(2):  # repeating is a no-op
        assert (await api.put(f"{ML}/blocks/{TRADER}", headers=g)).status_code == 204
    assert (await api.get(f"{ML}/blocks", headers=g)).json() == {"blocked_user_ids": [str(TRADER)]}
    async with maker() as s:
        assert await is_blocked_between(s, TRADER, GROWER)
        for viewer in (GROWER, TRADER):  # both directions are hidden
            names = await s.scalars(
                select(BuyerProfile.name).where(not_blocked(viewer, BuyerProfile.user_id))
            )
            assert list(names) == ([] if viewer == GROWER else ["Ramesh Traders"])
        brokers = await s.scalars(
            select(BrokerProfile.name).where(not_blocked(TRADER, BrokerProfile.user_id))
        )
        assert list(brokers) == ["Suresh"]
    assert (await api.delete(f"{ML}/blocks/{TRADER}", headers=g)).status_code == 204
    assert (await api.delete(f"{ML}/blocks/{TRADER}", headers=g)).status_code == 204
    async with maker() as s:
        assert not await is_blocked_between(s, GROWER, TRADER)


async def _action(maker: Maker, user: uuid.UUID, subject: uuid.UUID, action: str) -> uuid.UUID:
    async with maker() as s:
        row = AdminAction(
            subject_type="buyer",
            subject_id=subject,
            user_id=user,
            action=action,
            reason_code="checks_passed" if action == "verify" else "fake_identity",
            actor_id=ADMIN_ID,
            acted_at=T0,
            appeal_state="none",
            appeal_photo_keys=[],
        )
        s.add(row)
        await s.commit()
        return row.id


async def test_affected_user_sees_the_reason_and_appeals_once(
    api: httpx.AsyncClient, ids: dict[str, uuid.UUID], maker: Maker, storage: FakeStorage
) -> None:
    hidden = await _action(maker, TRADER, ids["buyer"], "hide")
    verified = await _action(maker, TRADER, ids["buyer"], "verify")
    t = _headers(TRADER)
    mine = (await api.get(f"{ML}/account-actions", headers=t)).json()["actions"]
    assert {(a["action"], a["reason_code"], a["can_appeal"]) for a in mine} == {
        ("hide", "fake_identity", True),
        ("verify", "checks_passed", False),
    }
    others = await api.get(f"{ML}/account-actions", headers=_headers(GROWER))
    assert others.json() == {"actions": []}
    url = f"{ML}/account-actions/{hidden}/appeal"
    not_mine = await api.post(url, json={"reason": "identity_genuine"}, headers=_headers(GROWER))
    assert not_mine.status_code == 404
    text = {"reason": "identity_genuine", "text": "I am real"}
    assert (await api.post(url, json=text, headers=t)).status_code == 422
    assert (await api.post(url, json={"reason": "paid_on_time"}, headers=t)).status_code == 422
    jpeg = {**t, "Content-Type": "image/jpeg"}
    early = await api.post(f"{url}/photos", content=EXIF_JPEG, headers=jpeg)
    assert early.status_code == 409  # a photo goes with an appeal once it is made
    r = await api.post(url, json={"reason": "identity_genuine"}, headers=t)
    assert r.status_code == 200, r.text
    assert (r.json()["appeal_state"], r.json()["can_appeal"]) == ("appealed", False)
    assert (await api.post(url, json={"reason": "not_duplicate"}, headers=t)).status_code == 409
    photo = await api.post(f"{url}/photos", content=EXIF_JPEG, headers=jpeg)
    assert photo.json()["appeal_photo_count"] == 1
    assert all(b"Exif" not in v for v in storage.objects.values())
    verify_url = f"{ML}/account-actions/{verified}/appeal"
    r = await api.post(verify_url, json={"reason": "identity_genuine"}, headers=t)
    assert r.status_code == 409  # a verify is not appealable
