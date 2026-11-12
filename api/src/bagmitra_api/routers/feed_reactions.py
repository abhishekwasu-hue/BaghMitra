"""Emoji reactions after reading a feed item or a Q&A answer (owner 2026-11-12, Q146).

`PUT /v1/reactions/{target}` sets the caller's one reaction (a different one replaces it),
`DELETE` removes it, `GET /v1/reactions?target=...` gives the counts and the caller's own
choice. A target is a feed item id or `qa:<id>` (a bundled answer). Owner data: the caller's
own row only; counts are sums across readers, never who reacted.
"""

from __future__ import annotations

import uuid
from collections import Counter
from typing import Annotated, Literal

from fastapi import APIRouter, Path, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed import reactions
from bagmitra_api.feed.models import FeedItem, FeedReaction
from bagmitra_api.feed.reactions import TARGET_PATTERN, Target

router = APIRouter(prefix="/v1", tags=["feed"], responses={401: {"model": ErrorResponse}})
ReactionKind = Literal["useful", "thanks", "liked", "okay", "unclear"]
TargetKey = Annotated[str, Path(pattern=TARGET_PATTERN, max_length=80)]
MAX_TARGETS = 50
VISIBLE = ("published", "withdrawn")
ERRORS: dict[int | str, dict[str, object]] = {
    404: {"model": ErrorResponse},
    422: {"model": ErrorResponse},
}


class ReactionIn(BaseModel):
    reaction: ReactionKind


class ReactionCountOut(BaseModel):
    reaction: ReactionKind
    count: int


class ReactionSummaryOut(BaseModel):
    """One target: every reaction with its count (app order, zeros included) and the caller's
    own reaction (`useful` | `thanks` | `liked` | `okay` | `unclear`), None when none."""

    target: str
    counts: list[ReactionCountOut]
    mine: str | None = None


class ReactionsResponse(BaseModel):
    reactions: list[ReactionSummaryOut]


def summary_counts(c: Counter[str] | None) -> list[ReactionCountOut]:
    return [ReactionCountOut(reaction=r, count=n) for r, n in reactions.ordered(c)]


def _target(key: str) -> Target:
    target = reactions.parse_target(key)
    if target is None:  # the path pattern already refuses it; kept for the query form
        raise ApiError(422, "invalid_target", "target must be a feed item id or qa:<id>")
    return target


async def _visible(session: AsyncSession, target: Target) -> None:
    if target.item_id is None:
        return
    item = await session.get(FeedItem, target.item_id)
    if item is None or item.status not in VISIBLE:
        raise ApiError(404, "not_found", "feed item not found")


async def _summary(session: AsyncSession, owner: uuid.UUID, target: Target) -> ReactionSummaryOut:
    counted = await reactions.counts(session, [target])
    row = await reactions.own(session, owner, target)
    return ReactionSummaryOut(
        target=target.key,
        counts=summary_counts(counted.get(target.key)),
        mine=row.reaction if row else None,
    )


@router.put("/reactions/{target}", operation_id="feed_reaction_put", responses=ERRORS)
async def put_reaction(
    target: TargetKey, body: ReactionIn, user: CurrentUser, session: DbSession
) -> ReactionSummaryOut:
    """Set the caller's reaction to a published (or withdrawn) feed item or a Q&A answer;
    a different reaction replaces the earlier one. Sending the same one again is a no-op."""
    parsed = _target(target)
    await _visible(session, parsed)
    row = await reactions.own(session, user.id, parsed)
    if row is None:
        row = FeedReaction(
            id=uuid.uuid4(), owner_id=user.id, item_id=parsed.item_id, qa_id=parsed.qa_id
        )
        session.add(row)
    row.reaction = body.reaction
    await session.commit()
    return await _summary(session, user.id, parsed)


@router.delete("/reactions/{target}", operation_id="feed_reaction_delete", responses=ERRORS)
async def delete_reaction(
    target: TargetKey, user: CurrentUser, session: DbSession
) -> ReactionSummaryOut:
    """Remove the caller's reaction (none is fine: the answer is the same)."""
    parsed = _target(target)
    row = await reactions.own(session, user.id, parsed)
    if row is not None:
        await session.delete(row)
        await session.commit()
    return await _summary(session, user.id, parsed)


@router.get("/reactions", operation_id="feed_reactions_get", responses=ERRORS)
async def get_reactions(
    user: CurrentUser,
    session: DbSession,
    target: Annotated[list[str], Query(min_length=1, max_length=MAX_TARGETS)],
) -> ReactionsResponse:
    """Counts and the caller's own reaction for up to 50 targets, in the order asked
    (duplicates once). A target nobody reacted to has zero counts."""
    parsed = list({t.key: t for t in (_target(k) for k in target)}.values())
    counted = await reactions.counts(session, parsed)
    own = await reactions.mine(session, user.id, parsed)
    return ReactionsResponse(
        reactions=[
            ReactionSummaryOut(
                target=t.key, counts=summary_counts(counted.get(t.key)), mine=own.get(t.key)
            )
            for t in parsed
        ]
    )
