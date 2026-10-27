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

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.gr_portal import FetchOutcome
from bagmitra_api.feed.models import FeedSource
from bagmitra_api.feed.news import NewsFeedAdapter, fetch_news_source
from bagmitra_api.feed.seed import seed_feed_sources


@dataclass(slots=True)
class NewsSummary:
    sources: list[FetchOutcome] = field(default_factory=list)

    @property
    def added(self) -> int:
        return sum(o.added for o in self.sources)

    def to_json(self) -> str:
        return json.dumps(
            {"sources": [asdict(o) for o in self.sources], "added": self.added},
            ensure_ascii=False,
        )


async def run_news(session: AsyncSession, adapter: NewsFeedAdapter) -> NewsSummary:
    await seed_feed_sources(session)
    summary = NewsSummary()
    sources = await session.scalars(
        select(FeedSource).where(FeedSource.tier == "news").order_by(FeedSource.key)
    )
    for source in list(sources):
        summary.sources.append(await fetch_news_source(session, source, adapter))
    return summary


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient() as http:
        adapter = NewsFeedAdapter(
            http,
            user_agent=settings.feed_fetch_user_agent,
            min_interval=settings.feed_fetch_min_interval_seconds,
            timeout=settings.feed_fetch_timeout_seconds,
        )
        async with get_sessionmaker()() as session:
            summary = await run_news(session, adapter)
            await session.commit()
    print(summary.to_json())
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
