"""One-off (owner Q139): put the already published news items into topic threads, oldest first.
Idempotent: only items without a thread are touched, so it is safe to repeat (every scheduled
news run does the same for new items). Needs FEED_AI_API_KEY; one small classify-model call per
item that has a candidate thread. Prints a JSON summary. Runbook: docs/runbooks/govt-feed.md §12.
    python -m bagmitra_api.feed.thread_backfill
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import asdict

import httpx

from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.ai import AnthropicFeedAi
from bagmitra_api.feed.threads import AnthropicThreader, thread_news


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with httpx.AsyncClient() as http, get_sessionmaker()() as session:
        threader = (
            AnthropicThreader(AnthropicFeedAi(http, settings))
            if settings.feed_ai_api_key.get_secret_value()
            else None
        )
        run = await thread_news(session, threader)
        await session.commit()
    print(json.dumps(asdict(run)))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
