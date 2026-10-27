"""The farmer's own feed state (addendum v1.4 §4.8-4.9, G2): seen / dismissed / "remind me"
per item, and push settings (quiet hours, weekly cap, category opt-out, weekly digest).
Owner data: every row belongs to the signed-in user."""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import datetime, time
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.alerts import DEFAULT_PREFS, MAX_WEEKLY_CAP
from bagmitra_api.feed.models import FeedDeadline, FeedItem, FeedPreferences, FeedReceipt
from bagmitra_api.weather.service import get_clock

router = APIRouter(prefix="/v1", tags=["feed"], responses={401: {"model": ErrorResponse}})
Clock = Annotated[Callable[[], datetime], Depends(get_clock)]
HHMM = r"^([01]\d|2[0-3]):[0-5]\d$"
PushCategory = Literal["deadline", "payment", "window_open"]
ERRORS: dict[int | str, dict[str, object]] = {
    404: {"model": ErrorResponse},
    409: {"model": ErrorResponse},
}


class FeedPreferencesBody(BaseModel):
    """Quiet hours are India local times "HH:MM" (start inclusive, end exclusive; equal
    means no quiet hours). `weekly_cap` counts alert pushes in any rolling 7 days."""

    quiet_start: str = Field(pattern=HHMM)
    quiet_end: str = Field(pattern=HHMM)
    weekly_cap: int = Field(ge=0, le=MAX_WEEKLY_CAP)
    opted_out: list[PushCategory] = Field(default_factory=list, max_length=3)
    digest_weekly: bool


class FeedReceiptOut(BaseModel):
    item_id: uuid.UUID
    seen: bool
    dismissed: bool
    remind: bool


def _hhmm(value: time) -> str:
    return value.strftime("%H:%M")


def _time(value: str) -> time:
    hours, minutes = value.split(":")
    return time(int(hours), int(minutes))


def _prefs_out(row: FeedPreferences | None) -> FeedPreferencesBody:
    if row is None:
        return FeedPreferencesBody(
            quiet_start=_hhmm(DEFAULT_PREFS.quiet_start),
            quiet_end=_hhmm(DEFAULT_PREFS.quiet_end),
            weekly_cap=DEFAULT_PREFS.weekly_cap,
            opted_out=[],
            digest_weekly=DEFAULT_PREFS.digest_weekly,
        )
    return FeedPreferencesBody(
        quiet_start=_hhmm(row.quiet_start),
        quiet_end=_hhmm(row.quiet_end),
        weekly_cap=row.weekly_cap,
        opted_out=list(row.opted_out),  # validated on write
        digest_weekly=row.digest_weekly,
    )


@router.get("/me/feed-preferences", operation_id="feed_preferences_get")
async def get_preferences(user: CurrentUser, session: DbSession) -> FeedPreferencesBody:
    """The caller's settings, or the defaults (21:00-07:00, 3 a week, digest on)."""
    return _prefs_out(await session.get(FeedPreferences, user.id))


@router.put(
    "/me/feed-preferences",
    operation_id="feed_preferences_put",
    responses={422: {"model": ErrorResponse}},
)
async def put_preferences(
    body: FeedPreferencesBody, user: CurrentUser, session: DbSession
) -> FeedPreferencesBody:
    row = await session.get(FeedPreferences, user.id)
    if row is None:
        row = FeedPreferences(owner_id=user.id)
        session.add(row)
    row.quiet_start = _time(body.quiet_start)
    row.quiet_end = _time(body.quiet_end)
    row.weekly_cap = body.weekly_cap
    row.opted_out = sorted(set(body.opted_out))
    row.digest_weekly = body.digest_weekly
    await session.commit()
    return _prefs_out(row)


async def _receipt(session: AsyncSession, owner: uuid.UUID, item_id: uuid.UUID) -> FeedReceipt:
    item = await session.get(FeedItem, item_id)
    if item is None or item.status not in ("published", "withdrawn"):
        raise ApiError(404, "not_found", "feed item not found")
    row = await session.scalar(
        select(FeedReceipt).where(FeedReceipt.owner_id == owner, FeedReceipt.item_id == item_id)
    )
    if row is None:
        row = FeedReceipt(id=uuid.uuid4(), owner_id=owner, item_id=item_id)
        session.add(row)
    return row


def _out(row: FeedReceipt) -> FeedReceiptOut:
    return FeedReceiptOut(
        item_id=row.item_id,
        seen=row.seen_at is not None,
        dismissed=row.dismissed_at is not None,
        remind=row.remind_requested_at is not None,
    )


@router.post("/feed/{item_id}/seen", operation_id="feed_mark_seen", responses=ERRORS)
async def mark_seen(
    item_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> FeedReceiptOut:
    row = await _receipt(session, user.id, item_id)
    row.seen_at = row.seen_at or clock()
    await session.commit()
    return _out(row)


@router.post("/feed/{item_id}/dismiss", operation_id="feed_dismiss", responses=ERRORS)
async def dismiss(
    item_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> FeedReceiptOut:
    """Hide the item from the caller's pushes (reminders and digest stop for it)."""
    row = await _receipt(session, user.id, item_id)
    row.dismissed_at = row.dismissed_at or clock()
    await session.commit()
    return _out(row)


@router.post("/feed/{item_id}/remind", operation_id="feed_remind", responses=ERRORS)
async def remind(
    item_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> FeedReceiptOut:
    """Record that the caller wants this item's date reminders even if it was not matched to
    their profile; undoes a dismiss. Only for a published item that has a date."""
    row = await _receipt(session, user.id, item_id)
    item = await session.get(FeedItem, item_id)
    if item is not None and item.status == "withdrawn":
        raise ApiError(409, "withdrawn", "the item was withdrawn")
    has_date = await session.scalar(
        select(FeedDeadline.id).where(FeedDeadline.item_id == item_id).limit(1)
    )
    if has_date is None:
        raise ApiError(409, "no_deadline", "the item has no date to remind about")
    row.remind_requested_at = row.remind_requested_at or clock()
    row.dismissed_at = None
    await session.commit()
    return _out(row)
