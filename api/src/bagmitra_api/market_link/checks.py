"""Per-check verification records (spec v1.5 §4, L7): zero-cost checks the admin does by hand.

The admin page opens the official public page for a check (GST Search Taxpayer, DGFT View IEC
Status, FoSCoS, the APEDA exporter directory, the MSAMB market committee profile) and the admin
records what was found. Nothing is fetched, scraped or automated: these pages use captchas and
take no number in the link, so the app copies the number for the admin (Q99). Badges come only
from these records and say what was checked and when ("checked on <date>"), never a guarantee.

Verified rule (§4): a trader is verified after an admin check of at least one of GSTIN / APMC
licence / IEC, an exporter after an IEC check, a broker after the admin's phone call (phone OTP
is the sign-in itself). A check counts while it is the latest of its kind and still names the
profile's current number; a re-check that finds GST cancelled or IEC deactivated removes it."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    ServiceProvider,
    VerificationCheck,
)

Subject = BuyerProfile | BrokerProfile | ServiceProvider
# The official public page of each check (opened by the admin, never fetched by the server).
OFFICIAL_PAGES = {
    "gstin": "https://services.gst.gov.in/services/searchtp",
    "iec": "https://www.dgft.gov.in/CP/?opt=view-any-ice",
    "fssai": "https://foscos.fssai.gov.in/",
    "apeda": "https://apeda.gov.in/exporter-directory",
    "apmc": "https://www.msamb.com/ApmcDetail/Profile",
}
NUMBER_FIELDS = {
    "gstin": "gst_no",
    "apmc": "apmc_licence_no",
    "fssai": "fssai_no",
    "iec": "iec_no",
    "apeda": "apeda_no",
}
# Which checks apply to which subject (spec §4 table).
SUBJECT_CHECKS = {
    "buyer": (*NUMBER_FIELDS, "phone_call", "place_photo"),
    "broker": ("phone_call", "place_photo"),
    "provider": ("phone_call", "place_photo"),
}
# The public badge a passed check gives (spec §4 table); a phone call or a place-photo check
# gives none (the representative's place photo has its own badge).
CHECK_BADGES = {
    "gstin": "gst_checked",
    "apmc": "apmc_seen",
    "fssai": "fssai_checked",
    "iec": "iec_active",
    "apeda": "apeda_listed",
}
TRADER_RULE = frozenset({"gstin", "apmc", "iec"})


class CheckOut(BaseModel):
    id: uuid.UUID
    kind: str
    number: str | None
    result: str
    registered_year: int | None
    official_url: str | None
    checked_by: uuid.UUID
    checked_at: datetime
    # The yearly re-check job listed this pass as due (recheck_job.py).
    recheck_listed_at: datetime | None


class OfficialLinkOut(BaseModel):
    """A button on the admin page: the page to open and the number to type into it."""

    kind: str
    number: str | None
    url: str | None


def number_for(subject: Subject, kind: str) -> str | None:
    """The number a check is about: a registration number, or the phone for the call."""
    if kind == "phone_call":
        return subject.phone
    field = NUMBER_FIELDS.get(kind)
    if field is None or not isinstance(subject, BuyerProfile):
        return None
    value: str | None = getattr(subject, field)
    return value


def official_url(subject: Subject, kind: str) -> str | None:
    if kind == "phone_call":
        return f"tel:{subject.phone}"
    return OFFICIAL_PAGES.get(kind)


def official_links(subject_type: str, subject: Subject) -> list[OfficialLinkOut]:
    """Every check that applies and has something to check (a number on the profile)."""
    links: list[OfficialLinkOut] = []
    for kind in SUBJECT_CHECKS[subject_type]:
        number = number_for(subject, kind)
        if kind in NUMBER_FIELDS and number is None:
            continue
        links.append(OfficialLinkOut(kind=kind, number=number, url=official_url(subject, kind)))
    return links


async def latest_checks(
    session: AsyncSession, subject_type: str, ids: list[uuid.UUID]
) -> dict[uuid.UUID, dict[str, VerificationCheck]]:
    """Per subject, the latest check of each kind (the one that decides)."""
    if not ids:
        return {}
    rows = await session.scalars(
        select(VerificationCheck)
        .where(
            VerificationCheck.subject_type == subject_type, VerificationCheck.subject_id.in_(ids)
        )
        .order_by(VerificationCheck.checked_at, VerificationCheck.created_at)
    )
    out: dict[uuid.UUID, dict[str, VerificationCheck]] = {}
    for row in rows:
        out.setdefault(row.subject_id, {})[row.kind] = row
    return out


def passed_kinds(subject: Subject, latest: dict[str, VerificationCheck]) -> set[str]:
    """Kinds whose latest check passed and still names the profile's current number."""
    return {
        kind
        for kind, row in latest.items()
        if row.result == "passed"
        and (kind == "place_photo" or row.number == number_for(subject, kind))
    }


def meets_verified_rule(subject: Subject, passed: set[str]) -> bool:
    """Spec §4: trader = one of GSTIN / APMC / IEC; exporter = IEC; broker = phone call.
    A provider has no stated rule beyond the admin's approval."""
    if isinstance(subject, BuyerProfile):
        return "iec" in passed if subject.kind == "exporter" else bool(passed & TRADER_RULE)
    if isinstance(subject, BrokerProfile):
        return "phone_call" in passed
    return True


def check_badges(
    subject: Subject, latest: dict[str, VerificationCheck], on: dict[str, date]
) -> list[tuple[str, date, int | None]]:
    """(badge kind, checked-on date, GST registration year) for every passed check."""
    passed = passed_kinds(subject, latest)
    return [
        (badge, on[kind], latest[kind].registered_year if kind == "gstin" else None)
        for kind, badge in CHECK_BADGES.items()
        if kind in passed
    ]
