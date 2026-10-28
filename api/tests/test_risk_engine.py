from __future__ import annotations

from datetime import date, timedelta

import pytest

from bagmitra_api.risk.engine import (
    RiskRule,
    RuleConfigError,
    evaluate,
    load_rules,
    parse_rules,
)
from bagmitra_api.weather.open_meteo import DailyWeather

START = date(2026, 3, 10)


def days(*temps: tuple[float, float], rain: float = 0.0) -> list[DailyWeather]:
    return [
        DailyWeather(START + timedelta(days=i), tmax, tmin, rain, None, None)
        for i, (tmax, tmin) in enumerate(temps)
    ]


def rule(**overrides: object) -> RiskRule:
    base: dict[str, object] = {
        "key": "hot",
        "kind": "threshold",
        "field": "t_max_c",
        "op": ">=",
        "value": 35,
        "min_days": 2,
        "source": "test",
        "labels": {"en": "Hot", "mr": "उष्ण", "hi": "गर्म"},
    }
    return parse_rules({"rules": [base | overrides]})[0]


def test_threshold_needs_consecutive_days_and_reports_the_first() -> None:
    weather = days((36, 20), (34, 20), (35, 21), (37, 22), (30, 18))
    [alert] = evaluate([rule()], weather)
    assert (alert.rule_key, alert.first_day, alert.value) == ("hot", START + timedelta(2), 37)
    assert evaluate([rule(min_days=3)], weather) == []


def test_threshold_skips_missing_values_and_supports_other_ops() -> None:
    weather = [DailyWeather(START, None, 10, 0.0, None, None)]
    assert evaluate([rule(min_days=1)], weather) == []
    cold = rule(key="cold", field="t_min_c", op="<=", value=10, min_days=1)
    [alert] = evaluate([cold], weather)
    assert (alert.first_day, alert.value) == (START, 10)


def test_degree_days_average_method_with_horizontal_cutoff() -> None:
    # Hand-computed: mean 25 -> 13.89; mean 40 capped at 32 -> 20.89; mean 10 -> 0.
    dd = rule(
        key="psylla",
        kind="degree_days",
        base_c=11.11,
        upper_c=32,
        per_unit=30,
        field=None,
        op=None,
        value=None,
        min_days=None,
    )
    weather = days((30, 20), (45, 35), (12, 8))
    [alert] = evaluate([dd], weather)
    assert alert.value == pytest.approx(13.89 + 20.89)
    assert alert.units == pytest.approx((13.89 + 20.89) / 30)
    assert evaluate([dd], days((12, 8))) == []


def test_bad_config_is_rejected_with_the_rule_key() -> None:
    with pytest.raises(RuleConfigError, match="hot"):
        rule(op="~")
    with pytest.raises(RuleConfigError, match="hot"):
        rule(field="sunshine")
    with pytest.raises(RuleConfigError, match="hot"):
        rule(labels={"en": "only english"})
    with pytest.raises(RuleConfigError, match="hot"):
        rule(kind="magic")


def test_shipped_rules_are_sourced_draft_and_free_of_chemical_advice() -> None:
    rules = load_rules()
    assert {r.key for r in rules} >= {"heat_fruit_drop", "psylla_degree_days"}
    for r in rules:
        assert r.source
        assert r.status == "draft"
        for text in r.labels.values():
            assert "spray" not in text.lower()
            assert "फवार" not in text
            assert "छिड़क" not in text


def test_missing_required_values_and_missing_temperatures() -> None:
    with pytest.raises(RuleConfigError, match="'value' is required"):
        rule(value=None)
    dd = rule(kind="degree_days", base_c=10, upper_c=30, per_unit=10)
    weather = [*days((30, 20)), DailyWeather(START + timedelta(1), None, 20, 0.0, None, None)]
    [alert] = evaluate([dd], weather)
    assert (alert.first_day, alert.value) == (START, 15)


def test_months_limit_a_threshold_to_part_of_the_year() -> None:
    wet = rule(key="wet", field="precip_mm", op=">=", value=10, min_days=1, months=[3])
    march = [DailyWeather(START, 30, 20, 25.0, None, None)]
    july = [DailyWeather(date(2026, 7, 10), 30, 20, 25.0, None, None)]
    [alert] = evaluate([wet], march)
    assert (alert.first_day, alert.value) == (START, 25.0)
    assert evaluate([wet], july) == []
    with pytest.raises(RuleConfigError, match="wet"):
        rule(key="wet", months=[13])
    with pytest.raises(RuleConfigError, match="wet"):
        rule(key="wet", months=[])


def test_action_links_an_alert_to_a_screen() -> None:
    assert rule(action="claim_kit").action == "claim_kit"
    assert rule().action is None
    with pytest.raises(RuleConfigError, match="hot"):
        rule(action="buy_now")


def test_weather_code_thresholds_catch_thunderstorms() -> None:
    storm = rule(key="storm", field="weather_code", op=">=", value=95, min_days=1)
    calm = DailyWeather(START, 30, 20, 0.0, None, None, weather_code=3)
    thunder = DailyWeather(START + timedelta(1), 30, 20, 8.0, None, None, weather_code=96)
    [alert] = evaluate([storm], [calm, thunder])
    assert (alert.first_day, alert.value) == (START + timedelta(1), 96)
    assert evaluate([storm], [calm]) == []


def test_shipped_storm_rules_point_to_the_claim_kit() -> None:
    by_key = {r.key: r for r in load_rules()}
    storm_keys = {"hail_thunderstorm", "high_wind_gust", "heavy_rain", "unseasonal_rain"}
    assert storm_keys <= set(by_key)
    for key in storm_keys:
        assert by_key[key].action == "claim_kit"
        assert by_key[key].kind == "threshold"
    assert by_key["heat_fruit_drop"].action is None

    def day(on: date, **kw: float) -> DailyWeather:
        values: dict[str, float | None] = {"precip_mm": 0.0, "wind_gust_kmh": 10.0}
        values.update(kw)
        return DailyWeather(
            on,
            30,
            20,
            values["precip_mm"],
            None,
            values["wind_gust_kmh"],
            weather_code=values.get("weather_code"),
        )

    rules = list(by_key.values())

    def fired(*weather: DailyWeather) -> set[str]:
        return {a.rule_key for a in evaluate(rules, list(weather))} & storm_keys

    assert fired(day(START)) == set()
    assert fired(day(START, weather_code=95)) == {"hail_thunderstorm"}
    assert fired(day(START, wind_gust_kmh=70)) == {"high_wind_gust"}
    # Monsoon rain is expected: only a very wet day alerts in July.
    assert fired(day(date(2026, 7, 10), precip_mm=30)) == set()
    assert fired(day(date(2026, 7, 10), precip_mm=80)) == {"heavy_rain"}
    # Out of season (March), a smaller fall already alerts.
    assert fired(day(START, precip_mm=30)) == {"unseasonal_rain"}
