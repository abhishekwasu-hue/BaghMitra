from __future__ import annotations

import re
from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market.service import (
    MarketContext,
    get_market_context,
    price_history,
    prices_for_commodities,
)

router = APIRouter(prefix="/v1", tags=["market"])
# Owner 2026-11-09: the trend chart goes back three months.
MAX_HISTORY_DAYS = 90


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
    are shown as published, never estimated, and come from storage only (filled by the scheduled
    pull; a request never fetches). `stale` says they are not current and `reason` says why.
    `scope` narrows the list to local or major mandis."""
    commodities = ctx.settings.market_commodities.get(crop)
    if not commodities:
        raise ApiError(404, "crop_not_priced", f"no market commodity configured for {crop}")
    view = await prices_for_commodities(session, ctx, commodities)
    local = ctx.settings.market_local_markets
    major = ctx.settings.market_major_markets
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
            is_local=market_matches(p.market, local),
            is_major=market_matches(p.market, major)
            or state_matches(p.state, ctx.settings.market_major_states),
        )
        for p in view.prices
    ]
    if scope == "local":
        rows = [r for r in rows if r.is_local]
    elif scope == "major":
        rows = [r for r in rows if r.is_major]
    rows.sort(key=lambda r: (not r.is_local, not r.is_major, r.state, r.market, r.variety or ""))
    return MarketPrices(prices=rows, stale=view.stale, reason=view.reason)


class PriceDay(BaseModel):
    day: date
    min_rs_per_quintal: int | None
    max_rs_per_quintal: int | None
    modal_rs_per_quintal: int
    source: str


class MarketPriceHistory(BaseModel):
    market: str
    variety: str | None
    grade: str | None
    days: list[PriceDay]
    stale: bool
    reason: str | None = None


@router.get(
    "/market/prices/history",
    operation_id="market_price_history_get",
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)
async def get_market_price_history(  # noqa: PLR0913 - query parameters
    _user: CurrentUser,
    session: DbSession,
    ctx: Annotated[MarketContext, Depends(get_market_context)],
    crop: Annotated[str, Query(pattern="^[a-z_]{2,32}$")],
    market: Annotated[str, Query(min_length=1, max_length=80)],
    variety: Annotated[str, Query(max_length=80)] = "",
    grade: Annotated[str, Query(max_length=40)] = "",
    days: Annotated[int, Query(ge=1, le=MAX_HISTORY_DAYS)] = MAX_HISTORY_DAYS,
) -> MarketPriceHistory:
    """Owner 2026-11-09 (price trend chart): the stored price (₹ per quintal) of one mandi for
    each day of the last `days` days (at most 90), oldest first, as published. A day without a
    published price is absent, never estimated. `variety` / `grade` are as in /market/prices
    (empty when the source left them blank); `stale` / `reason` as there."""
    commodities = ctx.settings.market_commodities.get(crop)
    if not commodities:
        raise ApiError(404, "crop_not_priced", f"no market commodity configured for {crop}")
    view = await price_history(
        session, ctx, commodities, market=market, variety=variety, grade=grade, days=days
    )
    return MarketPriceHistory(
        market=market,
        variety=variety or None,
        grade=grade or None,
        days=[
            PriceDay(
                day=p.day,
                min_rs_per_quintal=p.min_rs_per_quintal,
                max_rs_per_quintal=p.max_rs_per_quintal,
                modal_rs_per_quintal=p.modal_rs_per_quintal,
                source=p.source,
            )
            for p in view.prices
        ],
        stale=view.stale,
        reason=view.reason,
    )


def _words(text: str) -> list[str]:
    return re.findall(r"[a-z]+", text.casefold())


def market_matches(market: str, names: list[str]) -> bool:
    """True when one configured name appears as whole word(s) in the mandi name as Agmarknet
    prints it: "APMC Nagpur", "Mumbai- Fruit Market", "Pune(Moshi)" (live names, 2026-11-07)."""
    words = _words(market)
    for name in names:
        want = _words(name)
        if want and any(words[i : i + len(want)] == want for i in range(len(words))):
            return True
    return False


def state_matches(state: str, names: list[str]) -> bool:
    """True when the state Agmarknet prints is one of `names` (case and spaces ignored)."""
    return state.strip().casefold() in {n.strip().casefold() for n in names}
