"""The change checks of the update pushes (owner 2026-11-12, Q147), as pure functions so the
thresholds can be tested with fixtures. The job (`push/updates.py`) loads the data and sends.

Market: one mandi series (market, commodity, variety, grade) changed when its modal price on
the latest published day moved by at least PUSH_MARKET_MIN_PCT per cent OR PUSH_MARKET_MIN_RS
rupees per quintal against the previous published day of that series (days without a price
are skipped, never filled in), and the latest day is at most PUSH_MARKET_MAX_AGE_DAYS old.

Weather: for today and the next days (PUSH_WEATHER_DAYS in all), against the forecast the
check saw on its previous run for that day ("the previous forecast"; the day before when no
earlier forecast was seen, "the last 24 h"):
- rain_prob: chance of rain now at least PUSH_WEATHER_RAIN_PROB_HIGH (60 %) when it was at most
  PUSH_WEATHER_RAIN_PROB_LOW (30 %);
- rain_mm: expected rain of at least PUSH_WEATHER_RAIN_MM (10 mm) when it was less;
- wind: a gust of at least PUSH_WEATHER_GUST_KMH (40 km/h) when it was less;
and day on day (the day against the day before it in the same forecast):
- temp_up / temp_down: the maximum temperature changes by PUSH_WEATHER_TEMP_JUMP_C (5 °C) or more;
- heat: the maximum reaches PUSH_WEATHER_HEAT_C (35 °C) after a day below it (left out when a
  temp_up of the same day already says it);
- cold: the minimum falls to PUSH_WEATHER_COLD_C (4 °C) or less after a day above it.
No duplicate of the risk-rule pushes (push/deliver.py): a change is left out when the plot has
a risk alert of an overlapping rule (OVERLAP) for that day or the day before / after, or one
stored in the last 24 h (that push already told the grower)."""

from __future__ import annotations

from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta

from bagmitra_api.core.settings import Settings

# --- market ---------------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class SeriesKey:
    market: str
    commodity: str
    variety: str
    grade: str


@dataclass(frozen=True, slots=True)
class MarketRules:
    min_pct: float = 5.0
    min_rs: int = 300
    max_age_days: int = 3

    @classmethod
    def of(cls, settings: Settings) -> MarketRules:
        return cls(
            settings.push_market_min_pct,
            settings.push_market_min_rs,
            settings.push_market_max_age_days,
        )


@dataclass(frozen=True, slots=True)
class PriceChange:
    key: SeriesKey
    day: date
    price: int
    previous_day: date
    previous: int

    @property
    def delta(self) -> int:
        return self.price - self.previous

    @property
    def pct(self) -> float:
        return self.delta * 100 / self.previous

    @property
    def subject(self) -> str:
        k = self.key
        return f"{k.market}|{k.commodity}|{k.variety}|{k.grade}|{self.day.isoformat()}"[:300]


def price_change(
    key: SeriesKey, days: Mapping[date, int], today: date, rules: MarketRules
) -> PriceChange | None:
    """The change of one series between its two latest published days, or None."""
    published = sorted((d, p) for d, p in days.items() if p > 0)
    if len(published) < 2:
        return None
    (previous_day, previous), (day, price) = published[-2], published[-1]
    if day < today - timedelta(days=rules.max_age_days):
        return None
    change = PriceChange(key, day, price, previous_day, previous)
    if abs(change.delta) >= rules.min_rs or abs(change.pct) >= rules.min_pct:
        return change
    return None


# --- weather --------------------------------------------------------------------------------

RAIN_RULES = ("heavy_rain", "unseasonal_rain", "hail_thunderstorm")
OVERLAP: dict[str, tuple[str, ...]] = {
    "rain_prob": RAIN_RULES,
    "rain_mm": RAIN_RULES,
    "wind": ("high_wind_gust", "hail_thunderstorm"),
    "heat": ("heat_fruit_drop",),
    "temp_up_hot": ("heat_fruit_drop",),  # a rise that ends at or above the heat value
    "cold": ("cold_wave",),
}
SIGNAL_ORDER = ("rain_prob", "rain_mm", "wind", "temp_up", "heat", "temp_down", "cold")
COVER_DAYS = 1
COVER_RECENT = timedelta(hours=24)


@dataclass(frozen=True, slots=True)
class DayValues:
    day: date
    rain_prob_pct: float | None = None
    precip_mm: float | None = None
    wind_gust_kmh: float | None = None
    t_max_c: float | None = None
    t_min_c: float | None = None


@dataclass(frozen=True, slots=True)
class WeatherRules:
    rain_prob_high: float = 60.0
    rain_prob_low: float = 30.0
    rain_mm: float = 10.0
    temp_jump_c: float = 5.0
    heat_c: float = 35.0
    cold_c: float = 4.0
    gust_kmh: float = 40.0
    days: int = 2

    @classmethod
    def of(cls, settings: Settings) -> WeatherRules:
        return cls(
            settings.push_weather_rain_prob_high,
            settings.push_weather_rain_prob_low,
            settings.push_weather_rain_mm,
            settings.push_weather_temp_jump_c,
            settings.push_weather_heat_c,
            settings.push_weather_cold_c,
            settings.push_weather_gust_kmh,
            settings.push_weather_days,
        )


@dataclass(frozen=True, slots=True)
class WeatherSignal:
    day: date
    kind: str  # one of SIGNAL_ORDER
    value: float
    before: float | None = None  # the value compared with (previous forecast / day before)

    def subject(self, plot_id: object) -> str:
        return f"{plot_id}|{self.day.isoformat()}|{self.kind}"

    def overlap_key(self, rules: WeatherRules) -> str | None:
        if self.kind == "temp_up":
            return "temp_up_hot" if self.value >= rules.heat_c else None
        return self.kind if self.kind in OVERLAP else None


def _baseline(attr: str, seen: DayValues | None, day_before: DayValues | None) -> float | None:
    for row in (seen, day_before):
        value = getattr(row, attr) if row is not None else None
        if value is not None:
            return float(value)
    return None


def _rising(  # noqa: PLR0913 - one comparison, named parts
    signals: list[WeatherSignal],
    kind: str,
    attr: str,
    now: DayValues,
    seen: DayValues | None,
    day_before: DayValues | None,
    *,
    reach: float,
    was_at_most: float | None = None,
) -> None:
    """`kind` when `attr` is now at least `reach` and was below it (or at most `was_at_most`)."""
    value = getattr(now, attr)
    before = _baseline(attr, seen, day_before)
    if value is None or before is None or value < reach:
        return
    if (before <= was_at_most) if was_at_most is not None else (before < reach):
        signals.append(WeatherSignal(now.day, kind, float(value), before))


def weather_signals(
    current: Mapping[date, DayValues],
    seen: Mapping[date, DayValues],
    today: date,
    rules: WeatherRules,
) -> list[WeatherSignal]:
    """The sudden changes of today and the next days (see the module docstring)."""
    out: list[WeatherSignal] = []
    for offset in range(rules.days):
        day = today + timedelta(days=offset)
        now = current.get(day)
        if now is None:
            continue
        before_day = current.get(day - timedelta(days=1))
        earlier = seen.get(day)
        found: list[WeatherSignal] = []
        _rising(
            found,
            "rain_prob",
            "rain_prob_pct",
            now,
            earlier,
            before_day,
            reach=rules.rain_prob_high,
            was_at_most=rules.rain_prob_low,
        )
        _rising(found, "rain_mm", "precip_mm", now, earlier, before_day, reach=rules.rain_mm)
        _rising(found, "wind", "wind_gust_kmh", now, earlier, before_day, reach=rules.gust_kmh)
        if before_day is not None and now.t_max_c is not None and before_day.t_max_c is not None:
            jump = now.t_max_c - before_day.t_max_c
            if abs(jump) >= rules.temp_jump_c:
                kind = "temp_up" if jump > 0 else "temp_down"
                found.append(WeatherSignal(day, kind, now.t_max_c, before_day.t_max_c))
            elif now.t_max_c >= rules.heat_c > before_day.t_max_c:
                found.append(WeatherSignal(day, "heat", now.t_max_c, before_day.t_max_c))
        if (
            before_day is not None
            and now.t_min_c is not None
            and before_day.t_min_c is not None
            and now.t_min_c <= rules.cold_c < before_day.t_min_c
        ):
            found.append(WeatherSignal(day, "cold", now.t_min_c, before_day.t_min_c))
        out += sorted(found, key=lambda s: SIGNAL_ORDER.index(s.kind))
    return out


@dataclass(frozen=True, slots=True)
class StoredAlert:
    rule_key: str
    first_day: date
    created_at: datetime


def covered(
    signal: WeatherSignal,
    alerts: Iterable[StoredAlert],
    now: datetime,
    rules: WeatherRules,
) -> bool:
    """True when a risk-rule push of the plot already says this (no duplicate)."""
    key = signal.overlap_key(rules)
    if key is None:
        return False
    names = OVERLAP[key]
    for alert in alerts:
        if alert.rule_key not in names:
            continue
        if abs((alert.first_day - signal.day).days) <= COVER_DAYS:
            return True
        if now - alert.created_at <= COVER_RECENT:
            return True
    return False


def new_signals(
    signals: Sequence[WeatherSignal],
    alerts: Iterable[StoredAlert],
    now: datetime,
    rules: WeatherRules,
) -> list[WeatherSignal]:
    stored = list(alerts)
    return [s for s in signals if not covered(s, stored, now, rules)]
