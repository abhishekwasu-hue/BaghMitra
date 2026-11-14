"""One-off: remove "the source does not say" filler from AI articles already saved (owner
2026-11-14). New articles and the held re-checks are cleaned when they are read
(`feed.no_filler`); this reaches the articles saved before that, published ones included.

Read-only by default (dry run: prints what would be removed, the session is rolled back). With
`--apply` the cleaned article is written back (title unchanged, summary = the cleaned
standfirst) and a `filler_removed` review event is added. An article that would keep no section
is never written: it is listed under `left` for a person. No model call, no fetch.
Runbook: docs/runbooks/govt-feed.md §11.
    python -m bagmitra_api.feed.clean_filler [--apply]
"""

from __future__ import annotations

import argparse
import asyncio
import json
import uuid
from dataclasses import asdict, dataclass, field
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.feed.models import FeedItem, FeedItemI18n, FeedReviewEvent
from bagmitra_api.feed.no_filler import clean_saved

EVENT = "filler_removed"


@dataclass
class FillerRun:
    applied: bool = False
    checked: int = 0
    changed: int = 0
    # Per changed article: item id, status, lang and the removed sentences.
    items: list[dict[str, Any]] = field(default_factory=list)
    # Articles that would keep no section: not written.
    left: list[dict[str, Any]] = field(default_factory=list)


async def clean_filler(session: AsyncSession, *, apply: bool) -> FillerRun:
    """Every saved article (news, official, knowledge; any status), newest first."""
    run = FillerRun(applied=apply)
    rows = await session.execute(
        select(FeedItemI18n, FeedItem)
        .join(FeedItem, FeedItem.id == FeedItemI18n.item_id)
        .where(FeedItemI18n.article.is_not(None))
        .order_by(FeedItem.published_at.desc(), FeedItemI18n.lang)
    )
    events: dict[uuid.UUID, list[str]] = {}
    for row, item in rows.tuples():
        if not isinstance(row.article, dict):
            continue
        run.checked += 1
        cleaned, removed = clean_saved(row.article)
        if not removed:
            continue
        entry = {"item": str(item.id), "status": item.status, "lang": row.lang, "removed": removed}
        if cleaned is None:
            run.left.append(entry)
            continue
        run.changed += 1
        run.items.append(entry)
        if apply:
            row.article = cleaned
            row.summary = cleaned.get("standfirst", row.summary)
            events.setdefault(item.id, []).append(row.lang)
    for item_id, langs in events.items():
        session.add(
            FeedReviewEvent(
                id=uuid.uuid4(), item_id=item_id, actor_id=None, kind=EVENT, detail={"langs": langs}
            )
        )
    await session.flush()
    return run


async def main(argv: list[str] | None = None) -> int:  # pragma: no cover - thin CLI wrapper
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--apply", action="store_true", help="write the cleaned articles")
    args = parser.parse_args(argv)
    async with get_sessionmaker()() as session:
        run = await clean_filler(session, apply=args.apply)
        if args.apply:
            await session.commit()
        else:
            await session.rollback()
    print(json.dumps(asdict(run), ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
