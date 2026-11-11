"""Billing admin (billing addendum §2.4, §7): the subscription switch and per-role amounts, plan
configuration, manual grants (course bundle, FPO plans, support) with an audit trail. Role
`billing_admin`, set server-side in app_metadata."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, require_role
from bagmitra_api.billing.models import BillingEvent, BillingPlan, Subscription
from bagmitra_api.billing.play import PlayError, PlayPublisher, play_publisher
from bagmitra_api.billing.service import (
    GrantNotFoundError,
    GrantRequest,
    GrantStateError,
    PlanConfig,
    PlanInactiveError,
    PlanNotFoundError,
    grant_plan,
    plan_features,
    replace_plan,
    revoke_grant,
)
from bagmitra_api.billing.switch import (
    NoPlayPriceError,
    PlayNotSetUpError,
    PlayPlan,
    billing_settings,
    change_bill_limits,
    change_photo_limits,
    change_switch,
    migrate_role_prices,
    role_prices,
    set_role_amount,
    set_role_bill_limits,
    set_role_photo_limits,
)
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc
from bagmitra_api.db.session import DbSession
from bagmitra_api.photo_ai.limits import DAILY_DEFAULT, MONTHLY_DEFAULT
from bagmitra_api.sync.payloads import Slug

router = APIRouter(
    prefix="/v1/admin/billing",
    tags=["admin"],
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
BillingAdmin = Annotated[AuthenticatedUser, Depends(require_role("billing_admin"))]
FeatureLimit = Annotated[int, Field(ge=0, le=10**9)]
Play = Annotated[PlayPublisher | None, Depends(play_publisher)]
AppSettings = Annotated[Settings, Depends(get_settings)]
Role = Literal["grower", "trader", "broker", "exporter", "provider"]


class FeatureConfig(BaseModel):
    feature: str
    limit: int | None


class PlanOut(BaseModel):
    key: str
    names: dict[str, str]
    kind: str
    active: bool
    sort_order: int
    features: list[FeatureConfig]


class PlansResponse(BaseModel):
    plans: list[PlanOut]


class PlanIn(BaseModel):
    names: dict[str, str]
    kind: Literal["grower", "organisation"]
    active: bool = True
    sort_order: int = Field(default=0, ge=0, le=1000)
    # feature -> limit; null means included without a limit.
    features: dict[Slug, FeatureLimit | None]

    @field_validator("names")
    @classmethod
    def _english_required(cls, names: dict[str, str]) -> dict[str, str]:
        if not names.get("en", "").strip():
            raise ValueError("an English name is required")
        return names


class GrantIn(BaseModel):
    subject_type: Literal["farmer", "organisation"]
    subject_id: uuid.UUID
    plan_key: str = Field(max_length=32)
    period_end: datetime
    reason: str = Field(min_length=3, max_length=500)


class SubscriptionOut(BaseModel):
    id: uuid.UUID
    subject_type: str
    subject_id: uuid.UUID
    plan_key: str
    provider: str
    state: str
    period_start: datetime
    period_end: datetime
    reason: str | None


class SubscriptionsResponse(BaseModel):
    subscriptions: list[SubscriptionOut]


class EventOut(BaseModel):
    id: uuid.UUID
    subscription_id: uuid.UUID | None
    provider: str
    event_type: str
    created_at: datetime


class EventsResponse(BaseModel):
    events: list[EventOut]


class SwitchIn(BaseModel):
    # OFF = every signed-in user gets the full app; ON from `starts_on` (India date) if set.
    enabled: bool
    starts_on: date | None = None


class RolePriceOut(BaseModel):
    role: str
    # The admin's monthly amount; null = the role stays free even when the switch is ON.
    amount_paise: int | None
    # What Google Play reported for the role's monthly base plan in India (the source of truth).
    play_price_paise: int | None
    play_currency: str | None
    play_synced_at: datetime | None
    # Photo analysis per farmer on this role's plan (Q135); null = the default (5 / 50).
    photo_ai_daily: int | None = None
    photo_ai_monthly: int | None = None
    # Bill reading per farmer on this role's plan (Q136); null = the default (5 / 50).
    bill_read_daily: int | None = None
    bill_read_monthly: int | None = None


class PhotoLimitsOut(BaseModel):
    """Photo analysis limits for farmers without a role plan (or while the switch is off);
    null = the default. `daily_total`: all farmers together per India day; null = no cap."""

    free_daily: int | None
    free_monthly: int | None
    daily_total: int | None
    default_daily: int = DAILY_DEFAULT
    default_monthly: int = MONTHLY_DEFAULT


class BillLimitsOut(BaseModel):
    """Bill reading limits (Q136) for farmers without a role plan (or while the switch is off);
    null = the default. `daily_total`: all farmers together per India day; null = no cap."""

    free_daily: int | None
    free_monthly: int | None
    daily_total: int | None
    default_daily: int = DAILY_DEFAULT
    default_monthly: int = MONTHLY_DEFAULT


class BillingSettingsOut(SwitchIn):
    roles: list[RolePriceOut]
    photo_limits: PhotoLimitsOut
    bill_limits: BillLimitsOut


async def _plan_out(session: AsyncSession, plan: BillingPlan) -> PlanOut:
    features = await plan_features(session, plan.id)
    return PlanOut(
        key=plan.key,
        names=plan.names,
        kind=plan.kind,
        active=plan.active,
        sort_order=plan.sort_order,
        features=[FeatureConfig(feature=f, limit=v) for f, v in sorted(features.items())],
    )


async def _subscription_out(session: AsyncSession, row: Subscription) -> SubscriptionOut:
    plan = await session.get(BillingPlan, row.plan_id)
    return SubscriptionOut(
        id=row.id,
        subject_type=row.subject_type,
        subject_id=row.subject_id,
        plan_key=plan.key if plan else "",
        provider=row.provider,
        state=row.state,
        period_start=as_utc(row.period_start),
        period_end=as_utc(row.period_end),
        reason=row.reason,
    )


@router.get("/plans", operation_id="admin_billing_plans")
async def plans(_: BillingAdmin, session: DbSession) -> PlansResponse:
    rows = await session.scalars(select(BillingPlan).order_by(BillingPlan.sort_order))
    return PlansResponse(plans=[await _plan_out(session, p) for p in rows])


@router.put("/plans/{key}", operation_id="admin_billing_put_plan")
async def put_plan(key: Slug, body: PlanIn, _: BillingAdmin, session: DbSession) -> PlanOut:
    plan = await replace_plan(
        session,
        PlanConfig(
            key=key,
            names=body.names,
            kind=body.kind,
            active=body.active,
            sort_order=body.sort_order,
            features=dict(body.features),
        ),
    )
    await session.commit()
    return await _plan_out(session, plan)


@router.post(
    "/grants",
    status_code=201,
    operation_id="admin_billing_grant",
    responses={404: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
)
async def grant(body: GrantIn, admin: BillingAdmin, session: DbSession) -> SubscriptionOut:
    now = datetime.now(UTC)
    if as_utc(body.period_end) <= now:
        raise ApiError(422, "invalid_period", "the grant must end in the future")
    try:
        subscription = await grant_plan(
            session,
            GrantRequest(
                subject_type=body.subject_type,
                subject_id=body.subject_id,
                plan_key=body.plan_key,
                period_end=as_utc(body.period_end),
                reason=body.reason,
                granted_by=admin.id,
                now=now,
            ),
        )
    except PlanNotFoundError as exc:
        raise ApiError(404, "not_found", "plan not found") from exc
    except PlanInactiveError as exc:
        raise ApiError(409, "plan_inactive", "the plan is not active") from exc
    await session.commit()
    return await _subscription_out(session, subscription)


@router.post(
    "/grants/{grant_id}/revoke",
    operation_id="admin_billing_revoke",
    responses={404: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
)
async def revoke(grant_id: uuid.UUID, admin: BillingAdmin, session: DbSession) -> SubscriptionOut:
    try:
        subscription = await revoke_grant(session, grant_id, revoked_by=admin.id)
    except GrantNotFoundError as exc:
        raise ApiError(404, "not_found", "grant not found") from exc
    except GrantStateError as exc:
        raise ApiError(409, "already_revoked", "the grant is already revoked") from exc
    await session.commit()
    return await _subscription_out(session, subscription)


@router.get("/subscriptions", operation_id="admin_billing_subscriptions")
async def subscriptions(
    _: BillingAdmin, session: DbSession, subject_id: uuid.UUID | None = None
) -> SubscriptionsResponse:
    query = select(Subscription).order_by(Subscription.created_at.desc()).limit(200)
    if subject_id is not None:
        query = query.where(Subscription.subject_id == subject_id)
    rows = await session.scalars(query)
    return SubscriptionsResponse(subscriptions=[await _subscription_out(session, r) for r in rows])


@router.get("/events", operation_id="admin_billing_events")
async def events(
    _: BillingAdmin, session: DbSession, limit: Annotated[int, Query(ge=1, le=200)] = 50
) -> EventsResponse:
    rows = await session.scalars(
        select(BillingEvent).order_by(BillingEvent.created_at.desc(), BillingEvent.id).limit(limit)
    )
    return EventsResponse(
        events=[
            EventOut(
                id=e.id,
                subscription_id=e.subscription_id,
                provider=e.provider,
                event_type=e.event_type,
                created_at=as_utc(e.created_at),
            )
            for e in rows
        ]
    )


async def _settings_out(session: AsyncSession) -> BillingSettingsOut:
    row = await billing_settings(session)
    return BillingSettingsOut(
        enabled=row.enabled,
        starts_on=row.starts_on,
        roles=[
            RolePriceOut(
                role=r.role,
                amount_paise=r.amount_paise,
                play_price_paise=r.play_price_paise,
                play_currency=r.play_currency,
                play_synced_at=as_utc(r.play_synced_at) if r.play_synced_at else None,
                photo_ai_daily=r.photo_ai_daily,
                photo_ai_monthly=r.photo_ai_monthly,
                bill_read_daily=r.bill_read_daily,
                bill_read_monthly=r.bill_read_monthly,
            )
            for r in (await role_prices(session)).values()
        ],
        photo_limits=PhotoLimitsOut(
            free_daily=row.photo_ai_free_daily,
            free_monthly=row.photo_ai_free_monthly,
            daily_total=row.photo_ai_daily_total,
        ),
        bill_limits=BillLimitsOut(
            free_daily=row.bill_read_free_daily,
            free_monthly=row.bill_read_free_monthly,
            daily_total=row.bill_read_daily_total,
        ),
    )


@router.get("/settings", operation_id="admin_billing_settings")
async def get_billing_settings(_: BillingAdmin, session: DbSession) -> BillingSettingsOut:
    out = await _settings_out(session)
    await session.commit()
    return out


@router.put("/settings", operation_id="admin_billing_put_switch")
async def put_switch(body: SwitchIn, admin: BillingAdmin, session: DbSession) -> BillingSettingsOut:
    await change_switch(session, admin.id, enabled=body.enabled, starts_on=body.starts_on)
    out = await _settings_out(session)
    await session.commit()
    return out


PhotoLimit = Annotated[int, Field(ge=0, le=100_000)]


class PhotoLimitsIn(BaseModel):
    # Per farmer without a role plan; null = the default (5 a day, 50 a month).
    free_daily: PhotoLimit | None = None
    free_monthly: PhotoLimit | None = None
    # All farmers together per India day; null = no overall cap.
    daily_total: PhotoLimit | None = None


class RolePhotoLimitsIn(BaseModel):
    # Per farmer on this role's plan; null = the default (5 a day, 50 a month).
    daily: PhotoLimit | None = None
    monthly: PhotoLimit | None = None


@router.put("/photo-limits", operation_id="admin_billing_put_photo_limits")
async def put_photo_limits(
    body: PhotoLimitsIn, admin: BillingAdmin, session: DbSession
) -> BillingSettingsOut:
    """Photo analysis limits for farmers without a plan, and the optional overall cap (Q135)."""
    await change_photo_limits(
        session,
        admin.id,
        free_daily=body.free_daily,
        free_monthly=body.free_monthly,
        daily_total=body.daily_total,
    )
    out = await _settings_out(session)
    await session.commit()
    return out


@router.put("/roles/{role}/photo-limits", operation_id="admin_billing_put_role_photo_limits")
async def put_role_photo_limits(
    role: Role, body: RolePhotoLimitsIn, admin: BillingAdmin, session: DbSession
) -> BillingSettingsOut:
    """Photo analysis limits per farmer on this role's plan (Q135)."""
    await set_role_photo_limits(session, admin.id, role, daily=body.daily, monthly=body.monthly)
    out = await _settings_out(session)
    await session.commit()
    return out


class BillLimitsIn(BaseModel):
    # Bills read per farmer without a role plan; null = the default (5 a day, 50 a month).
    free_daily: PhotoLimit | None = None
    free_monthly: PhotoLimit | None = None
    # All farmers together per India day; null = no overall cap.
    daily_total: PhotoLimit | None = None


class RoleBillLimitsIn(BaseModel):
    # Bills read per farmer on this role's plan; null = the default (5 a day, 50 a month).
    daily: PhotoLimit | None = None
    monthly: PhotoLimit | None = None


@router.put("/bill-limits", operation_id="admin_billing_put_bill_limits")
async def put_bill_limits(
    body: BillLimitsIn, admin: BillingAdmin, session: DbSession
) -> BillingSettingsOut:
    """Bill reading limits for farmers without a plan, and the optional overall cap (Q136)."""
    await change_bill_limits(
        session,
        admin.id,
        free_daily=body.free_daily,
        free_monthly=body.free_monthly,
        daily_total=body.daily_total,
    )
    out = await _settings_out(session)
    await session.commit()
    return out


@router.put("/roles/{role}/bill-limits", operation_id="admin_billing_put_role_bill_limits")
async def put_role_bill_limits(
    role: Role, body: RoleBillLimitsIn, admin: BillingAdmin, session: DbSession
) -> BillingSettingsOut:
    """Bill reading limits per farmer on this role's plan (Q136)."""
    await set_role_bill_limits(session, admin.id, role, daily=body.daily, monthly=body.monthly)
    out = await _settings_out(session)
    await session.commit()
    return out


class RoleAmountIn(BaseModel):
    # Monthly amount in paise; null clears it (the role is free again; Play is not touched).
    amount_paise: Annotated[int | None, Field(gt=0, le=10**8)]


class MigrateIn(BaseModel):
    # The admin confirmed after reading Play's price-change rules on the page.
    confirm: Literal[True]


def _play_plan(settings: Settings, role: str) -> PlayPlan:
    return PlayPlan(settings.play_product_prefix + role, settings.play_base_plan_id)


@router.put(
    "/roles/{role}/amount",
    operation_id="admin_billing_put_role_amount",
    responses={502: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
async def put_role_amount(  # noqa: PLR0913 - path, body and dependencies
    role: Role,
    body: RoleAmountIn,
    admin: BillingAdmin,
    session: DbSession,
    play: Play,
    settings: AppSettings,
) -> BillingSettingsOut:
    try:
        await set_role_amount(
            session,
            play,
            role,
            body.amount_paise,
            _play_plan(settings, role),
            admin_id=admin.id,
            now=datetime.now(UTC),
        )
    except PlayNotSetUpError as exc:
        raise ApiError(503, "play_not_set_up", "Google Play is not set up yet") from exc
    except PlayError as exc:
        raise ApiError(502, "play_error", "Google Play did not accept the price") from exc
    out = await _settings_out(session)
    await session.commit()
    return out


@router.post(
    "/roles/{role}/migrate-prices",
    operation_id="admin_billing_migrate_prices",
    responses={409: {"model": ErrorResponse}, 502: {"model": ErrorResponse}},
)
async def migrate_prices(
    role: Role,
    _confirmed: MigrateIn,
    admin: BillingAdmin,
    session: DbSession,
    play: Play,
    settings: AppSettings,
) -> BillingSettingsOut:
    plan = _play_plan(settings, role)
    try:
        await migrate_role_prices(session, play, role, plan, admin_id=admin.id)
    except NoPlayPriceError as exc:
        raise ApiError(409, "no_play_price", "no price has been set in Google Play yet") from exc
    except PlayNotSetUpError as exc:
        raise ApiError(503, "play_not_set_up", "Google Play is not set up yet") from exc
    except PlayError as exc:
        raise ApiError(502, "play_error", "Google Play did not accept the migration") from exc
    out = await _settings_out(session)
    await session.commit()
    return out
