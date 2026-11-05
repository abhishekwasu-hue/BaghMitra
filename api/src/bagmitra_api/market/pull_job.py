"""Scheduled mandi price pull (audit BG-04): fetch every configured Agmarknet commodity
India-wide and store the rows, so a user request only ever reads stored prices.

Each commodity is fetched once per run (at most MARKET_MAX_PAGES pages, each request bounded by
MARKET_TIMEOUT_SECONDS) and its outcome is written to `market_pulls`; one failing commodity
does not stop the others. Two runs never overlap: on Postgres the run holds a session-level
advisory lock and a second run that finds it taken exits at once (`skipped_reason`). SQLite
(local development only) has no such lock and runs unguarded. With MARKET_API_KEY empty the run
does nothing. Prints a JSON summary; exit 1 when a commodity failed.

Run every 6 hours (deploy/deploy.sh adds the cron line when MARKET_API_KEY is set; runbook
docs/runbooks/market-prices.md):
    python -m bagmitra_api.market.pull_job
"""

from __future__ import annotations

import asyncio
import json
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dataclasses import asdict, dataclass, field
from datetime import datetime

import httpx
import structlog
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.market.agmarknet import MarketUnavailableError
from bagmitra_api.market.models import MarketPull
from bagmitra_api.market.service import AGMARKNET, MarketProvider, market_client, store_prices

log = structlog.get_logger("bagmitra.market.pull")

# Fixed key of the Postgres advisory lock that serialises market pulls (any 64-bit integer
# unique to this job).
PULL_LOCK_KEY = 0x6261_676D_6B74_0001  # "bagmkt" + 1
SKIPPED_NO_KEY = "no API key configured (MARKET_API_KEY)"
SKIPPED_LOCKED = "another market pull is running"


@dataclass
class CommodityOutcome:
    commodity: str
    rows: int = 0
    error: str | None = None


@dataclass
class MarketPullSummary:
    commodities: list[CommodityOutcome] = field(default_factory=list)
    skipped_reason: str | None = None

    @property
    def failed(self) -> int:
        return sum(o.error is not None for o in self.commodities)

    def to_json(self) -> str:
        return json.dumps({**asdict(self), "failed": self.failed}, ensure_ascii=False)


def configured_commodities(settings: Settings) -> list[str]:
    """Every Agmarknet commodity name of every priced crop, once, in a stable order."""
    return sorted({c for names in settings.market_commodities.values() for c in names})


@asynccontextmanager
async def pull_lock(engine: AsyncEngine) -> AsyncIterator[bool]:
    """Yields whether this run holds the pull lock. The lock lives on its own connection for
    the whole run (session-level, so the per-commodity commits do not release it)."""
    if engine.dialect.name != "postgresql":
        yield True
        return
    async with engine.connect() as conn:
        got = bool(
            (
                await conn.execute(text("SELECT pg_try_advisory_lock(:k)"), {"k": PULL_LOCK_KEY})
            ).scalar_one()
        )
        await conn.commit()
        try:
            yield got
        finally:
            if got:
                await conn.execute(text("SELECT pg_advisory_unlock(:k)"), {"k": PULL_LOCK_KEY})
                await conn.commit()


async def _record(session: AsyncSession, outcome: CommodityOutcome, now: datetime) -> None:
    pull = await session.get(MarketPull, outcome.commodity)
    if pull is None:
        pull = MarketPull(commodity=outcome.commodity, last_attempt_at=now, last_rows=0)
        session.add(pull)
    pull.last_attempt_at = now
    pull.last_error = outcome.error
    if outcome.error is None:
        pull.last_success_at = now
        pull.last_rows = outcome.rows
    await session.commit()


async def run_market_pull(
    session: AsyncSession, provider: MarketProvider, settings: Settings, now: datetime
) -> MarketPullSummary:
    """Fetch and store every configured commodity once; record each outcome."""
    summary = MarketPullSummary()
    if not settings.market_api_key.get_secret_value():
        summary.skipped_reason = SKIPPED_NO_KEY
        return summary
    for commodity in configured_commodities(settings):
        outcome = CommodityOutcome(commodity)
        try:
            prices = await provider.prices(commodity=commodity, state=settings.market_state or None)
        except MarketUnavailableError as exc:
            log.warning("market_pull_failed", commodity=commodity, code=exc.code, detail=str(exc))
            outcome.error = exc.code
        else:
            await store_prices(session, prices, source=AGMARKNET, now=now)
            outcome.rows = len(prices)
        await _record(session, outcome, now)
        summary.commodities.append(outcome)
    return summary


async def run_locked(
    engine: AsyncEngine,
    session: AsyncSession,
    provider: MarketProvider,
    settings: Settings,
    now: datetime,
) -> MarketPullSummary:
    async with pull_lock(engine) as held:
        if not held:
            return MarketPullSummary(skipped_reason=SKIPPED_LOCKED)
        return await run_market_pull(session, provider, settings, now)


def market_http(
    settings: Settings, transport: httpx.AsyncBaseTransport | None = None
) -> httpx.AsyncClient:
    """The HTTP client of a run: every request bounded by MARKET_TIMEOUT_SECONDS."""
    return httpx.AsyncClient(
        timeout=httpx.Timeout(settings.market_timeout_seconds), transport=transport
    )


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    maker = get_sessionmaker()
    engine = maker.kw["bind"]
    async with maker() as session, market_http(settings) as http:
        summary = await run_locked(
            engine, session, market_client(http, settings), settings, utcnow()
        )
    await engine.dispose()
    print(summary.to_json())
    return 1 if summary.failed else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
