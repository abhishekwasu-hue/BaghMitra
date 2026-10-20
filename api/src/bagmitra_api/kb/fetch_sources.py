"""CLI: fetch every registered source and print one line per result."""

from __future__ import annotations

import asyncio
import sys

import httpx

from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.kb.fetcher import fetch_all


async def main(only: list[str] | None) -> int:  # pragma: no cover - thin CLI wrapper
    async with get_sessionmaker()() as session, httpx.AsyncClient(follow_redirects=True) as client:
        outcomes = await fetch_all(session, client, only)
        await session.commit()
    for o in outcomes:
        print(f"{o.status:12} {o.key}" + (f"  {o.error}" if o.error else ""))
    return 0 if all(o.status == "ok" for o in outcomes) else 1


if __name__ == "__main__":  # pragma: no cover
    keys = sys.argv[sys.argv.index("--only") + 1 :] if "--only" in sys.argv else None
    raise SystemExit(asyncio.run(main(keys)))
