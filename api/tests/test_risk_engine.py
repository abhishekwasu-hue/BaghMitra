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
