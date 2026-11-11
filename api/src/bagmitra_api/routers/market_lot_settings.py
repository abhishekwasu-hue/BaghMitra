"""Lot form settings (owner 2026-11-11, Q138): the rate range per crop (santra, mosambi) and
basis (per quintal, per crate), and the default harvest window length. The app reads the values
in force and keeps them for offline use; the market-link admin reads and changes them (empty =
the default). Behind the legal gate `market_link_enabled` (404 while off)."""

from __future__ import annotations

from typing import Annotated, Literal, Self

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, model_validator

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.lot_rules import (
    CROPS,
    DEFAULT_RANGES,
    HARVEST_DAYS_DEFAULT,
    RANGED_BASES,
    LotRules,
    change_lot_settings,
    lot_rules,
    lot_settings_row,
    range_column,
    rules_of,
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
Crop = Literal["santra", "mosambi"]
Basis = Literal["per_quintal", "per_crate"]
Paise = Annotated[int | None, Field(gt=0, le=10**10)]


class RateRangeOut(BaseModel):
    crop: Crop
    basis: Basis
    min_paise: int
    max_paise: int


class LotSettingsOut(BaseModel):
    """What the lot and offer forms use: a crop / basis not listed (the whole orchard) has no
    range."""

    rate_ranges: list[RateRangeOut]
    harvest_window_days: int


def _in_force(rules: LotRules) -> LotSettingsOut:
    return LotSettingsOut(
        rate_ranges=[
            RateRangeOut.model_validate({"crop": c, "basis": b, "min_paise": lo, "max_paise": hi})
            for (c, b), (lo, hi) in rules.ranges.items()
        ],
        harvest_window_days=rules.harvest_window_days,
    )


@router.get("/lot-settings", operation_id="market_link_lot_settings")
async def get_lot_settings(_: CurrentUser, session: DbSession) -> LotSettingsOut:
    return _in_force(await lot_rules(session))


class AdminRangeIn(BaseModel):
    crop: Crop
    basis: Basis
    # Null = the default.
    min_paise: Paise = None
    max_paise: Paise = None


class AdminLotSettingsIn(BaseModel):
    """Every range of every crop and the harvest window length: a value, or null for the
    default. A range left out is the default too. A minimum must stay below its maximum (as
    they apply, defaults included)."""

    rate_ranges: list[AdminRangeIn] = Field(default_factory=list, max_length=8)
    harvest_window_days: Annotated[int | None, Field(ge=0, le=120)] = None

    @model_validator(mode="after")
    def _one_each_min_below_max(self) -> Self:
        seen = set()
        for r in self.rate_ranges:
            if (r.crop, r.basis) in seen:
                raise ValueError(f"{r.crop} {r.basis}: given twice")
            seen.add((r.crop, r.basis))
            lo = DEFAULT_RANGES[r.basis][0] if r.min_paise is None else r.min_paise
            hi = DEFAULT_RANGES[r.basis][1] if r.max_paise is None else r.max_paise
            if lo >= hi:
                raise ValueError(f"{r.crop} {r.basis}: the minimum must be below the maximum")
        return self

    def columns(self) -> dict[str, int | None]:
        """The settings columns, every one (left out = null = the default)."""
        out: dict[str, int | None] = {
            range_column(c, b, e): None for c in CROPS for b in RANGED_BASES for e in ("min", "max")
        }
        for r in self.rate_ranges:
            out[range_column(r.crop, r.basis, "min")] = r.min_paise
            out[range_column(r.crop, r.basis, "max")] = r.max_paise
        out["harvest_window_days"] = self.harvest_window_days
        return out


class AdminRangeOut(AdminRangeIn):
    # The default of this basis (the same for every crop).
    default_min_paise: int
    default_max_paise: int


class AdminLotSettingsOut(BaseModel):
    """The admin's stored values (null = default), with the defaults beside them."""

    rate_ranges: list[AdminRangeOut]
    harvest_window_days: int | None
    harvest_window_days_default: int
    # The values in force (the admin's, else the default), as the app gets them.
    effective: LotSettingsOut


async def _admin_out(session: DbSession) -> AdminLotSettingsOut:
    row = await lot_settings_row(session)
    return AdminLotSettingsOut(
        rate_ranges=[
            AdminRangeOut.model_validate(
                {
                    "crop": c,
                    "basis": b,
                    "min_paise": getattr(row, range_column(c, b, "min")),
                    "max_paise": getattr(row, range_column(c, b, "max")),
                    "default_min_paise": DEFAULT_RANGES[b][0],
                    "default_max_paise": DEFAULT_RANGES[b][1],
                }
            )
            for c in CROPS
            for b in RANGED_BASES
        ],
        harvest_window_days=row.harvest_window_days,
        harvest_window_days_default=HARVEST_DAYS_DEFAULT,
        effective=_in_force(rules_of(row)),
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
    """Saves every field (null or left out = the default); each change is logged with old /
    new values."""
    row = await lot_settings_row(session)
    change_lot_settings(session, row, body.columns(), actor_id=admin.id, now=clock())
    out = await _admin_out(session)
    await session.commit()
    return out
