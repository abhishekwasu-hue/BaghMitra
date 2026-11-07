"""Trust and safety checks for the admin queue (spec v1.5 §4C, L7). Each one only flags a
profile for the admin, who decides; nothing here blocks, hides or removes anyone.

- One registration number, one profile: a GSTIN / IEC / APMC licence number already on another
  profile is a second claim (numbers are indexed, not unique, so the claim is saved, Q80).
- Suspended users returning: a profile whose name, any registration number, or registration GPS
  fix (within MARKET_LINK_RETURNING_KM) matches a suspended profile, or whose account holds one.
- No fake deals for ratings (helpers for the rating flow): accounts seen on the same phone, and
  a pair of accounts that only ever complete deals with each other (Q100)."""

from __future__ import annotations

import hashlib
import unicodedata
import uuid
from typing import cast

from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.market_link.models import (
    AdminAction,
    BrokerProfile,
    BuyerProfile,
    DealParty,
    DeviceSighting,
    MarketDeal,
    RegistrationFix,
    ServiceProvider,
)
from bagmitra_api.market_link.registration import distance_km

Subject = BuyerProfile | BrokerProfile | ServiceProvider
MODELS: dict[str, type[Subject]] = {
    "buyer": BuyerProfile,
    "broker": BrokerProfile,
    "provider": ServiceProvider,
}
FLAG_DUPLICATE = "duplicate_number"
FLAG_RETURNING = "returning_suspended"
UNIQUE_NUMBERS = ("gst_no", "iec_no", "apmc_licence_no")
ALL_NUMBERS = (*UNIQUE_NUMBERS, "fssai_no", "apeda_no")


class RelatedOut(BaseModel):
    """Another profile this one matches, and on what."""

    flag: str
    # The matching field (gst_no, iec_no, apmc_licence_no, fssai_no, apeda_no), or name, gps
    # (registration fix within MARKET_LINK_RETURNING_KM) or account (same sign-in).
    why: str
    subject_type: str
    subject_id: uuid.UUID
    name: str


def norm_number(value: str | None) -> str | None:
    if not value:
        return None
    key = "".join(ch for ch in value.upper() if ch.isalnum())
    return key or None


def norm_name(value: str) -> str:
    """Case, spaces and punctuation ignored (Devanagari vowel signs are kept)."""
    text = unicodedata.normalize("NFC", value).casefold()
    return "".join(ch for ch in text if unicodedata.category(ch)[0] not in "PZSC")


def _numbers(subject: Subject, fields: tuple[str, ...]) -> dict[str, str]:
    if not isinstance(subject, BuyerProfile):
        return {}
    return {f: n for f in fields if (n := norm_number(getattr(subject, f))) is not None}


async def duplicate_numbers(
    session: AsyncSession, subjects: list[Subject]
) -> dict[uuid.UUID, list[RelatedOut]]:
    """Per buyer profile: the OTHER buyer profiles claiming one of its GSTIN / IEC / APMC."""
    mine = {s.id: n for s in subjects if (n := _numbers(s, UNIQUE_NUMBERS))}
    if not mine:
        return {}
    others = list(await session.scalars(select(BuyerProfile).order_by(BuyerProfile.created_at)))
    out: dict[uuid.UUID, list[RelatedOut]] = {}
    for subject_id, numbers in mine.items():
        for other in others:
            if other.id == subject_id:
                continue
            theirs = _numbers(other, UNIQUE_NUMBERS)
            for field, number in numbers.items():
                if theirs.get(field) == number:
                    out.setdefault(subject_id, []).append(
                        RelatedOut(
                            flag=FLAG_DUPLICATE,
                            why=field,
                            subject_type="buyer",
                            subject_id=other.id,
                            name=other.name,
                        )
                    )
    return out


async def suspended(session: AsyncSession) -> tuple[set[tuple[str, uuid.UUID]], set[uuid.UUID]]:
    """Profiles and accounts whose latest suspend / restore action is a suspension."""
    rows = await session.scalars(
        select(AdminAction)
        .where(AdminAction.action.in_(("suspend", "restore")))
        .order_by(AdminAction.acted_at, AdminAction.created_at)
    )
    last: dict[tuple[str, uuid.UUID], str] = {}
    for row in rows:
        last[(row.subject_type, row.subject_id)] = row.action
    on = {key for key, action in last.items() if action == "suspend"}
    users = {sid for kind, sid in on if kind == "user"}
    return {key for key in on if key[0] != "user"}, users


async def _suspended_profiles(
    session: AsyncSession, profiles: set[tuple[str, uuid.UUID]], users: set[uuid.UUID]
) -> list[tuple[str, Subject]]:
    found: list[tuple[str, Subject]] = []
    for kind, model in MODELS.items():
        ids = {sid for k, sid in profiles if k == kind}
        conditions = []
        if ids:
            conditions.append(model.id.in_(ids))
        if users:
            conditions.append(model.user_id.in_(users))
        if conditions:
            rows = await session.scalars(select(model).where(or_(*conditions)))
            found.extend((kind, cast(Subject, row)) for row in rows)
    return found


async def returning_suspended(
    session: AsyncSession, subject_type: str, subjects: list[Subject], km: float
) -> dict[uuid.UUID, list[RelatedOut]]:
    """Per profile: the suspended profiles it matches by name, number, GPS fix or account."""
    on, users = await suspended(session)
    if not on and not users:
        return {}
    bad = await _suspended_profiles(session, on, users)
    bad_fixes: list[tuple[str, Subject, RegistrationFix]] = []
    for kind, row in bad:
        fixes = await session.scalars(
            select(RegistrationFix).where(
                RegistrationFix.subject_type == kind, RegistrationFix.subject_id == row.id
            )
        )
        bad_fixes.extend((kind, row, f) for f in fixes)
    own_fixes: dict[uuid.UUID, list[RegistrationFix]] = {}
    if subjects:
        for f in await session.scalars(
            select(RegistrationFix).where(
                RegistrationFix.subject_type == subject_type,
                RegistrationFix.subject_id.in_([s.id for s in subjects]),
            )
        ):
            own_fixes.setdefault(f.subject_id, []).append(f)
    out: dict[uuid.UUID, list[RelatedOut]] = {}
    for s in subjects:
        if (subject_type, s.id) in on:
            continue  # the suspended profile itself is not "returning"
        seen: set[tuple[str, uuid.UUID]] = set()
        for why, kind, b in _matches(s, bad, bad_fixes, own_fixes.get(s.id, []), km):
            if (why, b.id) not in seen:
                seen.add((why, b.id))
                out.setdefault(s.id, []).append(
                    RelatedOut(
                        flag=FLAG_RETURNING,
                        why=why,
                        subject_type=kind,
                        subject_id=b.id,
                        name=b.name,
                    )
                )
    return out


def _matches(
    s: Subject,
    bad: list[tuple[str, Subject]],
    bad_fixes: list[tuple[str, Subject, RegistrationFix]],
    own_fixes: list[RegistrationFix],
    km: float,
) -> list[tuple[str, str, Subject]]:
    found: list[tuple[str, str, Subject]] = []
    numbers = _numbers(s, ALL_NUMBERS)
    for kind, b in bad:
        if b.id == s.id:
            continue
        if s.user_id is not None and s.user_id == b.user_id:
            found.append(("account", kind, b))
        if norm_name(b.name) and norm_name(b.name) == norm_name(s.name):
            found.append(("name", kind, b))
        theirs = _numbers(b, ALL_NUMBERS)
        found.extend((f, kind, b) for f, n in numbers.items() if theirs.get(f) == n)
    for kind, b, bf in bad_fixes:
        near = any(distance_km(f.lat, f.lon, bf.lat, bf.lon) <= km for f in own_fixes)
        if b.id != s.id and near:
            found.append(("gps", kind, b))
    return found


async def trust_flags(
    session: AsyncSession, subject_type: str, subjects: list[Subject], km: float
) -> dict[uuid.UUID, list[RelatedOut]]:
    """Duplicate-number and returning-suspended matches, per profile, for the admin queue."""
    out: dict[uuid.UUID, list[RelatedOut]] = {}
    for part in (
        await duplicate_numbers(session, subjects),
        await returning_suspended(session, subject_type, subjects, km),
    ):
        for sid, related in part.items():
            out.setdefault(sid, []).extend(related)
    return out


# --- fake deals for ratings (spec §4C; called by the rating flow) ----------------------------


def device_hash(push_token: str) -> str:
    """The phone's key: SHA-256 of its push token (the token itself is never stored here)."""
    return hashlib.sha256(push_token.encode()).hexdigest()


async def record_sighting(session: AsyncSession, push_token: str, user_id: uuid.UUID) -> None:
    """Remember that this account used this phone (once per pair; the caller commits)."""
    key = device_hash(push_token)
    exists = await session.scalar(
        select(DeviceSighting.id).where(
            DeviceSighting.device_hash == key, DeviceSighting.user_id == user_id
        )
    )
    if exists is None:
        session.add(DeviceSighting(device_hash=key, user_id=user_id))


async def same_device(session: AsyncSession, a: uuid.UUID, b: uuid.UUID) -> bool:
    """True when both accounts were ever seen on one phone: they cannot rate each other."""
    if a == b:
        return True
    phones_a = select(DeviceSighting.device_hash).where(DeviceSighting.user_id == a)
    hit = await session.scalar(
        select(DeviceSighting.id).where(
            DeviceSighting.user_id == b, DeviceSighting.device_hash.in_(phones_a)
        )
    )
    return hit is not None


async def _counterparts(session: AsyncSession, user: uuid.UUID) -> list[set[uuid.UUID]]:
    """For each completed deal of the user: the other parties' accounts."""
    mine = select(DealParty.deal_id).where(DealParty.user_id == user)
    rows = await session.execute(
        select(DealParty.deal_id, DealParty.user_id)
        .join(MarketDeal, MarketDeal.id == DealParty.deal_id)
        .where(DealParty.deal_id.in_(mine), MarketDeal.completed_at.is_not(None))
    )
    deals: dict[uuid.UUID, set[uuid.UUID]] = {}
    for deal_id, party in rows.tuples():
        others = deals.setdefault(deal_id, set())
        if party != user:
            others.add(party)
    return list(deals.values())


async def pair_only(session: AsyncSession, a: uuid.UUID, b: uuid.UUID, min_deals: int) -> bool:
    """True (flag to admin) when either account has at least `min_deals` completed deals and
    every one of them includes the other account (a broker may be on them too)."""
    for user, other in ((a, b), (b, a)):
        deals = await _counterparts(session, user)
        if len(deals) >= min_deals and all(other in parties for parties in deals):
            return True
    return False
