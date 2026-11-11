"""Lot form settings (owner 2026-11-11, Q138): the asking-rate range per quintal and per crate
and the default harvest window length. The app reads the values in force and keeps them for
offline use; the market-link admin reads and changes them (empty = the default). Behind the
legal gate `market_link_enabled` (404 while off)."""

from __future__ import annotations

from typing import Annotated, Literal, Self

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, model_validator

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.lot_rules import (
    DEFAULTS,
    SETTING_FIELDS,
    change_lot_settings,
    effective,
    lot_rules,
    lot_settings_row,
)
from bagmitra_api.routers.admin_market_link import Clock, MarketLinkAdmin
from bagmitra_api.routers.market_link import require_market_link

router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)
admin_router = APIRouter(
    prefix="/v1/admin/market-link",
    tags=["admin"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
Paise = Annotated[int | None, Field(gt=0, le=10**10)]


class RateRangeOut(BaseModel):
    basis: Literal["per_quintal", "per_crate"]
    min_paise: int
    max_paise: int


class LotSettingsOut(BaseModel):
    """What the lot form uses: a basis not listed (the whole orchard) has no range."""

    rate_ranges: list[RateRangeOut]
    harvest_window_days: int


@router.get("/lot-settings", operation_id="market_link_lot_settings")
async def get_lot_settings(_: CurrentUser, session: DbSession) -> LotSettingsOut:
    rules = await lot_rules(session)
    ranges = [
        RateRangeOut(basis=b, min_paise=rules.ranges[b][0], max_paise=rules.ranges[b][1])
        for b in ("per_quintal", "per_crate")
        if b in rules.ranges
    ]
    return LotSettingsOut(rate_ranges=ranges, harvest_window_days=rules.harvest_window_days)


class AdminLotSettingsIn(BaseModel):
    """Every field: a value, or null for the default. A minimum must stay below its maximum
    (as they apply, defaults included)."""

    per_quintal_min_paise: Paise = None
    per_quintal_max_paise: Paise = None
    per_crate_min_paise: Paise = None
    per_crate_max_paise: Paise = None
    harvest_window_days: Annotated[int | None, Field(ge=0, le=120)] = None

    @model_validator(mode="after")
    def _min_below_max(self) -> Self:
        v = {f: DEFAULTS[f] if getattr(self, f) is None else getattr(self, f) for f in DEFAULTS}
        for kind in ("per_quintal", "per_crate"):
            if v[f"{kind}_min_paise"] >= v[f"{kind}_max_paise"]:
                raise ValueError(f"{kind}: the minimum must be below the maximum")
        return self


class AdminLotSettingsOut(AdminLotSettingsIn):
    # The values in force (the admin's, else the default) and the defaults themselves.
    effective: dict[str, int]
    defaults: dict[str, int]


async def _admin_out(session: DbSession) -> AdminLotSettingsOut:
    row = await lot_settings_row(session)
    return AdminLotSettingsOut(
        **{f: getattr(row, f) for f in SETTING_FIELDS},
        effective=effective(row),
        defaults=dict(DEFAULTS),
    )


@admin_router.get("/lot-settings", operation_id="admin_market_link_lot_settings")
async def admin_lot_settings(_: MarketLinkAdmin, session: DbSession) -> AdminLotSettingsOut:
    out = await _admin_out(session)
    await session.commit()
    return out


@admin_router.put("/lot-settings", operation_id="admin_market_link_save_lot_settings")
async def save_lot_settings(
    body: AdminLotSettingsIn, admin: MarketLinkAdmin, session: DbSession, clock: Clock
) -> AdminLotSettingsOut:
    """Saves every field (null = the default); each change is logged with old / new values."""
    row = await lot_settings_row(session)
    change_lot_settings(session, row, body.model_dump(), actor_id=admin.id, now=clock())
    out = await _admin_out(session)
    await session.commit()
    return out
