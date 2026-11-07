"""Market linkage lots (spec v1.5 §3 steps 1-2, build prompt L3). Behind the legal gate
(decision j): every path answers 404 while `market_link_enabled` is off.

A grower drafts a lot and its photos offline (sync entities `market_lot`,
`market_lot_photo`); publishing and closing are online calls here, so a lot is never shown
to buyers from a queued write. Lot photos use the scouting photo bucket and its signed URLs
(key `<owner_id>/<photo_id>.jpg`, derived here); they are uploaded through the server,
which strips EXIF first (spec v1.5 §4B). Only admin-verified buyers and brokers list
published lots (decision h), and only the lots `lot_visible_to_traders` allows (season
package, §4E). They see exactly the §4E fields: first name, crop / variety, orchard acres,
tonnes, quality, photos, harvest window and district; never the surname, phone, village, plot
or the photos' GPS points (decision g: those wait for an accepted interest, L4).
"""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import UTC, date, datetime
from typing import Annotated

import structlog
from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer, Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import is_verified_viewer
from bagmitra_api.market_link.models import (
    LOT_MAX_PHOTOS,
    LOT_MIN_PHOTOS,
    MarketLot,
    MarketLotPhoto,
)
from bagmitra_api.market_link.orchard import orchard_check
from bagmitra_api.market_link.package import lot_shown, lot_visible_to_traders, package_on
from bagmitra_api.market_link.terms import require_role_accepted
from bagmitra_api.photos.exif import NotJpegError, strip_jpeg_metadata
from bagmitra_api.photos.storage import PhotoNotFoundError, PhotoStorage, PhotoStorageError
from bagmitra_api.routers.market_link import require_market_link
from bagmitra_api.routers.scouting_photos import (
    PHOTO_CONTENT_TYPE,
    PhotoContext,
    get_photo_context,
    photo_key_for,
)
from bagmitra_api.sync.service import record_server_write
from bagmitra_api.weather.service import get_clock

router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
log = structlog.get_logger("bagmitra.market_lots")
LOT_ENTITY = "market_lot"
# Every grower write here (publish, close, photo upload) needs the grower role's accepted
# terms, privacy notice and disclaimer with 18+ (spec v1.5 §4C, L1a); lot drafts too, in
# sync/registry.py `_grower_may_write`.
GROWER_WRITE = [Depends(require_role_accepted("grower"))]
# Published lots per page of the buyer list.
LOT_PAGE = 100
SQ_M_PER_ACRE = 4046.8564224
Clock = Annotated[Callable[[], datetime], Depends(get_clock)]


class GrowerLotOut(BaseModel):
    """The server-set state of the grower's own lot after publish / close."""

    id: uuid.UUID
    status: str
    published_at: datetime | None
    # inside / near: shown to traders; outside / unmapped: waits for an admin check (§4C).
    orchard_check: str | None
    crop: str
    variety: str | None
    village: str | None
    taluka: str | None
    district: str | None


class LotPhotoView(BaseModel):
    """A lot photo as a buyer sees it: no GPS point (it would show where the plot is)."""

    id: uuid.UUID
    captured_at: datetime


class BuyerLotOut(BaseModel):
    """A published lot for a verified buyer / broker: exactly the fields of spec v1.5 §4E.
    The grower's first name only; no surname, owner, phone, village, plot or point (decision
    g); `acres` is the plot's area."""

    id: uuid.UUID
    first_name: str | None
    crop: str
    variety: str | None
    acres: float | None
    quantity_t: float
    quality: str | None
    harvest_from: date
    harvest_to: date
    district: str | None
    published_at: datetime
    photos: list[LotPhotoView]


def first_name(display_name: str | None) -> str | None:
    """The first word of the grower's name (§4E: never the surname)."""
    words = (display_name or "").split()
    return words[0] if words else None


class BuyerLotsResponse(BaseModel):
    lots: list[BuyerLotOut]


async def _own_lot(session: DbSession, user: CurrentUser, lot_id: uuid.UUID) -> MarketLot:
    lot = await session.get(MarketLot, lot_id)
    if lot is None or lot.owner_id != user.id or lot.deleted_at is not None:
        raise ApiError(404, "lot_not_found")
    return lot


async def _live_photos(session: DbSession, lot_id: uuid.UUID) -> list[MarketLotPhoto]:
    rows = await session.scalars(
        select(MarketLotPhoto)
        .where(MarketLotPhoto.lot_id == lot_id, MarketLotPhoto.deleted_at.is_(None))
        .order_by(MarketLotPhoto.captured_at, MarketLotPhoto.id)
    )
    return list(rows)


async def _server_write(session: DbSession, user: CurrentUser, lot: MarketLot, action: str) -> None:
    """Record the change so the grower's phones pull the new state (sync LD-08)."""
    audit = await record_server_write(session, user, LOT_ENTITY, str(lot.id), action)
    lot.last_seq = audit.seq
    lot.client_updated_at = audit.client_updated_at


def _grower_view(lot: MarketLot) -> GrowerLotOut:
    return GrowerLotOut.model_validate(lot, from_attributes=True)


@router.post(
    "/lots/{lot_id}/publish", operation_id="market_link_publish_lot", dependencies=GROWER_WRITE
)
async def publish_lot(
    lot_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
) -> GrowerLotOut:
    """Shows a draft lot to verified buyers and brokers. Needs 3 to 8 live photos, each
    uploaded; crop and variety are copied from the plot again and the place names from the
    grower's profile (village, taluka, district; never the plot's point)."""
    lot = await _own_lot(session, user, lot_id)
    if lot.status != "draft":
        raise ApiError(409, "lot_not_draft")
    plot = await session.get(Plot, lot.plot_id)
    if plot is None or plot.owner_id != user.id or plot.deleted_at is not None:
        raise ApiError(409, "plot_not_found")
    photos = await _live_photos(session, lot.id)
    if not LOT_MIN_PHOTOS <= len(photos) <= LOT_MAX_PHOTOS:
        raise ApiError(
            422,
            "lot_photos_needed",
            f"a lot needs {LOT_MIN_PHOTOS} to {LOT_MAX_PHOTOS} photos, it has {len(photos)}",
        )
    if any(p.photo_key != photo_key_for(user.id, p.id) for p in photos):
        raise ApiError(422, "lot_photos_not_uploaded")
    centroid = (
        None
        if plot.centroid_lat is None or plot.centroid_lon is None
        else (plot.centroid_lat, plot.centroid_lon)
    )
    check = orchard_check(
        ((p.lat, p.lon) for p in photos),
        plot.boundary,
        centroid,
        settings.market_link_orchard_near_m,
    )
    # Spec §4C: a lot whose photos are not inside / near the mapped plot is published but
    # stays out of the traders' list until an admin checks it (admin side later).
    lot.orchard_check = check
    farmer = await session.get(Farmer, user.id)
    lot.crop, lot.variety = plot.crop, plot.variety
    lot.village = farmer.village if farmer else None
    lot.taluka = farmer.taluka if farmer else None
    lot.district = farmer.district if farmer else None
    lot.status = "published"
    lot.published_at = datetime.now(UTC)
    await _server_write(session, user, lot, "publish")
    await session.commit()
    return _grower_view(lot)


@router.post(
    "/lots/{lot_id}/close", operation_id="market_link_close_lot", dependencies=GROWER_WRITE
)
async def close_lot(lot_id: uuid.UUID, user: CurrentUser, session: DbSession) -> GrowerLotOut:
    """Takes a published lot off the buyers' list (the grower sold it or changed their mind)."""
    lot = await _own_lot(session, user, lot_id)
    if lot.status != "published":
        raise ApiError(409, "lot_not_published")
    lot.status = "closed"
    await _server_write(session, user, lot, "close")
    await session.commit()
    return _grower_view(lot)


@router.get("/lots", operation_id="market_link_lots")
async def list_lots(  # noqa: PLR0913 - query parameters and dependencies
    user: CurrentUser,
    session: DbSession,
    clock: Clock,
    district: Annotated[str | None, Query(max_length=120)] = None,
    crop: Annotated[str | None, Query(max_length=32)] = None,
    before: Annotated[datetime | None, Query()] = None,
) -> BuyerLotsResponse:
    """Published lots, newest first, for admin-verified buyers and brokers only (403
    `not_verified` for anyone else); while the season package is ON, only lots with an active
    package (§4E). Page with `before` = the last `published_at` seen."""
    if not await is_verified_viewer(session, user.id):
        raise ApiError(403, "not_verified")
    rule = lot_visible_to_traders(MarketLot, clock(), await package_on(session))
    query = (
        select(MarketLot, Farmer.display_name, Plot.area_sq_m)
        .outerjoin(Farmer, Farmer.id == MarketLot.owner_id)
        .outerjoin(Plot, Plot.id == MarketLot.plot_id)
        .where(rule)
    )
    for column, value in ((MarketLot.district, district), (MarketLot.crop, crop)):
        if value:
            query = query.where(column == value)
    if before is not None:
        query = query.where(MarketLot.published_at < before)
    rows = list(
        (
            await session.execute(
                query.order_by(MarketLot.published_at.desc(), MarketLot.id).limit(LOT_PAGE)
            )
        ).tuples()
    )
    photos: dict[uuid.UUID, list[LotPhotoView]] = {lot.id: [] for lot, _, _ in rows}
    if rows:
        found = await session.scalars(
            select(MarketLotPhoto)
            .where(MarketLotPhoto.lot_id.in_(photos), MarketLotPhoto.deleted_at.is_(None))
            .order_by(MarketLotPhoto.captured_at, MarketLotPhoto.id)
        )
        for p in found:
            if p.photo_key == photo_key_for(p.owner_id, p.id):
                photos[p.lot_id].append(LotPhotoView(id=p.id, captured_at=p.captured_at))
    plain = ("id", "crop", "variety", "quantity_t", "quality", "harvest_from", "harvest_to")
    return BuyerLotsResponse(
        lots=[
            BuyerLotOut(
                **{f: getattr(lot, f) for f in (*plain, "district", "published_at")},
                first_name=first_name(name),
                acres=None if area is None else round(area / SQ_M_PER_ACRE, 1),
                photos=photos[lot.id],
            )
            for lot, name, area in rows
        ]
    )


def _storage(ctx: PhotoContext) -> PhotoStorage:
    if ctx.storage is None:
        raise ApiError(503, "photo_backup_not_configured", "photo backup not configured")
    return ctx.storage


_PHOTO_RESPONSES: dict[int | str, dict[str, object]] = {
    413: {"model": ErrorResponse},
    415: {"model": ErrorResponse},
    502: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}


class LotPhotoStored(BaseModel):
    """The stored photo's key, to record on the photo through the outbox."""

    photo_key: str


class LotPhotoUrl(BaseModel):
    """A short-lived link to a lot photo (no key, no point: spec v1.5 §4B)."""

    url: str
    expires_in: int


@router.put(
    "/lot-photos/{photo_id}/photo",
    operation_id="market_link_upload_lot_photo",
    responses=_PHOTO_RESPONSES,
    dependencies=GROWER_WRITE,
    openapi_extra={
        "requestBody": {
            "required": True,
            "content": {PHOTO_CONTENT_TYPE: {"schema": {"type": "string", "format": "binary"}}},
        }
    },
)
async def upload_lot_photo(
    photo_id: uuid.UUID,
    request: Request,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
) -> LotPhotoStored:
    """Uploads one JPEG of the caller's own draft lot through the server, which strips its
    EXIF (GPS point, phone model, time) before storing it (spec v1.5 §4B). There is no signed
    upload URL for lot photos, so no stored lot photo can keep its metadata."""
    storage = _storage(ctx)
    photo = await session.get(MarketLotPhoto, photo_id)
    if photo is None or photo.owner_id != user.id or photo.deleted_at is not None:
        raise ApiError(404, "lot_photo_not_found")
    lot = await _own_lot(session, user, photo.lot_id)
    if lot.status != "draft":
        raise ApiError(409, "lot_not_draft")
    if request.headers.get("content-type", "").split(";")[0].strip() != PHOTO_CONTENT_TYPE:
        raise ApiError(415, "photo_not_jpeg")
    data = await request.body()
    if len(data) > ctx.settings.photo_max_bytes:
        raise ApiError(413, "photo_too_large", f"at most {ctx.settings.photo_max_bytes} bytes")
    try:
        clean = strip_jpeg_metadata(data)
    except NotJpegError as exc:
        raise ApiError(415, "photo_not_jpeg") from exc
    key = photo_key_for(user.id, photo.id)
    try:
        await storage.upload_object(key, clean, PHOTO_CONTENT_TYPE)
    except PhotoStorageError as exc:
        log.warning("lot_photo_upload_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable") from exc
    return LotPhotoStored(photo_key=key)


@router.get(
    "/lot-photos/{photo_id}/url",
    operation_id="market_link_lot_photo_url",
    responses=_PHOTO_RESPONSES,
)
async def lot_photo_url(
    photo_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    ctx: Annotated[PhotoContext, Depends(get_photo_context)],
    clock: Clock,
) -> LotPhotoUrl:
    """A short-lived download URL for an uploaded lot photo: for the grower, or for a
    verified buyer / broker while `lot_visible_to_traders` shows the lot. Only the derived
    key is signed."""
    storage = _storage(ctx)
    photo = await session.get(MarketLotPhoto, photo_id)
    lot = None if photo is None else await session.get(MarketLot, photo.lot_id)
    if photo is None or lot is None or photo.deleted_at is not None or lot.deleted_at is not None:
        raise ApiError(404, "lot_photo_not_found")
    own = photo.owner_id == user.id and lot.owner_id == user.id
    if not own and not (
        await lot_shown(session, lot.id, clock()) and await is_verified_viewer(session, user.id)
    ):
        raise ApiError(404, "lot_photo_not_found")
    key = photo_key_for(photo.owner_id, photo.id)
    if photo.photo_key != key:
        raise ApiError(404, "photo_not_found")
    expires = ctx.settings.photo_download_expiry_seconds
    try:
        signed = await storage.signed_download_url(key, expires)
    except PhotoNotFoundError as exc:
        raise ApiError(404, "photo_not_found") from exc
    except PhotoStorageError as exc:
        log.warning("lot_photo_download_sign_failed", reason=str(exc))
        raise ApiError(502, "photo_storage_unavailable") from exc
    return LotPhotoUrl(url=signed.url, expires_in=signed.expires_in)
