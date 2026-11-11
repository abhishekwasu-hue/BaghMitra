"""Optional backup of the bill photo on a spray record or an expense (OPEN_QUESTIONS Q136).

The same private bucket and signed URLs as the scouting photo backup (Q34): off (503
`photo_backup_not_configured`) unless photo storage is configured, JPEG only, at most
`PHOTO_MAX_BYTES`. The object path is always `<owner_id>/bill-<record_id>.jpg`, derived here
and never taken from the client; the record must be the caller's own, live record.
"""

from __future__ import annotations

import uuid
from typing import Annotated, Literal

import structlog
from fastapi import APIRouter, Depends

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError
from bagmitra_api.db.models import Expense, SprayRecord
from bagmitra_api.db.session import DbSession
from bagmitra_api.photos.storage import PhotoStorageError
from bagmitra_api.routers.scouting_photos import (
    _RESPONSES,
    PhotoContext,
    PhotoDownloadUrl,
    PhotoUploadIn,
    PhotoUploadUrl,
    _configured,
    get_photo_context,
    signed_download,
)

router = APIRouter(prefix="/v1", tags=["bill-photos"])
log = structlog.get_logger("bagmitra.photos")

BillKind = Literal["spray_record", "expense"]


def bill_photo_key_for(owner_id: uuid.UUID, record_id: uuid.UUID) -> str:
    return f"{owner_id}/bill-{record_id}.jpg"


async def _own_record(
    session: DbSession, user: CurrentUser, kind: BillKind, record_id: uuid.UUID
) -> SprayRecord | Expense:
    record: SprayRecord | Expense | None = (
        await session.get(SprayRecord, record_id)
        if kind == "spray_record"
        else await session.get(Expense, record_id)
    )
    if record is None or record.owner_id != user.id or record.deleted_at is not None:
        raise ApiError(404, "record_not_found")
    return record


@router.post(
    "/bill-photos/{kind}/{record_id}/upload-url",
    operation_id="bill_photo_upload_url",
    responses=_RESPONSES,
)
async def create_bill_photo_upload_url(  # noqa: PLR0913 - path, body and dependencies
    kind: BillKind,
    record_id: uuid.UUID,
    body: PhotoUploadIn,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoUploadUrl:
    """A signed upload URL for this record's bill photo (JPEG only, at most `max_bytes`).

    The phone PUTs the file to `upload_url`, then records `photo_key` as the record's
    `bill_photo_key` through the normal outbox.
    """
    configured = _configured(ctx.storage)
    record = await _own_record(session, user, kind, record_id)
    if body.size_bytes > ctx.settings.photo_max_bytes:
        raise ApiError(413, "photo_too_large", f"at most {ctx.settings.photo_max_bytes} bytes")
    key = bill_photo_key_for(record.owner_id, record.id)
    try:
        signed = await configured.signed_upload_url(key)
    except PhotoStorageError as exc:
        log.warning("bill_photo_upload_sign_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable") from exc
    return PhotoUploadUrl(
        upload_url=signed.url,
        photo_key=key,
        expires_in=signed.expires_in,
        max_bytes=ctx.settings.photo_max_bytes,
    )


@router.get(
    "/bill-photos/{kind}/{record_id}/url",
    operation_id="bill_photo_url",
    responses=_RESPONSES,
)
async def get_bill_photo_url(
    kind: BillKind,
    record_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> PhotoDownloadUrl:
    """A short-lived signed download URL for a backed-up bill photo. Only the key derived
    from the caller and the record is ever signed; a stored key that differs is no photo."""
    _configured(ctx.storage)
    record = await _own_record(session, user, kind, record_id)
    key = bill_photo_key_for(user.id, record.id)
    if not record.bill_photo_key or record.bill_photo_key != key:
        raise ApiError(404, "photo_not_found")
    return await signed_download(ctx, key)
