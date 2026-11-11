"""Open-Meteo weather adapter (M4: per-plot weather pulls).

Returns plain daily values for the risk engine, and the current reading for the home header
(Q140); it holds no thresholds and gives no advice.
The base URL and key come from settings: the free endpoint for development, the commercial
endpoint (with `apikey`) once the app is sold (OPEN_QUESTIONS Q25).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
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
    # Highest chance of rain in the day (%); forecast days only, past days come back null.
    "precipitation_probability_max",
)
# A series the parser accepts as absent (all None): the forecast screen shows it, no rule
# needs it, so a provider answer without it still serves the rest of the day.
_OPTIONAL_FIELDS = frozenset({"precipitation_probability_max"})
# The `current` block (Q140): the model's latest 15-minute value, its WMO sky code and
# whether the sun is up there (1 day, 0 night).
CURRENT_FIELDS = ("temperature_2m", "weather_code", "is_day")


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
    rain_prob_pct: float | None = None


@dataclass(frozen=True)
class CurrentWeather:
    """The provider's reading at `observed_at` (UTC); never estimated by us."""

    observed_at: datetime
    temperature_c: float
    weather_code: float | None
    is_day: bool | None


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
        if values is None and field in _OPTIONAL_FIELDS:
            values = [None] * len(days)
        if not isinstance(values, list) or len(values) != len(days):
            raise WeatherUnavailableError(f"series {field} missing or wrong length")
        series.append(values)
    return [
        DailyWeather(date.fromisoformat(d), *(_num(s[i]) for s in series))
        for i, d in enumerate(days)
    ]


def parse_current(payload: dict[str, Any]) -> CurrentWeather:
    current = payload.get("current")
    if not isinstance(current, dict) or not isinstance(current.get("time"), str):
        raise WeatherUnavailableError(f"no current block in response: {payload.get('reason')}")
    temperature = _num(current.get("temperature_2m"))
    if temperature is None:
        raise WeatherUnavailableError("no current temperature")
    offset = payload.get("utc_offset_seconds", 0)
    if not isinstance(offset, int) or isinstance(offset, bool):
        raise WeatherUnavailableError(f"bad utc offset: {offset!r}")
    try:
        stamp = datetime.fromisoformat(current["time"])
    except ValueError as exc:
        raise WeatherUnavailableError(f"bad current time: {current['time']!r}") from exc
    # The provider writes the time in the requested timezone without an offset.
    observed = (
        (stamp - timedelta(seconds=offset)).replace(tzinfo=UTC)
        if stamp.tzinfo is None
        else stamp.astimezone(UTC)
    )
    is_day = _num(current.get("is_day"))
    return CurrentWeather(
        observed_at=observed,
        temperature_c=temperature,
        weather_code=_num(current.get("weather_code")),
        is_day=None if is_day is None else is_day >= 1,
    )


class OpenMeteoClient:
    def __init__(self, http: httpx.AsyncClient, *, base_url: str, api_key: str) -> None:
        self._http = http
        self._base_url = base_url.rstrip("/")
        self._api_key = api_key

    async def daily(
        self, lat: float, lon: float, *, past_days: int, forecast_days: int
    ) -> list[DailyWeather]:
        return parse_daily(
            await self._forecast(
                {
                    "latitude": lat,
                    "longitude": lon,
                    "daily": ",".join(DAILY_FIELDS),
                    "timezone": "auto",
                    "past_days": past_days,
                    "forecast_days": forecast_days,
                }
            )
        )

    async def current(self, lat: float, lon: float) -> CurrentWeather:
        """The current reading only (no daily series); the time comes back in GMT."""
        return parse_current(
            await self._forecast(
                {
                    "latitude": lat,
                    "longitude": lon,
                    "current": ",".join(CURRENT_FIELDS),
                    "timezone": "GMT",
                }
            )
        )

    async def _forecast(self, params: dict[str, str | int | float]) -> dict[str, Any]:
        if self._api_key:
            params["apikey"] = self._api_key
        try:
            response = await self._http.get(f"{self._base_url}/forecast", params=params)
        except httpx.HTTPError as exc:
            raise WeatherUnavailableError(str(exc)) from exc
        if response.status_code != httpx.codes.OK:
            raise WeatherUnavailableError(f"HTTP {response.status_code}")
        payload = response.json()
        if not isinstance(payload, dict):
            raise WeatherUnavailableError("response is not an object")
        return payload
