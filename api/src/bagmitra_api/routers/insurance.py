"""Crop insurance helper (gap #1): enrolment deadlines from the reviewed govt feed.

The policy record itself syncs as the `insurance_policy` entity; this router only reads
published feed dates. No date or amount is ever made up: no matching item, no deadline.
"""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Literal
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.db.models import Farmer, Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.texts import FOOTER
from bagmitra_api.insurance.deadlines import insurance_deadlines
from bagmitra_api.weather.service import get_clock

router = APIRouter(prefix="/v1", tags=["insurance"])
INDIA = ZoneInfo("Asia/Kolkata")


class InsuranceDeadlineOut(BaseModel):
    item_id: uuid.UUID
    title: str
    due_date: date
    url: str
    # The bahar the notice names ("ambia" / "mrig"), or None when it names both or neither.
    # A plain string: the app's client generator cannot read a nullable enum.
    season: str | None


class InsuranceDeadlinesResponse(BaseModel):
    items: list[InsuranceDeadlineOut]
    footer: str


@router.get(
    "/insurance/deadlines",
    operation_id="insurance_deadlines",
    responses={401: {"model": ErrorResponse}},
)
async def deadlines(
    user: CurrentUser,
    session: DbSession,
    clock: Annotated[Callable[[], datetime], Depends(get_clock)],
    lang: Annotated[Literal["en", "mr", "hi"], Query()] = "en",
) -> InsuranceDeadlinesResponse:
    """Enrolment dates of published official crop insurance notices, soonest first."""
    farmer = await session.get(Farmer, user.id)
    crops = await session.scalars(
        select(Plot.crop).where(Plot.owner_id == user.id, Plot.deleted_at.is_(None))
    )
    found = await insurance_deadlines(
        session,
        today=clock().astimezone(INDIA).date(),
        lang=lang,
        district=farmer.district if farmer else None,
        crops=list(crops),
    )
    return InsuranceDeadlinesResponse(
        items=[
            InsuranceDeadlineOut(
                item_id=d.item_id, title=d.title, due_date=d.due_date, url=d.url, season=d.season
            )
            for d in found
        ],
        footer=FOOTER[lang],
    )
