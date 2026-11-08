"""What the signed-in user may use (billing addendum §2.4). The app downloads a snapshot, caches
it for offline use and never decides entitlements itself."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.billing.entitlements import ROLE_PLAN_PREFIX
from bagmitra_api.billing.service import entitlements_for, snapshot_for
from bagmitra_api.billing.switch import load_policy, user_roles
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession

router = APIRouter(
    prefix="/v1/billing", tags=["billing"], responses={401: {"model": ErrorResponse}}
)
AppSettings = Annotated[Settings, Depends(get_settings)]


class FeatureOut(BaseModel):
    enabled: bool
    limit: int | None


class EntitlementsOut(BaseModel):
    plans: list[str]
    features: dict[str, FeatureOut]
    valid_until: str
    computed_at: str


class EntitlementsResponse(BaseModel):
    entitlements: EntitlementsOut
    # Ed25519 over the canonical JSON of `entitlements`; null when no signing key is configured.
    signature: str | None


@router.get("/entitlements", operation_id="billing_entitlements")
async def entitlements(
    user: CurrentUser, session: DbSession, settings: AppSettings
) -> EntitlementsResponse:
    payload: dict[str, Any]
    payload, signature = await snapshot_for(
        session,
        "farmer",
        user.id,
        datetime.now(UTC),
        settings.entitlement_signing_key.get_secret_value(),
    )
    await session.commit()
    return EntitlementsResponse(
        entitlements=EntitlementsOut.model_validate(payload), signature=signature
    )


class PlanOfferOut(BaseModel):
    """Subscription page (§7) only while ON and a role is priced; the price is Play's own."""

    in_force: bool
    role: str | None
    product_id: str | None
    base_plan_id: str | None
    # A role plan of the user (or a higher-priced one) is active.
    covered: bool
    # Features locked right now (empty while the gate map is empty, OPEN_QUESTIONS Q118).
    locked: list[str]


@router.get("/plan", operation_id="billing_plan")
async def plan(user: CurrentUser, session: DbSession, settings: AppSettings) -> PlanOfferOut:
    now = datetime.now(UTC)
    policy = await load_policy(session)
    roles = await user_roles(session, user.id)
    ent = await entitlements_for(session, "farmer", user.id, now)
    prefix = ROLE_PLAN_PREFIX
    plan_roles = [p.removeprefix(prefix) for p in ent.plans if p.startswith(prefix)]
    role = policy.offer_role(roles) if policy.in_force(now) else None
    return PlanOfferOut(
        in_force=policy.in_force(now),
        role=role,
        product_id=settings.play_product_prefix + role if role else None,
        base_plan_id=settings.play_base_plan_id if role else None,
        covered=role is not None and role in policy.covered_roles(roles, plan_roles),
        locked=sorted(k for k, f in ent.features.items() if not f.enabled),
    )
