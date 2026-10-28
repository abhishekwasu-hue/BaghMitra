"""Open-Meteo daily weather adapter (M4: per-plot weather pulls).

Returns plain daily values for the risk engine; it holds no thresholds and gives no advice.
The base URL and key come from settings: the free endpoint for development, the commercial
endpoint (with `apikey`) once the app is sold (OPEN_QUESTIONS Q25).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Any

import httpx

DAILY_FIELDS = (
    "temperature_2m_max",
    "temperature_2m_min",
    "precipitation_sum",
    "relative_humidity_2m_mean",
    "wind_gusts_10m_max",
    # WMO weather code, the day's most severe: 95 thunderstorm, 96 / 99 with hail.
    "weather_code",
)


class WeatherUnavailableError(Exception):
    """The provider could not be reached or answered with something we cannot use."""


@dataclass(frozen=True)
class DailyWeather:
    day: date
    t_max_c: float | None
    t_min_c: float | None
    precip_mm: float | None
    rh_mean_pct: float | None
    wind_gust_kmh: float | None
    weather_code: float | None = None


def _num(value: object) -> float | None:
    if value is None:
        return None
    if isinstance(value, int | float) and not isinstance(value, bool):
        return float(value)
    raise WeatherUnavailableError(f"not a number: {value!r}")


def parse_daily(payload: dict[str, Any]) -> list[DailyWeather]:
    daily = payload.get("daily")
    if not isinstance(daily, dict) or not isinstance(daily.get("time"), list):
        raise WeatherUnavailableError(f"no daily series in response: {payload.get('reason')}")
    days: list[str] = daily["time"]
    series: list[list[object]] = []
    for field in DAILY_FIELDS:
        values = daily.get(field)
        if not isinstance(values, list) or len(values) != len(days):
            raise WeatherUnavailableError(f"series {field} missing or wrong length")
        series.append(values)
    return [
        DailyWeather(date.fromisoformat(d), *(_num(s[i]) for s in series))
        for i, d in enumerate(days)
    ]


class OpenMeteoClient:
    def __init__(self, http: httpx.AsyncClient, *, base_url: str, api_key: str) -> None:
        self._http = http
        self._base_url = base_url.rstrip("/")
        self._api_key = api_key

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        params: dict[str, str | int | float] = {
            "latitude": lat,
            "longitude": lon,
            "daily": ",".join(DAILY_FIELDS),
            "timezone": "auto",
            "past_days": past_days,
            "forecast_days": forecast_days,
        }
        if self._api_key:
            params["apikey"] = self._api_key
        try:
            response = await self._http.get(f"{self._base_url}/forecast", params=params)
        except httpx.HTTPError as exc:
            raise WeatherUnavailableError(str(exc)) from exc
        if response.status_code != httpx.codes.OK:
            raise WeatherUnavailableError(f"HTTP {response.status_code}")
        return parse_daily(response.json())
