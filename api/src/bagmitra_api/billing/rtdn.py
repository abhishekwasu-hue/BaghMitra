"""Google Play real-time developer notifications (billing addendum §2.2, §2.4).

Play publishes to a Cloud Pub/Sub topic; a push subscription posts each message here with a
Google-signed OIDC token (audience = PLAY_RTDN_AUDIENCE, signer = the push service account
PLAY_RTDN_PUSHER). Runbook: docs/runbooks/billing-play.md.

A notification is only a hint: the server re-fetches the truth from Play
(`purchases.subscriptionsv2.get`) through `sync_purchase`. Each Pub/Sub message id is recorded
once in `billing_events` (`rtdn:<messageId>`), written in the same transaction as its effect, so
a redelivery changes nothing and a failed try leaves nothing behind. Pub/Sub redelivers every
answer that is not 2xx (dead-letter topic per the runbook), so only a temporary failure (Play
down, not set up) answers with an error; a message that can never be handled is acknowledged
and logged.
"""

from __future__ import annotations

import base64
import binascii
import json
import uuid
from datetime import datetime
from typing import Annotated, Any

import httpx
import jwt
import structlog
from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import JwksKeys
from bagmitra_api.billing.models import BillingEvent, Subscription
from bagmitra_api.billing.play import PlayPublisher
from bagmitra_api.billing.purchases import (
    AccountMismatchError,
    UnknownProductError,
    sync_purchase,
    token_hash,
)
from bagmitra_api.core.settings import Settings, get_settings

log = structlog.get_logger(__name__)

GOOGLE_ISSUERS = ("https://accounts.google.com", "accounts.google.com")
SUBSCRIPTION_REVOKED = 12  # SubscriptionNotification.notificationType


class PushRefusedError(Exception):
    """The push did not carry a valid Google OIDC token for this endpoint."""


_KEYS: dict[str, JwksKeys] = {}


def google_oidc_keys(settings: Annotated[Settings, Depends(get_settings)]) -> JwksKeys:
    url = settings.google_oidc_certs_url
    if url not in _KEYS:

        async def fetch() -> dict[str, Any]:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(url)
                response.raise_for_status()
                document: dict[str, Any] = response.json()
                return document

        _KEYS[url] = JwksKeys(fetch)
    return _KEYS[url]


async def check_push_token(authorization: str | None, keys: JwksKeys, settings: Settings) -> None:
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise PushRefusedError("no bearer token")
    try:
        kid = jwt.get_unverified_header(token).get("kid")
        key = await keys.key_for(str(kid)) if kid else None
        if key is None:
            raise PushRefusedError("unknown signing key")
        claims = jwt.decode(
            token,
            key=key,
            algorithms=["RS256"],
            audience=settings.play_rtdn_audience,
            options={"require": ["exp", "iat", "iss", "aud", "email"]},
        )
    except (jwt.PyJWTError, httpx.HTTPError, ValueError, KeyError) as exc:
        raise PushRefusedError(type(exc).__name__) from exc
    if claims.get("iss") not in GOOGLE_ISSUERS:
        raise PushRefusedError("issuer")
    if claims.get("email") != settings.play_rtdn_pusher or claims.get("email_verified") is not True:
        raise PushRefusedError("push service account")


def read_message(body: dict[str, Any]) -> tuple[str, dict[str, Any] | None]:
    """The Pub/Sub message id and the decoded DeveloperNotification (None if unreadable)."""
    raw = body.get("message")
    message: dict[str, Any] = raw if isinstance(raw, dict) else {}
    message_id = str(message.get("messageId") or message.get("message_id") or "")
    try:
        note = json.loads(base64.b64decode(str(message.get("data", "")), validate=True))
    except (binascii.Error, ValueError):
        return message_id, None
    return message_id, note if isinstance(note, dict) else None


def _ledger(session: AsyncSession, message_id: str, event_type: str, **payload: Any) -> None:
    session.add(
        BillingEvent(
            id=uuid.uuid4(),
            subscription_id=payload.pop("subscription_id", None),
            provider="google_play",
            event_type=event_type,
            notification_id=f"rtdn:{message_id}",
            payload=payload,
        )
    )


async def revoke(session: AsyncSession, token: str) -> Subscription | None:
    """Voided or revoked: access ends at once (REVOKED never grants access)."""
    row = await session.scalar(
        select(Subscription).where(Subscription.purchase_token_hash == token_hash(token))
    )
    if row is not None:
        row.state = "REVOKED"
    return row


def _without_play(note: dict[str, Any] | None, settings: Settings) -> str | None:
    """Outcomes that need neither Play nor a stored row."""
    if note is None:
        return "rtdn_unreadable"
    if note.get("packageName") != settings.play_package_name.strip():
        return "rtdn_other_package"
    voided = note.get("voidedPurchaseNotification")
    if isinstance(voided, dict) and voided.get("purchaseToken"):
        return None
    sub = note.get("subscriptionNotification")
    if not isinstance(sub, dict) or not sub.get("purchaseToken"):
        return "rtdn_ignored"  # a test notification or a one-time product
    return None


async def handle(  # noqa: PLR0913 - session, Play, message, settings, clock
    session: AsyncSession,
    play: PlayPublisher,
    message_id: str,
    note: dict[str, Any] | None,
    settings: Settings,
    now: datetime,
) -> str:
    """Apply one notification; returns what was done (also the ledger event type). Raises
    PlayError when Play could not be asked (the caller answers non-2xx so Pub/Sub retries)."""
    seen = select(BillingEvent.id).where(BillingEvent.notification_id == f"rtdn:{message_id}")
    if await session.scalar(seen):
        return "duplicate"
    outcome = _without_play(note, settings)
    if outcome is not None or note is None:
        _ledger(session, message_id, outcome or "rtdn_unreadable")
        return outcome or "rtdn_unreadable"
    voided = note.get("voidedPurchaseNotification")
    if isinstance(voided, dict) and voided.get("purchaseToken"):
        row = await revoke(session, str(voided["purchaseToken"]))
        _ledger(session, message_id, "rtdn_voided", subscription_id=row.id if row else None)
        return "rtdn_voided"
    sub = note["subscriptionNotification"]
    token, kind = str(sub["purchaseToken"]), sub.get("notificationType")
    try:
        row = await sync_purchase(
            session,
            play,
            token,
            subject_id=None,
            now=now,
            product_prefix=settings.play_product_prefix,
        )
    except (UnknownProductError, AccountMismatchError) as exc:
        _ledger(session, message_id, "rtdn_refused", type=kind, reason=type(exc).__name__)
        return "rtdn_refused"
    if row is not None and kind == SUBSCRIPTION_REVOKED:
        row.state = "REVOKED"
    _ledger(
        session,
        message_id,
        "rtdn_applied" if row else "rtdn_unknown_token",
        subscription_id=row.id if row else None,
        type=kind,
    )
    return "rtdn_applied" if row else "rtdn_unknown_token"
