"""Audit 2026-11-07: hide / suspend / delete / block are enforced by the market-link API
itself, through the real endpoints (spec v1.5 §4, §4C; `market_link/visibility.py`).
A blocked pair do not see each other's lots or send interests either way; a lot an admin hid
is gone for every trader; restore and unblock bring everything back."""

from __future__ import annotations

import uuid
from typing import Any

import httpx

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
