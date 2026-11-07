"""Market linkage L7: the fake-deal checks before a rating is saved (spec v1.5 §4C; Q100,
Q113, Q115). Accounts seen on one phone cannot rate each other (409 `same_device`); a pair
of accounts that only ever complete deals with each other may still rate, and the deal
gets one `pair_only` event per rater and ratee for the admin."""

from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import select

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.market_link.deals import PartyRole, party_roles
from bagmitra_api.market_link.models import DealEvent, DeviceSighting, Rating
from bagmitra_api.market_link.trust import device_hash
from tests.test_market_deals import Clock, Deal, answers, clock, completed, rate
from tests.test_market_interests import ml, sender

__all__ = ["clock", "ml", "sender"]  # fixtures used below


async def _users(ml: Any, deal: Deal) -> dict[PartyRole, uuid.UUID]:
    async with ml.maker() as s:
        return await party_roles(s, uuid.UUID(deal.id))


async def _seen(ml: Any, phone: str, *users: uuid.UUID) -> None:
    async with ml.maker() as s:
        for u in users:
            s.add(DeviceSighting(device_hash=device_hash(phone), user_id=u))
        await s.commit()


async def _events(ml: Any, deal: Deal, kind: str) -> list[DealEvent]:
    async with ml.maker() as s:
        rows = await s.scalars(
            select(DealEvent).where(DealEvent.deal_id == uuid.UUID(deal.id), DealEvent.kind == kind)
        )
        return list(rows)


async def _ratings(ml: Any, deal: Deal) -> int:
    async with ml.maker() as s:
        rows = await s.scalars(select(Rating).where(Rating.deal_id == uuid.UUID(deal.id)))
        return len(list(rows))


async def test_parties_on_one_phone_cannot_rate_each_other(ml: Any, clock: Clock) -> None:
    deal = await completed(ml)
    users = await _users(ml, deal)
    await _seen(ml, "phone-1", users["grower"], users["trader"])
    r = await rate(ml, deal, deal.gh, "trader", answers("trader"))
    assert (r.status_code, r.json()["error"]["code"]) == (409, "same_device")
    r = await rate(ml, deal, deal.trader.h, "grower", answers("grower"))
    assert (r.status_code, r.json()["error"]["code"]) == (409, "same_device")
    assert await _ratings(ml, deal) == 0
    # The broker was never on that phone: the grower rates the broker as usual.
    r = await rate(ml, deal, deal.gh, "broker", answers("broker"))
    assert r.status_code == 200, r.text
    assert await _events(ml, deal, "pair_only") == []


async def test_other_phones_do_not_block(ml: Any, clock: Clock) -> None:
    deal = await completed(ml)
    users = await _users(ml, deal)
    await _seen(ml, "phone-1", users["grower"])
    await _seen(ml, "phone-2", users["trader"], users["broker"])
    r = await rate(ml, deal, deal.gh, "trader", answers("trader"))
    assert r.status_code == 200, r.text
    # Default MARKET_LINK_PAIR_MIN_DEALS (3): one deal is not a pair-only pattern yet.
    assert await _events(ml, deal, "pair_only") == []


async def test_pair_only_rating_is_saved_and_flagged_once(
    ml: Any, clock: Clock, settings: Settings
) -> None:
    low = settings.model_copy(update={"market_link_enabled": True, "market_link_pair_min_deals": 1})
    ml._transport.app.dependency_overrides[get_settings] = lambda: low
    deal = await completed(ml)
    users = await _users(ml, deal)
    for stars in (4, 2):  # a change of the rating does not flag again
        r = await rate(ml, deal, deal.gh, "trader", answers("trader", stars))
        assert r.status_code == 200, r.text
    events = await _events(ml, deal, "pair_only")
    assert [(e.actor_id, e.detail) for e in events] == [
        (None, {"rater_id": str(users["grower"]), "ratee_id": str(users["trader"])})
    ]
    assert await _ratings(ml, deal) > 0
    # The trader's rating of the grower is a second rater / ratee: its own flag.
    r = await rate(ml, deal, deal.trader.h, "grower", answers("grower"))
    assert r.status_code == 200, r.text
    assert len(await _events(ml, deal, "pair_only")) == 2
