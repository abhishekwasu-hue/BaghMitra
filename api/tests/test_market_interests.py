"""Market linkage L4: interests, compare, accept = introduction (spec v1.5 §3 steps 3-5;
decisions c, g, h, j). The grower's name, phone and plot pin stay hidden until the grower
accepts; accepting closes the other interests with a notice; only the lot's grower accepts."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime
from typing import Any

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import PushDevice
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.market_link.models import BrokerProfile, BuyerProfile, PartyVerification
from bagmitra_api.market_link.notify import get_push_factory
from bagmitra_api.push.sender import PushMessage, SendResult
from bagmitra_api.routers.market_interests import InterestIn
from bagmitra_api.routers.scouting_photos import get_photo_storage
from tests.test_market_lots_sync import LOTS, StoringStorage, accept, draft, headers

# Full coordinates: a short "21.2" also matched timestamps such as "...:21.234" (flaky).
GROWER_SECRETS = ("Ramesh", "+919812345678", "21.2751", "78.5853", "Bag 1")


class FakeSender:
    def __init__(self) -> None:
        self.sent: list[PushMessage] = []

    async def send(self, message: PushMessage) -> SendResult:
        self.sent.append(message)
        return SendResult.SENT


@pytest.fixture
def sender() -> FakeSender:
    return FakeSender()


@pytest.fixture
async def ml(settings: Settings, engine: AsyncEngine, sender: FakeSender) -> AsyncIterator[Any]:
    app = create_app(settings.model_copy(update={"market_link_enabled": True}))
    maker = async_sessionmaker(engine, expire_on_commit=False)

    @asynccontextmanager
    async def _open() -> AsyncIterator[FakeSender]:
        yield sender

    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_photo_storage] = StoringStorage
    app.dependency_overrides[get_push_factory] = lambda: _open
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        c.maker = maker  # type: ignore[attr-defined]
        yield c


class Party:
    def __init__(self, user: uuid.UUID, profile: uuid.UUID) -> None:
        self.user, self.profile, self.h = user, profile, headers(user)


async def party(
    c: Any, kind: str = "buyer", status: str = "approved", terms: bool = True, name: str = "Shinde"
) -> Party:
    """A trader (buyer) or broker with a verification record and, by default, the role's
    accepted terms; the user also has a phone for pushes."""
    user = uuid.uuid4()
    async with c.maker() as s:
        model = BuyerProfile if kind == "buyer" else BrokerProfile
        prof = model(user_id=user, name=name, phone="+919800000001", district="Amravati")
        s.add(prof)
        await s.flush()
        s.add(
            PartyVerification(
                subject_type=kind,
                subject_id=prof.id,
                document_keys=[],
                status=status,
                checked_by=uuid.uuid4(),
                checked_at=datetime.now(UTC),
            )
        )
        s.add(PushDevice(owner_id=user, token=f"tok-{user}", platform="android"))
        await s.commit()
        pid = prof.id
    p = Party(user, pid)
    if terms:
        await accept(c, p.h, "trader" if kind == "buyer" else "broker")
    return p


async def published(c: Any) -> tuple[uuid.UUID, uuid.UUID, dict[str, str]]:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, c.photos = await draft(c, h, grower)
    assert (await c.post(f"{LOTS}/{lot_id}/publish", headers=h)).status_code == 200
    async with c.maker() as s:
        s.add(PushDevice(owner_id=grower, token=f"tok-{grower}", platform="android"))
        await s.commit()
    return grower, lot_id, h


BODY = {"basis": "per_quintal", "rate_paise": 320_000, "quantity_t": 12.0}


async def send(c: Any, lot_id: uuid.UUID, p: Party, **kw: Any) -> httpx.Response:
    body = {**BODY, "harvest_date": "2026-12-05", **kw}
    r: httpx.Response = await c.post(f"{LOTS}/{lot_id}/interests", json=body, headers=p.h)
    return r


async def test_flag_off_hides_every_interest_endpoint(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    some = uuid.uuid4()
    for method, path in (
        ("POST", f"{LOTS}/{some}/interests"),
        ("GET", f"{LOTS}/{some}/interests"),
        ("GET", "/v1/market-link/interests/mine"),
        ("POST", f"/v1/market-link/interests/{some}/accept"),
        ("GET", f"/v1/market-link/deals/{some}"),
    ):
        r = await client.request(method, path, headers=auth_headers, json={})
        assert r.status_code == 404, (path, r.text)


async def test_unverified_cannot_send_or_see(ml: Any) -> None:
    grower, lot_id, gh = await published(ml)
    for p in (
        await party(ml, status="pending"),
        await party(ml, status="rejected"),
        Party(uuid.uuid4(), uuid.uuid4()),  # signed in, no profile
        Party(grower, uuid.uuid4()),  # the grower
    ):
        r = await send(ml, lot_id, p)
        assert (r.status_code, r.json()["error"]["code"]) == (403, "not_verified")
        assert (await ml.get(f"{LOTS}/{lot_id}/interests", headers=p.h)).status_code == (
            200 if p.user == grower else 404
        )
    no_terms = await party(ml, terms=False)
    r = await send(ml, lot_id, no_terms)
    assert (r.status_code, r.json()["error"]["code"]) == (403, "terms_not_accepted")
    assert (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"] == []


async def test_interest_fields_only(ml: Any) -> None:
    _, lot_id, _ = await published(ml)
    trader = await party(ml)
    for extra in (
        {"commission_pct": 2},
        {"broker_income": 1},
        {"aadhaar_no": "1"},
        {"labour_paid_by": "trader"},
        {"advance_paise": 1},
        {"note": "call 9822012345"},
    ):
        assert (await send(ml, lot_id, trader, **extra)).status_code == 422, extra
    assert (await send(ml, lot_id, trader, rate_paise=0)).status_code == 422
    assert set(InterestIn.model_fields) == {
        "basis",
        "rate_paise",
        "quantity_t",
        "harvest_date",
        "broker_id",
        "trader_id",
    }


async def test_grower_compares_with_contact_hidden_until_accept(
    ml: Any, sender: FakeSender
) -> None:
    grower, lot_id, gh = await published(ml)
    trader = await party(ml)
    broker = await party(ml, "broker", name="Kale")
    r = await send(ml, lot_id, trader, broker_id=str(broker.profile))
    assert r.status_code == 201, r.text
    assert (r.json()["status"], r.json()["via_broker"], r.json()["deal_id"]) == (
        "open",
        True,
        None,
    )
    [push] = sender.sent
    assert (push.token, push.data["kind"]) == (f"tok-{grower}", "new_interest")
    assert "32" not in push.body
    assert "Shinde" not in push.body
    # Grower: rate, basis, trader's public profile with the verified badge and counts.
    [item] = (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"]
    assert (item["rate_paise"], item["basis"], item["quantity_t"]) == (320_000, "per_quintal", 12.0)
    assert (item["trader"]["name"], item["broker"]["name"]) == ("Shinde", "Kale")
    assert [b["kind"] for b in item["trader"]["badges"]] == ["checked"]
    assert (item["trader"]["deals_completed"], item["trader"]["stars"]) == (0, [])
    # Trader and broker: no grower identity before acceptance.
    for p in (trader, broker):
        mine = await ml.get("/v1/market-link/interests/mine", headers=p.h)
        assert len(mine.json()["interests"]) == 1
        assert mine.json()["interests"][0]["lot"]["village"] == "Warud"
        for secret in (*GROWER_SECRETS, str(grower)):
            assert secret not in mine.text
        assert (await ml.get(f"{LOTS}/{lot_id}/interests", headers=p.h)).status_code == 404


async def test_broker_sends_for_a_trader(ml: Any) -> None:
    _, lot_id, gh = await published(ml)
    trader = await party(ml)
    broker = await party(ml, "broker")
    unverified = await party(ml, status="pending")
    assert (await send(ml, lot_id, broker, trader_id=str(unverified.profile))).status_code == 404
    assert (await send(ml, lot_id, trader, broker_id=str(uuid.uuid4()))).status_code == 404
    both = {"trader_id": str(trader.profile), "broker_id": str(broker.profile)}
    assert (await send(ml, lot_id, broker, **both)).status_code == 422
    assert (await send(ml, lot_id, trader, trader_id=str(trader.profile))).status_code == 403
    r = await send(ml, lot_id, broker, trader_id=str(trader.profile))
    assert r.status_code == 201, r.text
    [item] = (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"]
    assert item["trader"]["id"] == str(trader.profile)
    assert item["broker"]["id"] == str(broker.profile)
    mine = (await ml.get("/v1/market-link/interests/mine", headers=trader.h)).json()
    assert len(mine["interests"]) == 1


async def test_a_new_interest_replaces_the_open_one(ml: Any) -> None:
    _, lot_id, gh = await published(ml)
    trader = await party(ml)
    await send(ml, lot_id, trader)
    await send(ml, lot_id, trader, rate_paise=350_000)
    [item] = (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"]
    assert item["rate_paise"] == 350_000
    assert (
        len((await ml.get("/v1/market-link/interests/mine", headers=trader.h)).json()["interests"])
        == 1
    )


async def test_only_the_lot_owner_accepts_and_accept_closes_the_others(
    ml: Any, sender: FakeSender
) -> None:
    _, lot_id, gh = await published(ml)
    chosen, other = await party(ml), await party(ml, name="Wankhede")
    broker = await party(ml, "broker", name="Kale")
    one = (await send(ml, lot_id, chosen, broker_id=str(broker.profile))).json()["id"]
    two = (await send(ml, lot_id, other)).json()["id"]
    url = f"/v1/market-link/interests/{one}/accept"
    stranger = headers(uuid.uuid4())
    for h in (chosen.h, other.h, broker.h, stranger):
        await accept(ml, h)  # grower terms too: the refusal is about the lot's owner
        r = await ml.post(url, headers=h)
        assert (r.status_code, r.json()["error"]["code"]) == (404, "interest_not_found")
    sender.sent.clear()
    r = await ml.post(url, headers=gh)
    assert r.status_code == 200, r.text
    intro = r.json()
    assert intro["grower"]["name"] == "Ramesh Patil"
    assert intro["grower"]["phone"] == "+919812345678"
    assert intro["grower"]["pin"] is not None
    assert (intro["trader"]["name"], intro["broker"]["name"]) == ("Shinde", "Kale")
    # Pushes: accepted to the trader and the broker, closed to the other trader.
    kinds = {m.token: m.data["kind"] for m in sender.sent}
    assert kinds == {
        f"tok-{chosen.user}": "accepted",
        f"tok-{broker.user}": "accepted",
        f"tok-{other.user}": "closed",
    }
    assert all("+91" not in m.body and "Ramesh" not in m.body for m in sender.sent)
    deal = f"/v1/market-link/deals/{intro['deal_id']}"
    for h in (gh, chosen.h, broker.h):
        got = await ml.get(deal, headers=h)
        assert got.status_code == 200
        assert got.json()["grower"]["phone"] == "+919812345678"
    assert (await ml.get(deal, headers=other.h)).status_code == 404
    # The other interest is closed (its notice); it never reveals the grower.
    mine = await ml.get("/v1/market-link/interests/mine", headers=other.h)
    [closed] = mine.json()["interests"]
    assert (closed["status"], closed["deal_id"]) == ("closed", None)
    for secret in GROWER_SECRETS:
        assert secret not in mine.text
    listed = (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"]
    assert {(i["id"], i["status"]) for i in listed} == {(one, "accepted"), (two, "closed")}
    # The lot left the traders' list; nothing more can be accepted or sent.
    assert (await ml.get(LOTS, headers=other.h)).json()["lots"] == []
    again = await ml.post(f"/v1/market-link/interests/{two}/accept", headers=gh)
    assert (again.status_code, again.json()["error"]["code"]) == (409, "lot_not_published")
    assert (await send(ml, lot_id, other)).status_code == 404
    # The parties keep the lot's photos; the other trader loses them with the list.
    photo = f"/v1/market-link/lot-photos/{ml.photos[0]}/url"
    assert (await ml.get(photo, headers=chosen.h)).status_code == 200
    assert (await ml.get(photo, headers=other.h)).status_code == 404


async def test_closing_a_lot_closes_its_interests(ml: Any, sender: FakeSender) -> None:
    _, lot_id, gh = await published(ml)
    trader = await party(ml)
    await send(ml, lot_id, trader)
    sender.sent.clear()
    assert (await ml.post(f"{LOTS}/{lot_id}/close", headers=gh)).status_code == 200
    assert [m.data["kind"] for m in sender.sent] == ["closed"]
    mine = (await ml.get("/v1/market-link/interests/mine", headers=trader.h)).json()
    assert mine["interests"][0]["status"] == "closed"


async def test_revoked_trader_is_hidden_and_cannot_be_accepted(ml: Any) -> None:
    _, lot_id, gh = await published(ml)
    trader = await party(ml)
    iid = (await send(ml, lot_id, trader)).json()["id"]
    async with ml.maker() as s:
        s.add(
            PartyVerification(
                subject_type="buyer",
                subject_id=trader.profile,
                document_keys=[],
                status="rejected",
                checked_by=uuid.uuid4(),
                checked_at=datetime.now(UTC),
            )
        )
        await s.commit()
    assert (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"] == []
    r = await ml.post(f"/v1/market-link/interests/{iid}/accept", headers=gh)
    assert (r.status_code, r.json()["error"]["code"]) == (409, "party_not_verified")


async def test_a_grower_cannot_send_on_own_lot(ml: Any) -> None:
    grower, lot_id, _ = await published(ml)
    async with ml.maker() as s:
        prof = BuyerProfile(user_id=grower, name="G", phone="+919800000009", district="Amravati")
        s.add(prof)
        await s.flush()
        s.add(
            PartyVerification(
                subject_type="buyer",
                subject_id=prof.id,
                document_keys=[],
                status="approved",
                checked_by=uuid.uuid4(),
                checked_at=datetime.now(UTC),
            )
        )
        await s.commit()
        pid = prof.id
    me = Party(grower, pid)
    await accept(ml, me.h, "trader")
    r = await send(ml, lot_id, me)
    assert (r.status_code, r.json()["error"]["code"]) == (409, "own_lot")


async def test_a_lot_hidden_by_the_package_rule_takes_no_interest(ml: Any) -> None:
    """Spec v1.5 §4E: while the package switch is ON, a lot without an active grant is
    hidden from traders, so an interest on it is refused like any lot they cannot see."""
    from tests.test_package_rules import configure, give  # noqa: PLC0415 - shared helpers

    ml.now = [datetime.now(UTC)]
    await configure(ml, switch=True)
    grower, lot_id, _ = await published(ml)
    trader = await party(ml)
    r = await send(ml, lot_id, trader)
    assert r.status_code == 404, r.text
    assert r.json()["error"]["code"] == "lot_not_found"
    await give(ml, grower, "UTR246824682468")
    assert (await send(ml, lot_id, trader)).status_code == 201
