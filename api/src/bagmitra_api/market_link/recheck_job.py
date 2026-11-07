"""Yearly re-check reminder (spec v1.5 §4 "re-check yearly", L7).

Lists, on the admin's re-check list, every check whose latest result is a pass older than
MARKET_LINK_RECHECK_DAYS (default 365): it sets `recheck_listed_at` once on that record. The
badge stays until the admin records the re-check; a result of "cancelled" (GST cancelled, IEC
deactivated) then removes it. Nothing is fetched from any government page. Does nothing while
the module is off (MARKET_LINK_ENABLED). Two runs never overlap: on Postgres the run holds a
session-level advisory lock (pattern of market/pull_job.py). Prints a JSON summary.

Run nightly (deploy/deploy.sh adds the cron line unless CRON_ML_RECHECK=off):
    python -m bagmitra_api.market_link.recheck_job
"""

from __future__ import annotations

import asyncio
import json
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dataclasses import asdict, dataclass
from datetime import datetime

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.market_link.checks import due_for_recheck
from bagmitra_api.market_link.models import VerificationCheck

RECHECK_LOCK_KEY = 0x6261_676D_6C6B_0007  # "bagmlk" + 7
SKIPPED_OFF = "market link is off (MARKET_LINK_ENABLED)"
SKIPPED_LOCKED = "another re-check run is running"


@dataclass
class RecheckSummary:
    listed: int = 0
    already_listed: int = 0
    skipped_reason: str | None = None

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


@asynccontextmanager
async def recheck_lock(engine: AsyncEngine) -> AsyncIterator[bool]:
    if engine.dialect.name != "postgresql":
        yield True
        return
    async with engine.connect() as conn:
        key = {"k": RECHECK_LOCK_KEY}
        got = bool((await conn.execute(text("SELECT pg_try_advisory_lock(:k)"), key)).scalar_one())
        await conn.commit()
        try:
            yield got
        finally:
            if got:
                await conn.execute(text("SELECT pg_advisory_unlock(:k)"), key)
                await conn.commit()


async def run_recheck(session: AsyncSession, settings: Settings, now: datetime) -> RecheckSummary:
    summary = RecheckSummary()
    if not settings.market_link_enabled:
        summary.skipped_reason = SKIPPED_OFF
        return summary
    latest: dict[tuple[str, object, str], VerificationCheck] = {}
    for row in await session.scalars(
        select(VerificationCheck).order_by(
            VerificationCheck.checked_at, VerificationCheck.created_at
        )
    ):
        latest[(row.subject_type, row.subject_id, row.kind)] = row
    for row in due_for_recheck(latest.values(), now, settings.market_link_recheck_days):
        if row.recheck_listed_at is None:
            row.recheck_listed_at = now
            summary.listed += 1
        else:
            summary.already_listed += 1
    await session.commit()
    return summary


async def run_locked(
    engine: AsyncEngine, session: AsyncSession, settings: Settings, now: datetime
) -> RecheckSummary:
    async with recheck_lock(engine) as held:
        if not held:
            return RecheckSummary(skipped_reason=SKIPPED_LOCKED)
        return await run_recheck(session, settings, now)


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    maker = get_sessionmaker()
    engine = maker.kw["bind"]
    async with maker() as session:
        summary = await run_locked(engine, session, get_settings(), utcnow())
    await engine.dispose()
    print(summary.to_json())
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
