"""After the introduction (spec v1.5 §3 step 7, §3A; Q66, Q67): the "deal done" taps and the
rating window. BagMitra records only that both sides said the deal is done and the stars /
ticks they give each other; never the deal's terms, payment or any dispute (§1 core principle).

- The grower and the trader each tap "deal done"; the deal completes when both have (Q67,
  Q81: the broker does not tap). `completed_at` is the later tap.
- Rating opens at completion and can be given or changed for `RATING_DAYS` days, then locks.
- Who rates whom (Q112): the grower rates the trader and the broker; the trader and the broker
  rate the grower. Each rating answers every question of the rated role (seed `questions`).
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta
from functools import cache
from typing import Literal, cast

from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.errors import ApiError
from bagmitra_api.db.base import as_utc
from bagmitra_api.market_link.models import DealEvent, DealParty, MarketDeal
from bagmitra_api.market_link.seed import rating_tag_seeds
from bagmitra_api.market_link.trust import pair_only, same_device

PartyRole = Literal["grower", "trader", "broker"]
RATING_DAYS = 7
# Rater role -> the roles it rates (Q112).
RATES: dict[str, tuple[PartyRole, ...]] = {
    "grower": ("trader", "broker"),
    "trader": ("grower",),
    "broker": ("grower",),
}
# Roles that tap "deal done" (Q67, Q81).
TAPPERS = ("grower", "trader")
# Deal event kind: the rater and ratee only ever complete deals with each other (§4C, Q115).
PAIR_ONLY = "pair_only"


@cache
def questions() -> dict[str, tuple[str, ...]]:
    """Rated role -> its question keys, in order (spec §3A; one list with the tag seeds)."""
    return {role: tuple(qs) for role, qs in rating_tag_seeds().questions.items()}


class DealStateOut(BaseModel):
    """Where the deal stands for the caller: who tapped "deal done", and the rating window."""

    my_role: PartyRole
    grower_done_at: datetime | None
    trader_done_at: datetime | None
    completed_at: datetime | None
    # Rating can be given or changed until this moment (completion + 7 days); null before.
    rating_until: datetime | None
    rating_locked: bool
    # Roles the caller rates on this deal (only parties present on the deal).
    rates: list[PartyRole]


async def party_roles(session: AsyncSession, deal_id: uuid.UUID) -> dict[PartyRole, uuid.UUID]:
    """Role -> user id of the deal's parties."""
    rows = await session.execute(
        select(DealParty.role, DealParty.user_id).where(DealParty.deal_id == deal_id)
    )
    return {cast(PartyRole, role): user for role, user in rows.tuples()}


def _utc(value: datetime | None) -> datetime | None:
    return None if value is None else as_utc(value)


def rating_until(deal: MarketDeal) -> datetime | None:
    if deal.completed_at is None:
        return None
    return as_utc(deal.completed_at) + timedelta(days=RATING_DAYS)


def is_locked(deal: MarketDeal, now: datetime) -> bool:
    until = rating_until(deal)
    return until is not None and now >= until


def deal_state(
    deal: MarketDeal, role: PartyRole, parties: dict[PartyRole, uuid.UUID], now: datetime
) -> DealStateOut:
    return DealStateOut(
        my_role=role,
        grower_done_at=_utc(deal.grower_done_at),
        trader_done_at=_utc(deal.trader_done_at),
        completed_at=_utc(deal.completed_at),
        rating_until=rating_until(deal),
        rating_locked=is_locked(deal, now),
        rates=[r for r in RATES[role] if r in parties],
    )


async def rating_guard(
    session: AsyncSession,
    deal: MarketDeal,
    rater_id: uuid.UUID,
    ratee_id: uuid.UUID,
    pair_min_deals: int,
) -> None:
    """The fake-deal checks before a rating is saved (spec §4C, Q100, Q113, Q115).

    - Accounts ever seen on one phone cannot rate each other: 409 `same_device`.
    - A pair that only ever completes deals with each other is flagged to admin, not refused:
      the rating is saved and the deal gets one `pair_only` event per rater and ratee (no
      actor; the caller commits)."""
    if await same_device(session, rater_id, ratee_id):
        raise ApiError(409, "same_device", "Accounts on the same phone cannot rate each other")
    if not await pair_only(session, rater_id, ratee_id, pair_min_deals):
        return
    detail = {"rater_id": str(rater_id), "ratee_id": str(ratee_id)}
    flagged = await session.scalars(
        select(DealEvent.detail).where(DealEvent.deal_id == deal.id, DealEvent.kind == PAIR_ONLY)
    )
    if detail not in list(flagged):
        session.add(DealEvent(deal_id=deal.id, actor_id=None, kind=PAIR_ONLY, detail=detail))
