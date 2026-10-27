""" "Check this message" (addendum v1.4 §2, G3): a farmer pastes a forwarded text and learns
whether a matching official item exists in BagMitra (rules in `feed/check.py`).

Privacy: the pasted text is not stored anywhere; only its length and the verdict are logged.
Each signed-in user may check a limited number of messages per window (in memory).
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from datetime import UTC, datetime
from typing import Annotated, Literal

import structlog
from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.check import MAX_TEXT_CHARS, Candidate, RateLimiter, check_message, note
from bagmitra_api.feed.models import FeedItem, FeedItemI18n

router = APIRouter(prefix="/v1", tags=["feed"])
log = structlog.get_logger("bagmitra.feed.check")
# Most recent published official items compared per request.
CHECK_SCAN_LIMIT = 1000


class FeedCheckIn(BaseModel):
    text: str = Field(min_length=1, max_length=MAX_TEXT_CHARS)


class FeedCheckMatch(BaseModel):
    id: uuid.UUID
    title: str
    gr_number: str | None
    published_at: datetime
    url: str
    score: float


class FeedCheckResponse(BaseModel):
    verdict: Literal["official_match", "possible_match", "no_official_match"]
    matches: list[FeedCheckMatch]
    note: str


def get_check_limiter(
    request: Request, settings: Annotated[Settings, Depends(get_settings)]
) -> RateLimiter:
    """One limiter per app (created on first use)."""
    limiter: RateLimiter | None = getattr(request.app.state, "feed_check_limiter", None)
    if limiter is None:
        limiter = RateLimiter(
            settings.feed_check_rate_limit, settings.feed_check_rate_window_seconds
        )
        request.app.state.feed_check_limiter = limiter
    return limiter


def _title(texts: dict[str, str], lang: str) -> str:
    for key in (lang, "en", "mr", "hi"):
        if key in texts:
            return texts[key]
    return ""


def _utc(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value


@router.post(
    "/feed/check",
    operation_id="feed_check",
    responses={401: {"model": ErrorResponse}, 429: {"model": ErrorResponse}},
)
async def check(  # noqa: PLR0913 - body, query and dependencies
    body: FeedCheckIn,
    user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
    limiter: Annotated[RateLimiter, Depends(get_check_limiter)],
    lang: Annotated[Literal["en", "mr", "hi"], Query()] = "en",
) -> FeedCheckResponse:
    """Compares the pasted text with published official items only. Never says a message is
    fake: without a match the note says none was found and points to the official portal."""
    if not limiter.allow(str(user.id)):
        raise ApiError(429, "rate_limited", "too many checks; try again later")
    rows = list(
        await session.scalars(
            select(FeedItem)
            .where(FeedItem.status == "published", FeedItem.trust_level == "official")
            .order_by(FeedItem.published_at.desc())
            .limit(CHECK_SCAN_LIMIT)
        )
    )
    titles: dict[uuid.UUID, dict[str, str]] = defaultdict(dict)
    summaries: dict[uuid.UUID, list[str]] = defaultdict(list)
    ids = [r.id for r in rows]
    for t in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id.in_(ids))):
        titles[t.item_id][t.lang] = t.title
        if t.summary:
            summaries[t.item_id].append(t.summary)
    by_id = {r.id: r for r in rows}
    candidates = [
        Candidate(
            id=r.id,
            titles=titles[r.id],
            summaries=tuple(summaries[r.id]),
            gr_number=r.gr_number,
            external_id=r.external_id,
            published=_utc(r.published_at).date(),
            dates=frozenset(
                d for d in (r.deadline, r.valid_from, r.valid_to, r.payment_date) if d is not None
            ),
            url=r.url,
        )
        for r in rows
    ]
    result = check_message(body.text, candidates, glossary=settings.feed_scheme_glossary)
    log.info("feed.check", length=len(body.text), verdict=result.verdict)
    return FeedCheckResponse(
        verdict=result.verdict,
        matches=[
            FeedCheckMatch(
                id=m.candidate.id,
                title=_title(titles[m.candidate.id], lang),
                gr_number=m.candidate.gr_number,
                published_at=_utc(by_id[m.candidate.id].published_at),
                url=m.candidate.url,
                score=m.score,
            )
            for m in result.matches
        ],
        note=note(result.verdict, lang),
    )
