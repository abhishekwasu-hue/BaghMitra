"""In-app feedback (owner 2026-11-08): `POST /v1/feedback` from the app (idempotent on the
phone's id, so the offline queue may retry), an optional screenshot (JPEG, metadata stripped,
stored at `<owner_id>/feedback-<id>.jpg` so the account erasure removes it), and the admin
list for role `feedback_admin`."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, Request, Response
from pydantic import BaseModel, Field
from sqlalchemy import select

from bagmitra_api.auth.jwt import AuthenticatedUser, CurrentUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.base import as_utc
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.check import RateLimiter
from bagmitra_api.feedback.models import AppFeedback
from bagmitra_api.market_link.photos import JPEG_BODY, clean_jpeg, store_jpeg
from bagmitra_api.photos.storage import PhotoStorageError
from bagmitra_api.routers.scouting_photos import PhotoContext, get_photo_context

router = APIRouter(prefix="/v1", tags=["feedback"], responses={401: {"model": ErrorResponse}})
FEEDBACK_ADMIN = "feedback_admin"
Admin = Annotated[AuthenticatedUser, Depends(require_role(FEEDBACK_ADMIN))]
Photo = Annotated[PhotoContext, Depends(get_photo_context)]
Kind = Literal["problem", "suggestion", "question"]
Status = Literal["new", "seen", "done"]
SIGNED_URL_SECONDS = 600
_LIMIT = RateLimiter(20, 3600)  # per user per hour


class FeedbackIn(BaseModel):
    client_id: uuid.UUID
    kind: Kind
    # Code points (pydantic); the app limits 2000 letters, a Marathi letter is up to 4 code
    # points (audit M1).
    text: str = Field(min_length=1, max_length=8000)
    app_version: str = Field(min_length=1, max_length=40)
    device: str = Field(min_length=1, max_length=120)


class FeedbackOut(BaseModel):
    id: uuid.UUID
    kind: str
    text: str
    app_version: str
    device: str
    status: str
    created_at: datetime
    screenshot_url: str | None = None


class FeedbackList(BaseModel):
    feedback: list[FeedbackOut]


class StatusIn(BaseModel):
    status: Status


def _out(row: AppFeedback, url: str | None = None) -> FeedbackOut:
    return FeedbackOut(
        id=row.id,
        kind=row.kind,
        text=row.text,
        app_version=row.app_version,
        device=row.device,
        status=row.status,
        created_at=as_utc(row.created_at),
        screenshot_url=url,
    )


@router.post(
    "/feedback",
    operation_id="feedback_send",
    status_code=201,
    responses={429: {"model": ErrorResponse}},
)
async def send(body: FeedbackIn, user: CurrentUser, session: DbSession) -> FeedbackOut:
    row = await session.get(AppFeedback, body.client_id)
    if row is not None:
        if row.owner_id != user.id:
            raise ApiError(409, "feedback_id_taken", "send a new id")
        return _out(row)
    if not _LIMIT.allow(str(user.id)):
        raise ApiError(429, "rate_limited", "too many messages; try again later")
    row = AppFeedback(
        id=body.client_id,
        owner_id=user.id,
        **body.model_dump(exclude={"client_id"}),
        status="new",
    )
    session.add(row)
    await session.commit()
    return _out(row)


@router.put(
    "/feedback/{feedback_id}/screenshot",
    operation_id="feedback_screenshot",
    status_code=204,
    openapi_extra=JPEG_BODY,
    responses={404: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
async def screenshot(
    feedback_id: uuid.UUID, request: Request, user: CurrentUser, session: DbSession, ctx: Photo
) -> Response:
    row = await session.get(AppFeedback, feedback_id)
    if row is None or row.owner_id != user.id:
        raise ApiError(404, "feedback_not_found")
    data = await clean_jpeg(request, ctx)
    key = f"{user.id}/feedback-{row.id}.jpg"
    await store_jpeg(ctx, key, data)
    row.screenshot_key = key
    await session.commit()
    return Response(status_code=204)


@router.get("/admin/feedback", operation_id="admin_feedback_list", tags=["admin"])
async def admin_list(
    _: Admin,
    session: DbSession,
    ctx: Photo,
    status: Annotated[Status | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 200,
) -> FeedbackList:
    query = select(AppFeedback).order_by(AppFeedback.created_at.desc()).limit(limit)
    if status is not None:
        query = query.where(AppFeedback.status == status)
    out: list[FeedbackOut] = []
    for row in await session.scalars(query):
        url = None
        if row.screenshot_key and ctx.storage is not None:
            try:
                signed = await ctx.storage.signed_download_url(
                    row.screenshot_key, SIGNED_URL_SECONDS
                )
                url = signed.url
            except PhotoStorageError:
                url = None  # the list still shows the text
        out.append(_out(row, url))
    return FeedbackList(feedback=out)


@router.put(
    "/admin/feedback/{feedback_id}",
    operation_id="admin_feedback_status",
    tags=["admin"],
    responses={404: {"model": ErrorResponse}},
)
async def admin_status(
    feedback_id: uuid.UUID, body: StatusIn, _: Admin, session: DbSession
) -> FeedbackOut:
    row = await session.get(AppFeedback, feedback_id)
    if row is None:
        raise ApiError(404, "feedback_not_found")
    row.status = body.status
    await session.commit()
    return _out(row)
