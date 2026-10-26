"""Read-only reference data (admin-managed config) for the app's offline cache."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import utcnow
from bagmitra_api.db.models import CropStageTemplate
from bagmitra_api.db.session import DbSession
from bagmitra_api.kb.context import load_context
from bagmitra_api.kb.gate import crop_claims, normalise_ai, restriction_reasons
from bagmitra_api.kb.models import KbRestriction, KbSource, KbSynonym

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


class RestrictionOut(BaseModel):
    active_ingredient: str
    kind: str
    crops: list[str]
    crop_groups: list[str]
    notification: str
    effective_from: datetime


class SynonymOut(BaseModel):
    name: str
    active_ingredient: str


class RestrictionsResponse(BaseModel):
    restrictions: list[RestrictionOut]
    synonyms: list[SynonymOut]


@router.get("/restrictions", operation_id="reference_restrictions")
async def restrictions(_user: CurrentUser, session: DbSession) -> RestrictionsResponse:
    """Gazette bans / restrictions and trade names, cached by the app so spray records can
    be checked offline. Facts only; no advice text."""
    rows = await session.scalars(
        select(KbRestriction).order_by(KbRestriction.active_ingredient, KbRestriction.kind)
    )
    names = await session.scalars(select(KbSynonym).order_by(KbSynonym.name))
    return RestrictionsResponse(
        restrictions=[RestrictionOut.model_validate(r, from_attributes=True) for r in rows],
        synonyms=[SynonymOut.model_validate(n, from_attributes=True) for n in names],
    )


class LabelClaimOut(BaseModel):
    active_ingredient: str
    formulation: str
    target: str
    dose: str
    interval_days: int | None
    phi_days: int | None
    max_sprays: int | None
    label_crop: str
    source_key: str
    source_title: str
    source_url: str


class LabelClaimsResponse(BaseModel):
    # Always "label_information": these are registered label facts, not a recommendation.
    kind: Literal["label_information"] = "label_information"
    claims: list[LabelClaimOut]


@router.get("/label-claims", operation_id="reference_label_claims")
async def label_claims(
    _user: CurrentUser,
    session: DbSession,
    settings: Annotated[Settings, Depends(get_settings)],
    crop: Annotated[str, Query(pattern="^[a-z_]{2,32}$")],
    target: Annotated[str | None, Query(max_length=120)] = None,
) -> LabelClaimsResponse:
    """What CIB&RC registered labels say for the crop (owner, 2026-10-26: label information
    only). Only claims valid today whose active ingredient is neither banned nor restricted
    for the crop pass the legal gate; doses are quoted exactly as the label states them.
    The app shows this as label information with "read the label; confirm with KVK", never
    as BagMitra's own advice."""
    aliases = frozenset(a.lower() for a in settings.kb_crop_label_aliases.get(crop, []))
    if not aliases:
        return LabelClaimsResponse(claims=[])
    ctx = await load_context(
        session,
        crop_aliases=aliases,
        crop_groups=frozenset(settings.kb_crop_groups.get(crop, [])),
        now=utcnow(),
    )
    ingredients = {normalise_ai(c.active_ingredient, ctx.synonyms) for c in ctx.claims}
    legal = [
        c
        for ai in ingredients
        if not restriction_reasons(ai, ctx)
        for c in crop_claims(ai, ctx)
        if target is None or c.target.strip().lower() == target.strip().lower()
    ]
    sources = {
        s.key: s
        for s in await session.scalars(
            select(KbSource).where(KbSource.key.in_({c.source_key for c in legal}))
        )
    }
    return LabelClaimsResponse(
        claims=sorted(
            (
                LabelClaimOut(
                    active_ingredient=c.active_ingredient,
                    formulation=c.formulation,
                    target=c.target,
                    dose=c.dose,
                    interval_days=c.interval_days,
                    phi_days=c.phi_days,
                    max_sprays=c.max_sprays,
                    label_crop=c.crop,
                    source_key=c.source_key,
                    source_title=sources[c.source_key].title,
                    source_url=sources[c.source_key].url,
                )
                for c in legal
            ),
            key=lambda c: (c.active_ingredient, c.target, c.formulation),
        )
    )
