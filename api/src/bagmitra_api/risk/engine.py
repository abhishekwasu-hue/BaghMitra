"""Rule-based weather risk engine (M4; knowledge addendum v1.3 §3.7).

Every threshold, label and source lives in `rules.json` (or an admin copy of it), never in
code. The engine only decides whether a rule's trigger holds over daily weather; AI never
decides a trigger, and alert texts carry no chemical advice.

Rule kinds:
- `threshold`: `field op value` on at least `min_days` consecutive days. The alert names the
  first day of the first such run and the most extreme value in it. Optional `months`
  (1-12) limits the rule to part of the year, e.g. rain outside the monsoon months; a day
  in another month breaks a run.
- `degree_days`: sum over the window of max(0, min(mean, upper_c) - base_c), the average
  method with a horizontal cutoff; `units` = total / `per_unit` (e.g. insect generations).
"""

from __future__ import annotations

import json
import operator
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, fields
from datetime import date
from importlib import resources
from typing import Any

from bagmitra_api.weather.open_meteo import DailyWeather

LANGUAGES = ("en", "mr", "hi")
_OPS: dict[str, Callable[[float, float], bool]] = {
    ">=": operator.ge,
    ">": operator.gt,
    "<=": operator.le,
    "<": operator.lt,
}
_FIELDS = {f.name for f in fields(DailyWeather)} - {"day"}
# Screens an alert may link to in the app (`action` in rules.json, pushed as data).
ACTIONS = frozenset({"claim_kit"})


class RuleConfigError(ValueError):
    """A rule in the config cannot be evaluated."""


@dataclass(frozen=True)
class RiskRule:
    key: str
    kind: str
    source: str
    labels: Mapping[str, str]
    status: str = "draft"
    field: str | None = None
    op: str | None = None
    value: float | None = None
    min_days: int = 1
    base_c: float | None = None
    upper_c: float | None = None
    per_unit: float | None = None
    months: frozenset[int] | None = None
    action: str | None = None


@dataclass(frozen=True)
class RiskAlert:
    rule_key: str
    first_day: date
    value: float
    units: float | None = None


def _rule(raw: Mapping[str, Any]) -> RiskRule:
    key = str(raw.get("key", "?"))

    def need(name: str) -> Any:
        if raw.get(name) is None:
            raise RuleConfigError(f"rule {key}: '{name}' is required")
        return raw[name]

    labels = dict(need("labels"))
    if missing := [lang for lang in LANGUAGES if not labels.get(lang)]:
        raise RuleConfigError(f"rule {key}: labels missing for {missing}")
    action = raw.get("action")
    if action is not None and action not in ACTIONS:
        raise RuleConfigError(f"rule {key}: unknown action {action!r}")
    common: dict[str, Any] = {
        "key": key,
        "kind": need("kind"),
        "source": need("source"),
        "labels": labels,
        "status": raw.get("status", "draft"),
        "action": action,
    }
    if common["kind"] == "threshold":
        if need("field") not in _FIELDS:
            raise RuleConfigError(f"rule {key}: unknown field {raw['field']!r}")
        if need("op") not in _OPS:
            raise RuleConfigError(f"rule {key}: unknown op {raw['op']!r}")
        return RiskRule(
            **common,
            field=raw["field"],
            op=raw["op"],
            value=float(need("value")),
            min_days=int(raw.get("min_days") or 1),
            months=_months(key, raw.get("months")),
        )
    if common["kind"] == "degree_days":
        return RiskRule(
            **common,
            base_c=float(need("base_c")),
            upper_c=float(need("upper_c")),
            per_unit=float(need("per_unit")),
        )
    raise RuleConfigError(f"rule {key}: unknown kind {common['kind']!r}")


def _months(key: str, raw: object) -> frozenset[int] | None:
    if raw is None:
        return None
    if (
        not isinstance(raw, list)
        or not raw
        or not all(isinstance(m, int) and 1 <= m <= 12 for m in raw)
    ):
        raise RuleConfigError(f"rule {key}: 'months' must be a non-empty list of 1-12")
    return frozenset(raw)


def parse_rules(config: Mapping[str, Any]) -> list[RiskRule]:
    return [_rule(raw) for raw in config.get("rules", [])]


def load_rules() -> list[RiskRule]:
    text = resources.files("bagmitra_api.risk").joinpath("rules.json").read_text("utf-8")
    return parse_rules(json.loads(text))


def _threshold(rule: RiskRule, weather: Sequence[DailyWeather]) -> RiskAlert | None:
    if rule.field is None or rule.op is None or rule.value is None:
        raise RuleConfigError(f"rule {rule.key}: incomplete threshold")
    hit = _OPS[rule.op]
    run: list[tuple[date, float]] = []
    for day in weather:
        reading = getattr(day, rule.field)
        in_season = rule.months is None or day.day.month in rule.months
        if in_season and reading is not None and hit(reading, rule.value):
            run.append((day.day, reading))
            if len(run) >= rule.min_days:
                extreme = max if rule.op in (">=", ">") else min
                return RiskAlert(rule.key, run[0][0], extreme(v for _, v in run))
        else:
            run = []
    return None


def _degree_days(rule: RiskRule, weather: Sequence[DailyWeather]) -> RiskAlert | None:
    if rule.base_c is None or rule.upper_c is None or not rule.per_unit:
        raise RuleConfigError(f"rule {rule.key}: incomplete degree-day rule")
    total, first = 0.0, None
    for day in weather:
        if day.t_max_c is None or day.t_min_c is None:
            continue
        gained = max(0.0, min((day.t_max_c + day.t_min_c) / 2, rule.upper_c) - rule.base_c)
        if gained > 0 and first is None:
            first = day.day
        total += gained
    if first is None:
        return None
    return RiskAlert(rule.key, first, total, units=total / rule.per_unit)


def evaluate(rules: Sequence[RiskRule], weather: Sequence[DailyWeather]) -> list[RiskAlert]:
    ordered = sorted(weather, key=lambda d: d.day)
    alerts = []
    for rule in rules:
        check = _threshold if rule.kind == "threshold" else _degree_days
        if alert := check(rule, ordered):
            alerts.append(alert)
    return alerts
