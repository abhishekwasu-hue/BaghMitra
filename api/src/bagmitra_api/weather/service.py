"""Per-location weather storage: pull from the provider when stored days are old, otherwise
serve what is stored. A failed pull falls back to stored days marked stale."""

from __future__ import annotations

from collections.abc import AsyncIterator, Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Annotated, Protocol

import httpx
from fastapi import Depends
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc, utcnow
from bagmitra_api.weather.models import WeatherDaily
from bagmitra_api.weather.open_meteo import DailyWeather, OpenMeteoClient, WeatherUnavailableError

Cell = tuple[float, float]


class WeatherProvider(Protocol):
    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]: ...


async def get_weather_provider(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[WeatherProvider]:
    async with httpx.AsyncClient(timeout=10) as http:
        yield OpenMeteoClient(
            http,
            base_url=settings.weather_base_url,
            api_key=settings.weather_api_key.get_secret_value(),
        )


def get_clock() -> Callable[[], datetime]:
    return utcnow


@dataclass(frozen=True)
class WeatherContext:
    settings: Settings
    provider: WeatherProvider
    clock: Callable[[], datetime]


def get_weather_context(
    settings: Annotated[Settings, Depends(get_settings)],
    provider: Annotated[WeatherProvider, Depends(get_weather_provider)],
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
) -> WeatherContext:
    return WeatherContext(settings, provider, clock)


def cell_for(lat: float, lon: float, decimals: int) -> Cell:
    return (round(lat, decimals), round(lon, decimals))


def _to_daily(row: WeatherDaily) -> DailyWeather:
    return DailyWeather(
        row.day,
        row.t_max_c,
        row.t_min_c,
        row.precip_mm,
        row.rh_mean_pct,
        row.wind_gust_kmh,
        row.weather_code,
    )


async def _stored(session: AsyncSession, cell: Cell) -> list[WeatherDaily]:
    query = (
        select(WeatherDaily)
        .where(WeatherDaily.cell_lat == cell[0], WeatherDaily.cell_lon == cell[1])
        .order_by(WeatherDaily.day)
    )
    return list((await session.scalars(query)).all())


async def weather_for_cell(
    session: AsyncSession,
    provider: WeatherProvider,
    settings: Settings,
    cell: Cell,
    now: datetime,
) -> tuple[list[DailyWeather], bool]:
    """Days for the cell within the configured window and whether they are stale."""
    start = now.date() - timedelta(days=settings.weather_past_days)
    rows = [r for r in await _stored(session, cell) if r.day >= start]
    newest = max((as_utc(r.fetched_at) for r in rows), default=None)
    if newest is not None and now - newest < timedelta(hours=settings.weather_max_age_hours):
        return [_to_daily(r) for r in rows], False
    try:
        days = await provider.daily(
            *cell,
            past_days=settings.weather_past_days,
            forecast_days=settings.weather_forecast_days,
        )
    except WeatherUnavailableError:
        if not rows:
            raise
        return [_to_daily(r) for r in rows], True
    await session.execute(
        delete(WeatherDaily).where(
            WeatherDaily.cell_lat == cell[0],
            WeatherDaily.cell_lon == cell[1],
            WeatherDaily.day.in_([d.day for d in days]),
        )
    )
    session.add_all(
        WeatherDaily(
            cell_lat=cell[0],
            cell_lon=cell[1],
            day=d.day,
            t_max_c=d.t_max_c,
            t_min_c=d.t_min_c,
            precip_mm=d.precip_mm,
            rh_mean_pct=d.rh_mean_pct,
            wind_gust_kmh=d.wind_gust_kmh,
            weather_code=d.weather_code,
            fetched_at=now,
        )
        for d in days
    )
    await session.commit()
    return sorted((d for d in days if d.day >= start), key=lambda d: d.day), False
