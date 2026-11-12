"""AI step for listings from official portals (owner 2026-11-12, OPEN_QUESTIONS Q145).

For each official listing still waiting (status in_review, added by a portal adapter, no
finished attempt), from a source whose terms are `allowed`:
1. read its document politely (robots, spacing, MAX_DOCUMENT_BYTES) and keep its SHA-256 and
   size; extract the text (PDF text layer / HTML visible text, `feed/extract.py`). Only `ok`
   text is stored as the item's text: a scanned or legacy-font document is held for a person;
2. classify it (`gr | circular | scheme | alert`, categories `deadline | payment | new_scheme
   …`); an irrelevant document goes to `draft`;
3. write the article set (mr / hi / en) from that text and check it (`check_articles`);
4. a scheme also gets its scheme card from the summariser ("quote or not_stated");
5. the output check (`run_output_check`) compares every title, summary and card field with
   the stored text. Any issue holds the item (admin web, status "held"); otherwise it is
   published (FEED_AUTO_PUBLISH; false: it waits for a feed_admin approval).
At most FEED_AI_DAILY_ITEMS such attempts per UTC day (counted apart from the news articles).
Without a model key (FEED_AI_API_KEY empty) nothing happens and the listings wait.
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass
from datetime import datetime, time
from typing import Protocol

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AiUnavailableError, Classification, Summary
from bagmitra_api.feed.article import ArticleSet, check_articles
from bagmitra_api.feed.extract import extract
from bagmitra_api.feed.gr_portal import FetchFailedError, GrPortalAdapter
from bagmitra_api.feed.models import FeedItem, FeedReviewEvent, FeedSchemeCard, FeedSource
from bagmitra_api.feed.news_articles import _store
from bagmitra_api.feed.service import latest_card, run_output_check, sync_deadlines

ATTEMPT = "ai_official"
FINAL = ("published", "held", "draft", "review")
OFFICIAL_KINDS = ("gr", "circular", "scheme", "alert")
# Review-event `via` of the listings this step handles (manual uploads stay with the admin).
PORTAL_VIA = ("gr_portal", "official_portal")


class OfficialAi(Protocol):
    async def classify(self, text: str) -> Classification: ...

    async def summarise(self, text: str) -> Summary: ...

    async def write_article(self, text: str, *, source_url: str) -> ArticleSet: ...


@dataclass(slots=True)
class OfficialRun:
    published: int = 0
    held: int = 0
    drafted: int = 0
    review: int = 0
    retry: int = 0
    skipped_reason: str | None = None


def _event(
    item: FeedItem, kind: str, at: datetime | None = None, **detail: object
) -> FeedReviewEvent:
    event = FeedReviewEvent(
        id=uuid.uuid4(), item_id=item.id, actor_id=None, kind=kind, detail=detail
    )
    if at is not None:
        event.created_at = at
    return event


async def _calls_today(session: AsyncSession, now: datetime) -> int:
    start = datetime.combine(now.date(), time.min, tzinfo=now.tzinfo)
    count = await session.scalar(
        select(func.count())
        .select_from(FeedReviewEvent)
        .where(FeedReviewEvent.kind == ATTEMPT, FeedReviewEvent.created_at >= start)
    )
    return int(count or 0)


async def waiting(session: AsyncSession, limit: int) -> list[FeedItem]:
    """Portal listings of allowed official sources without a finished attempt, newest first."""
    finished = select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == ATTEMPT,
        FeedReviewEvent.detail["result"].as_string().in_(FINAL),
    )
    from_portal = select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == "created",
        FeedReviewEvent.detail["via"].as_string().in_(PORTAL_VIA),
    )
    rows = await session.scalars(
        select(FeedItem)
        .join(FeedSource, FeedSource.id == FeedItem.source_id)
        .where(
            FeedSource.tier == "official",
            FeedSource.terms_status == "allowed",
            FeedItem.type.in_(OFFICIAL_KINDS),
            FeedItem.status == "in_review",
            FeedItem.id.in_(from_portal),
            FeedItem.id.not_in(finished),
        )
        .order_by(FeedItem.published_at.desc())
        .limit(limit)
    )
    return list(rows)


def _hold(item: FeedItem, kind: str, text: str, where: str) -> str:
    item.status = "held"
    item.check_issues = [{"kind": kind, "text": text[:500], "where": where}]
    return "held"


async def _card(session: AsyncSession, item: FeedItem, summary: Summary) -> None:
    current = await latest_card(session, item.id)
    session.add(
        FeedSchemeCard(
            id=uuid.uuid4(),
            item_id=item.id,
            version=(current.version + 1) if current else 1,
            fields={k: dict(v) for k, v in summary.fields.items()},
        )
    )


async def process_one(  # noqa: PLR0913, PLR0911 - one listing, one return per outcome
    session: AsyncSession,
    item: FeedItem,
    adapter: GrPortalAdapter,
    ai: OfficialAi,
    settings: Settings,
    now: datetime,
) -> str:
    try:
        data, kind = await adapter.document(item.url)
    except FetchFailedError as exc:
        return _hold(item, "fetch", exc.reason, "document")
    item.raw_hash, item.raw_bytes = hashlib.sha256(data).hexdigest(), len(data)
    found = extract(data, kind, expect_marathi=True)
    session.add(
        _event(item, "extracted", method=found.method, quality=found.quality, pages=found.pages)
    )
    if found.quality != "ok":
        reason = found.reason or found.quality
        return _hold(item, f"text_{found.quality}", reason, "extracted_text")
    item.extracted_text = found.text
    try:
        sort = await ai.classify(found.text)
        session.add(
            _event(
                item,
                "classified",
                relevant=sort.relevant,
                item_kind=sort.kind,
                categories=sort.categories,
                crops=sort.crops,
                districts=sort.districts,
            )
        )
        if not sort.relevant:
            item.status = "draft"
            return "draft"
        item.type = sort.kind
        article = await ai.write_article(found.text, source_url=item.url)
        if not article.relevant or article.political:
            item.status = "draft"
            return "draft"
        summary = await ai.summarise(found.text) if item.type == "scheme" else None
    except AiUnavailableError as exc:
        session.add(_event(item, ATTEMPT, now, result="retry", reason=str(exc)[:300]))
        return "retry"
    await _store(session, item, article)
    if summary is not None:
        await _card(session, item, summary)
    await session.flush()
    problems = check_articles(found.text, article, source_url=item.url)
    issues = [{"kind": "article", "text": p, "where": ""} for p in problems]
    issues += await run_output_check(session, item, settings, None)
    item.check_issues = issues
    if issues:
        item.status = "held"
        return "held"
    if not settings.feed_auto_publish:
        return "review"
    item.status = "published"
    await sync_deadlines(session, item)
    session.add(_event(item, "auto_published"))
    return "published"


async def write_official_items(
    session: AsyncSession,
    adapter: GrPortalAdapter,
    ai: OfficialAi | None,
    settings: Settings,
    now: datetime,
) -> OfficialRun:
    run = OfficialRun()
    if ai is None:
        run.skipped_reason = "FEED_AI_API_KEY is not set"
        return run
    room = settings.feed_ai_daily_items - await _calls_today(session, now)
    if room <= 0:
        run.skipped_reason = "daily AI limit reached"
        return run
    for item in await waiting(session, room):
        outcome = await process_one(session, item, adapter, ai, settings, now)
        if outcome != "retry":
            session.add(_event(item, ATTEMPT, now, result=outcome))
        run.published += outcome == "published"
        run.held += outcome == "held"
        run.drafted += outcome == "draft"
        run.review += outcome == "review"
        run.retry += outcome == "retry"
        await session.flush()
    return run
