from __future__ import annotations

from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market.service import MarketContext, get_market_context, prices_for_commodities

router = APIRouter(prefix="/v1", tags=["market"])


class MarketPriceOut(BaseModel):
    day: date
    market: str
    state: str
    district: str
    commodity: str
    variety: str | None
    grade: str | None
    min_rs_per_quintal: int | None
    max_rs_per_quintal: int | None
    modal_rs_per_quintal: int
    source: str
    is_local: bool
    is_major: bool


class MarketPrices(BaseModel):
    prices: list[MarketPriceOut]
    stale: bool
    reason: str | None = None


@router.get(
    "/market/prices",
    operation_id="market_prices_get",
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)
async def get_market_prices(
    _user: CurrentUser,
    session: DbSession,
    ctx: Annotated[MarketContext, Depends(get_market_context)],
    crop: Annotated[str, Query(pattern="^[a-z_]{2,32}$")],
    scope: Literal["all", "local", "major"] = "all",
) -> MarketPrices:
    """Latest published price (₹ per quintal) at every reporting mandi in India for the crop:
    the local APMCs first, then the major terminal markets, then all others by state. Prices
    are shown as published, never estimated; `stale` says the source could not be reached and
    `reason` says why. `scope` narrows the list to local or major mandis."""
    commodities = ctx.settings.market_commodities.get(crop)
    if not commodities:
        raise ApiError(404, "crop_not_priced", f"no market commodity configured for {crop}")
    view = await prices_for_commodities(session, ctx, commodities)
    local = set(ctx.settings.market_local_markets)
    major = set(ctx.settings.market_major_markets)
    rows = [
        MarketPriceOut(
            day=p.day,
            market=p.market,
            state=p.state,
            district=p.district,
            commodity=p.commodity,
            variety=p.variety or None,
            grade=p.grade or None,
            min_rs_per_quintal=p.min_rs_per_quintal,
            max_rs_per_quintal=p.max_rs_per_quintal,
            modal_rs_per_quintal=p.modal_rs_per_quintal,
            source=p.source,
            is_local=p.market in local,
            is_major=p.market in major,
        )
        for p in view.prices
    ]
    if scope == "local":
        rows = [r for r in rows if r.is_local]
    elif scope == "major":
        rows = [r for r in rows if r.is_major]
    rows.sort(key=lambda r: (not r.is_local, not r.is_major, r.state, r.market, r.variety or ""))
    return MarketPrices(prices=rows, stale=view.stale, reason=view.reason)
