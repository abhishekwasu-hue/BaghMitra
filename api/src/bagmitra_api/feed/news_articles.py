"""AI articles for news headlines (spec v1.6, owner Q127).

For each news item still waiting (status in_review, no article attempt that finished), from a
source whose terms are `allowed`: fetch its page politely (robots, spacing, size limit), send
the visible text to the article writer, check the result (`feed.article.check_articles`) and
publish it when nothing fails (FEED_AUTO_PUBLISH), else hold it with the reasons. The page
text is never stored: only its SHA-256 and size. At most FEED_AI_DAILY_ITEMS writer calls per
UTC day; with no writer (FEED_AI_API_KEY empty) nothing happens.

Headline filter (owner 2026-11-13, Q150): before any page is fetched, the waiting headlines
(title, source, language only) go in batches of FILTER_BATCH to the cheap classify model, which
answers per headline relevant / political / reason (structured output). Not relevant or
political: the item goes to `draft` exactly as when the writer judges it so (an ATTEMPT event
with result `draft`, reason "prefilter: ..."), with no writer call and not counted against
FEED_AI_DAILY_ITEMS. Relevant: the writer gets it as before, newest first. Each verdict is a
FILTER review event, so a headline is classified once; at most FEED_AI_FILTER_DAILY_CALLS
filter calls per UTC day (counted from those events). A filter error stops the filter for the
run and is never a verdict: the unclassified headlines wait for the next run, and only items
with a `relevant` verdict reach the writer.
"""

from __future__ import annotations

import hashlib
import json
import uuid
from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import datetime, time
from typing import Any, Protocol

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings
from bagmitra_api.feed.ai import AiUnavailableError, AnthropicFeedAi, FeedArticleWriter
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
# Q150 headline filter: its verdict event, headlines per call, answer ceiling (thinking
# included) and the reason prefix of the drafts it makes (kept out of the writer's daily cap).
FILTER = "ai_prefilter"
FILTER_BATCH = 40
FILTER_MAX_TOKENS = 8000
PREFILTER = "prefilter: "
VERDICTS = ("relevant", "dropped")

FILTER_PROMPT = """You screen news headlines for BagMitra, an app for fruit-orchard and farming
growers in India, mostly in Maharashtra (orange, sweet lime and other fruit, field crops). The
document is a JSON list of headlines, each with a "key", its "title", the "source" name and the
"lang" code. Judge each headline from its words only. For every key answer:
- "relevant": true if the news is useful to such a grower: crops, horticulture and fruit, pests
  and diseases, weather and its effect on farming, markets and prices, farm inputs (seeds,
  fertilisers, pesticides), schemes, subsidies, payments or relief for farmers, agricultural
  policy, irrigation and water, livestock only when it concerns the farm. Crime,
  entertainment, sport and stories about a person are not relevant.
- "political": true if the news is about party politics, elections or a political
  personality (praise or criticism of a government, minister or person).
- "reason": a few English words saying why."""


@dataclass(frozen=True, slots=True)
class Headline:
    key: str
    title: str
    lang: str
    source: str


@dataclass(frozen=True, slots=True)
class Verdict:
    relevant: bool
    political: bool
    reason: str


class HeadlineFilter(Protocol):
    async def judge(self, headlines: Sequence[Headline]) -> dict[str, Verdict]: ...


def filter_schema(keys: Sequence[str]) -> dict[str, Any]:
    verdict = {
        "type": "object",
        "properties": {
            "key": {"type": "string", "enum": list(keys)},
            "relevant": {"type": "boolean"},
            "political": {"type": "boolean"},
            "reason": {"type": "string"},
        },
        "required": ["key", "relevant", "political", "reason"],
        "additionalProperties": False,
    }
    return {
        "type": "object",
        "properties": {"items": {"type": "array", "items": verdict}},
        "required": ["items"],
        "additionalProperties": False,
    }


def parse_verdicts(answer: dict[str, Any], keys: Sequence[str]) -> dict[str, Verdict]:
    """Verdicts by key; a key the answer leaves out gets none and stays waiting (the first
    answer for a repeated key counts)."""
    found: dict[str, Verdict] = {}
    items = answer.get("items")
    for entry in items if isinstance(items, list) else []:
        key = entry.get("key") if isinstance(entry, dict) else None
        if not isinstance(key, str) or key not in keys or key in found:
            continue
        reason = entry.get("reason")
        found[key] = Verdict(
            relevant=entry.get("relevant") is True,
            political=entry.get("political") is True,
            reason=reason.strip()[:200] if isinstance(reason, str) else "",
        )
    return found


class AnthropicHeadlineFilter:
    """The headline filter over the feed's Messages API path: the cheap classify model at low
    effort and a structured-output answer (one verdict per headline key)."""

    def __init__(self, ai: AnthropicFeedAi) -> None:
        self._ai = ai

    async def judge(self, headlines: Sequence[Headline]) -> dict[str, Verdict]:
        keys = [h.key for h in headlines]
        rows = [
            {"key": h.key, "title": h.title, "source": h.source, "lang": h.lang} for h in headlines
        ]
        answer = await self._ai.ask_small_json(
            FILTER_PROMPT,
            json.dumps(rows, ensure_ascii=False),
            schema=filter_schema(keys),
            max_tokens=FILTER_MAX_TOKENS,
        )
        return parse_verdicts(answer, keys)


@dataclass(slots=True)
class FilterRun:
    calls: int = 0
    relevant: int = 0
    dropped: int = 0
    errors: int = 0


@dataclass(slots=True)
class ArticleRun:
    published: int = 0
    held: int = 0
    drafted: int = 0
    retry: int = 0
    skipped_reason: str | None = None
    filter: FilterRun = field(default_factory=FilterRun)


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


def _day_start(now: datetime) -> datetime:
    return datetime.combine(now.date(), time.min, tzinfo=now.tzinfo)


async def _calls_today(session: AsyncSession, now: datetime) -> int:
    """Writer calls today; the filter's drafts (reason "prefilter: ...") made none."""
    reason = func.coalesce(FeedReviewEvent.detail["reason"].as_string(), "")
    count = await session.scalar(
        select(func.count())
        .select_from(FeedReviewEvent)
        .where(
            FeedReviewEvent.kind == ATTEMPT,
            FeedReviewEvent.created_at >= _day_start(now),
            reason.not_like(f"{PREFILTER}%"),
        )
    )
    return int(count or 0)


async def _filter_calls_today(session: AsyncSession, now: datetime) -> int:
    """Filter calls today: every FILTER event (verdict or error) names its call."""
    count = await session.scalar(
        select(func.count(func.distinct(FeedReviewEvent.detail["call"].as_string()))).where(
            FeedReviewEvent.kind == FILTER, FeedReviewEvent.created_at >= _day_start(now)
        )
    )
    return int(count or 0)


async def _waiting(
    session: AsyncSession, limit: int, *, relevant_only: bool = False, unclassified: bool = False
) -> list[FeedItem]:
    """Waiting news items, newest first; `relevant_only`: only those the filter kept;
    `unclassified`: only those it has not judged yet."""
    finished = select(FeedReviewEvent.item_id).where(
        FeedReviewEvent.kind == ATTEMPT,
        FeedReviewEvent.detail["result"].as_string().in_(FINAL),
    )
    query = (
        select(FeedItem)
        .join(FeedSource, FeedSource.id == FeedItem.source_id)
        .where(
            FeedItem.type == "news",
            FeedItem.status == "in_review",
            FeedSource.terms_status == "allowed",
            FeedItem.id.not_in(finished),
        )
    )
    if relevant_only or unclassified:
        judged = FeedReviewEvent.detail["result"].as_string()
        verdicts = select(FeedReviewEvent.item_id).where(FeedReviewEvent.kind == FILTER)
        if relevant_only:
            query = query.where(FeedItem.id.in_(verdicts.where(judged == "relevant")))
        if unclassified:
            query = query.where(FeedItem.id.not_in(verdicts.where(judged.in_(VERDICTS))))
    rows = await session.scalars(query.order_by(FeedItem.published_at.desc()).limit(limit))
    return list(rows)


async def _headlines(session: AsyncSession, items: Sequence[FeedItem]) -> list[Headline]:
    """Title (the first non-empty one stored), its language and the source name; no page."""
    titles: dict[uuid.UUID, tuple[str, str]] = {}
    rows = await session.scalars(
        select(FeedItemI18n)
        .where(FeedItemI18n.item_id.in_([i.id for i in items]))
        .order_by(FeedItemI18n.lang)
    )
    for row in rows:
        if row.title.strip() and row.item_id not in titles:
            titles[row.item_id] = (row.title.strip(), row.lang)
    sources = await session.execute(
        select(FeedSource.id, FeedSource.name).where(
            FeedSource.id.in_({i.source_id for i in items})
        )
    )
    names = dict(sources.tuples().all())
    return [
        Headline(f"H{n + 1}", *titles.get(item.id, ("", "")), source=names.get(item.source_id, ""))
        for n, item in enumerate(items)
    ]


def _judged(item: FeedItem, verdict: Verdict, call: str, now: datetime) -> list[FeedReviewEvent]:
    """The verdict event; a dropped item also gets the writer's draft bookkeeping."""
    keep = verdict.relevant and not verdict.political
    events = [
        _event(
            item,
            FILTER,
            now,
            call=call,
            result="relevant" if keep else "dropped",
            relevant=verdict.relevant,
            political=verdict.political,
            reason=verdict.reason,
        )
    ]
    if not keep:
        item.status = "draft"
        events.append(_event(item, ATTEMPT, now, result="draft", reason=PREFILTER + verdict.reason))
    return events


async def _prefilter(
    session: AsyncSession,
    prefilter: HeadlineFilter,
    settings: Settings,
    now: datetime,
    run: FilterRun,
) -> None:
    room = settings.feed_ai_filter_daily_calls - await _filter_calls_today(session, now)
    if room <= 0:
        return
    pending = await _waiting(session, room * FILTER_BATCH, unclassified=True)
    for start in range(0, len(pending), FILTER_BATCH):
        batch = pending[start : start + FILTER_BATCH]
        call = uuid.uuid4().hex
        headlines = await _headlines(session, batch)
        run.calls += 1
        try:
            verdicts = await prefilter.judge(headlines)
            if not verdicts:
                raise AiUnavailableError("filter answered no verdict")
        except AiUnavailableError as exc:
            # Never a verdict: this batch and the rest wait for the next run. The event also
            # counts the call against FEED_AI_FILTER_DAILY_CALLS.
            run.errors += 1
            reason = str(exc)[:300]
            session.add(_event(batch[0], FILTER, now, call=call, result="error", reason=reason))
            await session.flush()
            return
        for headline, item in zip(headlines, batch, strict=True):
            verdict = verdicts.get(headline.key)
            if verdict is None:
                continue  # not answered: judged on a later run
            session.add_all(_judged(item, verdict, call, now))
            if item.status == "draft":
                run.dropped += 1
            else:
                run.relevant += 1
        await session.flush()


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


async def write_news_articles(  # noqa: PLR0913 - the run with its clock and optional filter
    session: AsyncSession,
    adapter: NewsFeedAdapter,
    writer: FeedArticleWriter | None,
    settings: Settings,
    now: datetime,
    prefilter: HeadlineFilter | None = None,
) -> ArticleRun:
    """With `prefilter` (Q150) the headlines are judged first and only kept ones are written."""
    run = ArticleRun()
    if writer is None:
        run.skipped_reason = "FEED_AI_API_KEY is not set"
        return run
    if prefilter is not None:
        await _prefilter(session, prefilter, settings, now, run.filter)
    room = settings.feed_ai_daily_items - await _calls_today(session, now)
    if room <= 0:
        run.skipped_reason = "daily AI limit reached"
        return run
    for item in await _waiting(session, room, relevant_only=prefilter is not None):
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
