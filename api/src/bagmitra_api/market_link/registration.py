"""The registration GPS fix (spec v1.5 §4, addendum 3), shared by every market-link
registration: traders, exporters, brokers and providers (L2), representatives.

One foreground fix taken when the person registers; registration cannot finish without it.
Stored: lat, lon, accuracy, time, the phone geocoder's place / district / state / PIN and the
mock-location flag. Public profiles show only the place and the date (a badge); exact
coordinates go to admin (`AdminFixOut`). A mock fix, or one whose district differs from the
stated one, is flagged for the admin queue before any badge (OPEN_QUESTIONS Q79, Q87)."""

from __future__ import annotations

import math
import uuid
from datetime import UTC, date, datetime, timedelta
from zoneinfo import ZoneInfo

from pydantic import AwareDatetime, BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.errors import ApiError
from bagmitra_api.market_link.guards import MarketLinkIn
from bagmitra_api.market_link.models import RegistrationFix

INDIA = ZoneInfo("Asia/Kolkata")
EARTH_RADIUS_KM = 6371.0088
# A phone clock a little ahead of the server's is not a fix "from the future".
CLOCK_SKEW = timedelta(minutes=5)
# "At the moment of registration": an older fix is refused and the phone takes it again (Q87).
FIX_MAX_AGE = timedelta(minutes=30)
FLAG_MOCK = "mock_location"
FLAG_OTHER_DISTRICT = "outside_stated_district"
FLAG_NO_PLACE = "place_not_named"


class RegistrationFixIn(MarketLinkIn):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    accuracy_m: float = Field(ge=0)
    captured_at: AwareDatetime
    place: str | None = Field(default=None, max_length=120)
    district: str | None = Field(default=None, max_length=120)
    state: str | None = Field(default=None, max_length=120)
    pin: str | None = Field(default=None, pattern=r"^\d{6}$")
    is_mocked: bool = False


class AdminFixOut(BaseModel):
    lat: float
    lon: float
    accuracy_m: float
    captured_at: datetime
    place: str | None
    district: str | None
    state: str | None
    pin: str | None
    is_mocked: bool


def _clean(value: str | None) -> str | None:
    return value.strip() or None if value is not None else None


def check_fresh(fix: RegistrationFixIn, now: datetime) -> None:
    """The fix must be taken at the moment of registration (422 otherwise)."""
    if fix.captured_at > now + CLOCK_SKEW or now - fix.captured_at > FIX_MAX_AGE:
        raise ApiError(422, "registration_fix_stale", "take the location again")


def new_fix(
    fix: RegistrationFixIn, *, subject_type: str, subject_id: uuid.UUID, user_id: uuid.UUID
) -> RegistrationFix:
    return RegistrationFix(
        subject_type=subject_type,
        subject_id=subject_id,
        user_id=user_id,
        lat=fix.lat,
        lon=fix.lon,
        accuracy_m=fix.accuracy_m,
        captured_at=fix.captured_at,
        place=_clean(fix.place),
        district=_clean(fix.district),
        state=_clean(fix.state),
        pin=fix.pin,
        is_mocked=fix.is_mocked,
    )


def _district_key(name: str) -> str:
    key = name.casefold().strip()
    for suffix in (" district", " जिल्हा", " जिला"):
        key = key.removesuffix(suffix)
    return key.strip()


def fix_flags(fix: RegistrationFix | None, stated_district: str | None) -> list[str]:
    """Why the admin must look at this fix before any badge (empty: nothing to flag)."""
    if fix is None:
        return []
    flags = [FLAG_MOCK] if fix.is_mocked else []
    if not fix.district:
        flags.append(FLAG_NO_PLACE)
    elif stated_district and _district_key(fix.district) != _district_key(stated_district):
        flags.append(FLAG_OTHER_DISTRICT)
    return flags


async def latest_fixes(
    session: AsyncSession, subject_type: str, ids: list[uuid.UUID]
) -> dict[uuid.UUID, RegistrationFix]:
    if not ids:
        return {}
    rows = await session.scalars(
        select(RegistrationFix)
        .where(RegistrationFix.subject_type == subject_type, RegistrationFix.subject_id.in_(ids))
        .order_by(RegistrationFix.created_at)
    )
    return {row.subject_id: row for row in rows}


def admin_fix(fix: RegistrationFix | None) -> AdminFixOut | None:
    return None if fix is None else AdminFixOut.model_validate(fix, from_attributes=True)


def india_date(moment: datetime) -> date:
    """The calendar date in India (SQLite hands back naive UTC datetimes)."""
    aware = moment if moment.tzinfo is not None else moment.replace(tzinfo=UTC)
    return aware.astimezone(INDIA).date()


def distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle (haversine) distance."""
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(a))
