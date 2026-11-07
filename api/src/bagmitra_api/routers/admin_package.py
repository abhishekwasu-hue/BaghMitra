"""Season sale package admin (spec v1.5 §4E, L9a): company profile, package settings with the
switch guard, finding a grower by phone, and recording / revoking a grant. Admin web only; role
`market_link_admin`, behind the legal gate `market_link_enabled` (404 while off).

Consumption-only (research §7.1): the grower pays outside the app; the admin records it here.
Every change and grant is written to `admin_actions` (old / new, who, when)."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import date, datetime
from typing import Annotated, Literal

import httpx
from fastapi import APIRouter, Depends, Query, Request, Response
from pydantic import BaseModel, Field
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError

from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.models import MarketLot
from bagmitra_api.market_link.package import (
    GrantRequest,
    PackageError,
    apply_changes,
    company_profile,
    log_action,
    missing_for_switch,
    package_settings,
    record_grant,
    revoke_grant,
)
from bagmitra_api.market_link.package_models import (
    COMPANY_PROFILE_SUBJECT,
    CompanyProfile,
    PackageGrant,
    SeasonPackageSettings,
)
from bagmitra_api.market_link.package_notice import (
    ReceiptOut,
    ReceiptRefusedError,
    build_receipt,
    notify_grant,
)
from bagmitra_api.push.fcm import fcm_sender
from bagmitra_api.push.sender import PushSender
from bagmitra_api.routers.admin_market_link import Clock, MarketLinkAdmin
from bagmitra_api.routers.market_link import require_market_link

router = APIRouter(
    prefix="/v1/admin/market-link/package",
    tags=["admin"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
QR_TYPES = ("image/png", "image/jpeg")
QR_MAX_BYTES = 512 * 1024
Text = Annotated[str | None, Field(max_length=160)]


class PackageCompanyIn(BaseModel):
    """Every field optional; an empty string clears it. The bank account keeps its last 4
    digits only (§4E)."""

    legal_name: Text = None
    trade_name: Text = None
    address: Annotated[str | None, Field(max_length=400)] = None
    gstin: Annotated[str | None, Field(pattern=r"^([0-9A-Z]{15})?$")] = None
    pan: Annotated[str | None, Field(pattern=r"^([A-Z]{5}[0-9]{4}[A-Z])?$")] = None
    bank_account_name: Text = None
    bank_ifsc: Annotated[str | None, Field(pattern=r"^([A-Z]{4}0[A-Z0-9]{6})?$")] = None
    bank_account_last4: Annotated[str | None, Field(pattern=r"^([0-9]{4})?$")] = None
    upi_id: Annotated[str | None, Field(pattern=r"^([A-Za-z0-9._-]{2,64}@[A-Za-z]{2,32})?$")] = None
    invoice_prefix: Annotated[str | None, Field(pattern=r"^[A-Z0-9/-]{0,16}$")] = None
    # "18" or "2.5"; empty until the CA advises (stored in basis points).
    gst_rate_percent: Annotated[str | None, Field(pattern=r"^([0-9]{1,2}(\.[0-9]{1,2})?)?$")] = None


def _bp(percent: str | None) -> int | None:
    return None if not percent else round(float(percent) * 100)


def _percent(bp: int | None) -> str | None:
    return None if bp is None else f"{bp / 100:g}"


class PackageCompanyOut(PackageCompanyIn):
    merchant_qr: bool


class PackageSettingsIn(BaseModel):
    enabled: bool
    price_paise: Annotated[int | None, Field(gt=0, le=10**9)] = None
    validity_days: Annotated[int | None, Field(gt=0, le=366)] = None
    starts_at: date | None = None


class PackageSettingsOut(PackageSettingsIn):
    # Guard fields still empty: while any is listed the switch cannot turn ON.
    missing: list[str]


class PackageGrowerLot(BaseModel):
    id: uuid.UUID
    crop: str
    variety: str | None
    status: str


class PackageGrowerOut(BaseModel):
    id: uuid.UUID
    name: str | None
    phone: str | None
    village: str | None
    district: str | None
    lots: list[PackageGrowerLot]


class PackageGrowersResponse(BaseModel):
    growers: list[PackageGrowerOut]


class PackageGrantIn(BaseModel):
    grower_id: uuid.UUID
    # Null: every lot of this grower while the package runs.
    lot_id: uuid.UUID | None = None
    amount_paise: Annotated[int, Field(gt=0, le=10**9)]
    method: Literal["upi", "cash", "bank"]
    payment_ref: Annotated[str, Field(min_length=4, max_length=40)]
    paid_on: date


class PackageGrantOut(BaseModel):
    id: uuid.UUID
    grower_id: uuid.UUID
    lot_id: uuid.UUID | None
    amount_paise: int
    method: str
    payment_ref: str
    paid_on: date
    activated_at: datetime
    valid_until: datetime
    receipt_no: str
    revoked_at: datetime | None
    revoked_reason: str | None
    admin_id: uuid.UUID


class PackageGrantsResponse(BaseModel):
    grants: list[PackageGrantOut]


class PackageRevokeIn(BaseModel):
    reason: Annotated[str, Field(min_length=3, max_length=200)]


def _profile_out(row: CompanyProfile) -> PackageCompanyOut:
    fields = {f: getattr(row, f) for f in PackageCompanyIn.model_fields if f != "gst_rate_percent"}
    return PackageCompanyOut(
        **fields,
        gst_rate_percent=_percent(row.gst_rate_bp),
        merchant_qr=row.merchant_qr is not None,
    )


def _refused(exc: PackageError) -> ApiError:
    return ApiError(exc.status, exc.code, exc.message)


@router.get("/company-profile", operation_id="package_company_profile")
async def get_company_profile(_: MarketLinkAdmin, session: DbSession) -> PackageCompanyOut:
    row = await company_profile(session)
    await session.commit()
    return _profile_out(row)


@router.put("/company-profile", operation_id="package_save_company_profile")
async def save_company_profile(
    body: PackageCompanyIn, admin: MarketLinkAdmin, session: DbSession, clock: Clock
) -> PackageCompanyOut:
    """Saves the fields sent (an empty string clears one). While the switch is ON a guard
    field cannot be cleared."""
    row = await company_profile(session)
    sent = body.model_dump(exclude_unset=True)
    changes = {k: (None if v == "" else v) for k, v in sent.items()}
    if "gst_rate_percent" in changes:
        changes["gst_rate_bp"] = _bp(changes.pop("gst_rate_percent"))
    apply_changes(session, row, changes, actor_id=admin.id, now=clock())
    settings = await package_settings(session)
    if settings.enabled and (missing := missing_for_switch(row, settings)):
        await session.rollback()
        raise ApiError(409, "package_fields_missing", "missing: " + ", ".join(missing))
    await session.commit()
    return _profile_out(row)


@router.put(
    "/company-profile/merchant-qr",
    operation_id="package_upload_merchant_qr",
    responses={413: {"model": ErrorResponse}, 415: {"model": ErrorResponse}},
    openapi_extra={
        "requestBody": {
            "required": True,
            "content": {t: {"schema": {"type": "string", "format": "binary"}} for t in QR_TYPES},
        }
    },
)
async def upload_merchant_qr(
    request: Request, admin: MarketLinkAdmin, session: DbSession, clock: Clock
) -> PackageCompanyOut:
    """The bank's merchant QR image (PNG / JPEG) for the representatives' printed card."""
    kind = request.headers.get("content-type", "").split(";")[0].strip()
    if kind not in QR_TYPES:
        raise ApiError(415, "qr_not_image")
    data = await request.body()
    if not data or len(data) > QR_MAX_BYTES:
        raise ApiError(413, "qr_too_large", f"at most {QR_MAX_BYTES} bytes")
    row = await company_profile(session)
    had = row.merchant_qr is not None
    row.merchant_qr, row.merchant_qr_type = data, kind
    # The image itself is not logged, only that it changed.
    log_action(
        session,
        subject_type="company_profile",
        subject_id=COMPANY_PROFILE_SUBJECT,
        action="settings_change",
        reason_code="admin_setting",
        actor_id=admin.id,
        now=clock(),
        detail={"old": {"merchant_qr": had}, "new": {"merchant_qr": True}},
    )
    await session.commit()
    return _profile_out(row)


@router.get(
    "/company-profile/merchant-qr",
    operation_id="package_merchant_qr",
    response_class=Response,
    responses={200: {"content": {t: {} for t in QR_TYPES}}},
)
async def merchant_qr(_: MarketLinkAdmin, session: DbSession) -> Response:
    row = await company_profile(session)
    if row.merchant_qr is None:
        raise ApiError(404, "qr_not_found")
    return Response(
        row.merchant_qr,
        media_type=row.merchant_qr_type or "image/png",
        headers={"Cache-Control": "no-store"},
    )


def _settings_out(settings: SeasonPackageSettings, missing: list[str]) -> PackageSettingsOut:
    fields = {f: getattr(settings, f) for f in PackageSettingsIn.model_fields}
    return PackageSettingsOut(**fields, missing=missing)


@router.get("/settings", operation_id="package_settings")
async def get_package_settings(_: MarketLinkAdmin, session: DbSession) -> PackageSettingsOut:
    settings = await package_settings(session)
    missing = missing_for_switch(await company_profile(session), settings)
    await session.commit()
    return _settings_out(settings, missing)


@router.put("/settings", operation_id="package_save_settings")
async def save_settings(
    body: PackageSettingsIn, admin: MarketLinkAdmin, session: DbSession, clock: Clock
) -> PackageSettingsOut:
    """Switch, price, validity, start date. The switch cannot turn (or stay) ON while legal
    name, GSTIN, UPI ID or price is empty: 409 `package_fields_missing` names the fields."""
    settings = await package_settings(session)
    profile = await company_profile(session)
    apply_changes(session, settings, body.model_dump(), actor_id=admin.id, now=clock())
    missing = missing_for_switch(profile, settings)
    if settings.enabled and missing:
        await session.rollback()
        raise ApiError(409, "package_fields_missing", "missing: " + ", ".join(missing))
    await session.commit()
    return _settings_out(settings, missing)


def _phone_forms(phone: str) -> list[str]:
    digits = "".join(ch for ch in phone if ch.isdigit())[-10:]
    return [digits, f"91{digits}", f"+91{digits}"]


@router.get("/growers", operation_id="package_find_grower")
async def find_grower(
    _: MarketLinkAdmin,
    session: DbSession,
    phone: Annotated[str, Query(min_length=10, max_length=20)],
) -> PackageGrowersResponse:
    """Growers with this mobile number (10 digits, with or without +91) and their lots."""
    forms = _phone_forms(phone)
    if len(forms[0]) != 10:
        raise ApiError(422, "phone_invalid")
    farmers = list(
        await session.scalars(select(Farmer).where(or_(*(Farmer.phone == f for f in forms))))
    )
    out = []
    for f in farmers:
        lots = await session.scalars(
            select(MarketLot)
            .where(MarketLot.owner_id == f.id, MarketLot.deleted_at.is_(None))
            .order_by(MarketLot.created_at.desc())
        )
        out.append(
            PackageGrowerOut(
                id=f.id,
                name=f.display_name,
                phone=f.phone,
                village=f.village,
                district=f.district,
                lots=[PackageGrowerLot.model_validate(x, from_attributes=True) for x in lots],
            )
        )
    return PackageGrowersResponse(growers=out)


async def get_push_sender(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[PushSender | None]:
    """The FCM sender when its credentials are set (Q32); else None (no push)."""
    async with httpx.AsyncClient(timeout=settings.fcm_timeout_seconds) as http:
        yield fcm_sender(settings, http)


Sender = Annotated[PushSender | None, Depends(get_push_sender)]


@router.post("/grants", operation_id="package_record_grant", status_code=201)
async def create_grant(
    body: PackageGrantIn,
    admin: MarketLinkAdmin,
    session: DbSession,
    clock: Clock,
    sender: Sender,
) -> PackageGrantOut:
    """Records a payment received outside the app and activates the package: the lot (or
    every lot of the grower) is shown to traders until `valid_until`. 409
    `duplicate_payment_ref` for a used UTR; 409 `package_fields_missing` while legal name,
    GSTIN, UPI ID, price or validity is empty."""
    if await session.get(Farmer, body.grower_id) is None:
        raise ApiError(404, "grower_not_found")
    try:
        grant = await record_grant(
            session, GrantRequest(**body.model_dump()), admin_id=admin.id, now=clock()
        )
        await session.commit()
    except PackageError as exc:
        await session.rollback()
        raise _refused(exc) from exc
    except IntegrityError as exc:  # a second admin saved the same UTR or number just now
        await session.rollback()
        raise ApiError(409, "grant_conflict", "saved by someone else just now; try again") from exc
    out = PackageGrantOut.model_validate(grant, from_attributes=True)
    # L9b: "your sale package is active until <date>" (no amount); never blocks the save.
    await notify_grant(session, sender, grant, clock())
    return out


@router.get("/grants", operation_id="package_grants")
async def list_grants(
    _: MarketLinkAdmin, session: DbSession, grower_id: uuid.UUID | None = None
) -> PackageGrantsResponse:
    """Grants newest first (one grower's with `grower_id`)."""
    query = select(PackageGrant).order_by(PackageGrant.created_at.desc()).limit(200)
    if grower_id is not None:
        query = query.where(PackageGrant.grower_id == grower_id)
    rows = await session.scalars(query)
    return PackageGrantsResponse(
        grants=[PackageGrantOut.model_validate(g, from_attributes=True) for g in rows]
    )


@router.post("/grants/{grant_id}/revoke", operation_id="package_revoke_grant")
async def revoke(
    grant_id: uuid.UUID,
    body: PackageRevokeIn,
    admin: MarketLinkAdmin,
    session: DbSession,
    clock: Clock,
) -> PackageGrantOut:
    """Ends the grant now with a reason (logged); the lot hides from traders if no other
    grant covers it."""
    grant = await session.get(PackageGrant, grant_id)
    if grant is None:
        raise ApiError(404, "grant_not_found")
    try:
        revoke_grant(session, grant, body.reason, admin_id=admin.id, now=clock())
    except PackageError as exc:
        raise _refused(exc) from exc
    await session.commit()
    return PackageGrantOut.model_validate(grant, from_attributes=True)


@router.get("/grants/{grant_id}/receipt", operation_id="package_grant_receipt")
async def grant_receipt(grant_id: uuid.UUID, _: MarketLinkAdmin, session: DbSession) -> ReceiptOut:
    """What the receipt PDF shows (the admin web draws it): company profile, receipt number,
    grower, amount, GST line only when GSTIN and GST rate are set, payment reference and
    validity. 409 `company_profile_empty` while legal name or address is empty."""
    grant = await session.get(PackageGrant, grant_id)
    if grant is None:
        raise ApiError(404, "grant_not_found")
    try:
        return await build_receipt(session, await company_profile(session), grant)
    except ReceiptRefusedError as exc:
        raise ApiError(409, "company_profile_empty", str(exc)) from exc
