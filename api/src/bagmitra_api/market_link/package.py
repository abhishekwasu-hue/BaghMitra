"""Season sale package rules (spec v1.5 §4D, §4E): the switch guard, the one visibility rule
`lot_visible_to_traders`, recording and revoking a grant, and the admin_actions log.

Consumption-only (research §7.1): the grower pays outside the app; nothing here is reachable
from a grower or trader endpoint except the visibility rule and the grower's own status.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import ColumnElement, and_, exists, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.market_link.models import ORCHARD_OK, AdminAction, MarketLot
from bagmitra_api.market_link.package_models import (
    COMPANY_PROFILE_SUBJECT,
    PACKAGE_SETTINGS_SUBJECT,
    CompanyProfile,
    PackageGrant,
    SeasonPackageSettings,
)

INDIA = ZoneInfo("Asia/Kolkata")
# The switch cannot turn ON while one of these is empty (§4E guard); a grant also needs the
# validity days to set its end.
SWITCH_FIELDS = ("legal_name", "gstin", "upi_id", "price_paise")
RECEIPT_DIGITS = 5


class PackageError(Exception):
    """A refused package change: an API error code and the message the admin page shows."""

    def __init__(self, status: int, code: str, message: str) -> None:
        super().__init__(message)
        self.status, self.code, self.message = status, code, message


async def company_profile(session: AsyncSession) -> CompanyProfile:
    """The single company row; created empty on first use."""
    row = await session.get(CompanyProfile, 1)
    if row is None:
        row = CompanyProfile(id=1)
        session.add(row)
        await session.flush()
    return row


async def package_settings(session: AsyncSession) -> SeasonPackageSettings:
    """The single settings row; created with the switch OFF on first use."""
    row = await session.get(SeasonPackageSettings, 1)
    if row is None:
        row = SeasonPackageSettings(id=1, enabled=False)
        session.add(row)
        await session.flush()
    return row


def missing_for_switch(profile: CompanyProfile, settings: SeasonPackageSettings) -> list[str]:
    """The guard fields still empty, in the order the admin page names them."""
    values: dict[str, Any] = {
        "legal_name": profile.legal_name,
        "gstin": profile.gstin,
        "upi_id": profile.upi_id,
        "price_paise": settings.price_paise,
    }
    return [f for f in SWITCH_FIELDS if values[f] in (None, "")]


async def package_on(session: AsyncSession) -> bool:
    enabled = await session.scalar(
        select(SeasonPackageSettings.enabled).where(SeasonPackageSettings.id == 1)
    )
    return bool(enabled)


def grant_active(now: datetime) -> ColumnElement[bool]:
    """A grant that counts now: started, not ended, not revoked."""
    return and_(
        PackageGrant.revoked_at.is_(None),
        PackageGrant.activated_at <= now,
        PackageGrant.valid_until > now,
    )


def lot_visible_to_traders(
    lot: type[MarketLot], now: datetime, switch_on: bool
) -> ColumnElement[bool]:
    """THE rule for traders, exporters and brokers (§4E), as a SQL condition on `lot`:
    published, not deleted, photos inside / near the orchard (§4C), and, while the package
    switch is ON, an active grant of the lot's grower covering this lot or all their lots.
    Switch OFF: every published lot, as before the package. Hiding never touches the lot,
    its photos or the interests already received."""
    base = and_(
        lot.status == "published",
        lot.deleted_at.is_(None),
        lot.orchard_check.in_(ORCHARD_OK),
    )
    if not switch_on:
        return base
    covered = exists().where(
        PackageGrant.grower_id == lot.owner_id,
        or_(PackageGrant.lot_id.is_(None), PackageGrant.lot_id == lot.id),
        grant_active(now),
    )
    return and_(base, covered)


async def lot_shown(session: AsyncSession, lot_id: uuid.UUID, now: datetime) -> bool:
    """`lot_visible_to_traders` for one lot."""
    rule = lot_visible_to_traders(MarketLot, now, await package_on(session))
    found = await session.scalar(select(MarketLot.id).where(MarketLot.id == lot_id, rule))
    return found is not None


def log_action(  # noqa: PLR0913 - one admin_actions row, every column named
    session: AsyncSession,
    *,
    subject_type: str,
    subject_id: uuid.UUID,
    action: str,
    reason_code: str,
    actor_id: uuid.UUID,
    now: datetime,
    detail: dict[str, Any],
) -> None:
    """Every package settings change, grant and revoke (§4E: old / new, who, when). No
    `user_id`: these rows are not shown to the grower (consumption-only)."""
    session.add(
        AdminAction(
            subject_type=subject_type,
            subject_id=subject_id,
            user_id=None,
            action=action,
            reason_code=reason_code,
            actor_id=actor_id,
            acted_at=now,
            detail=detail,
        )
    )


def _plain(value: Any) -> Any:
    return value.isoformat() if isinstance(value, date) else value


def apply_changes(
    session: AsyncSession,
    row: CompanyProfile | SeasonPackageSettings,
    changes: dict[str, Any],
    *,
    actor_id: uuid.UUID,
    now: datetime,
) -> list[str]:
    """Sets the changed fields and logs them (old / new); returns the changed names."""
    old = {k: _plain(getattr(row, k)) for k, v in changes.items() if getattr(row, k) != v}
    if not old:
        return []
    for key in old:
        setattr(row, key, changes[key])
    subject = (
        COMPANY_PROFILE_SUBJECT if isinstance(row, CompanyProfile) else PACKAGE_SETTINGS_SUBJECT
    )
    log_action(
        session,
        subject_type="company_profile" if isinstance(row, CompanyProfile) else "package_settings",
        subject_id=subject,
        action="settings_change",
        reason_code="admin_setting",
        actor_id=actor_id,
        now=now,
        detail={"old": old, "new": {k: _plain(changes[k]) for k in old}},
    )
    return list(old)


def normalise_ref(ref: str) -> str:
    """UTR / reference as stored: no spaces, upper case (so a retyped UTR is a duplicate)."""
    return "".join(ref.split()).upper()


@dataclass(frozen=True)
class GrantRequest:
    grower_id: uuid.UUID
    lot_id: uuid.UUID | None
    amount_paise: int
    method: str
    payment_ref: str
    paid_on: date


def _start(now: datetime, starts_at: date | None) -> datetime:
    if starts_at is None:
        return now
    return max(now, datetime.combine(starts_at, time(), INDIA).astimezone(UTC))


async def record_grant(
    session: AsyncSession, req: GrantRequest, *, admin_id: uuid.UUID, now: datetime
) -> PackageGrant:
    """Records a payment received outside the app and activates the package (§4E). Refused
    while the guard fields or the validity are empty, for a used UTR, or for a lot that is not
    the grower's. The receipt number is the next one of the profile's prefix."""
    profile, settings = await company_profile(session), await package_settings(session)
    missing = missing_for_switch(profile, settings)
    days = settings.validity_days
    if days is None:
        missing.append("validity_days")
    if missing or days is None:
        raise PackageError(409, "package_fields_missing", "missing: " + ", ".join(missing))
    ref = normalise_ref(req.payment_ref)
    if await session.scalar(select(PackageGrant.id).where(PackageGrant.payment_ref == ref)):
        raise PackageError(409, "duplicate_payment_ref", "this payment reference is recorded")
    if req.lot_id is not None:
        lot = await session.get(MarketLot, req.lot_id)
        if lot is None or lot.owner_id != req.grower_id or lot.deleted_at is not None:
            raise PackageError(404, "lot_not_found", "the lot is not this grower's")
    prefix = profile.invoice_prefix or ""
    last = await session.scalar(
        select(func.max(PackageGrant.receipt_seq)).where(PackageGrant.receipt_prefix == prefix)
    )
    seq = (last or 0) + 1
    start = _start(now, settings.starts_at)
    grant = PackageGrant(
        grower_id=req.grower_id,
        lot_id=req.lot_id,
        amount_paise=req.amount_paise,
        method=req.method,
        payment_ref=ref,
        paid_on=req.paid_on,
        activated_at=start,
        valid_until=start + timedelta(days=days),
        receipt_prefix=prefix,
        receipt_seq=seq,
        receipt_no=f"{prefix}{seq:0{RECEIPT_DIGITS}d}",
        admin_id=admin_id,
    )
    session.add(grant)
    await session.flush()
    log_action(
        session,
        subject_type="package_grant",
        subject_id=grant.id,
        action="grant",
        reason_code="payment_recorded",
        actor_id=admin_id,
        now=now,
        detail={"old": None, "new": grant_detail(grant)},
    )
    return grant


def grant_detail(grant: PackageGrant) -> dict[str, Any]:
    return {
        "grower_id": str(grant.grower_id),
        "lot_id": None if grant.lot_id is None else str(grant.lot_id),
        "amount_paise": grant.amount_paise,
        "method": grant.method,
        "payment_ref": grant.payment_ref,
        "paid_on": grant.paid_on.isoformat(),
        "receipt_no": grant.receipt_no,
        "activated_at": grant.activated_at.isoformat(),
        "valid_until": grant.valid_until.isoformat(),
        "revoked_at": None if grant.revoked_at is None else grant.revoked_at.isoformat(),
    }


def revoke_grant(
    session: AsyncSession, grant: PackageGrant, reason: str, *, admin_id: uuid.UUID, now: datetime
) -> None:
    """Ends a grant now with the admin's reason (refunds are not built, §4E); its receipt
    number stays used, so the numbering keeps no gap."""
    if grant.revoked_at is not None:
        raise PackageError(409, "grant_revoked", "the grant is already revoked")
    old = grant_detail(grant)
    grant.revoked_at, grant.revoked_reason = now, reason
    log_action(
        session,
        subject_type="package_grant",
        subject_id=grant.id,
        action="revoke",
        reason_code="grant_revoked",
        actor_id=admin_id,
        now=now,
        detail={"old": old, "new": {**grant_detail(grant), "revoked_reason": reason}},
    )
