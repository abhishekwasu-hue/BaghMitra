"""What the signed-in user may use (billing addendum §2.4). The app downloads a snapshot, caches
it for offline use and never decides entitlements itself."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.billing.service import snapshot_for
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
