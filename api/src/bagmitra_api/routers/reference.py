"""Read-only reference data (admin-managed config) for the app's offline cache."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.db.models import CropStageTemplate
from bagmitra_api.db.session import DbSession

router = APIRouter(
    prefix="/v1/reference", tags=["reference"], responses={401: {"model": ErrorResponse}}
)


class TemplateStage(BaseModel):
    key: str
    labels: dict[str, str]
    # Day offset range relative to an earlier stage key, or "season_start".
    anchor: str
    offset_days_min: int
    offset_days_max: int
    source_ids: list[str]


class StageTemplate(BaseModel):
    id: uuid.UUID
    crop: str
    bahar: str
    version: int
    labels: dict[str, str]
    stages: list[TemplateStage]
    sources: dict[str, str]
    updated_at: datetime


class StageTemplatesResponse(BaseModel):
    templates: list[StageTemplate]


@router.get("/stage-templates", operation_id="reference_stage_templates")
async def stage_templates(
    _user: CurrentUser,
    session: DbSession,
    crop: Annotated[str | None, Query(max_length=32)] = None,
) -> StageTemplatesResponse:
    published: Literal["published"] = "published"
    query = select(CropStageTemplate).where(CropStageTemplate.status == published)
    if crop is not None:
        query = query.where(CropStageTemplate.crop == crop)
    rows = await session.scalars(query.order_by(CropStageTemplate.crop, CropStageTemplate.bahar))
    return StageTemplatesResponse(
        templates=[StageTemplate.model_validate(r, from_attributes=True) for r in rows]
    )
