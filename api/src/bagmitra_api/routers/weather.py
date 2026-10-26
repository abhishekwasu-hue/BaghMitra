from __future__ import annotations

import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.models import Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.risk.engine import evaluate, load_rules
from bagmitra_api.weather.open_meteo import WeatherUnavailableError
from bagmitra_api.weather.service import (
    WeatherContext,
    cell_for,
    get_weather_context,
    weather_for_cell,
)

router = APIRouter(prefix="/v1", tags=["weather"])


class WeatherDay(BaseModel):
    day: date
    t_max_c: float | None
    t_min_c: float | None
    precip_mm: float | None
    rh_mean_pct: float | None
    wind_gust_kmh: float | None


class WeatherAlert(BaseModel):
    rule_key: str
    first_day: date
    value: float
    units: float | None
    text: str
    source: str
    status: str


class PlotWeather(BaseModel):
    days: list[WeatherDay]
    alerts: list[WeatherAlert]
    stale: bool


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
    """Recent and forecast days for the plot's location, with rule-based risk alerts.

    Alerts come only from the configured rules (never from AI) and carry no chemical advice.
    """
    plot = await session.get(Plot, plot_id)
    if plot is None or plot.owner_id != user.id or plot.deleted_at is not None:
        raise ApiError(404, "plot_not_found")
    if plot.centroid_lat is None or plot.centroid_lon is None:
        raise ApiError(409, "plot_location_missing", "mark the plot location first")
    cell = cell_for(plot.centroid_lat, plot.centroid_lon, ctx.settings.weather_cell_decimals)
    try:
        days, stale = await weather_for_cell(session, ctx.provider, ctx.settings, cell, ctx.clock())
    except WeatherUnavailableError as exc:
        raise ApiError(503, "weather_unavailable", str(exc)) from exc
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
            )
            for a in evaluate(list(rules.values()), days)
        ],
        stale=stale,
    )
