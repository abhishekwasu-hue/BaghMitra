"""Market linkage L5: "deal done" and ratings (spec v1.5 §3 step 7, §3A; decisions d, e, j;
Q66, Q67). Behind the legal gate: every path answers 404 while `market_link_enabled` is off.

The grower and the trader each tap "deal done"; when both have, the deal is completed and its
parties may rate each other for 7 days: stars 1-5 for every question of the rated role and
optional ticks from the admin's active tag list. No text anywhere (unknown keys are refused).
Nothing about the deal's terms, payment or any dispute is recorded (§1 core principle).
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import cast

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.deals import (
    TAPPERS,
    DealStateOut,
    PartyRole,
    deal_state,
    is_locked,
    party_roles,
    questions,
    rating_guard,
)
from bagmitra_api.market_link.guards import MarketLinkIn
from bagmitra_api.market_link.models import DealEvent, MarketDeal, Rating, RatingTag
from bagmitra_api.routers.market_interests import IntroductionOut, introduction_for
from bagmitra_api.routers.market_link import Clock, require_market_link

router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
MAX_TAGS = 10


class AnswerIn(MarketLinkIn):
    """One question: 1-5 stars and optional tag ids (no text, Q66)."""

    question_key: str = Field(max_length=40)
    stars: int = Field(ge=1, le=5)
    tag_ids: list[uuid.UUID] = Field(default_factory=list, max_length=MAX_TAGS)


class RatingIn(MarketLinkIn):
    """Every question of the rated role, once each."""

    answers: list[AnswerIn] = Field(min_length=1, max_length=10)


class AnswerOut(BaseModel):
    question_key: str
    stars: int
    tag_ids: list[uuid.UUID]


class GivenRatingOut(BaseModel):
    ratee_role: PartyRole
    answers: list[AnswerOut]


class DealRatingsOut(BaseModel):
    """The caller's own ratings on the deal (to show and change them) and the window."""

    state: DealStateOut
    # Rated role -> its question keys, in order.
    questions: dict[str, list[str]]
    given: list[GivenRatingOut]


async def _party(
    session: DbSession, user: CurrentUser, deal_id: uuid.UUID, *, lock: bool = False
) -> tuple[MarketDeal, PartyRole, dict[PartyRole, uuid.UUID]]:
    """The deal and the caller's role on it; 404 for anyone not a party."""
    query = select(MarketDeal).where(MarketDeal.id == deal_id)
    deal = await session.scalar(query.with_for_update() if lock else query)
    parties = await party_roles(session, deal_id) if deal is not None else {}
    role = next((r for r, u in parties.items() if u == user.id), None)
    if deal is None or role is None:
        raise ApiError(404, "deal_not_found")
    return deal, role, parties


@router.post("/deals/{deal_id}/done", operation_id="market_link_deal_done")
async def deal_done(
    deal_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> IntroductionOut:
    """The grower or the trader says the deal is done (a repeat tap changes nothing). When
    both have tapped, the deal is completed and rating opens for 7 days (Q66, Q67)."""
    deal, role, _ = await _party(session, user, deal_id, lock=True)
    if role not in TAPPERS:
        raise ApiError(403, "broker_does_not_tap", "Only the grower and the trader tap")
    if deal.status == "cancelled":
        raise ApiError(409, "deal_cancelled")
    field = f"{role}_done_at"
    if getattr(deal, field) is None:
        now = clock()
        setattr(deal, field, now)
        session.add(DealEvent(deal_id=deal.id, actor_id=user.id, kind="done", detail={}))
        if deal.grower_done_at is not None and deal.trader_done_at is not None:
            deal.completed_at = now
            deal.status = "completed"
            session.add(DealEvent(deal_id=deal.id, actor_id=None, kind="completed", detail={}))
        await session.commit()
    return await introduction_for(session, deal, user.id, clock())


def _given(rows: list[Rating], parties: dict[PartyRole, uuid.UUID]) -> list[GivenRatingOut]:
    by_role: dict[PartyRole, list[AnswerOut]] = {}
    for r in rows:
        answer = AnswerOut(question_key=r.question_key, stars=r.stars, tag_ids=r.tag_ids)
        by_role.setdefault(cast(PartyRole, r.ratee_role), []).append(answer)
    return [
        GivenRatingOut(ratee_role=role, answers=answers)
        for role, answers in sorted(by_role.items())
        if role in parties
    ]


async def _ratings_out(
    session: DbSession,
    deal: MarketDeal,
    role: PartyRole,
    parties: dict[PartyRole, uuid.UUID],
    now: datetime,
) -> DealRatingsOut:
    state = deal_state(deal, role, parties, now)
    order = questions()

    def position(r: Rating) -> tuple[str, int]:  # the seed's question order
        keys = order.get(r.ratee_role, ())
        return r.ratee_role, keys.index(r.question_key) if r.question_key in keys else len(keys)

    rows = await session.scalars(
        select(Rating).where(Rating.deal_id == deal.id, Rating.rater_id == parties[role])
    )
    return DealRatingsOut(
        state=state,
        questions={r: list(order[r]) for r in state.rates},
        given=_given(sorted(rows, key=position), parties),
    )


@router.get("/deals/{deal_id}/ratings", operation_id="market_link_deal_ratings")
async def deal_ratings(
    deal_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> DealRatingsOut:
    """The caller's ratings on this deal, the questions to answer and the window."""
    deal, role, parties = await _party(session, user, deal_id)
    return await _ratings_out(session, deal, role, parties, clock())


async def _check_tags(session: DbSession, answers: list[AnswerIn]) -> None:
    wanted = {t for a in answers for t in a.tag_ids}
    if not wanted:
        return
    rows = await session.execute(
        select(RatingTag.id, RatingTag.question_key).where(
            RatingTag.id.in_(wanted), RatingTag.status == "active"
        )
    )
    active = dict(rows.tuples().all())
    for a in answers:
        if len(set(a.tag_ids)) != len(a.tag_ids) or any(
            active.get(t) != a.question_key for t in a.tag_ids
        ):
            raise ApiError(422, "unknown_tag", "Tick only tags listed under the question")


@router.put("/deals/{deal_id}/ratings/{ratee_role}", operation_id="market_link_rate")
async def rate(  # noqa: PLR0913 - path, body and dependencies
    deal_id: uuid.UUID,
    ratee_role: PartyRole,
    body: RatingIn,
    user: CurrentUser,
    session: DbSession,
    clock: Clock,
) -> DealRatingsOut:
    """Give or change the caller's rating of one party of a completed deal: every question
    of that role once. Only within 7 days of completion, then 409 `rating_locked`."""
    deal, role, parties = await _party(session, user, deal_id, lock=True)
    now = clock()
    state = deal_state(deal, role, parties, now)
    if ratee_role not in state.rates:
        raise ApiError(404, "ratee_not_found")
    if deal.completed_at is None:
        raise ApiError(409, "deal_not_completed", "Both sides tap deal done first")
    if is_locked(deal, now):
        raise ApiError(409, "rating_locked", "Ratings lock 7 days after the deal is done")
    keys = [a.question_key for a in body.answers]
    if sorted(keys) != sorted(questions()[ratee_role]):
        raise ApiError(422, "questions_mismatch", "Answer every question once")
    await _check_tags(session, body.answers)
    ratee = parties[ratee_role]
    await rating_guard(session, deal, user.id, ratee)
    existing = {
        r.question_key: r
        for r in await session.scalars(
            select(Rating).where(
                Rating.deal_id == deal.id, Rating.rater_id == user.id, Rating.ratee_id == ratee
            )
        )
    }
    for a in body.answers:
        tags = [str(t) for t in a.tag_ids]
        row = existing.get(a.question_key)
        if row is None:
            session.add(
                Rating(
                    deal_id=deal.id,
                    rater_id=user.id,
                    ratee_id=ratee,
                    ratee_role=ratee_role,
                    question_key=a.question_key,
                    stars=a.stars,
                    tag_ids=tags,
                )
            )
        else:
            row.stars, row.tag_ids = a.stars, tags
    kind = "rating_changed" if existing else "rated"
    detail = {"ratee_role": ratee_role}
    session.add(DealEvent(deal_id=deal.id, actor_id=user.id, kind=kind, detail=detail))
    await session.commit()
    return await _ratings_out(session, deal, role, parties, now)
