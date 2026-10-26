from __future__ import annotations

from datetime import date
from typing import Any

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.market.agmarknet import (
    AgmarknetClient,
    MandiPrice,
    MarketUnavailableError,
    parse_records,
)

# Shape of a data.gov.in "current daily price" response (values made up by hand).
SAMPLE: dict[str, Any] = {
    "status": "ok",
    "total": 2,
    "records": [
        {
            "state": "Maharashtra",
            "district": "Nagpur",
            "market": "Kalamna",
            "commodity": "Orange",
            "variety": "Nagpuri",
            "grade": "FAQ",
            "arrival_date": "24/10/2026",
            "min_price": "2500",
            "max_price": "4200",
            "modal_price": "3600",
        },
        {
            "state": "Maharashtra",
            "district": "Amravati",
            "market": "Warud",
            "commodity": "Orange",
            "variety": "Other",
            "grade": "",
            "arrival_date": "24/10/2026",
            "min_price": "NR",
            "max_price": "4000",
            "modal_price": "3300",
        },
    ],
}


def test_parse_records_reads_rupees_per_quintal_and_skips_unusable_rows() -> None:
    prices = parse_records(SAMPLE)
    assert prices == [
        MandiPrice(
            market="Kalamna",
            district="Nagpur",
            commodity="Orange",
            variety="Nagpuri",
            grade="FAQ",
            day=date(2026, 10, 24),
            min_rs_per_quintal=2500,
            max_rs_per_quintal=4200,
            modal_rs_per_quintal=3600,
        ),
        MandiPrice(
            market="Warud",
            district="Amravati",
            commodity="Orange",
            variety="Other",
            grade=None,
            day=date(2026, 10, 24),
            min_rs_per_quintal=None,
            max_rs_per_quintal=4000,
            modal_rs_per_quintal=3300,
        ),
    ]
    no_modal = {"records": [{**SAMPLE["records"][0], "modal_price": ""}]}
    assert parse_records(no_modal) == []
    with pytest.raises(MarketUnavailableError, match="records"):
        parse_records({"status": "error", "message": "bad key"})


async def test_client_filters_by_state_commodity_and_market_with_key() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=SAMPLE)

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = AgmarknetClient(
            http, base_url="https://example.test", resource_id="res-1", api_key="k1"
        )
        prices = await client.prices(state="Maharashtra", commodity="Orange", market="Kalamna")

    assert len(prices) == 2
    q = seen[0].url.params
    assert seen[0].url.path == "/resource/res-1"
    assert q["api-key"] == "k1"
    assert q["format"] == "json"
    assert q["filters[state]"] == "Maharashtra"
    assert q["filters[commodity]"] == "Orange"
    assert q["filters[market]"] == "Kalamna"


async def test_client_needs_a_key_and_reports_failures() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.params.get("api-key") == "down":
            raise httpx.ConnectError("down", request=request)
        return httpx.Response(403, json={"status": "error"})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        no_key = AgmarknetClient(http, base_url="https://x.test", resource_id="r", api_key="")
        with pytest.raises(MarketUnavailableError, match="API key"):
            await no_key.prices(state="Maharashtra", commodity="Orange")
        bad = AgmarknetClient(http, base_url="https://x.test", resource_id="r", api_key="k")
        with pytest.raises(MarketUnavailableError, match="403"):
            await bad.prices(state="Maharashtra", commodity="Orange")
        down = AgmarknetClient(http, base_url="https://x.test", resource_id="r", api_key="down")
        with pytest.raises(MarketUnavailableError, match="down"):
            await down.prices(state="Maharashtra", commodity="Orange")


def test_settings_name_the_markets_and_crop_commodities_as_config() -> None:
    s = Settings()
    assert s.market_api_key.get_secret_value() == ""
    assert "Kalamna" in s.market_markets
    assert s.market_commodities["santra"] == ["Orange"]
