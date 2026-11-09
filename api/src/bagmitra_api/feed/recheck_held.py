"""One-off: check the held AI news articles again with the current checks and publish those that
now pass (owner 2026-11-09). No model call; each page is fetched again. Prints a JSON summary.
Runbook: docs/runbooks/govt-feed.md §11.
    python -m bagmitra_api.feed.recheck_held
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import asdict

import httpx

from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.news import NewsFeedAdapter
from bagmitra_api.feed.news_articles import recheck_held_articles


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient() as http, get_sessionmaker()() as session:
        adapter = NewsFeedAdapter(
            http,
            user_agent=settings.feed_fetch_user_agent,
            min_interval=settings.feed_fetch_min_interval_seconds,
            timeout=settings.feed_fetch_timeout_seconds,
        )
        run = await recheck_held_articles(session, adapter, settings)
        await session.commit()
    print(json.dumps(asdict(run)))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
