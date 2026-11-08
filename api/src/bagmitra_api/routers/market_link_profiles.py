"""Market linkage L2: public profiles, the taluka list and the service directory (spec v1.5
§3 step 6, §3A, §4).

Any signed-in user reads VERIFIED trader / exporter / broker / provider profiles only
(decision h): name, firm, village / markets, contact number, crops, areas, completed deals,
stars per question, tag counts and badges from verification records. Never coordinates, PIN,
registration numbers or admin flags. Grower profiles are never public (no endpoint). The
directory lists verified providers with a phone number to call; no booking (Addendum 5).
"""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import datetime
from typing import Annotated, Any, Literal, cast

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import ColumnElement, Select, and_, func, select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.db.models import Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.models import BrokerProfile, BuyerProfile, ServiceProvider
from bagmitra_api.market_link.profiles import (
    MODELS,
    PublicProfileOut,
    Subject,
    SubjectType,
    public_views,
)
from bagmitra_api.market_link.registration import distance_km, india_date, latest_fixes
from bagmitra_api.market_link.visibility import not_blocked, visible
from bagmitra_api.routers.market_link import require_market_link
from bagmitra_api.weather.service import get_clock

Clock = Annotated[Callable[[], datetime], Depends(get_clock)]
Area = Annotated[str | None, Query(min_length=1, max_length=120)]
ProviderKind = Literal["weighbridge", "transporter", "labour_gang", "crate_supplier"]
router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={code: {"model": ErrorResponse} for code in (401, 404, 422)},
)


class ProfilesResponse(BaseModel):
    profiles: list[PublicProfileOut]


def _in_area(
    query: Select[Any], model: type[Subject], district: str | None, taluka: str | None
) -> Select[Any]:
    """Same district / taluka, ignoring case and spaces around it."""
    for column, wanted in ((model.district, district), (model.taluka, taluka)):
        if wanted is not None:
            query = query.where(func.lower(func.trim(column)) == wanted.strip().lower())
    return query


def _shown(kind: str, model: type[Subject], viewer: uuid.UUID) -> ColumnElement[bool]:
    """Not hidden, suspended nor deleted (`visible`) and not blocked either way (§4C)."""
    return and_(visible(kind, model.id, model.user_id), not_blocked(viewer, model.user_id))


@router.get("/profiles", operation_id="market_link_profiles")
async def profiles(  # noqa: PLR0913 - filters and dependencies
    user: CurrentUser,
    session: DbSession,
    clock: Clock,
    role: Literal["trader", "exporter", "broker"],
    district: Area = None,
    taluka: Area = None,
    sort: Literal["rating", "deals"] = "rating",
) -> ProfilesResponse:
    """The list per taluka (decision g): verified traders, exporters or brokers, by rating
    (mean of the question averages; unrated last) or by completed deals. Hidden, suspended,
    deleted and blocked (either way) profiles are left out (§4C)."""
    model: type[Subject]
    query: Select[Any]
    if role == "broker":
        model, kind = BrokerProfile, "broker"
        query = select(BrokerProfile)
    else:
        model, kind = BuyerProfile, "buyer"
        query = select(BuyerProfile).where(BuyerProfile.kind == role)
    query = query.where(_shown(kind, model, user.id))
    rows = list(await session.scalars(_in_area(query, model, district, taluka)))
    views = await public_views(session, kind, list(rows), india_date(clock()))

    def rating(p: PublicProfileOut) -> float:
        return -(p.overall if p.overall is not None else -1.0)

    if sort == "rating":
        views.sort(key=lambda p: (rating(p), -p.deals_completed, p.name.casefold()))
    else:
        views.sort(key=lambda p: (-p.deals_completed, rating(p), p.name.casefold()))
    return ProfilesResponse(profiles=views)


@router.get("/profiles/{subject_type}/{subject_id}", operation_id="market_link_profile")
async def profile(
    subject_type: SubjectType,
    subject_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    clock: Clock,
) -> PublicProfileOut:
    """One verified profile; an unverified, hidden, suspended, deleted or blocked one answers
    404 as if absent."""
    model = MODELS[subject_type]
    subject = cast(
        Subject | None,
        await session.scalar(
            select(model).where(model.id == subject_id, _shown(subject_type, model, user.id))
        ),
    )
    views = (
        await public_views(session, subject_type, [subject], india_date(clock()))
        if subject is not None
        else []
    )
    if not views:
        raise ApiError(404, "profile_not_found")
    return views[0]


@router.get("/providers", operation_id="market_link_providers_near")
async def directory(  # noqa: PLR0913 - filters and dependencies
    user: CurrentUser,
    session: DbSession,
    clock: Clock,
    kind: Annotated[ProviderKind | None, Query(alias="type")] = None,
    district: Area = None,
    taluka: Area = None,
    plot_id: uuid.UUID | None = None,
) -> ProfilesResponse:
    """Verified providers near the grower's own plot: nearest first when both have a location
    (distance in whole km from the provider's registration fix, Q80), the rest by district,
    taluka and name. A phone number to call; no booking."""
    origin: tuple[float, float] | None = None
    if plot_id is not None:
        plot = await session.get(Plot, plot_id)
        if plot is None or plot.owner_id != user.id or plot.deleted_at is not None:
            raise ApiError(404, "plot_not_found")
        if plot.centroid_lat is not None and plot.centroid_lon is not None:
            origin = (plot.centroid_lat, plot.centroid_lon)
    query: Select[Any] = select(ServiceProvider).where(_shown("provider", ServiceProvider, user.id))
    if kind is not None:
        query = query.where(ServiceProvider.kind == kind)
    rows = list(await session.scalars(_in_area(query, ServiceProvider, district, taluka)))
    views = await public_views(session, "provider", list(rows), india_date(clock()))
    fixes = await latest_fixes(session, "provider", [v.id for v in views])
    listed: list[tuple[float, PublicProfileOut]] = []
    for view in views:
        km = float("inf")
        if origin is not None and (fix := fixes.get(view.id)) is not None:
            km = distance_km(origin[0], origin[1], fix.lat, fix.lon)
            view.distance_km = round(km)
        listed.append((km, view))
    listed.sort(key=lambda kv: (kv[0], kv[1].district, kv[1].taluka or "", kv[1].name))
    return ProfilesResponse(profiles=[view for _, view in listed])
