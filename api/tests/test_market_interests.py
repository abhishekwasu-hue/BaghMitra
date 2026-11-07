"""Market linkage L4, part 1: verified traders / brokers send interests and the grower compares
them (spec v1.5 §3 steps 3-4; decisions c, g, h, j). The grower's name, phone and plot pin stay
hidden from every sender."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

import httpx

from bagmitra_api.db.models import PushDevice
from bagmitra_api.market_link.models import BrokerProfile, BuyerProfile, PartyVerification
from bagmitra_api.routers.market_interests import InterestIn
from tests.test_market_lots_sync import LOTS, accept, draft, headers, ml, storage

# The enabled client and storage fixtures of the lot tests.
__all__ = ["ml", "storage"]

GROWER_SECRETS = ("Ramesh", "+919812345678", "21.2", "78.5", "Bag 1")


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
    lot_id, _ = await draft(c, h, grower)
    assert (await c.post(f"{LOTS}/{lot_id}/publish", headers=h)).status_code == 200
    async with c.maker() as s:
        s.add(PushDevice(owner_id=grower, token=f"tok-{grower}", platform="android"))
        await s.commit()
    return grower, lot_id, h


BODY = {"basis": "per_tonne", "rate_paise": 3_200_000, "quantity_t": 12.0}


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


async def test_grower_compares_with_contact_hidden_until_accept(ml: Any) -> None:
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
    # Grower: rate, basis, trader's public profile with the verified badge and counts.
    [item] = (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"]
    assert (item["rate_paise"], item["basis"], item["quantity_t"]) == (3_200_000, "per_tonne", 12.0)
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
    await send(ml, lot_id, trader, rate_paise=3_500_000)
    [item] = (await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)).json()["interests"]
    assert item["rate_paise"] == 3_500_000
    assert (
        len((await ml.get("/v1/market-link/interests/mine", headers=trader.h)).json()["interests"])
        == 1
    )


async def test_revoked_trader_is_hidden(ml: Any) -> None:
    _, lot_id, gh = await published(ml)
    trader = await party(ml)
    await send(ml, lot_id, trader)
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
