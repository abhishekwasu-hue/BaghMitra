"""Sarkari Sandesh feed for the app (addendum v1.4 §4.7-4.8, G0 read API).

Only published or withdrawn items (a withdrawn one shows what replaced it); a scheme whose
validity or application window has ended is never shown as available. Matching to the
farmer is rule-based (district from the profile, crops and hectares from their plots) and
worded "may be eligible". Information, not advice: every response carries the footer.
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from collections.abc import Callable, Iterable
from dataclasses import dataclass
from datetime import date, datetime
from typing import Annotated, Literal
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer, Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.matching import (
    Profile,
    Target,
    eligibility_reasons,
    passes_filter,
    profile_from,
)
from bagmitra_api.feed.models import (
    FeedItem,
    FeedItemI18n,
    FeedItemTarget,
    FeedReceipt,
    FeedSource,
)
from bagmitra_api.feed.texts import FOOTER
from bagmitra_api.weather.service import get_clock

router = APIRouter(prefix="/v1", tags=["feed"])
INDIA = ZoneInfo("Asia/Kolkata")
VISIBLE = ("published", "withdrawn")
# Most recent items considered per request; the app caches the last 50 (spec §4.8).
SCAN_LIMIT = 500
FeedLang = Literal["en", "mr", "hi"]
FeedFilter = Literal["official", "scheme", "deadline", "news"]


class ArticleSectionOut(BaseModel):
    heading: str
    body: str


class ArticleFactOut(BaseModel):
    label: str
    value: str


class ArticleChartPointOut(BaseModel):
    label: str
    value: float


class ArticleChartOut(BaseModel):
    type: str  # "bar" | "pie"
    title: str
    unit: str
    data: list[ArticleChartPointOut]


class ArticleDateOut(BaseModel):
    date: date
    label: str


class ArticleSourceOut(BaseModel):
    title: str
    url: str


class ArticleOut(BaseModel):
    """Spec v1.6: the AI article from the official source, in the asked language."""

    headline: str
    standfirst: str
    key_points: list[str]
    sections: list[ArticleSectionOut]
    facts: list[ArticleFactOut]
    charts: list[ArticleChartOut]
    key_dates: list[ArticleDateOut]
    sources: list[ArticleSourceOut]


class FeedItemOut(BaseModel):
    id: uuid.UUID
    type: str
    trust: Literal["official", "news"]
    title: str
    summary: str | None
    department: str | None
    gr_number: str | None
    published_at: datetime
    # True: the source gave no date; published_at is when BagMitra first saw the item.
    date_is_first_seen: bool = False
    url: str
    deadline: date | None
    valid_to: date | None
    replaced_by: uuid.UUID | None
    may_be_eligible_because: list[str]
    # The caller marked it seen (POST /v1/feed/{id}/seen); optional for older clients.
    seen: bool = False
    # Who issued it: "central" (Government of India) or "state" (Maharashtra), from the source;
    # None if unknown. Plain str in the contract (the app generator has no nullable enums).
    level: str | None = None  # "central" or "state" only
    # The AI article (spec v1.6); None for items without one.
    article: ArticleOut | None = None
    # Q139: the news topic thread; items with the same id are one card in the app.
    thread_id: uuid.UUID | None = None


class FeedThreadOut(BaseModel):
    """A news topic (Q139): one card in the list, a dated timeline when opened. The title and
    summary are the latest item's own checked text."""

    id: uuid.UUID
    title: str
    summary: str | None
    # published_at of the newest visible item.
    latest_at: datetime
    item_count: int
    # Items the caller has not opened yet; has_new marks the card.
    unseen_count: int
    has_new: bool


class FeedResponse(BaseModel):
    items: list[FeedItemOut]
    footer: str
    # Q139: the threads of the news items in `items` (older apps ignore it).
    threads: list[FeedThreadOut] = []


class FeedThreadResponse(BaseModel):
    thread: FeedThreadOut
    # Oldest first: the dated timeline of the topic.
    items: list[FeedItemOut]
    footer: str


def _expired_scheme(item: FeedItem, today: date) -> bool:
    if item.type != "scheme":
        return False
    return any(d is not None and d < today for d in (item.valid_to, item.deadline))


def _wanted(item: FeedItem, kind: FeedFilter | None, today: date) -> bool:
    if kind is None:
        return True
    if kind == "official":
        return item.trust_level == "official"
    if kind == "news":
        return item.type == "news"
    if kind == "scheme":
        return item.type == "scheme"
    return item.status == "published" and item.deadline is not None and item.deadline >= today


def _text(texts: dict[str, FeedItemI18n], lang: str) -> FeedItemI18n | None:
    for key in (lang, "en", "mr", "hi"):
        if key in texts:
            return texts[key]
    return None


async def _seen(
    session: AsyncSession, owner: uuid.UUID, ids: Iterable[uuid.UUID]
) -> set[uuid.UUID]:
    return set(
        await session.scalars(
            select(FeedReceipt.item_id).where(
                FeedReceipt.owner_id == owner,
                FeedReceipt.item_id.in_(list(ids)),
                FeedReceipt.seen_at.is_not(None),
            )
        )
    )


@dataclass(slots=True)
class _Context:
    """What turning stored items into FeedItemOut needs: texts, targets, the caller's profile,
    their seen receipts and the source levels."""

    texts: dict[uuid.UUID, dict[str, FeedItemI18n]]
    targets: dict[uuid.UUID, list[Target]]
    profile: Profile
    seen: set[uuid.UUID]
    levels: dict[uuid.UUID, str]

    def out(self, item: FeedItem, text: FeedItemI18n, lang: FeedLang) -> FeedItemOut:
        return FeedItemOut(
            id=item.id,
            type=item.type,
            trust="official" if item.trust_level == "official" else "news",
            title=text.title,
            summary=text.summary,
            department=item.department,
            gr_number=item.gr_number,
            published_at=item.published_at,
            date_is_first_seen=item.date_is_first_seen,
            url=item.url,
            deadline=item.deadline,
            valid_to=item.valid_to,
            replaced_by=item.replaced_by_id,
            may_be_eligible_because=eligibility_reasons(self.targets[item.id], self.profile, lang),
            seen=item.id in self.seen,
            level=self.levels.get(item.source_id),
            article=ArticleOut.model_validate(text.article) if text.article else None,
            thread_id=item.thread_id,
        )


async def _context(session: AsyncSession, user_id: uuid.UUID, rows: list[FeedItem]) -> _Context:
    ids = [r.id for r in rows]
    texts: dict[uuid.UUID, dict[str, FeedItemI18n]] = defaultdict(dict)
    for t in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id.in_(ids))):
        texts[t.item_id][t.lang] = t
    targets: dict[uuid.UUID, list[Target]] = defaultdict(list)
    for g in await session.scalars(select(FeedItemTarget).where(FeedItemTarget.item_id.in_(ids))):
        targets[g.item_id].append(Target(g.district, g.crop, g.min_ha, g.max_ha))
    farmer = await session.get(Farmer, user_id)
    plots = await session.execute(
        select(Plot.crop, Plot.area_sq_m).where(Plot.owner_id == user_id, Plot.deleted_at.is_(None))
    )
    profile = profile_from(farmer.district if farmer else None, plots.tuples().all())
    source_ids = {item.source_id for item in rows}
    levels = {
        sid: level
        for sid, level in await session.execute(
            select(FeedSource.id, FeedSource.level).where(FeedSource.id.in_(source_ids))
        )
        if level in ("central", "state")
    }
    return _Context(texts, targets, profile, await _seen(session, user_id, ids), levels)


async def _threads_out(
    session: AsyncSession, user_id: uuid.UUID, latest: dict[uuid.UUID, FeedItemOut]
) -> list[FeedThreadOut]:
    """Thread cards for the given threads: `latest` is each thread's newest shown item, whose
    title and summary the card shows. Counts are over every visible item of the thread."""
    if not latest:
        return []
    members: dict[uuid.UUID, list[tuple[uuid.UUID, datetime]]] = defaultdict(list)
    for item_id, thread_id, when in await session.execute(
        select(FeedItem.id, FeedItem.thread_id, FeedItem.published_at).where(
            FeedItem.thread_id.in_(list(latest)), FeedItem.status.in_(VISIBLE)
        )
    ):
        members[thread_id].append((item_id, when))
    seen = await _seen(session, user_id, [i for m in members.values() for i, _ in m])
    out = []
    for thread_id, item in latest.items():
        rows = members.get(thread_id) or [(item.id, item.published_at)]
        unseen = sum(1 for i, _ in rows if i not in seen)
        out.append(
            FeedThreadOut(
                id=thread_id,
                title=item.title,
                summary=item.summary,
                latest_at=max(w for _, w in rows),
                item_count=len(rows),
                unseen_count=unseen,
                has_new=unseen > 0,
            )
        )
    return out


@router.get(
    "/feed",
    operation_id="feed_list",
    responses={401: {"model": ErrorResponse}},
)
async def feed(  # noqa: PLR0913 - query parameters and dependencies
    user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
    lang: Annotated[FeedLang, Query()] = "en",
    type: Annotated[FeedFilter | None, Query()] = None,  # noqa: A002 - public query name
    district: Annotated[str | None, Query(max_length=120)] = None,
    crop: Annotated[str | None, Query(max_length=32)] = None,
) -> FeedResponse:
    """Newest first. `district` / `crop` narrow the list to items meant for them (items for
    everyone always pass); `may_be_eligible_because` is computed from the caller's own
    profile and plots. News items carry their topic `thread_id`; `threads` describes those
    threads (Q139), so the app shows one card per topic."""
    today = clock().astimezone(INDIA).date()
    rows = list(
        await session.scalars(
            select(FeedItem)
            .where(FeedItem.status.in_(VISIBLE))
            .order_by(FeedItem.published_at.desc())
            .limit(SCAN_LIMIT)
        )
    )
    ctx = await _context(session, user.id, rows)
    items: list[FeedItemOut] = []
    latest: dict[uuid.UUID, FeedItemOut] = {}
    for item in rows:
        text = _text(ctx.texts[item.id], lang)
        if (
            text is None
            or _expired_scheme(item, today)
            or not _wanted(item, type, today)
            or not passes_filter(ctx.targets[item.id], district=district, crop=crop)
        ):
            continue
        out = ctx.out(item, text, lang)
        items.append(out)
        if item.thread_id is not None:
            latest.setdefault(item.thread_id, out)
        if len(items) >= settings.feed_page_size:
            break
    return FeedResponse(
        items=items, footer=FOOTER[lang], threads=await _threads_out(session, user.id, latest)
    )


@router.get(
    "/feed/threads/{thread_id}",
    operation_id="feed_thread",
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)
async def feed_thread(
    thread_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    lang: Annotated[FeedLang, Query()] = "en",
) -> FeedThreadResponse:
    """Every visible item of one news topic, oldest first (the dated timeline, Q139)."""
    rows = list(
        await session.scalars(
            select(FeedItem)
            .where(FeedItem.thread_id == thread_id, FeedItem.status.in_(VISIBLE))
            .order_by(FeedItem.published_at, FeedItem.id)
        )
    )
    ctx = await _context(session, user.id, rows)
    items = [
        ctx.out(item, text, lang)
        for item in rows
        if (text := _text(ctx.texts[item.id], lang)) is not None
    ]
    if not items:
        raise ApiError(404, "not_found", "feed thread not found")
    (thread,) = await _threads_out(session, user.id, {thread_id: items[-1]})
    return FeedThreadResponse(thread=thread, items=items, footer=FOOTER[lang])
