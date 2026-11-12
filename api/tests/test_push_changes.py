"""Q147 change checks with fixtures: mandi price thresholds, weather jumps, and no duplicate
of the risk-rule pushes."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.push import texts
from bagmitra_api.push.changes import (
    DayValues,
    MarketRules,
    SeriesKey,
    StoredAlert,
    WeatherRules,
    WeatherSignal,
    covered,
    new_signals,
    price_change,
    weather_signals,
)

TODAY = date(2026, 11, 12)
NOW = datetime(2026, 11, 12, 3, 0, tzinfo=UTC)
KEY = SeriesKey("Warud", "Orange", "Nagpuri", "FAQ")
RULES = MarketRules()
W = WeatherRules()


def days(*prices: tuple[int, int]) -> dict[date, int]:
    """(days ago, modal) pairs."""
    return {TODAY - timedelta(days=ago): p for ago, p in prices}


def test_defaults_come_from_settings() -> None:
    s = Settings()
    assert MarketRules.of(s) == MarketRules(5.0, 300, 3)
    assert WeatherRules.of(s) == WeatherRules(60.0, 30.0, 10.0, 5.0, 35.0, 4.0, 40.0, 2)
    assert (s.push_article_daily_max, s.push_market_daily_max, s.push_weather_daily_max) == (
        2,
        1,
        1,
    )
    changed = Settings(push_market_min_pct=8, push_weather_gust_kmh=50)
    assert MarketRules.of(changed).min_pct == 8
    assert WeatherRules.of(changed).gust_kmh == 50


@pytest.mark.parametrize(
    ("prices", "moved"),
    [
        (((1, 3200), (0, 3500)), True),  # +300 (exactly the rupee threshold) and +9 %
        (((1, 3200), (0, 3460)), True),  # +260, +8 %: the per cent threshold
        (((1, 8000), (0, 8300)), True),  # +300, +3.75 %: the rupee threshold alone
        (((1, 8000), (0, 8299)), False),  # +299, +3.7 %: neither
        (((1, 4000), (0, 3790)), True),  # -210, -5.25 %: a fall counts the same
        (((1, 4000), (0, 3810)), False),  # -190, -4.75 %
        (((0, 3500),), False),  # one day only: nothing to compare
    ],
)
def test_price_thresholds(prices: tuple[tuple[int, int], ...], moved: bool) -> None:
    assert (price_change(KEY, days(*prices), TODAY, RULES) is not None) is moved


def test_change_is_against_the_previous_published_day_not_a_filled_gap() -> None:
    change = price_change(KEY, days((9, 2000), (5, 3200), (0, 3500)), TODAY, RULES)
    assert change is not None
    assert (change.previous_day, change.previous, change.price) == (
        TODAY - timedelta(days=5),
        3200,
        3500,
    )
    assert change.delta == 300
    assert round(change.pct) == 9
    assert change.subject == "Warud|Orange|Nagpuri|FAQ|2026-11-12"


def test_old_latest_day_and_zero_prices_send_nothing() -> None:
    assert price_change(KEY, days((6, 3000), (4, 4000)), TODAY, RULES) is None  # 4 days old
    assert price_change(KEY, days((5, 3000), (3, 4000)), TODAY, RULES) is not None
    assert price_change(KEY, days((1, 0), (0, 4000)), TODAY, RULES) is None
    stricter = MarketRules(min_pct=20, min_rs=1000)
    assert price_change(KEY, days((1, 3200), (0, 3500)), TODAY, stricter) is None


def dv(day_offset: int, **values: float) -> DayValues:
    return DayValues(TODAY + timedelta(days=day_offset), **values)


def kinds(found: list[WeatherSignal]) -> list[tuple[int, str]]:
    return [((s.day - TODAY).days, s.kind) for s in found]


def test_rain_chance_jump_needs_a_low_previous_forecast() -> None:
    current = {d.day: d for d in (dv(0, rain_prob_pct=20), dv(1, rain_prob_pct=70))}
    seen_low = {TODAY + timedelta(days=1): dv(1, rain_prob_pct=30)}
    seen_mid = {TODAY + timedelta(days=1): dv(1, rain_prob_pct=31)}
    assert kinds(weather_signals(current, seen_low, TODAY, W)) == [(1, "rain_prob")]
    assert weather_signals(current, seen_mid, TODAY, W) == []
    # No earlier forecast for tomorrow: compared with today (the last 24 h).
    assert kinds(weather_signals(current, {}, TODAY, W)) == [(1, "rain_prob")]
    found = weather_signals(current, seen_low, TODAY, W)[0]
    assert (found.value, found.before) == (70, 30)


def test_rain_amount_wind_and_the_day_window() -> None:
    current = {
        d.day: d
        for d in (
            dv(-1, precip_mm=0, wind_gust_kmh=20),
            dv(0, precip_mm=12, wind_gust_kmh=45),
            dv(1, precip_mm=9.9, wind_gust_kmh=39),
            dv(2, precip_mm=30, wind_gust_kmh=70),  # outside today + tomorrow
        )
    }
    assert kinds(weather_signals(current, {}, TODAY, W)) == [(0, "rain_mm"), (0, "wind")]
    # Already expected at the previous run: not new, nothing to say.
    seen = {TODAY: dv(0, precip_mm=11, wind_gust_kmh=41)}
    assert weather_signals(current, seen, TODAY, W) == []
    wider = WeatherRules(days=3)
    assert (2, "rain_mm") in kinds(weather_signals(current, {}, TODAY, wider))


def test_temperature_jump_heat_and_cold() -> None:
    current = {
        d.day: d
        for d in (
            dv(-1, t_max_c=30, t_min_c=12),
            dv(0, t_max_c=36, t_min_c=6),  # +6 °C and above 35: only temp_up says it
            dv(1, t_max_c=30.5, t_min_c=3.5),  # -5.5 °C and a cold night
        )
    }
    assert kinds(weather_signals(current, {}, TODAY, W)) == [
        (0, "temp_up"),
        (1, "temp_down"),
        (1, "cold"),
    ]
    gentle = {d.day: d for d in (dv(-1, t_max_c=33), dv(0, t_max_c=35.5), dv(1, t_max_c=36))}
    assert kinds(weather_signals(gentle, {}, TODAY, W)) == [(0, "heat")], "crossing once"
    steady = {d.day: d for d in (dv(-1, t_max_c=31), dv(0, t_max_c=34.9), dv(1, t_max_c=30))}
    assert weather_signals(steady, {}, TODAY, W) == []


def test_missing_values_send_nothing() -> None:
    current = {d.day: d for d in (dv(0), dv(1, rain_prob_pct=90))}
    assert weather_signals(current, {}, TODAY, W) == [], "no value to compare with"


def alert(rule: str, day_offset: int, hours_ago: float = 72) -> StoredAlert:
    return StoredAlert(rule, TODAY + timedelta(days=day_offset), NOW - timedelta(hours=hours_ago))


def test_no_duplicate_with_the_risk_rule_pushes() -> None:
    rain = WeatherSignal(TODAY + timedelta(days=1), "rain_mm", 70, 0)
    assert covered(rain, [alert("heavy_rain", 1)], NOW, W)
    assert covered(rain, [alert("unseasonal_rain", 2)], NOW, W), "the day after counts"
    assert not covered(rain, [alert("unseasonal_rain", -3)], NOW, W), "an old episode"
    assert covered(rain, [alert("hail_thunderstorm", 6, hours_ago=3)], NOW, W), "just pushed"
    assert not covered(rain, [alert("heat_fruit_drop", 1)], NOW, W)
    gust = WeatherSignal(TODAY, "wind", 65, 20)
    assert covered(gust, [alert("high_wind_gust", 0)], NOW, W)
    hot = WeatherSignal(TODAY, "temp_up", 37, 31)
    mild = WeatherSignal(TODAY, "temp_up", 33, 27)
    assert covered(hot, [alert("heat_fruit_drop", 0)], NOW, W)
    assert not covered(mild, [alert("heat_fruit_drop", 0)], NOW, W), "a rise below 35 °C"
    assert not covered(WeatherSignal(TODAY, "temp_down", 25, 31), [alert("cold_wave", 0)], NOW, W)
    assert covered(WeatherSignal(TODAY, "cold", 3, 6), [alert("cold_wave", 0)], NOW, W)
    signals = [rain, gust, mild]
    assert new_signals(signals, [alert("heavy_rain", 1)], NOW, W) == [gust, mild]


def test_texts_are_calm_and_numbers_first() -> None:
    every = [
        *(t for table in texts.WEATHER_LINES.values() for t in table.values()),
        *texts.MARKET_TITLE.values(),
        *texts.WEATHER_TITLE.values(),
        *texts.ARTICLE_ONE.values(),
        *texts.ARTICLE_MANY.values(),
    ]
    for line in every:
        assert not any(w in line.casefold() for w in texts.ALARM_WORDS), line
    assert texts.indian(3500) == "3,500"
    assert texts.indian(125000) == "1,25,000"
    assert texts.indian(-300) == "-300"
    assert texts.digits(texts.indian(3500), "mr") == "३,५००"
    assert texts.signed_rs(300, "mr") == "+₹३००"
    assert texts.signed_pct(-9.4, "en") == "-9%"
    assert texts.mandi_name("APMC Nagpur", "mr") == "नागपूर"
    assert texts.mandi_name("Warud", "mr") == "वरूड"
    assert texts.mandi_name("Some Mandi", "mr") == "Some Mandi"
    assert texts.mandi_name("Warud", "en") == "Warud"
    assert texts.crop_name("santra", "mr") == "संत्रा"
    assert texts.variety_name("Other", "Orange", "mr") == ""
    assert texts.variety_name("Orange", "Orange", "mr") == ""
    assert texts.variety_name("Nagpuri", "Orange", "mr") == "नागपुरी"
    assert texts.place_key(" अमरावती ") == "amravati"
    assert texts.place_key("Amravati") == "amravati"
    assert texts.place_key(None) == ""
    assert texts.when_word(TODAY + timedelta(days=1), TODAY, "mr") == "उद्या"
    assert texts.when_word(TODAY - timedelta(days=1), TODAY, "hi") == "कल"
    assert texts.when_word(TODAY + timedelta(days=3), TODAY, "mr") == "१५/११ रोजी"
