"""Per-location weather storage: pull from the provider when stored days are old, otherwise
serve what is stored. A failed pull falls back to stored days marked stale. The current
reading (Q140) is cached in memory per cell for a short window instead."""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator, Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Annotated, Protocol

import httpx
import structlog
from fastapi import Depends
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc, utcnow
from bagmitra_api.weather.models import WeatherDaily
from bagmitra_api.weather.open_meteo import (
    CurrentWeather,
    DailyWeather,
    OpenMeteoClient,
    WeatherUnavailableError,
)

log = structlog.get_logger("bagmitra.weather")

Cell = tuple[float, float]


class WeatherProvider(Protocol):
    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]: ...


class CurrentWeatherProvider(Protocol):
    async def current(self, lat: float, lon: float) -> CurrentWeather: ...


class PlotWeatherProvider(WeatherProvider, CurrentWeatherProvider, Protocol):
    """What the plot weather answer reads: the days and the current reading."""


async def get_weather_provider(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[PlotWeatherProvider]:
    async with httpx.AsyncClient(timeout=10) as http:
        yield OpenMeteoClient(
            http,
            base_url=settings.weather_base_url,
            api_key=settings.weather_api_key.get_secret_value(),
        )


def get_clock() -> Callable[[], datetime]:
    return utcnow


class CurrentWeatherCache:
    """The current reading per cell, kept in this process's memory (no table: a reading is
    worth little after an hour). Within the window every plot in the cell gets the stored
    reading; after it the provider is asked again, and if that fails the last reading is
    served with its own observation time, or None when there is none. Never estimated."""

    def __init__(self) -> None:
        self._entries: dict[Cell, tuple[CurrentWeather, datetime]] = {}
        self._locks: dict[Cell, asyncio.Lock] = {}

    async def get(
        self,
        provider: CurrentWeatherProvider,
        cell: Cell,
        now: datetime,
        window: timedelta,
    ) -> CurrentWeather | None:
        # One call per cell at a time: concurrent requests wait and reuse its answer.
        async with self._locks.setdefault(cell, asyncio.Lock()):
            entry = self._entries.get(cell)
            if entry is not None and now - entry[1] < window:
                return entry[0]
            try:
                current = await provider.current(*cell)
            except WeatherUnavailableError as exc:
                log.warning("current_weather_unavailable", detail=str(exc))
                return entry[0] if entry is not None else None
            self._entries[cell] = (current, now)
            return current


_current_cache = CurrentWeatherCache()


def get_current_cache() -> CurrentWeatherCache:
    return _current_cache


@dataclass(frozen=True)
class WeatherContext:
    settings: Settings
    provider: PlotWeatherProvider
    clock: Callable[[], datetime]
    current_cache: CurrentWeatherCache


def get_weather_context(
    settings: Annotated[Settings, Depends(get_settings)],
    provider: Annotated[PlotWeatherProvider, Depends(get_weather_provider)],
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
    current_cache: Annotated[CurrentWeatherCache, Depends(get_current_cache)],
) -> WeatherContext:
    return WeatherContext(settings, provider, clock, current_cache)


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
        row.rain_prob_pct,
    )


def alert_days(days: list[DailyWeather], settings: Settings, now: datetime) -> list[DailyWeather]:
    """The days the risk rules read: the past days and the first `weather_alert_forecast_days`
    forecast days. The forecast screen serves more days; the rules keep their window (Q134)."""
    end = now.date() + timedelta(days=settings.weather_alert_forecast_days)
    return [d for d in days if d.day <= end]


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
            rain_prob_pct=d.rain_prob_pct,
            fetched_at=now,
        )
        for d in days
    )
    await session.commit()
    return sorted((d for d in days if d.day >= start), key=lambda d: d.day), False
