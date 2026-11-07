"""Market linkage API (spec v1.5). Behind the legal gate `market_link_enabled` (decision j):
while it is off, every /v1/market-link/* path answers 404 before auth runs, as if absent."""

from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.models import RatingTag


async def require_market_link(settings: Annotated[Settings, Depends(get_settings)]) -> None:
    if not settings.market_link_enabled:
        raise ApiError(404, "not_found", "Not Found")


router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)


class RatingTagOut(BaseModel):
    id: uuid.UUID
    key: str
    question_key: str
    polarity: str
    label_mr: str
    label_hi: str
    label_en: str
    sort_order: int


class RatingTagsResponse(BaseModel):
    tags: list[RatingTagOut]


@router.get("/rating-tags", operation_id="market_link_rating_tags")
async def rating_tags(_user: CurrentUser, session: DbSession) -> RatingTagsResponse:
    """The active tick list under each rating question (spec §3A); the app caches it."""
    rows = await session.scalars(
        select(RatingTag)
        .where(RatingTag.status == "active")
        .order_by(RatingTag.question_key, RatingTag.sort_order, RatingTag.key)
    )
    return RatingTagsResponse(
        tags=[RatingTagOut.model_validate(r, from_attributes=True) for r in rows]
    )
