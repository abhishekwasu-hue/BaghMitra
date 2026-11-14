from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta
from typing import Annotated

import structlog
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.models import Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.risk.engine import evaluate, load_rules, rules_for_crop
from bagmitra_api.weather.open_meteo import WeatherUnavailableError
from bagmitra_api.weather.service import (
    WeatherContext,
    alert_days,
    cell_for,
    get_weather_context,
    weather_for_cell,
)

log = structlog.get_logger("bagmitra.weather")

router = APIRouter(prefix="/v1", tags=["weather"])


class WeatherDay(BaseModel):
    day: date
    t_max_c: float | None
    t_min_c: float | None
    precip_mm: float | None
    rh_mean_pct: float | None
    wind_gust_kmh: float | None
    # WMO code (95 thunderstorm, 96 / 99 with hail); optional for older stored days.
    weather_code: float | None = None
    # Chance of rain, % (highest in the day); None for past days and older stored days.
    rain_prob_pct: float | None = None


class WeatherAlert(BaseModel):
    rule_key: str
    first_day: date
    value: float
    units: float | None
    text: str
    source: str
    status: str
    # App screen the alert links to ("claim_kit": take loss photos now), if any.
    action: str | None = None


class CurrentConditions(BaseModel):
    """The provider's reading for the plot's location at `observed_at` (UTC), for the home
    header (Q140). Served from a short per-location cache; an older reading keeps its own
    time, so the phone can tell how old it is."""

    temperature_c: float
    # WMO code (0 clear, 2-3 cloud, 51+ rain, 95+ thunderstorm); None when not given.
    weather_code: float | None
    # Whether the sun is up at the location; None when not given.
    is_day: bool | None
    observed_at: datetime


class PlotWeather(BaseModel):
    days: list[WeatherDay]
    alerts: list[WeatherAlert]
    stale: bool
    # The current reading; None when the provider has given none yet (older apps ignore it).
    current: CurrentConditions | None = None


@router.get(
    "/plots/{plot_id}/weather",
    operation_id="plot_weather_get",
    responses={
        401: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        503: {"model": ErrorResponse},
    },
)
async def get_plot_weather(
    plot_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[WeatherContext, Depends(get_weather_context)],
    lang: Annotated[str, Query(pattern="^[a-z]{2}$")] = "en",
) -> PlotWeather:
    """Recent and forecast days for the plot's location, with rule-based risk alerts, and
    the current reading there (null when the provider has given none).

    Alerts come only from the configured rules (never from AI) and carry no chemical advice.
    """
    plot = await session.get(Plot, plot_id)
    if plot is None or plot.owner_id != user.id or plot.deleted_at is not None:
        raise ApiError(404, "plot_not_found")
    if plot.centroid_lat is None or plot.centroid_lon is None:
        raise ApiError(409, "plot_location_missing", "mark the plot location first")
    cell = cell_for(plot.centroid_lat, plot.centroid_lon, ctx.settings.weather_cell_decimals)
    now = ctx.clock()
    try:
        days, stale = await weather_for_cell(session, ctx.provider, ctx.settings, cell, now)
    except WeatherUnavailableError as exc:
        log.warning("weather_source_unavailable", detail=str(exc))
        raise ApiError(503, "weather_unavailable") from exc
    current = await ctx.current_cache.get(
        ctx.provider,
        cell,
        now,
        timedelta(minutes=ctx.settings.weather_current_cache_minutes),
    )
    rules = {r.key: r for r in load_rules()}
    return PlotWeather(
        days=[WeatherDay.model_validate(d, from_attributes=True) for d in days],
        alerts=[
            WeatherAlert(
                rule_key=a.rule_key,
                first_day=a.first_day,
                value=a.value,
                units=a.units,
                text=rules[a.rule_key].labels.get(lang) or rules[a.rule_key].labels["en"],
                source=rules[a.rule_key].source,
                status=rules[a.rule_key].status,
                action=rules[a.rule_key].action,
            )
            # A rule for other crops (e.g. citrus psylla) never alerts this plot.
            for a in evaluate(
                rules_for_crop(list(rules.values()), plot.crop),
                alert_days(days, ctx.settings, now),
            )
        ],
        stale=stale,
        current=None
        if current is None
        else CurrentConditions.model_validate(current, from_attributes=True),
    )
