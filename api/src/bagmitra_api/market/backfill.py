"""One-off backfill of past mandi prices (OPEN_QUESTIONS Q130) so the price trend chart
(`GET /v1/market/prices/history`) has history from the first day.

Source: the data.gov.in "Variety-wise Daily Market Prices" archive
(MARKET_ARCHIVE_RESOURCE_ID, same base URL and MARKET_API_KEY as the daily pull). Its market
names can differ from the current feed's ("Pune(Moshi) APMC" vs "Pune(Moshi)"), so no name is
ever mapped by guess: an archive row is stored only when its (commodity, market, variety, grade)
key already exists among the rows stored from the current feed (source `agmarknet`). A day that
already has a row for that key is never overwritten; only missing days are inserted, with source
`agmarknet` through `store_prices`, so the read paths and "Agmarknet wins over manual" hold.
Unmatched rows are counted and their top market names reported, never stored. The pull
freshness record (`market_pulls`) is not touched. Prices are never invented.

    python -m bagmitra_api.market.backfill [--days N]     # N 1..90, default 90

Prints one JSON line per commodity; exit 2 when MARKET_API_KEY is empty, 1 when a commodity
failed. Runbook: docs/runbooks/market-prices.md ("90-day backfill (Q130)").
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from collections import Counter
from dataclasses import asdict, dataclass, field
from datetime import date, datetime, timedelta
from typing import Any, Protocol

import httpx
import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.market.agmarknet import (
    REASON_BAD_RESPONSE,
    REASON_NOT_CONFIGURED,
    REASON_UNREACHABLE,
    MandiPrice,
    MarketUnavailableError,
    parse_records,
)
from bagmitra_api.market.models import MarketPrice
from bagmitra_api.market.pull_job import (
    SKIPPED_LOCKED,
    SKIPPED_NO_KEY,
    configured_commodities,
    market_http,
    pull_lock,
)
from bagmitra_api.market.service import AGMARKNET, store_prices

log = structlog.get_logger("bagmitra.market.backfill")

ARCHIVE_PAGE_LIMIT = 1000
# Bound per commodity: 100 pages of 1000 rows (a 90-day Orange query held 5629 rows, seen live).
ARCHIVE_MAX_PAGES = 100
MAX_DAYS = 90  # the trend chart goes back at most three months (Q130)
TOP_UNMATCHED = 10

Key = tuple[str, str, str, str]  # commodity, market, variety, grade ('' when blank)


class ArchiveProvider(Protocol):
    async def prices(self, *, commodity: str, since: date) -> list[MandiPrice]: ...


class ArchiveClient:
    """Reads the archive resource; same error codes as `AgmarknetClient`."""

    def __init__(
        self,
        http: httpx.AsyncClient,
        *,
        base_url: str,
        resource_id: str,
        api_key: str,
        max_pages: int = ARCHIVE_MAX_PAGES,
    ) -> None:
        self._http = http
        self._url = f"{base_url.rstrip('/')}/resource/{resource_id}"
        self._api_key = api_key
        self._max_pages = max_pages

    async def _page(self, params: dict[str, str | int]) -> dict[str, Any]:
        try:
            response = await self._http.get(self._url, params=params)
        except httpx.HTTPError as exc:
            raise MarketUnavailableError(str(exc), code=REASON_UNREACHABLE) from exc
        if response.status_code != httpx.codes.OK:
            raise MarketUnavailableError(f"HTTP {response.status_code}")
        try:
            payload = response.json()
        except ValueError as exc:
            raise MarketUnavailableError("not JSON", code=REASON_BAD_RESPONSE) from exc
        if not isinstance(payload, dict):
            raise MarketUnavailableError("not a JSON object", code=REASON_BAD_RESPONSE)
        return payload

    async def prices(self, *, commodity: str, since: date) -> list[MandiPrice]:
        """Every archive row of the commodity from `since` on, newest first."""
        if not self._api_key:
            raise MarketUnavailableError(SKIPPED_NO_KEY, code=REASON_NOT_CONFIGURED)
        params: dict[str, str | int] = {
            "api-key": self._api_key,
            "format": "json",
            "limit": ARCHIVE_PAGE_LIMIT,
            "filters[Commodity]": commodity,
            "sort[Arrival_Date]": "desc",
            "range[Arrival_Date][gte]": since.strftime("%d/%m/%Y"),
        }
        prices: list[MandiPrice] = []
        seen = 0
        for page in range(self._max_pages):
            payload = await self._page({**params, "offset": page * ARCHIVE_PAGE_LIMIT})
            parsed, count = parse_archive(payload)
            # Filters match as free text: keep only the exact commodity (as the daily pull).
            prices.extend(p for p in parsed if p.commodity.casefold() == commodity.casefold())
            seen += count
            total = payload.get("total")
            if count < ARCHIVE_PAGE_LIMIT or (isinstance(total, int) and seen >= total):
                break
        return prices


def parse_archive(payload: dict[str, Any]) -> tuple[list[MandiPrice], int]:
    """(usable rows, number of records on the page). The archive prints Title_Case fields
    (Arrival_Date, Modal_Price, ...); the daily feed's parser reads the same names in lower
    case, so the keys are lowered and that parser reused."""
    records = payload.get("records")
    if not isinstance(records, list) or not all(isinstance(r, dict) for r in records):
        raise MarketUnavailableError(
            f"no records in response: {payload.get('message')}", code=REASON_BAD_RESPONSE
        )
    lowered = [{str(k).lower(): v for k, v in r.items()} for r in records]
    try:
        return parse_records({"records": lowered}), len(records)
    except ValueError as exc:  # e.g. a date that is not DD/MM/YYYY
        raise MarketUnavailableError(str(exc), code=REASON_BAD_RESPONSE) from exc


def archive_client(http: httpx.AsyncClient, settings: Settings) -> ArchiveClient:
    return ArchiveClient(
        http,
        base_url=settings.market_api_base_url,
        resource_id=settings.market_archive_resource_id,
        api_key=settings.market_api_key.get_secret_value(),
    )


@dataclass
class BackfillOutcome:
    commodity: str
    read: int = 0
    stored: int = 0
    skipped_existing: int = 0
    unmatched: int = 0
    top_unmatched_markets: list[tuple[str, int]] = field(default_factory=list)
    error: str | None = None


@dataclass
class BackfillSummary:
    commodities: list[BackfillOutcome] = field(default_factory=list)
    skipped_reason: str | None = None

    @property
    def failed(self) -> int:
        return sum(o.error is not None for o in self.commodities)

    def to_json(self) -> str:
        return json.dumps({**asdict(self), "failed": self.failed}, ensure_ascii=False)


def _key(p: MandiPrice | MarketPrice) -> Key:
    return (p.commodity, p.market, p.variety or "", p.grade or "")


async def _backfill_one(
    session: AsyncSession, archive: ArchiveProvider, commodity: str, since: date, now: datetime
) -> BackfillOutcome:
    outcome = BackfillOutcome(commodity)
    try:
        prices = await archive.prices(commodity=commodity, since=since)
    except MarketUnavailableError as exc:
        log.warning("market_backfill_failed", commodity=commodity, code=exc.code, detail=str(exc))
        outcome.error = exc.code
        return outcome
    current = (
        await session.scalars(
            select(MarketPrice).where(
                MarketPrice.commodity == commodity, MarketPrice.source == AGMARKNET
            )
        )
    ).all()
    known = {_key(r) for r in current}
    have = {(r.day, _key(r)) for r in current}
    unmatched: Counter[str] = Counter()
    new: list[MandiPrice] = []
    for p in prices:
        if p.day < since:
            continue  # outside the window
        outcome.read += 1
        if _key(p) not in known:
            unmatched[p.market] += 1
        elif (p.day, _key(p)) in have:
            outcome.skipped_existing += 1
        else:
            have.add((p.day, _key(p)))
            new.append(p)
    await store_prices(session, new, source=AGMARKNET, now=now)
    outcome.stored = len(new)
    outcome.unmatched = sum(unmatched.values())
    outcome.top_unmatched_markets = unmatched.most_common(TOP_UNMATCHED)
    return outcome


async def run_backfill(
    session: AsyncSession,
    archive: ArchiveProvider,
    settings: Settings,
    now: datetime,
    days: int = MAX_DAYS,
) -> BackfillSummary:
    """Backfill the last `days` days (today included) of every configured commodity."""
    if not 1 <= days <= MAX_DAYS:
        raise ValueError(f"days must be in 1..{MAX_DAYS}")
    summary = BackfillSummary()
    if not settings.market_api_key.get_secret_value():
        summary.skipped_reason = SKIPPED_NO_KEY
        return summary
    # The same window as the history read path: day > today - days.
    since = now.date() - timedelta(days=days - 1)
    for commodity in configured_commodities(settings):
        summary.commodities.append(await _backfill_one(session, archive, commodity, since, now))
    return summary


def _days(value: str) -> int:
    try:
        days = int(value)
    except ValueError:
        days = 0
    if not 1 <= days <= MAX_DAYS:
        raise argparse.ArgumentTypeError(f"--days must be a whole number in 1..{MAX_DAYS}")
    return days


async def main(argv: list[str] | None = None, settings: Settings | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m bagmitra_api.market.backfill")
    parser.add_argument("--days", type=_days, default=MAX_DAYS, help="1..90 (default 90)")
    args = parser.parse_args(argv)
    settings = settings or get_settings()
    if not settings.market_api_key.get_secret_value():
        print(json.dumps({"error": SKIPPED_NO_KEY}), file=sys.stderr)
        return 2
    return await _run(settings, args.days)  # pragma: no cover - needs the database


async def _run(settings: Settings, days: int) -> int:  # pragma: no cover - thin CLI wrapper
    maker = get_sessionmaker()
    engine = maker.kw["bind"]
    # Held like the scheduled pull, so the two never write the same rows at once.
    async with pull_lock(engine) as held, maker() as session, market_http(settings) as http:
        if not held:
            summary = BackfillSummary(skipped_reason=SKIPPED_LOCKED)
        else:
            summary = await run_backfill(
                session, archive_client(http, settings), settings, utcnow(), days
            )
    await engine.dispose()
    if summary.skipped_reason:
        print(json.dumps({"skipped_reason": summary.skipped_reason}))
    for outcome in summary.commodities:
        print(json.dumps(asdict(outcome), ensure_ascii=False))
    return 1 if summary.failed or summary.skipped_reason else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
