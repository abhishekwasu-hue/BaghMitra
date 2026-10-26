"""Daily weather pull: refresh every plot location and store new risk alerts, so alerts
exist without anyone opening the app.

Plots are grouped by weather cell, so one provider call serves every plot in a cell
(`weather_for_cell` stores the days). The configured rules are evaluated over the cell's
days and each plot in the cell gets the alerts it does not have yet; the unique key
(plot, rule, first day) keeps a repeated pull from storing an alert twice. A provider
failure for one cell is recorded in the summary and the other cells still run.

Delivery is a later step: it sends a push for every `plot_risk_alerts` row with
`notified_at IS NULL` and then stamps `notified_at`. This job leaves `notified_at` null.

Run once a day (runbook: docs/runbooks/weather-pull.md):
    python -m bagmitra_api.weather.pull_job
"""

from __future__ import annotations

import asyncio
import json
import uuid
from collections import defaultdict
from collections.abc import Sequence
from dataclasses import asdict, dataclass, field
from datetime import datetime

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.models import Plot, PlotRiskAlert
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.risk.engine import RiskRule, evaluate, load_rules
from bagmitra_api.weather.open_meteo import OpenMeteoClient, WeatherUnavailableError
from bagmitra_api.weather.service import Cell, WeatherProvider, cell_for, weather_for_cell


@dataclass(frozen=True)
class CellFailure:
    cell: Cell
    error: str


@dataclass
class PullSummary:
    cells: int = 0
    plots: int = 0
    new_alerts: int = 0
    failed_cells: int = 0
    stale_cells: int = 0
    failures: list[CellFailure] = field(default_factory=list)

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


@dataclass(frozen=True)
class _PlotRef:
    id: uuid.UUID
    owner_id: uuid.UUID


async def _located_plots(session: AsyncSession, decimals: int) -> dict[Cell, list[_PlotRef]]:
    """Plain values, not ORM rows: the per-cell commits must not expire what we iterate."""
    query = select(Plot.id, Plot.owner_id, Plot.centroid_lat, Plot.centroid_lon).where(
        Plot.deleted_at.is_(None),
        Plot.centroid_lat.is_not(None),
        Plot.centroid_lon.is_not(None),
    )
    by_cell: dict[Cell, list[_PlotRef]] = defaultdict(list)
    for plot_id, owner_id, lat, lon in (await session.execute(query)).tuples():
        if lat is not None and lon is not None:  # narrowed by the query; keeps mypy exact
            by_cell[cell_for(lat, lon, decimals)].append(_PlotRef(plot_id, owner_id))
    return dict(sorted(by_cell.items()))


async def run_daily_pull(
    session: AsyncSession,
    provider: WeatherProvider,
    settings: Settings,
    now: datetime,
    *,
    rules: Sequence[RiskRule] | None = None,
) -> PullSummary:
    """Pull each plot cell once, evaluate the rules and store alerts not stored before."""
    active = list(rules) if rules is not None else load_rules()
    by_cell = await _located_plots(session, settings.weather_cell_decimals)
    summary = PullSummary(cells=len(by_cell), plots=sum(len(p) for p in by_cell.values()))
    for cell, plots in by_cell.items():
        try:
            days, stale = await weather_for_cell(session, provider, settings, cell, now)
        except WeatherUnavailableError as exc:
            await session.rollback()
            summary.failed_cells += 1
            summary.failures.append(CellFailure(cell, str(exc)))
            continue
        summary.stale_cells += stale
        found = evaluate(active, days)
        plot_ids = [p.id for p in plots]
        existing = set(
            (
                await session.execute(
                    select(
                        PlotRiskAlert.plot_id, PlotRiskAlert.rule_key, PlotRiskAlert.first_day
                    ).where(
                        PlotRiskAlert.plot_id.in_(plot_ids),
                        PlotRiskAlert.first_day.in_({a.first_day for a in found}),
                    )
                )
            ).tuples()
        )
        new = [
            PlotRiskAlert(
                owner_id=plot.owner_id,
                plot_id=plot.id,
                rule_key=alert.rule_key,
                first_day=alert.first_day,
                value=alert.value,
                units=alert.units,
                created_at=now,
            )
            for plot in plots
            for alert in found
            if (plot.id, alert.rule_key, alert.first_day) not in existing
        ]
        session.add_all(new)
        await session.commit()
        summary.new_alerts += len(new)
    return summary


async def main() -> int:  # pragma: no cover - thin CLI wrapper
    settings = get_settings()
    async with get_sessionmaker()() as session, httpx.AsyncClient(timeout=10) as http:
        provider = OpenMeteoClient(
            http,
            base_url=settings.weather_base_url,
            api_key=settings.weather_api_key.get_secret_value(),
        )
        summary = await run_daily_pull(session, provider, settings, utcnow())
    print(summary.to_json())
    return 1 if summary.failed_cells else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
