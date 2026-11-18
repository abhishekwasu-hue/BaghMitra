"""Read-only diagnostic: which commodity names the Agmarknet daily feed carries, and whether
each configured name (`MARKET_COMMODITIES`) is one of them.

Names are matched exactly by the pull, so a misspelt name only yields no rows. This lists every
commodity name in the current daily feed (data.gov.in resource `MARKET_RESOURCE_ID`, no
commodity filter, at most `--max-pages` pages of 500 rows; India-wide unless `--state` is
given) with its row count, then each configured crop and name with its rows. The daily feed
holds only the latest reported days, so a crop out of season can be missing although its name
is right: a configured name with no row in the feed is looked up once in the 90-day archive
(`MARKET_ARCHIVE_RESOURCE_ID`, one page) before it is called "not found".

Writes nothing (no table, no lock, no file). Exit 2 without MARKET_API_KEY, 1 when the feed
could not be read.

    python -m bagmitra_api.market.list_commodities [--state Maharashtra] [--max-pages 60]
"""

from __future__ import annotations

import argparse
import asyncio
from collections import Counter
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Any

import httpx

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.market.agmarknet import PAGE_LIMIT, REASON_BAD_RESPONSE, MarketUnavailableError
from bagmitra_api.market.pull_job import market_http

DEFAULT_MAX_PAGES = 60
ARCHIVE_DAYS = 90


@dataclass
class FeedNames:
    counts: Counter[str] = field(default_factory=Counter)
    pages: int = 0
    # The feed had more rows than --max-pages pages: a rare name may be missing from `counts`.
    truncated: bool = False


async def _get(http: httpx.AsyncClient, url: str, params: dict[str, str | int]) -> dict[str, Any]:
    try:
        response = await http.get(url, params=params)
    except httpx.HTTPError as exc:
        raise MarketUnavailableError(str(exc)) from exc
    if response.status_code != httpx.codes.OK:
        raise MarketUnavailableError(f"HTTP {response.status_code}")
    try:
        payload = response.json()
    except ValueError as exc:
        raise MarketUnavailableError("not JSON", code=REASON_BAD_RESPONSE) from exc
    if not isinstance(payload, dict) or not isinstance(payload.get("records"), list):
        raise MarketUnavailableError("no records in response", code=REASON_BAD_RESPONSE)
    return payload


def _url(settings: Settings, resource_id: str) -> str:
    return f"{settings.market_api_base_url.rstrip('/')}/resource/{resource_id}"


async def feed_names(
    http: httpx.AsyncClient, settings: Settings, *, state: str | None, max_pages: int
) -> FeedNames:
    """Every commodity name in the daily feed with its number of rows."""
    params: dict[str, str | int] = {
        "api-key": settings.market_api_key.get_secret_value(),
        "format": "json",
        "limit": PAGE_LIMIT,
    }
    if state:
        params["filters[state]"] = state
    out = FeedNames()
    url = _url(settings, settings.market_resource_id)
    for page in range(max_pages):
        records = (await _get(http, url, {**params, "offset": page * PAGE_LIMIT}))["records"]
        out.pages += 1
        for r in records:
            if isinstance(r, dict) and (name := str(r.get("commodity") or "").strip()):
                out.counts[name] += 1
        if len(records) < PAGE_LIMIT:
            return out
    out.truncated = True
    return out


async def archive_rows(http: httpx.AsyncClient, settings: Settings, name: str, since: date) -> int:
    """Rows of exactly `name` on the archive's first page since `since` (0 = not seen)."""
    payload = await _get(
        http,
        _url(settings, settings.market_archive_resource_id),
        {
            "api-key": settings.market_api_key.get_secret_value(),
            "format": "json",
            "limit": 100,
            "filters[Commodity]": name,
            "range[Arrival_Date][gte]": since.strftime("%d/%m/%Y"),
        },
    )
    # Filters match as free text: count only the exact name (as the pull keeps).
    return sum(
        1
        for r in payload["records"]
        if isinstance(r, dict)
        and str(r.get("Commodity") or r.get("commodity") or "").strip().casefold()
        == name.strip().casefold()
    )


def feed_rows(names: FeedNames, name: str) -> int:
    key = name.strip().casefold()
    return sum(n for c, n in names.counts.items() if c.casefold() == key)


async def report(
    http: httpx.AsyncClient,
    settings: Settings,
    *,
    state: str | None,
    max_pages: int,
    today: date,
) -> list[str]:
    names = await feed_names(http, settings, state=state, max_pages=max_pages)
    where = state or "India"
    lines = [
        f"Daily feed ({where}): {sum(names.counts.values())} rows, {len(names.counts)} "
        f"commodity names, {names.pages} page(s)"
        + (
            " - more rows than --max-pages read; raise it to see every name"
            if names.truncated
            else ""
        ),
    ]
    lines += [
        f"{n:6d}  {c}" for c, n in sorted(names.counts.items(), key=lambda x: x[0].casefold())
    ]
    lines += ["", "Configured names (MARKET_COMMODITIES):"]
    since = today - timedelta(days=ARCHIVE_DAYS)
    for crop, configured in sorted(settings.market_commodities.items()):
        for name in configured:
            rows = feed_rows(names, name)
            if rows:
                lines.append(f"  {crop:14s} {name!r}: {rows} rows in the daily feed")
                continue
            try:
                archived = await archive_rows(http, settings, name, since)
            except MarketUnavailableError as exc:
                lines.append(f"  {crop:14s} {name!r}: not in the daily feed; archive: {exc}")
                continue
            lines.append(
                f"  {crop:14s} {name!r}: not in the daily feed; "
                + (
                    f"in the {ARCHIVE_DAYS}-day archive ({archived} rows on the first page)"
                    if archived
                    else f"NOT FOUND in the {ARCHIVE_DAYS}-day archive either"
                )
            )
    return lines


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0] if __doc__ else None)
    p.add_argument("--state", default=None, help="only this state (as Agmarknet prints it)")
    p.add_argument("--max-pages", type=int, default=DEFAULT_MAX_PAGES)
    return p.parse_args(argv)


async def main(argv: list[str] | None = None) -> int:  # pragma: no cover - thin CLI wrapper
    args = parse_args(argv)
    settings = get_settings()
    if not settings.market_api_key.get_secret_value():
        print("no API key configured (MARKET_API_KEY)")
        return 2
    async with market_http(settings) as http:
        try:
            lines = await report(
                http, settings, state=args.state, max_pages=args.max_pages, today=date.today()
            )
        except MarketUnavailableError as exc:
            print(f"daily feed not readable: {exc.code}: {exc}")
            return 1
    print("\n".join(lines))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main()))
