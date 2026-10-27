"""Registers the feed sources of addendum v1.4 §3 (idempotent). Terms stay `unknown` until
the owner checks them; seeding never fetches anything.

Usage: python -m bagmitra_api.feed.seed
"""

from __future__ import annotations

import asyncio
import json
import uuid
from importlib import resources
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.models import FeedSource


def source_seeds() -> list[dict[str, Any]]:
    text = resources.files("bagmitra_api.feed.seed_data").joinpath("sources.json").read_text()
    seeds: list[dict[str, Any]] = json.loads(text)["sources"]
    return seeds


async def seed_feed_sources(session: AsyncSession) -> int:
    """Adds missing sources; existing rows keep their recorded terms and fetch status."""
    existing = set(await session.scalars(select(FeedSource.key)))
    added = 0
    for seed in source_seeds():
        if seed["key"] in existing:
            continue
        session.add(FeedSource(id=uuid.uuid4(), terms_status="unknown", **seed))
        added += 1
    await session.flush()
    return added


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session:
        await seed_feed_sources(session)
        await session.commit()


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
