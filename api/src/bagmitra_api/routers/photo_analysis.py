"""Crop photo analysis (owner Q135, stage 2): the farmer sends one photo of a leaf, fruit,
trunk or the whole tree from their own plot and gets up to three possible problems from the
practice cards, each with the visible signs and a calm explanation in en / mr / hi.

- Consent is the one given at signup through the privacy policy; nothing is asked per photo.
- The photo's metadata (EXIF GPS, phone, time) is stripped before it goes to the model or to
  storage. Every analysed photo is kept as a training sample (`photo_analysis_samples`, photo
  at `<owner_id>/analysis-<id>.<ext>`), erased with the account, deleted by the farmer with
  `DELETE /v1/photo-analysis/{photo_id}`, and removed after PHOTO_AI_RETENTION_DAYS.
- Limits per farmer per India day and month are the billing admin's settings
  (`photo_ai/limits.py`); over a limit the answer is 429 `analysis_limit` with which limit and
  when it resets.
- Role `kb_admin` labels samples and exports the labelled ones for training.
"""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime
from typing import Annotated, Any, Literal

import httpx
import structlog
from fastapi import APIRouter, Depends, File, Form, Query, Response, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import select

from bagmitra_api.auth.jwt import AuthenticatedUser, CurrentUser, require_role
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.base import as_utc
from bagmitra_api.db.models import Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.feed.ai import AiUnavailableError
from bagmitra_api.photo_ai.analyse import PARTS, AnthropicPhotoAi, PhotoAnalyser, signs_by_lang
from bagmitra_api.photo_ai.limits import limit_hit
from bagmitra_api.photo_ai.models import PhotoAnalysisSample
from bagmitra_api.photo_ai.profiles import known_keys, names
from bagmitra_api.photos.exif import (
    PNG_SIGNATURE,
    NotJpegError,
    NotPngError,
    strip_jpeg_metadata,
    strip_png_metadata,
)
from bagmitra_api.photos.storage import PhotoStorageError
from bagmitra_api.routers.scouting_photos import PhotoContext, get_photo_context

router = APIRouter(prefix="/v1", tags=["photo-analysis"])
log = structlog.get_logger("bagmitra.photo_ai")

KB_ADMIN = "kb_admin"
Admin = Annotated[AuthenticatedUser, Depends(require_role(KB_ADMIN))]
Photo = Annotated[PhotoContext, Depends(get_photo_context)]
# A pattern, not an enum: the app's generated client cannot read an inline enum in a
# multipart form (swagger_dart_code_generator).
PART_PATTERN = rf"^({'|'.join(PARTS)})$"
LabelSource = Literal["expert", "farmer", "lab"]
SIGNED_URL_SECONDS = 3600
JPEG, PNG = "image/jpeg", "image/png"
EXTENSIONS = {JPEG: "jpg", PNG: "png"}


async def get_photo_analyser(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[PhotoAnalyser | None]:
    """Claude with PHOTO_AI_API_KEY (else FEED_AI_API_KEY); None while neither is set."""
    if not settings.photo_ai_key:
        yield None
        return
    async with httpx.AsyncClient() as http:
        yield AnthropicPhotoAi(http, settings)


Analyser = Annotated[PhotoAnalyser | None, Depends(get_photo_analyser)]


class LocalizedText(BaseModel):
    en: str
    mr: str
    hi: str


class LocalizedSigns(BaseModel):
    # What the model saw in the photo, short phrases per language; a list may be empty.
    en: list[str]
    mr: list[str]
    hi: list[str]


class CandidateOut(BaseModel):
    # A practice-card profile key, or `healthy` / `other`.
    key: str
    name: LocalizedText
    confidence: float = Field(ge=0, le=1)
    signs: LocalizedSigns
    explanation: LocalizedText


class PhotoAnalysisOut(BaseModel):
    # At most three, most likely first.
    candidates: list[CandidateOut]
    unsure: bool
    # The stored training sample (use it to delete the photo again).
    photo_id: uuid.UUID


class SampleOut(BaseModel):
    id: uuid.UUID
    plot_id: uuid.UUID
    part: str | None
    scouting_item: str | None
    model: str
    candidates: list[CandidateOut]
    unsure: bool
    label: str | None
    label_source: str | None
    created_at: datetime
    # Short-lived signed link to the photo; null without photo storage or a stored photo.
    photo_url: str | None


class SamplesOut(BaseModel):
    samples: list[SampleOut]


class LabelIn(BaseModel):
    label: str = Field(min_length=1, max_length=32)
    source: LabelSource = "expert"


def _candidate_out(raw: dict[str, Any]) -> CandidateOut:
    key = str(raw["key"])
    explanation = raw.get("explanation")
    return CandidateOut(
        key=key,
        name=LocalizedText(**names(key)),
        confidence=float(raw.get("confidence", 0.0)),
        # Samples stored before the languages hold a plain English list.
        signs=LocalizedSigns(**signs_by_lang(raw.get("signs"))),
        explanation=LocalizedText(**explanation)
        if isinstance(explanation, dict)
        else LocalizedText(en="", mr="", hi=""),
    )


def clean_photo(data: bytes) -> tuple[str, bytes]:
    """The media type and the image without metadata; 415 for anything but JPEG / PNG."""
    try:
        if data.startswith(b"\xff\xd8"):
            return JPEG, strip_jpeg_metadata(data)
        if data.startswith(PNG_SIGNATURE):
            return PNG, strip_png_metadata(data)
    except (NotJpegError, NotPngError) as exc:
        raise ApiError(415, "photo_not_supported", "send one JPEG or PNG photo") from exc
    raise ApiError(415, "photo_not_supported", "send one JPEG or PNG photo")


_RESPONSES: dict[int | str, dict[str, object]] = {
    401: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    413: {"model": ErrorResponse},
    415: {"model": ErrorResponse},
    429: {"model": ErrorResponse},
    502: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}


@router.post(
    "/plots/{plot_id}/photo-analysis",
    operation_id="photo_analysis_create",
    responses=_RESPONSES,
)
async def analyse_photo(  # noqa: PLR0913 - path, form fields and dependencies
    plot_id: uuid.UUID,
    photo: Annotated[UploadFile, File(description="One JPEG or PNG photo")],
    user: CurrentUser,
    session: DbSession,
    ctx: Photo,
    analyser: Analyser,
    part: Annotated[
        str | None, Form(pattern=PART_PATTERN, description="leaf | fruit | trunk | whole_tree")
    ] = None,
    scouting_item: Annotated[
        str | None, Form(pattern=r"^[a-z][a-z0-9_]{1,31}$", description="scouting entry slug")
    ] = None,
) -> PhotoAnalysisOut:
    """Analyses one crop photo of the caller's own plot (owner Q135).

    429 `analysis_limit`: `error.details` has `limit` (daily | monthly | total), `max` and
    `resets_at` (UTC); the `Retry-After` header has the seconds until then. 503
    `analysis_unavailable`: no API key on the server. 502 `analysis_failed`: the model could
    not answer; nothing is stored or counted."""
    plot = await session.get(Plot, plot_id)
    if plot is None or plot.owner_id != user.id or plot.deleted_at is not None:
        raise ApiError(404, "plot_not_found")
    if analyser is None:
        raise ApiError(503, "analysis_unavailable", "photo analysis is not set up")
    data = await photo.read(ctx.settings.photo_max_bytes + 1)
    if len(data) > ctx.settings.photo_max_bytes:
        raise ApiError(413, "photo_too_large", f"at most {ctx.settings.photo_max_bytes} bytes")
    media_type, clean = clean_photo(data)
    now = datetime.now(UTC)
    hit = await limit_hit(session, user.id, now)
    if hit is not None:
        seconds = max(1, int((hit.resets_at - now).total_seconds()))
        raise ApiError(
            429,
            "analysis_limit",
            f"{hit.kind} photo limit reached",
            details={
                "limit": hit.kind,
                "max": str(hit.limit),
                "resets_at": hit.resets_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            },
            headers={"Retry-After": str(seconds)},
        )
    try:
        result = await analyser.analyse(clean, media_type, part)
    except AiUnavailableError as exc:
        log.warning("photo_analysis_failed", reason=str(exc))
        raise ApiError(502, "analysis_failed", "the photo could not be analysed") from exc
    sample_id = uuid.uuid4()
    key: str | None = None
    if ctx.storage is not None:
        candidate_key = f"{user.id}/analysis-{sample_id}.{EXTENSIONS[media_type]}"
        try:
            await ctx.storage.put_object(candidate_key, clean, media_type)
            key = candidate_key
        except PhotoStorageError as exc:
            # The farmer still gets the answer; the sample is kept without its photo.
            log.warning("photo_analysis_store_failed", reason=str(exc))
    candidates = [c.to_dict() for c in result.candidates]
    session.add(
        PhotoAnalysisSample(
            id=sample_id,
            owner_id=user.id,
            plot_id=plot.id,
            part=part,
            scouting_item=scouting_item,
            model=analyser.model,
            candidates=candidates,
            unsure=result.unsure,
            photo_key=key,
        )
    )
    await session.commit()
    log.info("photo_analysed", unsure=result.unsure, candidates=len(candidates))
    return PhotoAnalysisOut(
        candidates=[_candidate_out(c) for c in candidates],
        unsure=result.unsure,
        photo_id=sample_id,
    )


@router.delete(
    "/photo-analysis/{photo_id}",
    operation_id="photo_analysis_delete",
    status_code=204,
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
)
async def delete_sample(
    photo_id: uuid.UUID, user: CurrentUser, session: DbSession, ctx: Photo
) -> Response:
    """Deletes the caller's own analysed photo and its result (also when the app deletes the
    scouting entry it belongs to). 502 when storage fails; nothing is deleted then."""
    row = await session.get(PhotoAnalysisSample, photo_id)
    if row is None or row.owner_id != user.id:
        raise ApiError(404, "photo_not_found")
    if row.photo_key and ctx.storage is not None:
        try:
            await ctx.storage.delete_objects([row.photo_key])
        except PhotoStorageError as exc:
            log.warning("photo_analysis_delete_failed", reason=str(exc))
            raise ApiError(502, "photo_storage_unavailable") from exc
    await session.delete(row)
    await session.commit()
    return Response(status_code=204)


async def _sample_out(row: PhotoAnalysisSample, ctx: PhotoContext) -> SampleOut:
    url = None
    if row.photo_key and ctx.storage is not None:
        try:
            url = (await ctx.storage.signed_download_url(row.photo_key, SIGNED_URL_SECONDS)).url
        except PhotoStorageError:
            url = None  # the row is still listed
    return SampleOut(
        id=row.id,
        plot_id=row.plot_id,
        part=row.part,
        scouting_item=row.scouting_item,
        model=row.model,
        candidates=[_candidate_out(c) for c in row.candidates],
        unsure=row.unsure,
        label=row.label,
        label_source=row.label_source,
        created_at=as_utc(row.created_at),
        photo_url=url,
    )


@router.get(
    "/admin/photo-analysis/samples",
    operation_id="admin_photo_analysis_samples",
    tags=["admin"],
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
async def admin_samples(
    _: Admin,
    session: DbSession,
    ctx: Photo,
    labelled: Annotated[bool, Query(description="true: the training export")] = True,
    limit: Annotated[int, Query(ge=1, le=500)] = 200,
) -> SamplesOut:
    """Training export: labelled samples with a signed photo link (1 hour) and the label.
    `labelled=false` lists the samples still to label. No owner id is listed."""
    query = select(PhotoAnalysisSample).order_by(PhotoAnalysisSample.created_at.desc())
    query = query.where(
        PhotoAnalysisSample.label.is_not(None) if labelled else PhotoAnalysisSample.label.is_(None)
    )
    rows = await session.scalars(query.limit(limit))
    return SamplesOut(samples=[await _sample_out(r, ctx) for r in rows])


@router.put(
    "/admin/photo-analysis/samples/{photo_id}/label",
    operation_id="admin_photo_analysis_label",
    tags=["admin"],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
async def admin_label(
    photo_id: uuid.UUID, body: LabelIn, _: Admin, session: DbSession, ctx: Photo
) -> SampleOut:
    """Confirms what a sample shows (a profile key, `healthy` or `other`) for training."""
    if body.label not in known_keys():
        raise ApiError(422, "unknown_label", "use a practice-card key, healthy or other")
    row = await session.get(PhotoAnalysisSample, photo_id)
    if row is None:
        raise ApiError(404, "photo_not_found")
    row.label, row.label_source = body.label, body.source
    await session.commit()
    return await _sample_out(row, ctx)
