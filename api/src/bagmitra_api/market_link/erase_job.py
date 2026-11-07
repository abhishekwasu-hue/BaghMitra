"""Nightly erasure of deleted accounts' market-link data once 180 days have passed (Q68, spec
v1.5 §4C; `market_link/erasure.py` says what goes and what stays).

Two runs never overlap: on Postgres the run holds a session-level advisory lock and a second
run that finds it taken exits at once (`skipped_reason`); SQLite (local development) runs
unguarded. Prints a JSON summary; exit 1 when an account could not be erased.

deploy/deploy.sh adds the cron line unless CRON_MARKET_LINK_ERASE=off:
    python -m bagmitra_api.market_link.erase_job
"""

from __future__ import annotations

import asyncio
import json
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Any

import httpx
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession

from bagmitra_api.core.settings import get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.market_link.erasure import erase_due
from bagmitra_api.photos.storage import PhotoStorage, SupabaseStorageClient

# Fixed key of the advisory lock of this job ("bagmle" + 1).
ERASE_LOCK_KEY = 0x6261_676D_6C65_0001
SKIPPED_LOCKED = "another market-link erasure is running"


@asynccontextmanager
async def erase_lock(engine: AsyncEngine) -> AsyncIterator[bool]:
    """Yields whether this run holds the lock (its own connection, for the whole run)."""
    if engine.dialect.name != "postgresql":
        yield True
        return
    async with engine.connect() as conn:
        key = {"k": ERASE_LOCK_KEY}
        got = bool((await conn.execute(text("SELECT pg_try_advisory_lock(:k)"), key)).scalar_one())
        await conn.commit()
        try:
            yield got
        finally:
            if got:
                await conn.execute(text("SELECT pg_advisory_unlock(:k)"), key)
                await conn.commit()


async def run_locked(
    engine: AsyncEngine, session: AsyncSession, storage: PhotoStorage | None, now: datetime
) -> dict[str, Any]:
    async with erase_lock(engine) as held:
        if not held:
            return {"skipped_reason": SKIPPED_LOCKED}
        return (await erase_due(session, storage, now)).to_dict()


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    maker = get_sessionmaker()
    engine = maker.kw["bind"]
    async with (
        maker() as session,
        httpx.AsyncClient(timeout=settings.photo_storage_timeout_seconds) as http,
    ):
        storage = (
            SupabaseStorageClient(
                http,
                base_url=settings.photo_storage_url,
                bucket=settings.photo_storage_bucket,
                service_key=settings.photo_storage_service_key.get_secret_value(),
            )
            if settings.photo_storage_enabled
            else None
        )
        summary = await run_locked(engine, session, storage, utcnow())
    await engine.dispose()
    print(json.dumps(summary))
    return 1 if summary.get("failed") or summary.get("waiting_for_storage") else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
