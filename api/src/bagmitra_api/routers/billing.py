"""What the signed-in user may use (billing addendum §2.4). The app downloads a snapshot, caches
it for offline use and never decides entitlements itself. A Play purchase is unlocked only after
the server verified it with Google (`POST /v1/billing/google/verify`)."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.billing.entitlements import ROLE_PLAN_PREFIX
from bagmitra_api.billing.models import Subscription
from bagmitra_api.billing.play import PlayError, PlayPublisher, play_publisher
from bagmitra_api.billing.purchases import (
    AccountMismatchError,
    TokenOwnedError,
    UnknownProductError,
    account_id,
    sync_purchase,
)
from bagmitra_api.billing.service import entitlements_for, snapshot_for
from bagmitra_api.billing.switch import load_policy, user_roles
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.check import RateLimiter

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


# Play's price-change states that still need the in-app notice (spec §7); APPLIED and CANCELED
# do not, and neither does a decrease (it reaches the subscriber at the next payment by itself).
NOTICE_STATES = ("OUTSTANDING", "CONFIRMED")


class PriceChangeOut(BaseModel):
    # OUTSTANDING (not yet accepted) or CONFIRMED, as Play reports it.
    state: str | None
    # PRICE_INCREASE (opt-in) or OPT_OUT_PRICE_INCREASE; decreases need no notice.
    mode: str | None = None
    new_price_paise: int
    currency: str | None
    charge_time: str | None


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
    # Passed to Play's billing flow as the obfuscated account id (never the user id itself).
    account_id: str
    # A price change Play announced for the user's subscription: the app must show a notice.
    price_change: PriceChangeOut | None


class VerifyIn(BaseModel):
    purchase_token: str = Field(min_length=10, max_length=1000)


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
        account_id=account_id(user.id),
        price_change=await _price_change(session, user.id),
    )


async def _price_change(session: DbSession, user_id: uuid.UUID) -> PriceChangeOut | None:
    rows = await session.scalars(
        select(Subscription).where(
            Subscription.subject_id == user_id,
            Subscription.provider == "google_play",
            Subscription.state.in_(("ACTIVE", "IN_GRACE_PERIOD")),
            Subscription.price_change.is_not(None),
        )
    )
    for row in rows:
        change = row.price_change or {}
        if change.get("state") in NOTICE_STATES and change.get("mode") != "PRICE_DECREASE":
            return PriceChangeOut.model_validate(change)
    return None


def get_verify_limiter(request: Request, settings: AppSettings) -> RateLimiter:
    limiter: RateLimiter | None = getattr(request.app.state, "billing_verify_limiter", None)
    if limiter is None:
        limiter = RateLimiter(settings.billing_verify_rate_limit, 3600)
        request.app.state.billing_verify_limiter = limiter
    return limiter


@router.post(
    "/google/verify",
    operation_id="billing_google_verify",
    responses={
        403: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
        429: {"model": ErrorResponse},
        502: {"model": ErrorResponse},
        503: {"model": ErrorResponse},
    },
)
async def verify(  # noqa: PLR0913 - body and dependencies
    body: VerifyIn,
    user: CurrentUser,
    session: DbSession,
    settings: AppSettings,
    play: Annotated[PlayPublisher | None, Depends(play_publisher)],
    limiter: Annotated[RateLimiter, Depends(get_verify_limiter)],
) -> EntitlementsResponse:
    """The app sends the purchase token; only after Google confirms it does the snapshot
    change. The server acknowledges the purchase."""
    if not limiter.allow(str(user.id)):
        raise ApiError(429, "rate_limited", "too many checks; try again later")
    if play is None:
        raise ApiError(503, "play_not_set_up", "Google Play is not set up yet")
    try:
        await sync_purchase(
            session,
            play,
            body.purchase_token,
            subject_id=user.id,
            now=datetime.now(UTC),
            product_prefix=settings.play_product_prefix,
        )
    except TokenOwnedError as exc:
        raise ApiError(409, "token_in_use", "this purchase belongs to another account") from exc
    except AccountMismatchError as exc:
        raise ApiError(
            403, "account_mismatch", "this purchase was made for another account"
        ) from exc
    except UnknownProductError as exc:
        raise ApiError(422, "unknown_product", "not a BagMitra subscription") from exc
    except PlayError as exc:
        raise ApiError(502, "play_error", "Google Play could not confirm the purchase") from exc
    return await entitlements(user, session, settings)
