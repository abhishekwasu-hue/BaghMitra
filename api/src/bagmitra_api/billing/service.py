"""Database side of billing: load plans and subscriptions, compute and store snapshots, manual
grants. The decision of what a user may use stays in `compute_entitlements`."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.billing.entitlements import (
    Entitlements,
    PlanFacts,
    SubscriptionFacts,
    compute_entitlements,
)
from bagmitra_api.billing.models import (
    BillingEvent,
    BillingPlan,
    EntitlementSnapshot,
    PlanEntitlement,
    Subscription,
)
from bagmitra_api.billing.signing import sign_snapshot
from bagmitra_api.db.base import as_utc


@dataclass(frozen=True, slots=True)
class PlanConfig:
    key: str
    names: dict[str, str]
    kind: str
    active: bool
    sort_order: int
    features: dict[str, int | None]


@dataclass(frozen=True, slots=True)
class GrantRequest:
    subject_type: str
    subject_id: uuid.UUID
    plan_key: str
    period_end: datetime
    reason: str
    granted_by: uuid.UUID
    now: datetime


class PlanNotFoundError(LookupError):
    pass


class PlanInactiveError(ValueError):
    pass


class GrantNotFoundError(LookupError):
    pass


class GrantStateError(ValueError):
    pass


async def plan_features(session: AsyncSession, plan_id: uuid.UUID) -> dict[str, int | None]:
    rows = await session.scalars(select(PlanEntitlement).where(PlanEntitlement.plan_id == plan_id))
    return {r.feature_key: r.limit_value for r in rows}


async def replace_plan(session: AsyncSession, config: PlanConfig) -> BillingPlan:
    """Create or update a plan; its feature list is replaced as a whole."""
    key = config.key
    plan = await session.scalar(select(BillingPlan).where(BillingPlan.key == key))
    if plan is None:
        plan = BillingPlan(id=uuid.uuid4(), key=key)
    plan.names, plan.kind = config.names, config.kind
    plan.active, plan.sort_order = config.active, config.sort_order
    session.add(plan)
    await session.flush()
    await session.execute(delete(PlanEntitlement).where(PlanEntitlement.plan_id == plan.id))
    for feature, limit in config.features.items():
        session.add(
            PlanEntitlement(
                id=uuid.uuid4(), plan_id=plan.id, feature_key=feature, limit_value=limit
            )
        )
    await session.flush()
    return plan


async def load_plans(session: AsyncSession) -> dict[str, PlanFacts]:
    plans = await session.scalars(select(BillingPlan).where(BillingPlan.active.is_(True)))
    return {p.key: PlanFacts(p.key, await plan_features(session, p.id)) for p in plans}


async def entitlements_for(
    session: AsyncSession, subject_type: str, subject_id: uuid.UUID, now: datetime
) -> Entitlements:
    plans = await load_plans(session)
    keys = {p.id: p.key for p in await session.scalars(select(BillingPlan))}
    rows = await session.scalars(
        select(Subscription).where(
            Subscription.subject_type == subject_type, Subscription.subject_id == subject_id
        )
    )
    facts = [
        SubscriptionFacts(
            plan_key=keys[r.plan_id],
            state=r.state,  # type: ignore[arg-type]
            period_start=as_utc(r.period_start),
            period_end=as_utc(r.period_end),
            grace_until=as_utc(r.grace_until) if r.grace_until else None,
        )
        for r in rows
    ]
    return compute_entitlements(facts, plans, now=now)


async def snapshot_for(
    session: AsyncSession,
    subject_type: str,
    subject_id: uuid.UUID,
    now: datetime,
    signing_key: str,
) -> tuple[dict[str, Any], str | None]:
    """Compute, store (one row per subject) and sign the subject's entitlements."""
    entitlements = await entitlements_for(session, subject_type, subject_id, now)
    payload = entitlements.to_dict()
    signature = sign_snapshot(payload, signing_key) if signing_key else None
    row = await session.scalar(
        select(EntitlementSnapshot).where(
            EntitlementSnapshot.subject_type == subject_type,
            EntitlementSnapshot.subject_id == subject_id,
        )
    )
    row = row or EntitlementSnapshot(
        id=uuid.uuid4(), subject_type=subject_type, subject_id=subject_id
    )
    row.computed, row.valid_until, row.signature = payload, entitlements.valid_until, signature
    session.add(row)
    await session.flush()
    return payload, signature


def _event(subscription: Subscription, event_type: str, **payload: Any) -> BillingEvent:
    return BillingEvent(
        id=uuid.uuid4(),
        subscription_id=subscription.id,
        provider=subscription.provider,
        event_type=event_type,
        notification_id=None,
        payload=payload,
    )


async def grant_plan(session: AsyncSession, request: GrantRequest) -> Subscription:
    plan_key = request.plan_key
    plan = await session.scalar(select(BillingPlan).where(BillingPlan.key == plan_key))
    if plan is None:
        raise PlanNotFoundError(plan_key)
    if not plan.active:
        raise PlanInactiveError(plan_key)
    subscription = Subscription(
        id=uuid.uuid4(),
        subject_type=request.subject_type,
        subject_id=request.subject_id,
        plan_id=plan.id,
        provider="manual_grant",
        state="ACTIVE",
        period_start=request.now,
        period_end=request.period_end,
        auto_renew=False,
        reason=request.reason,
        granted_by=request.granted_by,
    )
    session.add(subscription)
    await session.flush()
    session.add(
        _event(
            subscription,
            "grant_created",
            plan=plan_key,
            period_end=request.period_end.astimezone(UTC).isoformat(),
            reason=request.reason,
            granted_by=str(request.granted_by),
        )
    )
    await session.flush()
    return subscription


async def revoke_grant(
    session: AsyncSession, grant_id: uuid.UUID, *, revoked_by: uuid.UUID
) -> Subscription:
    subscription = await session.get(Subscription, grant_id)
    if subscription is None or subscription.provider != "manual_grant":
        raise GrantNotFoundError(str(grant_id))
    if subscription.state == "REVOKED":
        raise GrantStateError("already revoked")
    subscription.state = "REVOKED"
    session.add(_event(subscription, "grant_revoked", revoked_by=str(revoked_by)))
    await session.flush()
    return subscription
