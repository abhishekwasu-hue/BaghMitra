"""Sarkari Sandesh feed for the app (addendum v1.4 §4.7-4.8, G0 read API).

Only published or withdrawn items (a withdrawn one shows what replaced it); a scheme whose
validity or application window has ended is never shown as available. Matching to the
farmer is rule-based (district from the profile, crops and hectares from their plots) and
worded "may be eligible". Information, not advice: every response carries the footer.
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Literal
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer, Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.matching import Target, eligibility_reasons, passes_filter, profile_from
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedItemTarget
from bagmitra_api.weather.service import get_clock

router = APIRouter(prefix="/v1", tags=["feed"])
INDIA = ZoneInfo("Asia/Kolkata")
VISIBLE = ("published", "withdrawn")
# Most recent items considered per request; the app caches the last 50 (spec §4.8).
SCAN_LIMIT = 500
FOOTER = {
    "en": "Check the official GR/portal before acting.",
    "mr": "कोणतीही कृती करण्यापूर्वी अधिकृत शासन निर्णय (GR) / पोर्टल तपासा.",
    "hi": "कोई भी कदम उठाने से पहले आधिकारिक GR / पोर्टल देखें।",
}
FeedLang = Literal["en", "mr", "hi"]
FeedFilter = Literal["official", "scheme", "deadline", "news"]


class FeedItemOut(BaseModel):
    id: uuid.UUID
    type: str
    trust: Literal["official", "news"]
    title: str
    summary: str | None
    department: str | None
    gr_number: str | None
    published_at: datetime
    url: str
    deadline: date | None
    valid_to: date | None
    replaced_by: uuid.UUID | None
    may_be_eligible_because: list[str]


class FeedResponse(BaseModel):
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
    profile and plots."""
    today = clock().astimezone(INDIA).date()
    rows = list(
        await session.scalars(
            select(FeedItem)
            .where(FeedItem.status.in_(VISIBLE))
            .order_by(FeedItem.published_at.desc())
            .limit(SCAN_LIMIT)
        )
    )
    ids = [r.id for r in rows]
    texts: dict[uuid.UUID, dict[str, FeedItemI18n]] = defaultdict(dict)
    for t in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id.in_(ids))):
        texts[t.item_id][t.lang] = t
    targets: dict[uuid.UUID, list[Target]] = defaultdict(list)
    for g in await session.scalars(select(FeedItemTarget).where(FeedItemTarget.item_id.in_(ids))):
        targets[g.item_id].append(Target(g.district, g.crop, g.min_ha, g.max_ha))

    farmer = await session.get(Farmer, user.id)
    plots = await session.execute(
        select(Plot.crop, Plot.area_sq_m).where(Plot.owner_id == user.id, Plot.deleted_at.is_(None))
    )
    profile = profile_from(farmer.district if farmer else None, plots.tuples().all())

    items: list[FeedItemOut] = []
    for item in rows:
        text = _text(texts[item.id], lang)
        if (
            text is None
            or _expired_scheme(item, today)
            or not _wanted(item, type, today)
            or not passes_filter(targets[item.id], district=district, crop=crop)
        ):
            continue
        items.append(
            FeedItemOut(
                id=item.id,
                type=item.type,
                trust="official" if item.trust_level == "official" else "news",
                title=text.title,
                summary=text.summary,
                department=item.department,
                gr_number=item.gr_number,
                published_at=item.published_at,
                url=item.url,
                deadline=item.deadline,
                valid_to=item.valid_to,
                replaced_by=item.replaced_by_id,
                may_be_eligible_because=eligibility_reasons(targets[item.id], profile, lang),
            )
        )
        if len(items) >= settings.feed_page_size:
            break
    return FeedResponse(items=items, footer=FOOTER[lang])
