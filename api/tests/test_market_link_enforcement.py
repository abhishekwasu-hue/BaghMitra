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
from bagmitra_api.market_link.models import PartyVerification, Rating, ServiceProvider
from tests.test_market_interests import ml, party, published, send, sender
from tests.test_market_link_profiles import _deal
from tests.test_market_link_reports import ADMIN, ADMIN_BASE
from tests.test_market_lots_sync import LOTS, headers

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


async def provider(c: Any, user: uuid.UUID) -> uuid.UUID:
    """A verified weighbridge owned by `user`."""
    async with c.maker() as s:
        row = ServiceProvider(
            user_id=user,
            kind="weighbridge",
            name="Kata",
            phone="+919800000002",
            district="Amravati",
        )
        s.add(row)
        await s.flush()
        s.add(
            PartyVerification(
                subject_type="provider",
                subject_id=row.id,
                document_keys=[],
                status="approved",
                checked_by=uuid.uuid4(),
                checked_at=datetime.now(UTC),
            )
        )
        await s.commit()
        return row.id


async def listed(c: Any, h: dict[str, str]) -> set[str]:
    out: set[str] = set()
    for path, params in (("profiles", {"role": "trader"}), ("providers", {})):
        r = await c.get(f"{ML}/{path}", params=params, headers=h)
        assert r.status_code == 200, r.text
        out |= {p["id"] for p in r.json()["profiles"]}
    return out


async def test_profiles_and_providers_follow_hide_suspend_and_block(ml: Any) -> None:
    viewer = uuid.uuid4()
    vh = headers(viewer)
    trader, owner = await party(ml), uuid.uuid4()
    kata = await provider(ml, owner)
    ids = {str(trader.profile), str(kata)}
    assert ids <= await listed(ml, vh)
    one = f"{ML}/profiles/buyer/{trader.profile}"
    assert (await ml.get(one, headers=vh)).status_code == 200
    # Hidden profile, suspended user, a block either way: gone from both lists and the page.
    await act(ml, "buyer", trader.profile, "hide", "fake_identity")
    await act(ml, "user", owner, "suspend", "abuse")
    assert not ids & await listed(ml, vh)
    assert (await ml.get(one, headers=vh)).status_code == 404
    await act(ml, "buyer", trader.profile, "restore", "checks_passed")
    await act(ml, "user", owner, "restore", "checks_passed")
    assert ids <= await listed(ml, vh)
    for blocker, blocked in ((vh, trader.user), (trader.h, viewer)):
        assert (await ml.put(f"{ML}/blocks/{blocked}", headers=blocker)).status_code == 204
        assert str(trader.profile) not in await listed(ml, vh)
        assert (await ml.get(one, headers=vh)).status_code == 404
        assert (await ml.delete(f"{ML}/blocks/{blocked}", headers=blocker)).status_code == 204
    assert ids <= await listed(ml, vh)


async def test_the_grower_does_not_see_interests_of_blocked_or_suspended_traders(
    ml: Any,
) -> None:
    _, lot_id, gh = await published(ml)
    blocked, suspended, kept = await party(ml), await party(ml), await party(ml, name="Kale")
    for t in (blocked, suspended, kept):
        assert (await send(ml, lot_id, t)).status_code == 201

    async def names() -> list[str]:
        r = await ml.get(f"{LOTS}/{lot_id}/interests", headers=gh)
        assert r.status_code == 200, r.text
        return sorted(i["trader"]["id"] for i in r.json()["interests"])

    everyone = sorted(str(t.profile) for t in (blocked, suspended, kept))
    assert await names() == everyone
    assert (await ml.put(f"{ML}/blocks/{blocked.user}", headers=gh)).status_code == 204
    await act(ml, "user", suspended.user, "suspend", "abuse")
    assert await names() == [str(kept.profile)]
    assert (await ml.delete(f"{ML}/blocks/{blocked.user}", headers=gh)).status_code == 204
    await act(ml, "user", suspended.user, "restore", "checks_passed")
    assert await names() == everyone


async def test_ratings_of_a_suspended_or_deleted_rater_still_count(ml: Any) -> None:
    trader = await party(ml)
    raters = (uuid.uuid4(), uuid.uuid4())
    async with ml.maker() as s:
        for rater in raters:
            deal = await _deal(ml.maker, trader.user, None, done=True)
            s.add(
                Rating(
                    deal_id=deal,
                    rater_id=rater,
                    ratee_id=trader.user,
                    ratee_role="trader",
                    question_key="trader_on_date",
                    stars=4,
                    tag_ids=[],
                )
            )
        now = datetime.now(UTC)
        s.add(DeferredErasure(user_id=raters[1], requested_at=now, erase_after=now))
        await s.commit()
    await act(ml, "user", raters[0], "suspend", "abuse")
    r = await ml.get(f"{ML}/profiles/buyer/{trader.profile}", headers=headers(uuid.uuid4()))
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["stars"] == [{"question_key": "trader_on_date", "average": 4.0, "count": 2}]
    assert not {str(x) for x in raters} & set(str(body).split("'"))  # no rater named
