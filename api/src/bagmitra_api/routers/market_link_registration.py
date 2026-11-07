"""Market linkage L2: trader, exporter, broker and service-provider registration (spec v1.5
§2, §2.1, §4; addenda 1-3; §4B).

One sign-in (the existing phone OTP / Google); one account may hold several roles: one trader
OR exporter profile, one broker profile and one provider per kind. Every registration needs the
one foreground GPS fix taken now (`registration_fixes`); a mock fix or one from another
district is flagged in the admin queue before any badge. Registration numbers (GSTIN, APMC,
FSSAI, IEC, APEDA) are stored for the admin's manual check only; an exporter needs an IEC. No
Aadhaar / UID, commission or income anywhere (decision c, addendum 1). Every photo is
EXIF-stripped by the API before storage (spec §4B). Every write needs the
role's terms accepted first (`require_role_accepted`, spec §4C). Behind the
`market_link_enabled` gate (404 when off).
"""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Literal, cast

from fastapi import APIRouter, Depends, Query, Request
from pydantic import AwareDatetime, BaseModel, BeforeValidator, Field, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, CurrentUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import MarketLinkIn, latest_verifications
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    PartyVerification,
    RepresentativeUpload,
    ServiceProvider,
)
from bagmitra_api.market_link.photos import JPEG_BODY, clean_jpeg, store_jpeg
from bagmitra_api.market_link.profiles import (
    MODELS,
    MyProfileOut,
    Subject,
    SubjectType,
    own_views,
)
from bagmitra_api.market_link.registration import (
    RegistrationFixIn,
    check_fresh,
    india_date,
    new_fix,
)
from bagmitra_api.market_link.terms import accepted_roles, current_versions, require_role_accepted
from bagmitra_api.routers.market_link import require_market_link
from bagmitra_api.routers.scouting_photos import PhotoContext, get_photo_context
from bagmitra_api.weather.service import get_clock

REP_ROLE = "market_link_rep"
ADMIN_ROLE = "market_link_admin"
Clock = Annotated[Callable[[], datetime], Depends(get_clock)]
Photo = Annotated[PhotoContext, Depends(get_photo_context)]
PhoneNo = Annotated[str, Field(pattern=r"^\+91[6-9]\d{9}$")]
Place = Annotated[str, Field(min_length=1, max_length=120)]
Places = Annotated[list[Place], Field(default_factory=list, max_length=20)]
Crops = Annotated[list[Annotated[str, Field(min_length=1, max_length=32)]], Field(max_length=20)]


def _upper(value: object) -> object:
    return value.strip().upper() or None if isinstance(value, str) else value


Upper = BeforeValidator(_upper)
Gstin = Annotated[str, Upper, Field(pattern=r"^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$")]
Iec = Annotated[str, Upper, Field(pattern=r"^[A-Z0-9]{10}$")]
Fssai = Annotated[str, Upper, Field(pattern=r"^\d{14}$")]
Licence = Annotated[str, Upper, Field(min_length=1, max_length=40)]
ProviderKind = Literal["weighbridge", "transporter", "labour_gang", "crate_supplier"]
# Documents a registrant may photograph for the admin's check (spec §4; brokers have none).
DocKind = Literal["gst", "apmc", "fssai", "iec", "apeda", "certificate"]
DOCS: dict[str, frozenset[str]] = {
    "buyer": frozenset({"gst", "apmc", "fssai", "iec", "apeda"}),
    "broker": frozenset(),
    "provider": frozenset({"certificate"}),
}
_ERRORS: dict[int | str, dict[str, object]] = {
    code: {"model": ErrorResponse} for code in (401, 403, 404, 409, 413, 422, 502, 503)
}
router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses=_ERRORS,
)
admin_router = APIRouter(
    prefix="/v1/admin/market-link",
    tags=["admin"],
    dependencies=[Depends(require_market_link)],
    responses=_ERRORS,
)


class _Registration(MarketLinkIn):
    name: Place
    phone: PhoneNo
    district: Place
    taluka: Place | None = None
    address: str | None = Field(default=None, max_length=300)
    # Required (addendum 3): registration cannot finish without a fix taken now.
    fix: RegistrationFixIn


class BuyerIn(_Registration):
    """A trader or an exporter: firm, the markets / villages they buy in, crops, and the
    registration numbers they hold (stored for the admin's manual check)."""

    firm: str | None = Field(default=None, max_length=120)
    markets: Places
    crops: Crops = Field(default_factory=list)
    gst_no: Gstin | None = None
    apmc_licence_no: Licence | None = None
    fssai_no: Fssai | None = None
    iec_no: Iec | None = None
    apeda_no: Licence | None = None


class BrokerIn(_Registration):
    village: Place
    service_areas: Places
    crops: Crops = Field(default_factory=list)


class ProviderFields(MarketLinkIn):
    """Spec §4 fields per kind. `name` is the owner (weighbridge, transporter) or the leader
    (labour gang, crate supplier)."""

    kind: ProviderKind
    name: Place
    phone: PhoneNo
    village: Place
    taluka: Place | None = None
    district: Place
    service_areas: Places
    address: str | None = Field(default=None, max_length=300)
    cert_valid_until: date | None = None
    vehicle_numbers: list[Annotated[str, Upper, Field(min_length=4, max_length=16)]] = Field(
        default_factory=list, max_length=20
    )
    capacity_t: float | None = Field(default=None, gt=0, le=100)
    refrigerated: bool | None = None
    carrier_reg_no: str | None = Field(default=None, min_length=1, max_length=40)

    @model_validator(mode="after")
    def _fields_of_kind(self) -> ProviderFields:
        transport = (self.vehicle_numbers, self.capacity_t, self.refrigerated, self.carrier_reg_no)
        if self.kind == "weighbridge" and self.cert_valid_until is None:
            raise ValueError("a weighbridge needs its certificate valid-until date")
        if self.kind != "weighbridge" and self.cert_valid_until is not None:
            raise ValueError("only a weighbridge has a certificate")
        if self.kind == "transporter":
            if not self.vehicle_numbers or self.capacity_t is None or self.refrigerated is None:
                raise ValueError("a transporter needs vehicle numbers, capacity and refrigerated")
        elif any(v not in (None, []) for v in transport):
            raise ValueError("vehicle fields are for a transporter only")
        if self.kind in ("labour_gang", "crate_supplier") and not self.service_areas:
            raise ValueError("a labour gang / crate supplier needs a service area")
        return self


class ProviderIn(ProviderFields):
    fix: RegistrationFixIn


class AdminProviderIn(ProviderFields):
    # The admin web has no phone GPS; an admin-added provider may come without one (Q79).
    fix: RegistrationFixIn | None = None


class AddressIn(MarketLinkIn):
    address: str | None = Field(default=None, max_length=300)


class MyProfilesResponse(BaseModel):
    profiles: list[MyProfileOut]


def _today(clock: Callable[[], datetime]) -> date:
    return india_date(clock())


async def _own(
    session: AsyncSession, kind: str, subject: Subject, clock: Callable[[], datetime]
) -> MyProfileOut:
    return (await own_views(session, kind, [subject], _today(clock)))[0]


async def _register(  # noqa: PLR0913 - the one shared registration path
    session: AsyncSession,
    kind: str,
    subject: Subject,
    fix: RegistrationFixIn | None,
    user: uuid.UUID,
    now: datetime,
) -> None:
    """Saves the profile, its fix and a pending record (the verification queue, Q72)."""
    address = (subject.address or "").strip() or None
    subject.address = address
    subject.address_set_by = user if address else None
    subject.address_set_at = now if address else None
    subject.created_at = subject.updated_at = now
    session.add(subject)
    await session.flush()
    if fix is not None:
        session.add(new_fix(fix, subject_type=kind, subject_id=subject.id, user_id=user))
    session.add(
        PartyVerification(
            subject_type=kind,
            subject_id=subject.id,
            status="pending",
            created_at=now,
            updated_at=now,
        )
    )
    await session.commit()


async def _buyer(
    kind: Literal["trader", "exporter"],
    body: BuyerIn,
    user: AuthenticatedUser,
    session: AsyncSession,
    clock: Callable[[], datetime],
) -> MyProfileOut:
    if kind == "exporter" and body.iec_no is None:
        raise ApiError(422, "exporter_needs_iec", "an exporter needs an IEC")
    if kind == "trader" and not (body.gst_no or body.apmc_licence_no or body.iec_no):
        # Spec §4: a trader is verified on a check of GSTIN, APMC licence or IEC (Q88).
        raise ApiError(422, "trader_needs_a_number", "GSTIN, APMC licence or IEC")
    now = clock()
    check_fresh(body.fix, now)
    if await session.scalar(select(BuyerProfile.id).where(BuyerProfile.user_id == user.id)):
        raise ApiError(409, "profile_exists", "already registered as a trader / exporter")
    profile = BuyerProfile(**body.model_dump(exclude={"fix"}), kind=kind, user_id=user.id)
    await _register(session, "buyer", profile, body.fix, user.id, now)
    return await _own(session, "buyer", profile, clock)


@router.post("/traders", operation_id="market_link_register_trader", status_code=201)
async def register_trader(
    body: BuyerIn,
    user: Annotated[AuthenticatedUser, Depends(require_role_accepted("trader"))],
    session: DbSession,
    clock: Clock,
) -> MyProfileOut:
    """Trader registration with the GPS fix; lands in the verification queue."""
    return await _buyer("trader", body, user, session, clock)


@router.post("/exporters", operation_id="market_link_register_exporter", status_code=201)
async def register_exporter(
    body: BuyerIn,
    user: Annotated[AuthenticatedUser, Depends(require_role_accepted("exporter"))],
    session: DbSession,
    clock: Clock,
) -> MyProfileOut:
    """Exporter registration (IEC required, spec §4)."""
    return await _buyer("exporter", body, user, session, clock)


@router.post("/brokers", operation_id="market_link_register_broker", status_code=201)
async def register_broker(
    body: BrokerIn,
    user: Annotated[AuthenticatedUser, Depends(require_role_accepted("broker"))],
    session: DbSession,
    clock: Clock,
) -> MyProfileOut:
    """Broker (मध्यस्थ (दलाल)) registration: phone sign-in + GPS fix; the admin then calls
    (spec §4 broker rule; no photo ID, no place photo needed)."""
    now = clock()
    check_fresh(body.fix, now)
    if await session.scalar(select(BrokerProfile.id).where(BrokerProfile.user_id == user.id)):
        raise ApiError(409, "profile_exists", "already registered as a broker")
    profile = BrokerProfile(**body.model_dump(exclude={"fix"}), user_id=user.id)
    await _register(session, "broker", profile, body.fix, user.id, now)
    return await _own(session, "broker", profile, clock)


@router.post("/providers", operation_id="market_link_register_provider", status_code=201)
async def register_provider(
    body: ProviderIn,
    user: Annotated[AuthenticatedUser, Depends(require_role_accepted("provider"))],
    session: DbSession,
    clock: Clock,
) -> MyProfileOut:
    """Service provider registration (one per kind per user) with the GPS fix."""
    now = clock()
    check_fresh(body.fix, now)
    taken = await session.scalar(
        select(ServiceProvider.id).where(
            ServiceProvider.user_id == user.id, ServiceProvider.kind == body.kind
        )
    )
    if taken is not None:
        raise ApiError(409, "profile_exists", "already registered as this kind")
    provider = ServiceProvider(**body.model_dump(exclude={"fix"}), user_id=user.id)
    await _register(session, "provider", provider, body.fix, user.id, now)
    return await _own(session, "provider", provider, clock)


@router.get("/me/profiles", operation_id="market_link_my_profiles")
async def my_profiles(user: CurrentUser, session: DbSession, clock: Clock) -> MyProfilesResponse:
    """Every market-link profile of the signed-in user, with its check status."""
    out: list[MyProfileOut] = []
    for kind, model in MODELS.items():
        rows = list(await session.scalars(select(model).where(model.user_id == user.id)))
        out += await own_views(session, kind, cast(list[Subject], rows), _today(clock))
    return MyProfilesResponse(profiles=out)


def subject_role(subject: Subject) -> str:
    """The market-link role a profile is used in (terms are accepted per role, §4C)."""
    if isinstance(subject, BuyerProfile):
        return subject.kind
    return "broker" if isinstance(subject, BrokerProfile) else "provider"


async def require_accepted(
    session: AsyncSession, settings: Settings, user: AuthenticatedUser, role: str
) -> None:
    """`require_role_accepted` for a role known only from the profile being written."""
    if role not in await accepted_roles(session, user.id, current_versions(settings)):
        raise ApiError(403, "terms_not_accepted", f"Accept the current terms for {role}")


async def subject_of(session: AsyncSession, kind: str, subject_id: uuid.UUID) -> Subject:
    subject = cast(Subject | None, await session.get(MODELS[kind], subject_id))
    if subject is None:
        raise ApiError(404, "profile_not_found")
    return subject


@router.put(
    "/profiles/{subject_type}/{subject_id}/address", operation_id="market_link_profile_address"
)
async def set_address(  # noqa: PLR0913 - path, body and dependencies
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    body: AddressIn,
    user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
    clock: Clock,
) -> MyProfileOut:
    """The optional address: only the profile owner or a BagMitra representative sets it
    (addendum 2); who and when are stored, and a representative's entry is also a record."""
    subject = await subject_of(session, subject_type, subject_id)
    is_rep = REP_ROLE in user.roles
    if subject.user_id != user.id and not is_rep:
        raise ApiError(403, "forbidden", "only the owner or a representative")
    own = subject.user_id == user.id
    await require_accepted(
        session, settings, user, subject_role(subject) if own else "representative"
    )
    now = clock()
    address = (body.address or "").strip() or None
    subject.address, subject.address_set_by, subject.address_set_at = address, user.id, now
    if not own and address is not None:
        session.add(
            RepresentativeUpload(
                subject_type=subject_type,
                subject_id=subject.id,
                uploaded_by=user.id,
                address=address,
                created_at=now,
                updated_at=now,
            )
        )
    await session.commit()
    return await _own(session, subject_type, subject, clock)


async def _add_document(
    session: AsyncSession, kind: str, subject_id: uuid.UUID, key: str, now: datetime
) -> None:
    """Adds the photo to the pending record; after a decision, a new pending record (with the
    earlier documents) puts the profile back in the queue for a re-check (Q81)."""
    latest = (await latest_verifications(session, kind, [subject_id])).get(subject_id)
    if latest is not None and latest.status == "pending":
        latest.document_keys = [*latest.document_keys, key]
        return
    session.add(
        PartyVerification(
            subject_type=kind,
            subject_id=subject_id,
            status="pending",
            document_keys=[*(latest.document_keys if latest else []), key],
            created_at=now,
            updated_at=now,
        )
    )


@router.post(
    "/profiles/{subject_type}/{subject_id}/documents",
    operation_id="market_link_profile_document",
    openapi_extra=JPEG_BODY,
)
async def add_document(  # noqa: PLR0913 - path, query, body and dependencies
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    doc: DocKind,
    request: Request,
    user: CurrentUser,
    session: DbSession,
    clock: Clock,
    ctx: Photo,
    settings: Annotated[Settings, Depends(get_settings)],
    valid_until: date | None = None,
) -> MyProfileOut:
    """A document photo for the admin's check (in-app camera): GSTIN / APMC / FSSAI / IEC /
    APEDA for a trader or exporter, the Legal Metrology certificate (with its valid-until
    date) for a weighbridge. Owner only; EXIF stripped before storage (spec §4B)."""
    subject = await subject_of(session, subject_type, subject_id)
    if subject.user_id != user.id:
        raise ApiError(403, "forbidden", "only the owner")
    await require_accepted(session, settings, user, subject_role(subject))
    is_cert = doc == "certificate"
    if doc not in DOCS[subject_type] or (
        is_cert and (not isinstance(subject, ServiceProvider) or subject.kind != "weighbridge")
    ):
        raise ApiError(422, "document_not_for_profile", f"{doc} is not for this profile")
    if is_cert and valid_until is None:
        raise ApiError(422, "valid_until_required", "the certificate's valid-until date")
    data = await clean_jpeg(request, ctx)
    key = f"market-link/{subject_type}/{subject.id}/{doc}-{uuid.uuid4()}.jpg"
    await store_jpeg(ctx, key, data)
    now = clock()
    if isinstance(subject, ServiceProvider) and is_cert:
        subject.cert_photo_key, subject.cert_valid_until = key, valid_until
    await _add_document(session, subject_type, subject.id, key, now)
    await session.commit()
    return await _own(session, subject_type, subject, clock)


@router.post(
    "/profiles/{subject_type}/{subject_id}/place-photo",
    operation_id="market_link_profile_place_photo",
    status_code=201,
    openapi_extra=JPEG_BODY,
)
async def place_photo(  # noqa: PLR0913 - path, query, body and dependencies
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    captured_at: AwareDatetime,
    lat: Annotated[float, Query(ge=-90, le=90)],
    lon: Annotated[float, Query(ge=-180, le=180)],
    request: Request,
    rep: Annotated[AuthenticatedUser, Depends(require_role(REP_ROLE))],
    session: DbSession,
    ctx: Photo,
    settings: Annotated[Settings, Depends(get_settings)],
) -> None:
    """A representative's place photo from a visit (in-app camera, time + GPS): who and when
    are stored; EXIF is stripped before storage (addendum 2, spec §4B)."""
    subject = await subject_of(session, subject_type, subject_id)
    await require_accepted(session, settings, rep, "representative")
    data = await clean_jpeg(request, ctx)
    key = f"market-link/{subject_type}/{subject.id}/place-{uuid.uuid4()}.jpg"
    await store_jpeg(ctx, key, data)
    session.add(
        RepresentativeUpload(
            subject_type=subject_type,
            subject_id=subject.id,
            uploaded_by=rep.id,
            photo_key=key,
            captured_at=captured_at,
            lat=lat,
            lon=lon,
        )
    )
    await session.commit()


@admin_router.post("/providers", operation_id="admin_market_link_provider_add", status_code=201)
async def admin_add_provider(
    body: AdminProviderIn,
    admin: Annotated[AuthenticatedUser, Depends(require_role(ADMIN_ROLE))],
    session: DbSession,
    clock: Clock,
) -> MyProfileOut:
    """Admin adds a provider it knows (no account of its own, spec §2); it waits in the queue
    for a decision like any other (Q72)."""
    now = clock()
    provider = ServiceProvider(**body.model_dump(exclude={"fix"}), user_id=None, added_by=admin.id)
    await _register(session, "provider", provider, body.fix, admin.id, now)
    return await _own(session, "provider", provider, clock)
