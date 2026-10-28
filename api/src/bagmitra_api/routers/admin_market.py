"""Manual mandi price upload: the fallback when Agmarknet has no price or is down.

Rows are stored with source `manual` next to Agmarknet rows; readers show the latest price
per mandi, and on the same day the Agmarknet row wins. Only the `market_admin` role (server-
set Supabase app_metadata) may upload. Prices are entered as published by the mandi."""

from __future__ import annotations

from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Self
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, model_validator

from bagmitra_api.auth.jwt import AuthenticatedUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market.agmarknet import MandiPrice
from bagmitra_api.market.service import MANUAL, store_prices
from bagmitra_api.weather.service import get_clock

router = APIRouter(
    prefix="/v1/admin/market",
    tags=["admin"],
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
INDIA = ZoneInfo("Asia/Kolkata")
MarketAdmin = Annotated[AuthenticatedUser, Depends(require_role("market_admin"))]

Name = Annotated[str, Field(min_length=1, max_length=120)]
Rupees = Annotated[int, Field(gt=0, le=1_000_000)]


class ManualPriceIn(BaseModel):
    day: date
    market: Name
    state: Name
    district: Name
    commodity: Name
    variety: Annotated[str, Field(max_length=120)] | None = None
    grade: Annotated[str, Field(max_length=60)] | None = None
    min_rs_per_quintal: Rupees | None = None
    max_rs_per_quintal: Rupees | None = None
    modal_rs_per_quintal: Rupees

    @model_validator(mode="after")
    def _range(self) -> Self:
        low = self.min_rs_per_quintal or self.modal_rs_per_quintal
        high = self.max_rs_per_quintal or self.modal_rs_per_quintal
        if not low <= self.modal_rs_per_quintal <= high:
            raise ValueError("expected min <= modal <= max")
        return self


class ManualPricesIn(BaseModel):
    prices: list[ManualPriceIn] = Field(min_length=1, max_length=500)


class ManualPricesOut(BaseModel):
    stored: int


@router.post(
    "/prices",
    operation_id="admin_market_prices_upload",
    responses={422: {"model": ErrorResponse}},
)
async def upload_prices(
    body: ManualPricesIn,
    _admin: MarketAdmin,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
) -> ManualPricesOut:
    """Store prices typed in from a mandi's published rate list (same day and mandi replace)."""
    now = clock()
    today = now.astimezone(INDIA).date()  # mandi rate lists are dated in India time
    known = {c for commodities in settings.market_commodities.values() for c in commodities}
    for i, p in enumerate(body.prices):
        if p.commodity not in known:
            raise ApiError(422, "unknown_commodity", f"row {i}: {p.commodity} is not configured")
        if p.day > today:
            raise ApiError(422, "future_day", f"row {i}: {p.day} is after today")
    await store_prices(
        session,
        [
            MandiPrice(
                market=p.market,
                state=p.state,
                district=p.district,
                commodity=p.commodity,
                variety=p.variety,
                grade=p.grade,
                day=p.day,
                min_rs_per_quintal=p.min_rs_per_quintal,
                max_rs_per_quintal=p.max_rs_per_quintal,
                modal_rs_per_quintal=p.modal_rs_per_quintal,
            )
            for p in body.prices
        ],
        source=MANUAL,
        now=now,
    )
    return ManualPricesOut(stored=len(body.prices))
