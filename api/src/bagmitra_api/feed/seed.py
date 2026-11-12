"""Registers the feed sources of addendum v1.4 §3 (idempotent). Terms stay `unknown` until
the owner checks them, unless the seed records the owner's decision (`terms_status`, e.g.
Mahasamvad, Q129, and the owner approval of 2026-11-12, Q145); seeding never fetches anything.

A seed that records a decision also updates an existing row whose terms are still `unknown`
(nobody decided yet) to the seed's terms, note, address and fetch method, so a deploy
enables it with no manual step. A row an admin set to `allowed` or `disallowed` keeps it.

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


def seed_option(key: str, name: str) -> Any:
    """A reader option of a seeded source that is not a database column (Q145: `backfill`,
    `departments`); None when the seed has none."""
    return next((s.get(name) for s in source_seeds() if s["key"] == key), None)


# Fields a seeded decision carries onto an undecided row (never the fetch status or errors).
DECISION_FIELDS = ("terms_status", "notes", "url", "fetch_method", "name", "tier", "level")


async def seed_feed_sources(session: AsyncSession) -> int:
    """Adds missing sources and applies seeded decisions to rows still `unknown`; rows with
    recorded terms keep them and their fetch status. Returns the number of rows added."""
    existing = {s.key: s for s in await session.scalars(select(FeedSource))}
    added = 0
    for seed in source_seeds():
        row = existing.get(seed["key"])
        if row is None:
            columns = {k: v for k, v in seed.items() if k in ("key", *DECISION_FIELDS)}
            values = {"terms_status": "unknown", **columns}
            session.add(FeedSource(id=uuid.uuid4(), **values))
            added += 1
        elif row.terms_status == "unknown" and seed.get("terms_status", "unknown") != "unknown":
            for name in DECISION_FIELDS:
                if name in seed:
                    setattr(row, name, seed[name])
            row.last_error = None  # the "not fetched: terms unknown" note no longer holds
    await session.flush()
    return added


async def main() -> None:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session:
        await seed_feed_sources(session)
        await session.commit()


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
