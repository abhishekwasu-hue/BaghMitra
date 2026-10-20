"""Billing admin (billing addendum §2.4): plan configuration, manual grants (course bundle, FPO
plans, support) with an audit trail. Role `billing_admin`, set server-side in app_metadata."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import AuthenticatedUser, require_role
from bagmitra_api.billing.models import BillingEvent, BillingPlan, Subscription
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
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.base import as_utc
from bagmitra_api.db.session import DbSession
from bagmitra_api.sync.payloads import Slug

router = APIRouter(
    prefix="/v1/admin/billing",
    tags=["admin"],
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
BillingAdmin = Annotated[AuthenticatedUser, Depends(require_role("billing_admin"))]
FeatureLimit = Annotated[int, Field(ge=0, le=10**9)]


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
