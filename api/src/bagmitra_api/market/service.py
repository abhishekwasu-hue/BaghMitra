"""Mandi price storage and the read path (audit BG-04).

Prices come in only through the scheduled pull (`market/pull_job.py`, cron) and the
market_admin manual upload; a user request never calls Agmarknet. The read path serves what is
stored and says whether it is current (the fallback rule):
- MARKET_API_KEY empty: stored rows (e.g. manual ones), `stale`, reason `source_not_configured`;
- every commodity of the crop had a successful pull within MARKET_MAX_AGE_HOURS: not stale
  (also when that pull found no rows, e.g. off season: an empty list, not an error);
- otherwise stored rows, `stale`, with the reason of the commodity's last failed pull
  (`source_unreachable` / `source_bad_response`), `source_not_pulled_yet` when no pull has run,
  or `source_pull_overdue` when the pulls stopped (cron missing).
Prices are never invented. Readers get the latest price per mandi (market, variety, grade); on
the same day an Agmarknet row wins over a manual one."""

from __future__ import annotations

from collections.abc import Callable, Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Annotated, Protocol

import httpx
from fastapi import Depends
from sqlalchemy import select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc
from bagmitra_api.market.agmarknet import REASON_NOT_CONFIGURED, AgmarknetClient, MandiPrice
from bagmitra_api.market.models import MarketPrice, MarketPull
from bagmitra_api.weather.service import get_clock

AGMARKNET = "agmarknet"
MANUAL = "manual"  # typed in by a market_admin when Agmarknet has no price
REASON_NOT_PULLED = "source_not_pulled_yet"
REASON_OVERDUE = "source_pull_overdue"


class MarketProvider(Protocol):
    async def prices(
        self, *, commodity: str, state: str | None = None, market: str | None = None
    ) -> list[MandiPrice]: ...


def market_client(http: httpx.AsyncClient, settings: Settings) -> AgmarknetClient:
    return AgmarknetClient(
        http,
        base_url=settings.market_api_base_url,
        resource_id=settings.market_resource_id,
        api_key=settings.market_api_key.get_secret_value(),
        max_pages=settings.market_max_pages,
    )


@dataclass(frozen=True)
class MarketContext:
    settings: Settings
    clock: Callable[[], datetime]


def get_market_context(
    settings: Annotated[Settings, Depends(get_settings)],
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
) -> MarketContext:
    return MarketContext(settings, clock)


@dataclass(frozen=True)
class PriceView:
    prices: list[MarketPrice]
    stale: bool
    reason: str | None = None


async def store_prices(
    session: AsyncSession, prices: Sequence[MandiPrice], *, source: str, now: datetime
) -> None:
    """Insert or replace rows by their key (day, market, commodity, variety, grade, source)."""
    rows = {
        (p.day, p.market, p.commodity, p.variety or "", p.grade or "", source): p for p in prices
    }
    if not rows:
        return
    key = (
        MarketPrice.day,
        MarketPrice.market,
        MarketPrice.commodity,
        MarketPrice.variety,
        MarketPrice.grade,
        MarketPrice.source,
    )
    existing = await session.scalars(select(MarketPrice).where(tuple_(*key).in_(list(rows))))
    for row in existing:
        await session.delete(row)
    await session.flush()
    session.add_all(
        MarketPrice(
            day=k[0],
            market=k[1],
            commodity=k[2],
            variety=k[3],
            grade=k[4],
            source=k[5],
            state=p.state,
            district=p.district,
            min_rs_per_quintal=p.min_rs_per_quintal,
            max_rs_per_quintal=p.max_rs_per_quintal,
            modal_rs_per_quintal=p.modal_rs_per_quintal or 0,
            fetched_at=now,
        )
        for k, p in rows.items()
    )
    await session.commit()


async def _latest_per_mandi(
    session: AsyncSession, commodities: Sequence[str], since: datetime
) -> list[MarketPrice]:
    query = (
        select(MarketPrice)
        .where(MarketPrice.commodity.in_(commodities), MarketPrice.day >= since.date())
        .order_by(MarketPrice.day.desc(), MarketPrice.source == MANUAL)
    )
    latest: dict[tuple[str, str, str, str], MarketPrice] = {}
    for row in (await session.scalars(query)).all():
        latest.setdefault((row.market, row.commodity, row.variety, row.grade), row)
    return list(latest.values())


def _pull_problem(pull: MarketPull | None, now: datetime, max_age: timedelta) -> str | None:
    """None when the commodity's stored prices are current, else the reason code."""
    if pull is None:
        return REASON_NOT_PULLED
    if pull.last_success_at is not None and now - as_utc(pull.last_success_at) < max_age:
        return None
    return pull.last_error or REASON_OVERDUE


async def _freshness(
    session: AsyncSession, ctx: MarketContext, commodities: Sequence[str]
) -> tuple[bool, str | None]:
    """(stale, reason) for the stored prices of `commodities`; see the module docstring."""
    settings, now = ctx.settings, ctx.clock()
    if not settings.market_api_key.get_secret_value():
        return True, REASON_NOT_CONFIGURED
    pulls = {
        p.commodity: p
        for p in await session.scalars(
            select(MarketPull).where(MarketPull.commodity.in_(commodities))
        )
    }
    max_age = timedelta(hours=settings.market_max_age_hours)
    for commodity in commodities:
        problem = _pull_problem(pulls.get(commodity), now, max_age)
        if problem is not None:
            return True, problem
    return False, None


async def prices_for_commodities(
    session: AsyncSession, ctx: MarketContext, commodities: Sequence[str]
) -> PriceView:
    """Stored prices only (no fetch); see the module docstring for the stale rule."""
    since = ctx.clock() - timedelta(days=ctx.settings.market_window_days)
    rows = await _latest_per_mandi(session, commodities, since)
    stale, reason = await _freshness(session, ctx, commodities)
    return PriceView(rows, stale=stale, reason=reason)


async def price_history(  # noqa: PLR0913 - one mandi is named by all of these
    session: AsyncSession,
    ctx: MarketContext,
    commodities: Sequence[str],
    *,
    market: str,
    variety: str,
    grade: str,
    days: int,
) -> PriceView:
    """Owner 2026-11-09 (price trend): one stored price per day for one mandi (market, variety,
    grade) over the last `days` days, oldest first. On a day with both, the Agmarknet row wins
    over a manual one. Days without a published price are simply absent (never filled in)."""
    since = (ctx.clock() - timedelta(days=days)).date()
    query = (
        select(MarketPrice)
        .where(
            MarketPrice.commodity.in_(commodities),
            MarketPrice.market == market,
            MarketPrice.variety == variety,
            MarketPrice.grade == grade,
            MarketPrice.day > since,
        )
        .order_by(MarketPrice.day, MarketPrice.source == MANUAL)
    )
    per_day: dict[date, MarketPrice] = {}
    for row in (await session.scalars(query)).all():
        per_day.setdefault(row.day, row)
    stale, reason = await _freshness(session, ctx, commodities)
    return PriceView(list(per_day.values()), stale=stale, reason=reason)
