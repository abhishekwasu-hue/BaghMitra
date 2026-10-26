"""Agmarknet daily mandi prices through the data.gov.in API (M5: market prices).

Returns prices as published (rupees per quintal) with the state, market, variety and grade
for every mandi in India that reports the commodity (owner, 2026-10-26: all major mandis);
it holds no advice and never estimates a missing price. The resource id and crop commodity
names are settings; the API key is a secret (OPEN_QUESTIONS Q26).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime
from typing import Any

import httpx

PAGE_LIMIT = 500


class MarketUnavailableError(Exception):
    """The price source could not be reached or answered with something we cannot use."""


@dataclass(frozen=True)
class MandiPrice:
    market: str
    state: str
    district: str
    commodity: str
    variety: str | None
    grade: str | None
    day: date
    min_rs_per_quintal: int | None
    max_rs_per_quintal: int | None
    modal_rs_per_quintal: int | None


def _rupees(value: object) -> int | None:
    text = str(value or "").strip().replace(",", "")
    if not text:
        return None
    try:
        return round(float(text))
    except ValueError:
        return None  # e.g. "NR" (not reported)


def _text(value: object) -> str | None:
    text = str(value or "").strip()
    return text or None


def parse_records(payload: dict[str, Any]) -> list[MandiPrice]:
    records = payload.get("records")
    if not isinstance(records, list):
        raise MarketUnavailableError(f"no records in response: {payload.get('message')}")
    prices = []
    for r in records:
        modal = _rupees(r.get("modal_price"))
        market, day = _text(r.get("market")), _text(r.get("arrival_date"))
        if modal is None or market is None or day is None:
            continue  # a row without a modal price, market or date says nothing usable
        prices.append(
            MandiPrice(
                market=market,
                state=_text(r.get("state")) or "",
                district=_text(r.get("district")) or "",
                commodity=_text(r.get("commodity")) or "",
                variety=_text(r.get("variety")),
                grade=_text(r.get("grade")),
                day=datetime.strptime(day, "%d/%m/%Y").date(),
                min_rs_per_quintal=_rupees(r.get("min_price")),
                max_rs_per_quintal=_rupees(r.get("max_price")),
                modal_rs_per_quintal=modal,
            )
        )
    return prices


class AgmarknetClient:
    def __init__(
        self,
        http: httpx.AsyncClient,
        *,
        base_url: str,
        resource_id: str,
        api_key: str,
        max_pages: int = 20,
    ) -> None:
        self._http = http
        self._url = f"{base_url.rstrip('/')}/resource/{resource_id}"
        self._api_key = api_key
        self._max_pages = max_pages

    async def _page(self, params: dict[str, str | int]) -> dict[str, Any]:
        try:
            response = await self._http.get(self._url, params=params)
        except httpx.HTTPError as exc:
            raise MarketUnavailableError(str(exc)) from exc
        if response.status_code != httpx.codes.OK:
            raise MarketUnavailableError(f"HTTP {response.status_code}")
        payload: dict[str, Any] = response.json()
        return payload

    async def prices(
        self, *, commodity: str, state: str | None = None, market: str | None = None
    ) -> list[MandiPrice]:
        """All reported rows for the commodity, India-wide unless a state or market is given.
        Pages through the resource; stops at `max_pages` so one pull stays bounded."""
        if not self._api_key:
            raise MarketUnavailableError("no API key configured (MARKET_API_KEY)")
        params: dict[str, str | int] = {
            "api-key": self._api_key,
            "format": "json",
            "limit": PAGE_LIMIT,
            "filters[commodity]": commodity,
        }
        if state:
            params["filters[state]"] = state
        if market:
            params["filters[market]"] = market
        prices: list[MandiPrice] = []
        for page in range(self._max_pages):
            payload = await self._page({**params, "offset": page * PAGE_LIMIT})
            prices.extend(parse_records(payload))
            if len(payload["records"]) < PAGE_LIMIT:
                break
        return prices
