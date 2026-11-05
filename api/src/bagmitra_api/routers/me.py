from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from typing import Annotated

import httpx
import structlog
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from bagmitra_api.account.auth_admin import AuthAdmin, SupabaseAuthAdmin
from bagmitra_api.account.erase import erase_account
from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer
from bagmitra_api.db.session import DbSession
from bagmitra_api.photos.storage import PhotoStorage, PhotoStorageError
from bagmitra_api.routers.scouting_photos import get_photo_storage

router = APIRouter(prefix="/v1", tags=["profile"])
log = structlog.get_logger("bagmitra.account")


class FarmerProfile(BaseModel):
    id: uuid.UUID
    phone: str | None
    display_name: str | None
    language: str
    village: str | None
    taluka: str | None
    district: str | None
    consent_data_processing: bool
    consent_whatsapp: bool


@router.get(
    "/me",
    operation_id="me_get",
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)
async def get_me(user: CurrentUser, session: DbSession) -> FarmerProfile:
    farmer = await session.get(Farmer, user.id)
    if farmer is None:
        raise ApiError(404, "profile_not_found", "complete onboarding first")
    return FarmerProfile.model_validate(farmer, from_attributes=True)


class AccountDeleted(BaseModel):
    """The server holds none of the grower's records or photos any more.
    `sign_in_account_removed` is false when the sign-in account is left for the owner to
    remove by hand (no service role key configured, or Supabase did not answer)."""

    rows_deleted: int
    photos_deleted: int
    sign_in_account_removed: bool


async def get_auth_admin(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[AuthAdmin | None]:
    """The Supabase Auth admin client, or None without SUPABASE_URL + service role key."""
    if not settings.auth_admin_enabled:
        yield None
        return
    async with httpx.AsyncClient(timeout=settings.supabase_admin_timeout_seconds) as http:
        yield SupabaseAuthAdmin(
            http,
            base_url=settings.supabase_url,
            service_key=settings.supabase_service_role_key.get_secret_value(),
        )


@router.delete(
    "/me",
    operation_id="me_delete",
    responses={401: {"model": ErrorResponse}, 502: {"model": ErrorResponse}},
)
async def delete_me(
    user: CurrentUser,
    session: DbSession,
    storage: Annotated[PhotoStorage | None, Depends(get_photo_storage)],
    auth_admin: Annotated[AuthAdmin | None, Depends(get_auth_admin)],
) -> AccountDeleted:
    """Erase the caller's account: every record, the sync history, devices, notice receipts,
    backed-up photos and (when configured) the sign-in account. It cannot be undone."""
    try:
        result = await erase_account(session, user.id, storage=storage, auth_admin=auth_admin)
    except PhotoStorageError as exc:
        log.warning("account_photo_delete_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable", "try again later") from exc
    return AccountDeleted(
        rows_deleted=result.rows_deleted,
        photos_deleted=result.photos_deleted,
        sign_in_account_removed=result.sign_in_account_removed,
    )
