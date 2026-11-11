from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.weather.open_meteo import (
    CURRENT_FIELDS,
    DAILY_FIELDS,
    CurrentWeather,
    DailyWeather,
    OpenMeteoClient,
    WeatherUnavailableError,
    parse_current,
    parse_daily,
)

# Shape of a real Open-Meteo /v1/forecast daily response (values shortened by hand).
SAMPLE: dict[str, Any] = {
    "latitude": 21.25,
    "longitude": 77.75,
    "timezone": "Asia/Kolkata",
    "daily_units": {"temperature_2m_max": "°C", "precipitation_sum": "mm"},
    "daily": {
        "time": ["2026-03-14", "2026-03-15"],
        "temperature_2m_max": [38.4, 40.1],
        "temperature_2m_min": [21.0, 22.6],
        "precipitation_sum": [0.0, 12.5],
        "relative_humidity_2m_mean": [31, None],
        "wind_gusts_10m_max": [24.1, 61.2],
        "weather_code": [3, 95],
        "precipitation_probability_max": [10, 85],
    },
}


def test_parse_daily_maps_each_day_and_keeps_missing_values_missing() -> None:
    days = parse_daily(SAMPLE)
    assert days == [
        DailyWeather(date(2026, 3, 14), 38.4, 21.0, 0.0, 31.0, 24.1, 3.0, 10.0),
        DailyWeather(date(2026, 3, 15), 40.1, 22.6, 12.5, None, 61.2, 95.0, 85.0),
    ]


def test_parse_daily_without_rain_probability_keeps_the_other_values() -> None:
    # Past days, or a provider answer without the series, have no chance of rain.
    daily = {k: v for k, v in SAMPLE["daily"].items() if k != "precipitation_probability_max"}
    days = parse_daily({"daily": daily})
    assert [d.rain_prob_pct for d in days] == [None, None]
    assert days[1].precip_mm == 12.5
    ragged = {"daily": {**SAMPLE["daily"], "precipitation_probability_max": [10]}}
    with pytest.raises(WeatherUnavailableError, match="precipitation_probability_max"):
        parse_daily(ragged)


def test_parse_daily_rejects_ragged_or_missing_series() -> None:
    ragged = {"daily": {**SAMPLE["daily"], "precipitation_sum": [0.0]}}
    with pytest.raises(WeatherUnavailableError, match="precipitation_sum"):
        parse_daily(ragged)
    with pytest.raises(WeatherUnavailableError, match="daily"):
        parse_daily({"error": True, "reason": "bad"})


async def test_client_sends_location_window_and_optional_key() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=SAMPLE)

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = OpenMeteoClient(http, base_url="https://example.test/v1", api_key="k1")
        days = await client.daily(21.25, 77.75, past_days=7, forecast_days=7)

    assert len(days) == 2
    q = seen[0].url.params
    assert seen[0].url.path == "/v1/forecast"
    assert (q["latitude"], q["longitude"]) == ("21.25", "77.75")
    assert (q["past_days"], q["forecast_days"]) == ("7", "7")
    assert q["daily"] == ",".join(DAILY_FIELDS)
    assert "precipitation_probability_max" in q["daily"].split(",")
    assert q["timezone"] == "auto"
    assert q["apikey"] == "k1"


async def test_client_omits_empty_key_and_reports_failures() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert "apikey" not in request.url.params
        return httpx.Response(429, json={"error": True, "reason": "limit"})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = OpenMeteoClient(http, base_url="https://example.test/v1", api_key="")
        with pytest.raises(WeatherUnavailableError, match="429"):
            await client.daily(21.25, 77.75, past_days=0, forecast_days=3)


async def test_client_reports_network_errors() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("down", request=request)

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = OpenMeteoClient(http, base_url="https://example.test/v1", api_key="")
        with pytest.raises(WeatherUnavailableError, match="down"):
            await client.daily(21.25, 77.75, past_days=0, forecast_days=3)


def test_parse_daily_rejects_non_numbers() -> None:
    bad = {"daily": {**SAMPLE["daily"], "temperature_2m_max": ["hot", 40.1]}}
    with pytest.raises(WeatherUnavailableError, match="not a number"):
        parse_daily(bad)


def test_settings_default_to_the_free_endpoint_without_a_key() -> None:
    s = Settings()
    assert s.weather_base_url.startswith("https://api.open-meteo.com")
    assert s.weather_api_key.get_secret_value() == ""


# Shape of a real Open-Meteo /v1/forecast `current` response (GMT, the default timezone).
CURRENT_SAMPLE: dict[str, Any] = {
    "latitude": 21.25,
    "longitude": 77.75,
    "utc_offset_seconds": 0,
    "timezone": "GMT",
    "current_units": {"time": "iso8601", "temperature_2m": "°C", "is_day": ""},
    "current": {
        "time": "2026-11-11T12:45",
        "interval": 900,
        "temperature_2m": 21.4,
        "weather_code": 0,
        "is_day": 0,
    },
}


def test_parse_current_reads_temperature_sky_night_and_time_in_utc() -> None:
    assert parse_current(CURRENT_SAMPLE) == CurrentWeather(
        observed_at=datetime(2026, 11, 11, 12, 45, tzinfo=UTC),
        temperature_c=21.4,
        weather_code=0.0,
        is_day=False,
    )


def test_parse_current_turns_a_local_time_into_utc() -> None:
    local = {
        **CURRENT_SAMPLE,
        "utc_offset_seconds": 19800,
        "current": {**CURRENT_SAMPLE["current"], "time": "2026-11-11T18:15", "is_day": 1},
    }
    now = parse_current(local)
    assert now.observed_at == datetime(2026, 11, 11, 12, 45, tzinfo=UTC)
    assert now.is_day is True


def test_parse_current_keeps_missing_sky_missing_but_needs_a_temperature() -> None:
    no_sky = {"current": {"time": "2026-11-11T12:45", "temperature_2m": 20.0}}
    assert parse_current(no_sky).weather_code is None
    assert parse_current(no_sky).is_day is None
    for bad in (
        {"error": True, "reason": "bad"},
        {"current": {"time": "2026-11-11T12:45", "temperature_2m": None}},
        {"current": {"time": "not a time", "temperature_2m": 20.0}},
        {"current": {"time": "2026-11-11T12:45", "temperature_2m": "warm"}},
        {**CURRENT_SAMPLE, "utc_offset_seconds": "5h"},
    ):
        with pytest.raises(WeatherUnavailableError):
            parse_current(bad)


async def test_client_asks_for_the_current_block_only() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=CURRENT_SAMPLE)

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = OpenMeteoClient(http, base_url="https://example.test/v1", api_key="k1")
        now = await client.current(21.25, 77.75)

    assert now.temperature_c == 21.4
    q = seen[0].url.params
    assert seen[0].url.path == "/v1/forecast"
    assert (q["latitude"], q["longitude"]) == ("21.25", "77.75")
    assert q["current"] == ",".join(CURRENT_FIELDS) == "temperature_2m,weather_code,is_day"
    assert "daily" not in q
    assert q["apikey"] == "k1"


async def test_client_reports_current_failures() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(503, json={"error": True, "reason": "busy"})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = OpenMeteoClient(http, base_url="https://example.test/v1", api_key="")
        with pytest.raises(WeatherUnavailableError, match="503"):
            await client.current(21.25, 77.75)


async def test_client_rejects_an_answer_that_is_not_an_object() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=[1, 2])

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = OpenMeteoClient(http, base_url="https://example.test/v1", api_key="")
        with pytest.raises(WeatherUnavailableError, match="not an object"):
            await client.current(21.25, 77.75)


def test_current_cache_window_defaults_to_thirty_minutes() -> None:
    assert Settings().weather_current_cache_minutes == 30
