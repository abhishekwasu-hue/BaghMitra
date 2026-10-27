"""Mandi price storage: pull India-wide from Agmarknet when stored prices are old, otherwise
serve what is stored. A failed pull falls back to stored prices marked stale; prices are
never invented. Readers get the latest price per mandi (market, variety, grade); on the
same day an Agmarknet row wins over a manual one."""

from __future__ import annotations

from collections.abc import AsyncIterator, Callable, Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Annotated, Protocol

import httpx
from fastapi import Depends
from sqlalchemy import select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc
from bagmitra_api.market.agmarknet import AgmarknetClient, MandiPrice, MarketUnavailableError
from bagmitra_api.market.models import MarketPrice
from bagmitra_api.weather.service import get_clock

AGMARKNET = "agmarknet"
MANUAL = "manual"  # typed in by a market_admin when Agmarknet has no price


class MarketProvider(Protocol):
    async def prices(
        self, *, commodity: str, state: str | None = None, market: str | None = None
    ) -> list[MandiPrice]: ...


async def get_market_provider(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[MarketProvider]:
    async with httpx.AsyncClient(timeout=15) as http:
        yield AgmarknetClient(
            http,
            base_url=settings.market_api_base_url,
            resource_id=settings.market_resource_id,
            api_key=settings.market_api_key.get_secret_value(),
            max_pages=settings.market_max_pages,
        )


@dataclass(frozen=True)
class MarketContext:
    settings: Settings
    provider: MarketProvider
    clock: Callable[[], datetime]


def get_market_context(
    settings: Annotated[Settings, Depends(get_settings)],
    provider: Annotated[MarketProvider, Depends(get_market_provider)],
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
) -> MarketContext:
    return MarketContext(settings, provider, clock)


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


async def prices_for_commodities(
    session: AsyncSession, ctx: MarketContext, commodities: Sequence[str]
) -> PriceView:
    settings, now = ctx.settings, ctx.clock()
    since = now - timedelta(days=settings.market_window_days)
    rows = await _latest_per_mandi(session, commodities, since)
    pulled = [as_utc(r.fetched_at) for r in rows if r.source == AGMARKNET]
    if pulled and now - max(pulled) < timedelta(hours=settings.market_max_age_hours):
        return PriceView(rows, stale=False)
    try:
        fetched = [
            p
            for commodity in commodities
            for p in await ctx.provider.prices(
                commodity=commodity, state=settings.market_state or None
            )
        ]
    except MarketUnavailableError as exc:
        return PriceView(rows, stale=True, reason=str(exc))
    await store_prices(session, fetched, source=AGMARKNET, now=now)
    return PriceView(await _latest_per_mandi(session, commodities, since), stale=False)
