"""Trust and safety shared by the user and admin routers (spec v1.5 §4, §4C; L6): who a
report or action is about, and report / appeal photos.
"""

from __future__ import annotations

import uuid
from typing import Any

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.errors import ApiError
from bagmitra_api.market_link.models import (
    BrokerProfile,
    BuyerProfile,
    MarketLot,
    Rating,
    ServiceProvider,
)
from bagmitra_api.market_link.photos import JPEG_BODY, clean_jpeg, store_jpeg
from bagmitra_api.routers.scouting_photos import PhotoContext

# Report / action target -> (model, column naming the user it is about).
TARGETS: dict[str, tuple[type[Any], str]] = {
    "buyer": (BuyerProfile, "user_id"),
    "broker": (BrokerProfile, "user_id"),
    "provider": (ServiceProvider, "user_id"),
    "lot": (MarketLot, "owner_id"),
    "rating": (Rating, "rater_id"),
}


async def subject_user(
    session: AsyncSession, subject_type: str, subject_id: uuid.UUID
) -> uuid.UUID | None:
    """The user a subject belongs to (None for an admin-added provider); 404 if it is absent.
    A `user` subject is the user id itself."""
    if subject_type == "user":
        return subject_id
    model, column = TARGETS[subject_type]
    row = await session.get(model, subject_id)
    if row is None:
        raise ApiError(404, "subject_not_found")
    owner: uuid.UUID | None = getattr(row, column)
    return owner


async def store_photo(request: Request, ctx: PhotoContext, key: str) -> None:
    """Stores one JPEG through the server with its metadata (EXIF GPS point, phone, time)
    stripped first (spec v1.5 §4B; L3's `market_link/photos.py`): no signed upload URL."""
    if ctx.storage is None:
        raise ApiError(503, "photo_backup_not_configured", "photo storage not configured")
    await store_jpeg(ctx, key, await clean_jpeg(request, ctx))


PHOTO_BODY = JPEG_BODY
