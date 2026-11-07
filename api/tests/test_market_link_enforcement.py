"""Audit 2026-11-07: hide / suspend / delete / block are enforced by the market-link API
itself, through the real endpoints (spec v1.5 §4, §4C; `market_link/visibility.py`).
A blocked pair do not see each other's lots or send interests either way; a lot an admin hid
is gone for every trader; restore and unblock bring everything back."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

import httpx

from bagmitra_api.account.models import DeferredErasure
from tests.test_market_interests import ml, party, published, send, sender
from tests.test_market_link_reports import ADMIN, ADMIN_BASE
from tests.test_market_lots_sync import LOTS

__all__ = ["ml", "sender"]  # fixtures used by name

ML = "/v1/market-link"


async def act(c: Any, kind: str, subject: uuid.UUID, action: str, reason: str) -> None:
    body = {"subject_type": kind, "subject_id": str(subject), "action": action}
    r = await c.post(f"{ADMIN_BASE}/actions", json={**body, "reason_code": reason}, headers=ADMIN)
    assert r.status_code == 201, r.text


async def lot_ids(c: Any, h: dict[str, str]) -> set[str]:
    r: httpx.Response = await c.get(LOTS, headers=h)
    assert r.status_code == 200, r.text
    return {x["id"] for x in r.json()["lots"]}


async def photo_status(c: Any, h: dict[str, str]) -> int:
    r: httpx.Response = await c.get(f"{ML}/lot-photos/{c.photos[0]}/url", headers=h)
    return r.status_code


async def test_a_block_either_way_hides_the_lot_and_refuses_interests(ml: Any) -> None:
    grower, lot_id, gh = await published(ml)
    trader = await party(ml)
    assert str(lot_id) in await lot_ids(ml, trader.h)
    for blocker, blocked in ((gh, trader.user), (trader.h, grower)):
        assert (await ml.put(f"{ML}/blocks/{blocked}", headers=blocker)).status_code == 204
        assert str(lot_id) not in await lot_ids(ml, trader.h)
        assert await photo_status(ml, trader.h) == 404
        r = await send(ml, lot_id, trader)
        assert (r.status_code, r.json()["error"]["code"]) == (404, "lot_not_found")
        assert (await ml.delete(f"{ML}/blocks/{blocked}", headers=blocker)).status_code == 204
        assert str(lot_id) in await lot_ids(ml, trader.h)  # unblock brings it back
        assert await photo_status(ml, trader.h) == 200
    assert (await send(ml, lot_id, trader)).status_code == 201


async def test_a_broker_cannot_bring_a_trader_the_grower_blocked(ml: Any) -> None:
    _, lot_id, gh = await published(ml)
    trader, broker = await party(ml), await party(ml, kind="broker")
    assert (await ml.put(f"{ML}/blocks/{trader.user}", headers=gh)).status_code == 204
    r = await send(ml, lot_id, broker, trader_id=str(trader.profile))
    assert (r.status_code, r.json()["error"]["code"]) == (404, "lot_not_found")
    assert str(lot_id) in await lot_ids(ml, broker.h)  # the broker still sees the lot
    assert (await ml.delete(f"{ML}/blocks/{trader.user}", headers=gh)).status_code == 204
    assert (await send(ml, lot_id, broker, trader_id=str(trader.profile))).status_code == 201


async def test_a_lot_an_admin_hid_is_gone_for_every_trader_until_restored(ml: Any) -> None:
    _, lot_id, _ = await published(ml)
    one, two = await party(ml), await party(ml, name="Patil")
    await act(ml, "lot", lot_id, "hide", "fake_lot")
    for t in (one, two):
        assert str(lot_id) not in await lot_ids(ml, t.h)
        assert await photo_status(ml, t.h) == 404
        r = await send(ml, lot_id, t)
        assert (r.status_code, r.json()["error"]["code"]) == (404, "lot_not_found")
    await act(ml, "lot", lot_id, "restore", "checks_passed")
    assert str(lot_id) in await lot_ids(ml, two.h)
    assert (await send(ml, lot_id, two)).status_code == 201


async def test_a_suspended_grower_lots_are_gone(ml: Any) -> None:
    grower, lot_id, _ = await published(ml)
    trader = await party(ml)
    await act(ml, "user", grower, "suspend", "abuse")
    assert str(lot_id) not in await lot_ids(ml, trader.h)
    await act(ml, "user", grower, "restore", "checks_passed")
    assert str(lot_id) in await lot_ids(ml, trader.h)


SOME = uuid.UUID(int=7)
# Every market-link write a suspended account may not make (register, publish, interest,
# accept, deal done, rate, report). Blocks, appeals, terms and closing an own lot stay open.
WRITES = (
    ("POST", "/traders"),
    ("POST", "/exporters"),
    ("POST", "/brokers"),
    ("POST", "/providers"),
    ("PUT", f"/profiles/buyer/{SOME}/address"),
    ("POST", f"/profiles/buyer/{SOME}/documents"),
    ("POST", f"/profiles/buyer/{SOME}/place-photo"),
    ("POST", f"/lots/{SOME}/publish"),
    ("PUT", f"/lot-photos/{SOME}/photo"),
    ("POST", f"/lots/{SOME}/interests"),
    ("POST", f"/interests/{SOME}/accept"),
    ("POST", f"/deals/{SOME}/done"),
    ("PUT", f"/deals/{SOME}/ratings/buyer"),
    ("POST", "/reports"),
    ("POST", f"/reports/{SOME}/photos"),
)


async def test_a_suspended_account_makes_no_write_and_sees_why(ml: Any) -> None:
    trader = await party(ml)
    await act(ml, "buyer", trader.profile, "suspend", "fake_identity")
    for method, path in WRITES:
        r = await ml.request(method, f"{ML}{path}", json={}, headers=trader.h)
        assert (r.status_code, r.json()["error"]["code"]) == (403, "suspended"), (path, r.text)
    mine = (await ml.get(f"{ML}/account-actions", headers=trader.h)).json()["actions"]
    assert [(a["action"], a["reason_code"]) for a in mine] == [("suspend", "fake_identity")]
    await act(ml, "buyer", trader.profile, "restore", "checks_passed")
    r = await ml.post(f"{ML}/reports", json={}, headers=trader.h)
    assert r.status_code == 422  # past the guard again


async def test_a_suspended_hidden_or_deleted_viewer_sees_no_lot(ml: Any) -> None:
    _, lot_id, _ = await published(ml)
    suspended, hidden, deleted = await party(ml), await party(ml), await party(ml)
    await act(ml, "user", suspended.user, "suspend", "abuse")
    await act(ml, "buyer", hidden.profile, "hide", "fake_identity")
    async with ml.maker() as s:
        now = datetime.now(UTC)
        s.add(DeferredErasure(user_id=deleted.user, requested_at=now, erase_after=now))
        await s.commit()
    for p in (suspended, hidden, deleted):
        r = await ml.get(LOTS, headers=p.h)
        assert (r.status_code, r.json()["error"]["code"]) == (403, "not_verified")
        assert await photo_status(ml, p.h) == 404
    r = await send(ml, lot_id, hidden)
    assert (r.status_code, r.json()["error"]["code"]) == (403, "not_verified")
    await act(ml, "user", suspended.user, "restore", "checks_passed")
    await act(ml, "buyer", hidden.profile, "restore", "checks_passed")
    for p in (suspended, hidden):
        assert str(lot_id) in await lot_ids(ml, p.h)


async def test_a_broker_cannot_bring_a_hidden_trader(ml: Any) -> None:
    _, lot_id, _ = await published(ml)
    trader, broker = await party(ml), await party(ml, kind="broker")
    await act(ml, "buyer", trader.profile, "hide", "fake_identity")
    r = await send(ml, lot_id, broker, trader_id=str(trader.profile))
    assert (r.status_code, r.json()["error"]["code"]) == (404, "trader_not_found")
