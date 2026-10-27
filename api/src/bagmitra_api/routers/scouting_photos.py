"""Optional scouting photo backup (OPEN_QUESTIONS Q34): signed URLs for a private bucket.

Unless PHOTO_STORAGE_URL and PHOTO_STORAGE_SERVICE_KEY are set, both endpoints answer 503
`photo_backup_not_configured` and the app keeps photos on the phone only. The
object path is always `<owner_id>/<record_id>.jpg`, derived here and never taken from the
client. The record must be the caller's own, live scouting record.
"""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from dataclasses import dataclass
from typing import Annotated, Final, Literal

import httpx
import structlog
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import ScoutingRecord
from bagmitra_api.db.session import DbSession
from bagmitra_api.photos.storage import (
    PhotoNotFoundError,
    PhotoStorage,
    PhotoStorageError,
    SupabaseStorageClient,
)

router = APIRouter(prefix="/v1", tags=["scouting"])
log = structlog.get_logger("bagmitra.photos")

PHOTO_CONTENT_TYPE: Final = "image/jpeg"


def photo_key_for(owner_id: uuid.UUID, record_id: uuid.UUID) -> str:
    return f"{owner_id}/{record_id}.jpg"


async def get_photo_storage(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[PhotoStorage | None]:
    """The configured storage, or None when photo backup is off."""
    if not settings.photo_storage_enabled:
        yield None
        return
    async with httpx.AsyncClient(timeout=settings.photo_storage_timeout_seconds) as http:
        yield SupabaseStorageClient(
            http,
            base_url=settings.photo_storage_url,
            bucket=settings.photo_storage_bucket,
            service_key=settings.photo_storage_service_key.get_secret_value(),
        )


@dataclass(frozen=True)
class PhotoContext:
    settings: Settings
    storage: PhotoStorage | None


def get_photo_context(
    settings: Annotated[Settings, Depends(get_settings)],
    storage: Annotated[PhotoStorage | None, Depends(get_photo_storage)],
) -> PhotoContext:
    return PhotoContext(settings, storage)


class PhotoUploadIn(BaseModel):
    content_type: Literal["image/jpeg"] = PHOTO_CONTENT_TYPE
    size_bytes: int = Field(gt=0)


class PhotoUploadUrl(BaseModel):
    upload_url: str
    photo_key: str
    expires_in: int
    content_type: str = PHOTO_CONTENT_TYPE
    max_bytes: int


class PhotoDownloadUrl(BaseModel):
    url: str
    photo_key: str
    expires_in: int


def _configured(storage: PhotoStorage | None) -> PhotoStorage:
    if storage is None:
        raise ApiError(503, "photo_backup_not_configured", "photo backup not configured")
    return storage


async def _own_record(
    session: DbSession, user: CurrentUser, record_id: uuid.UUID
) -> ScoutingRecord:
    record = await session.get(ScoutingRecord, record_id)
    if record is None or record.owner_id != user.id or record.deleted_at is not None:
        raise ApiError(404, "scouting_record_not_found")
    return record


_RESPONSES: dict[int | str, dict[str, object]] = {
    401: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    413: {"model": ErrorResponse},
    502: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}


@router.post(
    "/scouting/{record_id}/photo-upload-url",
    operation_id="scouting_photo_upload_url",
    responses=_RESPONSES,
)
async def create_photo_upload_url(
    record_id: uuid.UUID,
    body: PhotoUploadIn,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoUploadUrl:
    """A signed upload URL for this record's photo (JPEG only, at most `max_bytes`).

    The phone PUTs the file to `upload_url` with `Content-Type: image/jpeg`, then records
    `photo_key` on the scouting record through the normal outbox.
    """
    configured = _configured(ctx.storage)
    record = await _own_record(session, user, record_id)
    if body.size_bytes > ctx.settings.photo_max_bytes:
        raise ApiError(413, "photo_too_large", f"at most {ctx.settings.photo_max_bytes} bytes")
    key = photo_key_for(record.owner_id, record.id)
    try:
        signed = await configured.signed_upload_url(key)
    except PhotoStorageError as exc:
        log.warning("photo_upload_sign_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable") from exc
    return PhotoUploadUrl(
        upload_url=signed.url,
        photo_key=key,
        expires_in=signed.expires_in,
        max_bytes=ctx.settings.photo_max_bytes,
    )


@router.get(
    "/scouting/{record_id}/photo-url",
    operation_id="scouting_photo_url",
    responses=_RESPONSES,
)
async def get_photo_url(
    record_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoDownloadUrl:
    """A short-lived signed download URL for a backed-up photo."""
    configured = _configured(ctx.storage)
    record = await _own_record(session, user, record_id)
    if not record.photo_key:
        raise ApiError(404, "photo_not_found")
    expires = ctx.settings.photo_download_expiry_seconds
    try:
        signed = await configured.signed_download_url(record.photo_key, expires)
    except PhotoNotFoundError as exc:
        raise ApiError(404, "photo_not_found") from exc
    except PhotoStorageError as exc:
        log.warning("photo_download_sign_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable") from exc
    return PhotoDownloadUrl(
        url=signed.url, photo_key=record.photo_key, expires_in=signed.expires_in
    )
