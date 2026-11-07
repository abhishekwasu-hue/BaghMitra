"""Market linkage admin: verification queue and rating tags (spec v1.5 §3A, §4; decisions c,
h, j; Q70). Role `market_link_admin`, behind the `market_link_enabled` gate."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from bagmitra_api.auth.grant_roles import KNOWN_ROLES
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.guards import is_verified
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    PartyVerification,
    RatingTag,
    ServiceProvider,
)
from bagmitra_api.market_link.seed import seed_rating_tags
from bagmitra_api.photos.storage import SignedUrl
from bagmitra_api.routers.scouting_photos import get_photo_storage
from bagmitra_api.weather.service import get_clock
from tests.conftest import make_token

Maker = async_sessionmaker[AsyncSession]
BASE = "/v1/admin/market-link"
ADMIN_ID = uuid.uuid4()
T0 = datetime(2026, 11, 1, 9, 0, tzinfo=UTC)


def _headers(*roles: str, user: uuid.UUID | None = None) -> dict[str, str]:
    token = make_token(user or uuid.uuid4(), app_metadata={"roles": list(roles)})
    return {"Authorization": f"Bearer {token}"}


ADMIN = _headers("market_link_admin", user=ADMIN_ID)


class FakeStorage:
    def __init__(self) -> None:
        self.signed: list[str] = []

    async def signed_download_url(self, key: str, expires_in: int) -> SignedUrl:
        self.signed.append(key)
        return SignedUrl(url=f"https://storage.test/{key}?token=t", expires_in=expires_in)


class Ticks:
    """A clock that moves one minute per call, so the latest record is unambiguous."""

    def __init__(self) -> None:
        self.now = T0

    def __call__(self) -> datetime:
        self.now += timedelta(minutes=1)
        return self.now


ticks = Ticks()


@pytest.fixture
def storage() -> FakeStorage:
    return FakeStorage()


@pytest.fixture
def maker(engine: AsyncEngine) -> Maker:
    return async_sessionmaker(engine, expire_on_commit=False)


@pytest.fixture
async def subjects(maker: Maker) -> dict[str, uuid.UUID]:
    """A buyer with a pending record (documents), a broker with no record yet (older), and an
    approved provider (not in the queue)."""
    ids = {k: uuid.uuid4() for k in ("buyer", "broker", "provider")}
    async with maker() as s:
        s.add_all(
            [
                BuyerProfile(
                    id=ids["buyer"],
                    user_id=uuid.uuid4(),
                    name="Ramesh Traders",
                    firm="RT & Sons",
                    phone="919800000001",
                    markets=["Kalamna"],
                    district="Nagpur",
                    crops=["santra"],
                    apmc_licence_no="APMC-42",
                    created_at=T0 - timedelta(days=1),
                ),
                BrokerProfile(
                    id=ids["broker"],
                    user_id=uuid.uuid4(),
                    name="Suresh Dalal",
                    phone="919800000002",
                    district="Amravati",
                    created_at=T0 - timedelta(days=3),
                ),
                ServiceProvider(
                    id=ids["provider"],
                    kind="weighbridge",
                    name="Warud Kata",
                    phone="919800000003",
                    district="Amravati",
                    cert_photo_key="docs/cert.jpg",
                    created_at=T0 - timedelta(days=5),
                ),
                PartyVerification(
                    subject_type="buyer",
                    subject_id=ids["buyer"],
                    document_keys=["docs/apmc.jpg", "docs/shop.jpg"],
                    status="pending",
                    created_at=T0 - timedelta(hours=1),
                ),
                PartyVerification(
                    subject_type="provider",
                    subject_id=ids["provider"],
                    status="approved",
                    checked_by=ADMIN_ID,
                    checked_at=T0 - timedelta(days=4),
                    created_at=T0 - timedelta(days=4),
                ),
            ]
        )
        await seed_rating_tags(s)
        await s.commit()
    return ids


def _app(settings: Settings, maker: Maker, storage: FakeStorage, on: bool) -> FastAPI:
    app = create_app(settings.model_copy(update={"market_link_enabled": on}))
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_clock] = lambda: ticks
    app.dependency_overrides[get_photo_storage] = lambda: storage
    return app


@pytest.fixture(autouse=True)
def _reset_clock() -> None:
    ticks.now = T0


@pytest.fixture
async def api(
    settings: Settings,
    maker: Maker,
    storage: FakeStorage,
    subjects: dict[str, uuid.UUID],
) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=_app(settings, maker, storage, on=True))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


def test_role_is_known_to_the_grant_script() -> None:
    assert "market_link_admin" in KNOWN_ROLES
    # BagMitra representative (addendum 2): place photo + address only (built in L2).
    assert "market_link_rep" in KNOWN_ROLES


async def test_flag_off_is_404_even_for_the_admin(
    settings: Settings,
    maker: Maker,
    storage: FakeStorage,
    subjects: dict[str, uuid.UUID],
) -> None:
    transport = httpx.ASGITransport(app=_app(settings, maker, storage, on=False))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        for headers in (ADMIN, {}):
            assert (await c.get(f"{BASE}/verifications", headers=headers)).status_code == 404
            assert (await c.get(f"{BASE}/rating-tags", headers=headers)).status_code == 404


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "/verifications"),
        ("GET", "/verifications/buyer/{buyer}"),
        ("POST", "/verifications/buyer/{buyer}/decision"),
        ("GET", "/verifications/buyer/{buyer}/documents/0/url"),
        ("GET", "/rating-tags"),
        ("PUT", "/rating-tags/{tag}"),
    ],
)
async def test_role_required(
    api: httpx.AsyncClient, subjects: dict[str, uuid.UUID], method: str, path: str
) -> None:
    url = BASE + path.format(buyer=subjects["buyer"], tag=uuid.uuid4())
    body = {"status": "approved"} if method == "POST" else None
    assert (await api.request(method, url, json=body)).status_code == 401
    others = sorted(KNOWN_ROLES - {"market_link_admin"})
    for headers in (_headers(), _headers(*others)):
        res = await api.request(method, url, json=body, headers=headers)
        assert res.status_code == 403, res.text
        assert res.json()["error"]["message"] == "requires role market_link_admin"


async def test_queue_lists_pending_oldest_first_with_fields_and_documents(
    api: httpx.AsyncClient, subjects: dict[str, uuid.UUID]
) -> None:
    res = await api.get(f"{BASE}/verifications", headers=ADMIN)
    assert res.status_code == 200, res.text
    queue = res.json()["subjects"]
    assert [(s["subject_type"], s["name"]) for s in queue] == [
        ("broker", "Suresh Dalal"),
        ("buyer", "Ramesh Traders"),
    ]
    buyer = queue[1]
    assert buyer["status"] == "pending"
    assert buyer["document_keys"] == ["docs/apmc.jpg", "docs/shop.jpg"]
    assert buyer["fields"] == {
        "name": "Ramesh Traders",
        "firm": "RT & Sons",
        "phone": "919800000001",
        "markets": "Kalamna",
        "district": "Nagpur",
        "crops": "santra",
        "apmc_licence_no": "APMC-42",
        "kind": "trader",
    }
    only = await api.get(f"{BASE}/verifications?subject_type=buyer", headers=ADMIN)
    assert [s["subject_type"] for s in only.json()["subjects"]] == ["buyer"]
    bad = await api.get(f"{BASE}/verifications?subject_type=grower", headers=ADMIN)
    assert bad.status_code == 422


async def test_approve_writes_a_new_record_and_verifies(
    api: httpx.AsyncClient,
    maker: Maker,
    subjects: dict[str, uuid.UUID],
) -> None:
    buyer = subjects["buyer"]
    async with maker() as s:
        assert await is_verified(s, "buyer", buyer) is False
    url = f"{BASE}/verifications/buyer/{buyer}/decision"
    # Spec §4 (L7): a trader is approved only after a check of GSTIN / APMC / IEC.
    refused = await api.post(url, headers=ADMIN, json={"status": "approved"})
    assert refused.status_code == 422
    assert refused.json()["error"]["code"] == "verified_rule_not_met"
    check = {"kind": "apmc", "result": "passed"}
    checked = await api.post(
        f"{BASE}/verifications/buyer/{buyer}/checks", headers=ADMIN, json=check
    )
    assert checked.status_code == 200, checked.text
    res = await api.post(url, headers=ADMIN, json={"status": "approved"})
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["subject"]["status"] == "approved"
    newest, pending = body["history"]
    assert newest["status"] == "approved"
    assert newest["checked_by"] == str(ADMIN_ID)
    assert newest["checked_at"].startswith("2026-11-01T09:02")
    assert newest["document_keys"] == ["docs/apmc.jpg", "docs/shop.jpg"]
    assert pending["status"] == "pending"
    assert pending["checked_by"] is None
    async with maker() as s:
        assert await is_verified(s, "buyer", buyer) is True
    queue = (await api.get(f"{BASE}/verifications", headers=ADMIN)).json()["subjects"]
    assert [q["subject_type"] for q in queue] == ["broker"]


async def test_reject_needs_a_reason(
    api: httpx.AsyncClient, subjects: dict[str, uuid.UUID]
) -> None:
    url = f"{BASE}/verifications/broker/{subjects['broker']}/decision"
    for body in ({"status": "rejected"}, {"status": "rejected", "reason": "  "}):
        assert (await api.post(url, headers=ADMIN, json=body)).status_code == 422
    res = await api.post(
        url, headers=ADMIN, json={"status": "rejected", "reason": "Photo ID unreadable"}
    )
    assert res.status_code == 200, res.text
    [row] = res.json()["history"]
    assert (row["status"], row["reason"]) == ("rejected", "Photo ID unreadable")
    assert row["checked_by"] == str(ADMIN_ID)


async def test_later_reject_revokes_and_old_rows_stay(
    api: httpx.AsyncClient,
    maker: Maker,
    subjects: dict[str, uuid.UUID],
) -> None:
    provider = subjects["provider"]
    url = f"{BASE}/verifications/provider/{provider}/decision"
    res = await api.post(url, headers=ADMIN, json={"status": "rejected", "reason": "Cert expired"})
    assert res.status_code == 200, res.text
    assert [h["status"] for h in res.json()["history"]] == ["rejected", "approved"]
    async with maker() as s:
        assert await is_verified(s, "provider", provider) is False
        old = await s.scalar(
            select(PartyVerification).where(PartyVerification.status == "approved")
        )
        assert old is not None
        assert old.checked_at is not None
        assert old.reason is None
    history = await api.get(f"{BASE}/verifications/provider/{provider}", headers=ADMIN)
    assert history.status_code == 200
    assert history.json()["subject"]["document_keys"] == ["docs/cert.jpg"]
    assert history.json()["subject"]["fields"]["kind"] == "weighbridge"


async def test_unknown_subject_is_404(
    api: httpx.AsyncClient, subjects: dict[str, uuid.UUID]
) -> None:
    missing = uuid.uuid4()
    assert (
        await api.get(f"{BASE}/verifications/buyer/{missing}", headers=ADMIN)
    ).status_code == 404
    res = await api.post(
        f"{BASE}/verifications/buyer/{missing}/decision", headers=ADMIN, json={"status": "approved"}
    )
    assert res.status_code == 404
    assert res.json()["error"]["code"] == "subject_not_found"
    # A buyer id asked for as a broker is unknown too.
    wrong = f"{BASE}/verifications/broker/{subjects['buyer']}"
    assert (await api.get(wrong, headers=ADMIN)).status_code == 404


@pytest.mark.parametrize(
    "extra", [{"commission": 2}, {"brokerage_paise": 100}, {"meta": {"dalali": 1}}, {"x": 1}]
)
async def test_decision_rejects_commission_and_unknown_keys(
    api: httpx.AsyncClient,
    maker: Maker,
    subjects: dict[str, uuid.UUID],
    extra: dict[str, object],
) -> None:
    url = f"{BASE}/verifications/buyer/{subjects['buyer']}/decision"
    res = await api.post(url, headers=ADMIN, json={"status": "approved", **extra})
    assert res.status_code == 422, res.text
    async with maker() as s:
        assert await s.scalar(select(func.count()).select_from(PartyVerification)) == 2


async def test_document_url_signs_only_keys_on_record(
    api: httpx.AsyncClient, storage: FakeStorage, subjects: dict[str, uuid.UUID]
) -> None:
    base = f"{BASE}/verifications/buyer/{subjects['buyer']}/documents"
    res = await api.get(f"{base}/1/url", headers=ADMIN)
    assert res.status_code == 200, res.text
    assert res.json()["photo_key"] == "docs/shop.jpg"
    assert (await api.get(f"{base}/2/url", headers=ADMIN)).status_code == 404
    assert (await api.get(f"{base}/-1/url", headers=ADMIN)).status_code == 404
    assert storage.signed == ["docs/shop.jpg"]


async def test_rating_tags_list_all_and_edit(
    api: httpx.AsyncClient,
    maker: Maker,
) -> None:
    res = await api.get(f"{BASE}/rating-tags", headers=ADMIN)
    assert res.status_code == 200, res.text
    tags = res.json()["tags"]
    assert tags
    assert {t["status"] for t in tags} == {"draft"}
    tag = tags[0]
    body = {"label_mr": " नवीन ", "label_hi": "नया", "label_en": "New", "status": "active"}
    put = await api.put(f"{BASE}/rating-tags/{tag['id']}", headers=ADMIN, json=body)
    assert put.status_code == 200, put.text
    assert (put.json()["label_mr"], put.json()["status"]) == ("नवीन", "active")
    async with maker() as s:
        row = await s.get(RatingTag, uuid.UUID(tag["id"]))
        assert row is not None
        assert (row.status, row.key) == ("active", tag["key"])
    user = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    public = (await api.get("/v1/market-link/rating-tags", headers=user)).json()["tags"]
    assert [t["id"] for t in public] == [tag["id"]]
    for bad in (
        {**body, "status": "live"},
        {**body, "label_en": ""},
        {**body, "commission": 1},
        {**body, "key": "renamed"},
    ):
        res = await api.put(f"{BASE}/rating-tags/{tag['id']}", headers=ADMIN, json=bad)
        assert res.status_code == 422, bad
    missing = await api.put(f"{BASE}/rating-tags/{uuid.uuid4()}", headers=ADMIN, json=body)
    assert missing.status_code == 404
