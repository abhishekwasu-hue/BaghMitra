"""News run (addendum v1.4 G3): reads the feed of every news-tier source whose terms are
`allowed` and adds new headlines to the review queue, then prints a JSON summary.

The run first registers seeded sources that are missing (idempotent, terms `unknown`), so a
source added to `seed_data/sources.json` after migration 0019 shows up for its terms check.
Sources with other terms are reported `refused` and nothing is requested from them. Safe to
run repeatedly (dedupe by guid / link). Runbook: docs/runbooks/govt-feed.md §9.
    python -m bagmitra_api.feed.news_job
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.ai import AnthropicFeedAi, FeedArticleWriter
from bagmitra_api.feed.backfill import BackfillOutcome, backfill_news_source
from bagmitra_api.feed.gr_portal import FetchOutcome
from bagmitra_api.feed.models import FeedSource
from bagmitra_api.feed.news import NewsFeedAdapter, fetch_news_source
from bagmitra_api.feed.news_articles import (
    AnthropicHeadlineFilter,
    ArticleRun,
    HeadlineFilter,
    recheck_held_articles,
    write_news_articles,
)
from bagmitra_api.feed.seed import seed_feed_sources
from bagmitra_api.feed.threads import (
    THREADS_PER_RUN,
    AnthropicThreader,
    FeedThreader,
    ThreadRun,
    thread_news,
)


@dataclass(slots=True)
class NewsSummary:
    sources: list[FetchOutcome] = field(default_factory=list)
    # Q145: the one-off ~30-day backfill, per source with a plan that is not done yet.
    backfill: list[BackfillOutcome] = field(default_factory=list)

    @property
    def added(self) -> int:
        return sum(o.added for o in self.sources) + sum(b.added for b in self.backfill)

    def to_json(self) -> str:
        return json.dumps(
            {
                "sources": [asdict(o) for o in self.sources],
                "backfill": [asdict(b) for b in self.backfill if b.status != "not_planned"],
                "added": self.added,
            },
            ensure_ascii=False,
        )


async def run_news(
    session: AsyncSession, adapter: NewsFeedAdapter, now: datetime | None = None
) -> NewsSummary:
    await seed_feed_sources(session)
    summary = NewsSummary()
    sources = await session.scalars(
        select(FeedSource).where(FeedSource.tier == "news").order_by(FeedSource.key)
    )
    for source in list(sources):
        summary.sources.append(await fetch_news_source(session, source, adapter))
        # Owner 2026-11-12 (Q145): the past ~30 days once, capped per run, on its own.
        backfilled = await backfill_news_source(session, source, adapter, now or datetime.now(UTC))
        if backfilled.status not in ("not_planned", "done") or backfilled.added:
            summary.backfill.append(backfilled)
    return summary


async def article_step(  # noqa: PLR0913 - the run with its clock and optional filter
    session: AsyncSession,
    adapter: NewsFeedAdapter,
    writer: FeedArticleWriter | None,
    settings: Settings,
    now: datetime,
    prefilter: HeadlineFilter | None = None,
) -> tuple[ArticleRun, ArticleRun]:
    """New headlines are judged by the headline filter (Q150) and the kept ones get their
    article; then the held articles are checked again with the current checks (owner
    2026-11-10: every run, no separate command; no model call)."""
    written = await write_news_articles(session, adapter, writer, settings, now, prefilter)
    await session.commit()
    rechecked = await recheck_held_articles(session, adapter, settings)
    await session.commit()
    return written, rechecked


async def thread_step(session: AsyncSession, threader: FeedThreader | None) -> ThreadRun:
    """Q139: every run puts published news without a topic into one, oldest first, at most
    THREADS_PER_RUN items. New items and, after deploy, the already published ones are
    threaded this way (no manual step); safe to repeat."""
    run = await thread_news(session, threader, limit=THREADS_PER_RUN)
    await session.commit()
    return run


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient() as http:
        adapter = NewsFeedAdapter(
            http,
            user_agent=settings.feed_fetch_user_agent,
            min_interval=settings.feed_fetch_min_interval_seconds,
            timeout=settings.feed_fetch_timeout_seconds,
        )
        # Spec v1.6: the AI writes (and, when checks pass, publishes) the new headlines.
        writer = (
            AnthropicFeedAi(http, settings) if settings.feed_ai_api_key.get_secret_value() else None
        )
        async with get_sessionmaker()() as session:
            summary = await run_news(session, adapter)
            await session.commit()
            # Q150: the cheap headline filter runs first; the writer sees only useful news.
            prefilter = AnthropicHeadlineFilter(writer) if writer is not None else None
            articles, rechecked = await article_step(
                session, adapter, writer, settings, datetime.now(UTC), prefilter
            )
            threads = await thread_step(
                session, AnthropicThreader(writer) if writer is not None else None
            )
    print(summary.to_json())
    print(json.dumps(asdict(articles)))
    print(json.dumps({"recheck": asdict(rechecked)}))
    print(json.dumps({"threads": asdict(threads)}))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
