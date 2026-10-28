from __future__ import annotations

from datetime import date
from typing import Any

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.weather.open_meteo import (
    DAILY_FIELDS,
    DailyWeather,
    OpenMeteoClient,
    WeatherUnavailableError,
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
    },
}


def test_parse_daily_maps_each_day_and_keeps_missing_values_missing() -> None:
    days = parse_daily(SAMPLE)
    assert days == [
        DailyWeather(date(2026, 3, 14), 38.4, 21.0, 0.0, 31.0, 24.1, 3.0),
        DailyWeather(date(2026, 3, 15), 40.1, 22.6, 12.5, None, 61.2, 95.0),
    ]


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
