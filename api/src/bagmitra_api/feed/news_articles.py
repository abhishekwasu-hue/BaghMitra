"""AI articles for news headlines (spec v1.6, owner Q127).

For each news item still waiting (status in_review, no article attempt that finished), from a
source whose terms are `allowed`: fetch its page politely (robots, spacing, size limit), send
the visible text to the article writer, check the result (`feed.article.check_articles`) and
publish it when nothing fails (FEED_AUTO_PUBLISH), else hold it with the reasons. The page
text is never stored: only its SHA-256 and size. At most FEED_AI_DAILY_ITEMS writer calls per
UTC day; with no writer (FEED_AI_API_KEY empty) nothing happens.
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass
from datetime import datetime, time

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AiUnavailableError, FeedArticleWriter
from bagmitra_api.feed.article import ArticleError, ArticleSet, check_articles, parse_articles
from bagmitra_api.feed.extract import html_text
from bagmitra_api.feed.gr_portal import FetchFailedError
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent, FeedSource
from bagmitra_api.feed.news import NewsFeedAdapter

ATTEMPT = "ai_article"
RECHECK = "ai_article_recheck"
MAX_PAGE_BYTES = 2 * 1024 * 1024
# Attempts that end the item's AI step (an unavailable model is tried again next run).
FINAL = ("published", "held", "draft", "review")


@dataclass(slots=True)
class ArticleRun:
    published: int = 0
    held: int = 0
    drafted: int = 0
    retry: int = 0
    skipped_reason: str | None = None


def _event(
    item: FeedItem, kind: str, at: datetime | None = None, **detail: object
) -> FeedReviewEvent:
    """`at` stamps the event with the run's clock: the daily model-call cap counts ATTEMPT
    events from the run's day, so they must carry that clock, not the wall clock."""
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


async def _waiting(session: AsyncSession, limit: int) -> list[FeedItem]:
    finished = select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == ATTEMPT,
        FeedReviewEvent.detail["result"].as_string().in_(FINAL),
    )
    rows = await session.scalars(
        select(FeedItem)
        .join(FeedSource, FeedSource.id == FeedItem.source_id)
        .where(
            FeedItem.type == "news",
            FeedItem.status == "in_review",
            FeedSource.terms_status == "allowed",
            FeedItem.id.not_in(finished),
        )
        .order_by(FeedItem.published_at.desc())
        .limit(limit)
    )
    return list(rows)


async def _page(adapter: NewsFeedAdapter, url: str) -> bytes:
    await adapter.check_robots(url)
    response = await adapter.get(url)
    if response.status_code >= 400:
        raise FetchFailedError("fetch_failed", f"HTTP {response.status_code} for the page")
    if len(response.content) > MAX_PAGE_BYTES:
        raise FetchFailedError("fetch_failed", f"page larger than {MAX_PAGE_BYTES} bytes")
    return response.content


async def _store(session: AsyncSession, item: FeedItem, result: ArticleSet) -> None:
    rows = {
        r.lang: r
        for r in await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
    }
    for lang, article in result.articles.items():
        row = rows.get(lang)
        if row is None:
            row = FeedItemI18n(id=uuid.uuid4(), item_id=item.id, lang=lang, title="")
            session.add(row)
        row.title, row.summary = article.headline[:500], article.standfirst
        row.article = article.as_json()


async def _one(  # noqa: PLR0913 - one item of the run, with the run clock
    session: AsyncSession,
    item: FeedItem,
    adapter: NewsFeedAdapter,
    writer: FeedArticleWriter,
    settings: Settings,
    now: datetime,
) -> str:
    try:
        data = await _page(adapter, item.url)
    except FetchFailedError as exc:
        item.status = "held"
        item.check_issues = [{"kind": "fetch", "text": exc.reason[:500], "where": "page"}]
        return "held"
    item.raw_hash, item.raw_bytes = hashlib.sha256(data).hexdigest(), len(data)
    text = html_text(data)
    try:
        result = await writer.write_article(text, source_url=item.url)
    except AiUnavailableError as exc:
        session.add(_event(item, ATTEMPT, now, result="retry", reason=str(exc)[:300]))
        return "retry"
    if not result.relevant or result.political:
        item.status = "draft"
        return "draft"
    await _store(session, item, result)
    problems = check_articles(text, result, source_url=item.url)
    item.check_issues = [{"kind": "article", "text": p, "where": ""} for p in problems]
    if problems:
        item.status = "held"
        return "held"
    if not settings.feed_auto_publish:
        return "review"
    item.status = "published"
    session.add(_event(item, "auto_published"))
    return "published"


async def write_news_articles(
    session: AsyncSession,
    adapter: NewsFeedAdapter,
    writer: FeedArticleWriter | None,
    settings: Settings,
    now: datetime,
) -> ArticleRun:
    run = ArticleRun()
    if writer is None:
        run.skipped_reason = "FEED_AI_API_KEY is not set"
        return run
    room = settings.feed_ai_daily_items - await _calls_today(session, now)
    if room <= 0:
        run.skipped_reason = "daily AI limit reached"
        return run
    for item in await _waiting(session, room):
        outcome = await _one(session, item, adapter, writer, settings, now)
        if outcome != "retry":
            session.add(_event(item, ATTEMPT, now, result=outcome))
        run.published += outcome == "published"
        run.held += outcome == "held"
        run.drafted += outcome == "draft"
        run.retry += outcome == "retry"
        await session.flush()
    return run


async def _saved_articles(session: AsyncSession, item: FeedItem) -> ArticleSet | None:
    """The article set the writer produced for a held item, as saved; None without one."""
    rows = await session.scalars(select(FeedItemI18n).where(FeedItemI18n.item_id == item.id))
    langs = {r.lang: r.article for r in rows if r.article}
    try:
        return parse_articles({"relevant": True, "political": False, "lang": langs})
    except ArticleError:
        return None


async def recheck_held_articles(
    session: AsyncSession, adapter: NewsFeedAdapter, settings: Settings
) -> ArticleRun:
    """Owner 2026-11-09: check the held news articles again with the current checks (e.g. after
    the check learned number words) and publish those that now pass. The saved article is used
    as it is (no model call, no cost); its page is fetched again because the text is never
    stored. Items held before an article existed (page not readable) are left as they are."""
    run = ArticleRun()
    held = await session.scalars(
        select(FeedItem)
        .where(FeedItem.type == "news", FeedItem.status == "held")
        .order_by(FeedItem.published_at.desc())
    )
    for item in list(held):
        articles = await _saved_articles(session, item)
        if articles is None:
            continue
        try:
            data = await _page(adapter, item.url)
        except FetchFailedError as exc:
            session.add(_event(item, RECHECK, result="retry", reason=exc.reason[:300]))
            run.retry += 1
            continue
        item.raw_hash, item.raw_bytes = hashlib.sha256(data).hexdigest(), len(data)
        problems = check_articles(html_text(data), articles, source_url=item.url)
        item.check_issues = [{"kind": "article", "text": p, "where": ""} for p in problems]
        if problems:
            outcome = "held"
        elif settings.feed_auto_publish:
            item.status, outcome = "published", "published"
            session.add(_event(item, "auto_published"))
        else:
            item.status, outcome = "in_review", "review"
        session.add(_event(item, RECHECK, result=outcome))
        run.published += outcome == "published"
        run.held += outcome == "held"
        await session.flush()
    return run
