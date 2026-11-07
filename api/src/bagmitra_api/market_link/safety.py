"""Trust and safety shared by the user and admin routers (spec v1.5 §4, §4C; L6): who a
report or action is about, the action log, the grievance timeline and report / appeal photos.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta
from typing import Any

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings
from bagmitra_api.market_link.models import (
    AdminAction,
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


def new_action(  # noqa: PLR0913 - one log row
    *,
    subject_type: str,
    subject_id: uuid.UUID,
    user_id: uuid.UUID | None,
    action: str,
    reason_code: str,
    actor_id: uuid.UUID,
    now: datetime,
) -> AdminAction:
    return AdminAction(
        id=uuid.uuid4(),
        subject_type=subject_type,
        subject_id=subject_id,
        user_id=user_id,
        action=action,
        reason_code=reason_code,
        actor_id=actor_id,
        acted_at=now,
        appeal_state="none",
        appeal_photo_keys=[],
        created_at=now,
        updated_at=now,
    )


def overdue(
    settings: Settings,
    now: datetime,
    since: datetime | None,
    acknowledged_at: datetime | None,
    closed: bool,
) -> tuple[bool, bool]:
    """(acknowledgement overdue, closing overdue) for a complaint received at `since`."""
    if since is None:
        return False, False
    if since.tzinfo is None:  # SQLite returns naive UTC
        since = since.replace(tzinfo=now.tzinfo)
    ack_late = acknowledged_at is None and now - since > timedelta(
        hours=settings.market_link_ack_hours
    )
    close_late = not closed and now - since > timedelta(days=settings.market_link_close_days)
    return ack_late and not closed, close_late


async def store_photo(request: Request, ctx: PhotoContext, key: str) -> None:
    """Stores one JPEG through the server with its metadata (EXIF GPS point, phone, time)
    stripped first (spec v1.5 §4B; L3's `market_link/photos.py`): no signed upload URL."""
    if ctx.storage is None:
        raise ApiError(503, "photo_backup_not_configured", "photo storage not configured")
    await store_jpeg(ctx, key, await clean_jpeg(request, ctx))


PHOTO_BODY = JPEG_BODY
