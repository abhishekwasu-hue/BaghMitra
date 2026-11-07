"""Profile views of traders / exporters, brokers and providers (spec v1.5 §3A, §4; L2).
Built only from stored records: badges from verification records, registration fixes and
representative uploads, each with its date. The registrant's own view adds the check status,
the flags and the exact fix; nothing else ever carries coordinates, PIN or numbers."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import date
from typing import Literal

from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.market_link.guards import counts_as_verified, latest_verifications
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    PartyVerification,
    RegistrationFix,
    RepresentativeUpload,
    ServiceProvider,
)
from bagmitra_api.market_link.registration import (
    AdminFixOut,
    admin_fix,
    fix_flags,
    india_date,
    latest_fixes,
)

Subject = BuyerProfile | BrokerProfile | ServiceProvider
SubjectType = Literal["buyer", "broker", "provider"]
MODELS: dict[str, type[Subject]] = {
    "buyer": BuyerProfile,
    "broker": BrokerProfile,
    "provider": ServiceProvider,
}


class BadgeOut(BaseModel):
    """What was checked and when; the app words it "checked on <date>", never a guarantee.
    `checked`: an admin approval on record; `registered_from`: the registration GPS fix's
    place; `place_photo`: a BagMitra representative's visit photo."""

    kind: Literal["checked", "registered_from", "place_photo"]
    on: date
    place: str | None = None


class ProviderDetailsOut(BaseModel):
    cert_valid_until: date | None
    # Spec §4: the app warns when the weighbridge certificate date has passed.
    certificate_expired: bool
    vehicle_numbers: list[str]
    capacity_t: float | None
    refrigerated: bool | None
    carrier_reg_no: str | None


class ProfileBase(BaseModel):
    subject_type: str
    id: uuid.UUID
    # trader / exporter, broker, or the provider kind.
    kind: str
    name: str
    firm: str | None
    phone: str
    village: str | None
    markets: list[str]
    taluka: str | None
    district: str
    crops: list[str]
    areas: list[str]
    address: str | None
    badges: list[BadgeOut]
    provider: ProviderDetailsOut | None = None


class NumbersOut(BaseModel):
    gst_no: str | None
    apmc_licence_no: str | None
    fssai_no: str | None
    iec_no: str | None
    apeda_no: str | None


class MyProfileOut(ProfileBase):
    """The registrant's own view: status of the latest check and why the admin looks at it."""

    status: str
    reason: str | None
    flags: list[str]
    fix: AdminFixOut | None
    numbers: NumbersOut | None
    documents: int
    has_certificate_photo: bool


@dataclass(frozen=True)
class Records:
    checks: dict[uuid.UUID, PartyVerification]
    fixes: dict[uuid.UUID, RegistrationFix]
    photos: dict[uuid.UUID, RepresentativeUpload]


async def records(session: AsyncSession, kind: str, subjects: list[Subject]) -> Records:
    ids = [s.id for s in subjects]
    photos: dict[uuid.UUID, RepresentativeUpload] = {}
    if ids:
        rows = await session.scalars(
            select(RepresentativeUpload)
            .where(
                RepresentativeUpload.subject_type == kind,
                RepresentativeUpload.subject_id.in_(ids),
                RepresentativeUpload.photo_key.is_not(None),
            )
            .order_by(RepresentativeUpload.created_at)
        )
        photos = {row.subject_id: row for row in rows}
    return Records(
        checks=await latest_verifications(session, kind, ids),
        fixes=await latest_fixes(session, kind, ids),
        photos=photos,
    )


def _badges(subject: Subject, rec: Records) -> list[BadgeOut]:
    badges: list[BadgeOut] = []
    check = rec.checks.get(subject.id)
    if counts_as_verified(check) and check is not None and check.checked_at is not None:
        badges.append(BadgeOut(kind="checked", on=india_date(check.checked_at)))
    if (fix := rec.fixes.get(subject.id)) is not None:
        place = ", ".join(p for p in (fix.place, fix.district) if p) or None
        badges.append(BadgeOut(kind="registered_from", on=india_date(fix.captured_at), place=place))
    if (photo := rec.photos.get(subject.id)) is not None:
        badges.append(BadgeOut(kind="place_photo", on=india_date(photo.created_at)))
    return badges


def _provider_details(subject: Subject, today: date) -> ProviderDetailsOut | None:
    if not isinstance(subject, ServiceProvider):
        return None
    return ProviderDetailsOut(
        cert_valid_until=subject.cert_valid_until,
        certificate_expired=subject.cert_valid_until is not None
        and subject.cert_valid_until < today,
        vehicle_numbers=list(subject.vehicle_numbers),
        capacity_t=subject.capacity_t,
        refrigerated=subject.refrigerated,
        carrier_reg_no=subject.carrier_reg_no,
    )


def base_fields(kind: str, s: Subject, rec: Records, today: date) -> dict[str, object]:
    """The fields every view shows (public or own)."""
    return {
        "subject_type": kind,
        "id": s.id,
        "kind": s.kind if isinstance(s, BuyerProfile | ServiceProvider) else "broker",
        "name": s.name,
        "firm": s.firm if isinstance(s, BuyerProfile) else None,
        "phone": s.phone,
        "village": None if isinstance(s, BuyerProfile) else s.village,
        "markets": list(s.markets) if isinstance(s, BuyerProfile) else [],
        "taluka": s.taluka,
        "district": s.district,
        "crops": [] if isinstance(s, ServiceProvider) else list(s.crops),
        "areas": [] if isinstance(s, BuyerProfile) else list(s.service_areas),
        "address": s.address,
        "badges": _badges(s, rec),
        "provider": _provider_details(s, today),
    }


def _numbers(s: Subject) -> NumbersOut | None:
    if not isinstance(s, BuyerProfile):
        return None
    return NumbersOut(
        gst_no=s.gst_no,
        apmc_licence_no=s.apmc_licence_no,
        fssai_no=s.fssai_no,
        iec_no=s.iec_no,
        apeda_no=s.apeda_no,
    )


async def own_views(
    session: AsyncSession, kind: str, subjects: list[Subject], today: date
) -> list[MyProfileOut]:
    rec = await records(session, kind, subjects)
    out: list[MyProfileOut] = []
    for s in subjects:
        check, fix = rec.checks.get(s.id), rec.fixes.get(s.id)
        out.append(
            MyProfileOut.model_validate(
                {
                    **base_fields(kind, s, rec, today),
                    "status": check.status if check is not None else "pending",
                    "reason": check.reason if check is not None else None,
                    "flags": fix_flags(fix, s.district),
                    "fix": admin_fix(fix),
                    "numbers": _numbers(s),
                    "documents": len(check.document_keys) if check is not None else 0,
                    "has_certificate_photo": isinstance(s, ServiceProvider)
                    and s.cert_photo_key is not None,
                }
            )
        )
    return out
