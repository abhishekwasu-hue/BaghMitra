"""Market linkage interests and the introduction (spec v1.5 §3 steps 3-5, build prompt L4).
Behind the legal gate (decision j): every path answers 404 while `market_link_enabled` is off.

An admin-verified trader / exporter sends an interest on a published lot, directly or naming a
verified broker; a verified broker may send one for a named verified trader (decision h). An
interest holds only rate and basis, quantity and proposed harvest date (§3 step 3). The grower
compares the interests on their own lot side by side (accepting one is part 2). Everything
after the introduction is settled between them off the app (§1 core principle, §3 step 5).
"""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Annotated, Literal, cast

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import or_, select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import MarketLinkIn, is_verified
from bagmitra_api.market_link.models import (
    ORCHARD_OK,
    BrokerProfile,
    BuyerProfile,
    MarketDeal,
    MarketLot,
    MarketOffer,
)
from bagmitra_api.market_link.profiles import PublicProfileOut, Subject, public_views
from bagmitra_api.market_link.registration import india_date
from bagmitra_api.market_link.terms import accepted_roles, current_versions
from bagmitra_api.routers.market_link import Clock, require_market_link
from bagmitra_api.routers.market_lots import _own_lot

router = APIRouter(
    prefix="/v1/market-link",
    tags=["market-link"],
    dependencies=[Depends(require_market_link)],
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
)
AppSettings = Annotated[Settings, Depends(get_settings)]


class InterestIn(MarketLinkIn):
    """Spec §3 step 3, nothing more. `rate_paise` is per tonne, per crate or the whole amount,
    by `basis`. A trader may name a broker (`broker_id`); a broker names the trader
    (`trader_id`) it brings. Unknown keys (terms, commission, payer ...) are refused."""

    basis: Literal["per_tonne", "per_crate", "lump_sum"]
    rate_paise: int = Field(gt=0, le=10**12)
    quantity_t: float | None = Field(default=None, gt=0, le=10_000)
    harvest_date: date
    broker_id: uuid.UUID | None = None
    trader_id: uuid.UUID | None = None

    @model_validator(mode="after")
    def _one_named_party(self) -> InterestIn:
        if self.broker_id is not None and self.trader_id is not None:
            raise ValueError("name either a broker or a trader, not both")
        return self


class LotBrief(BaseModel):
    """What the sender already saw in the lot list: never the grower's identity."""

    id: uuid.UUID
    crop: str
    variety: str | None
    quantity_t: float
    basis: str
    village: str | None
    taluka: str | None
    district: str | None
    status: str


class InterestOut(BaseModel):
    id: uuid.UUID
    lot_id: uuid.UUID
    basis: str
    rate_paise: int
    quantity_t: float | None
    harvest_date: date
    # open / accepted / closed (another was accepted or the lot was closed) / withdrawn.
    status: str
    created_at: datetime
    via_broker: bool
    # Set once accepted: the introduction to open (contacts).
    deal_id: uuid.UUID | None = None


class SentInterestOut(InterestOut):
    lot: LotBrief


class SentInterestsResponse(BaseModel):
    interests: list[SentInterestOut]


class GrowerInterestOut(InterestOut):
    """An interest beside the others: the trader's (and broker's) public profile with the
    verified badge, completed-deal count and stars (spec §3 step 4)."""

    trader: PublicProfileOut
    broker: PublicProfileOut | None


class LotInterestsResponse(BaseModel):
    interests: list[GrowerInterestOut]


def _interest(offer: MarketOffer, deal_id: uuid.UUID | None = None) -> dict[str, object]:
    fields = ("id", "lot_id", "basis", "rate_paise", "quantity_t", "harvest_date", "status")
    return {
        **{f: getattr(offer, f) for f in fields},
        "created_at": offer.created_at,
        "via_broker": offer.broker_user_id is not None,
        "deal_id": deal_id,
    }


def _brief(lot: MarketLot) -> LotBrief:
    return LotBrief.model_validate(lot, from_attributes=True)


async def _verified_profile[P: (BuyerProfile, BrokerProfile)](
    session: DbSession, model: type[P], *, user_id: uuid.UUID | None = None, pid: uuid.UUID | None
) -> P | None:
    query = select(model).where(model.user_id == user_id if pid is None else model.id == pid)
    profile = await session.scalar(query)
    kind = "buyer" if model is BuyerProfile else "broker"
    if profile is None or not await is_verified(session, kind, profile.id):
        return None
    return profile


async def _require_accepted(
    session: DbSession, settings: Settings, user_id: uuid.UUID, role: str
) -> None:
    if role not in await accepted_roles(session, user_id, current_versions(settings)):
        raise ApiError(403, "terms_not_accepted", f"Accept the current terms for {role}")


@router.post("/lots/{lot_id}/interests", operation_id="market_link_send_interest", status_code=201)
async def send_interest(
    lot_id: uuid.UUID,
    body: InterestIn,
    user: CurrentUser,
    session: DbSession,
    settings: AppSettings,
) -> InterestOut:
    """An interest on a published lot from a verified trader / exporter (optionally naming a
    verified broker) or from a verified broker for a named verified trader. A trader's new
    interest replaces their open one on the same lot."""
    if body.trader_id is not None:  # a broker brings a trader
        broker = await _verified_profile(session, BrokerProfile, user_id=user.id, pid=None)
        if broker is None:
            raise ApiError(403, "not_verified")
        await _require_accepted(session, settings, user.id, "broker")
        buyer = await _verified_profile(session, BuyerProfile, pid=body.trader_id)
        if buyer is None:
            raise ApiError(404, "trader_not_found")
    else:
        buyer = await _verified_profile(session, BuyerProfile, user_id=user.id, pid=None)
        if buyer is None:
            raise ApiError(403, "not_verified")
        await _require_accepted(session, settings, user.id, buyer.kind)
        broker = None
        if body.broker_id is not None:
            broker = await _verified_profile(session, BrokerProfile, pid=body.broker_id)
            if broker is None:
                raise ApiError(404, "broker_not_found")
    lot = await session.get(MarketLot, lot_id)
    if (
        lot is None
        or lot.deleted_at is not None
        or lot.status != "published"
        or lot.orchard_check not in ORCHARD_OK
    ):
        raise ApiError(404, "lot_not_found")
    if lot.owner_id in (buyer.user_id, broker.user_id if broker else None):
        raise ApiError(409, "own_lot")
    for old in await session.scalars(
        select(MarketOffer).where(
            MarketOffer.lot_id == lot.id,
            MarketOffer.buyer_user_id == buyer.user_id,
            MarketOffer.status == "open",
        )
    ):
        old.status = "withdrawn"
    offer = MarketOffer(
        **body.model_dump(include={"basis", "rate_paise", "quantity_t", "harvest_date"}),
        lot_id=lot.id,
        buyer_user_id=buyer.user_id,
        broker_user_id=broker.user_id if broker else None,
        submitted_by=user.id,
        status="open",
    )
    session.add(offer)
    await session.flush()
    await session.commit()
    return InterestOut.model_validate(_interest(offer))


async def _deal_ids(session: DbSession, offer_ids: list[uuid.UUID]) -> dict[uuid.UUID, uuid.UUID]:
    if not offer_ids:
        return {}
    rows = await session.execute(
        select(MarketDeal.offer_id, MarketDeal.id).where(MarketDeal.offer_id.in_(offer_ids))
    )
    return dict(rows.tuples().all())


@router.get("/interests/mine", operation_id="market_link_my_interests")
async def my_interests(user: CurrentUser, session: DbSession) -> SentInterestsResponse:
    """Interests where the caller is the trader or the named broker, newest first, with the
    lot and, once accepted, the introduction to open; a closed one is the notice that the
    grower accepted another or closed the lot."""
    offers = list(
        await session.scalars(
            select(MarketOffer)
            .where(or_(MarketOffer.buyer_user_id == user.id, MarketOffer.broker_user_id == user.id))
            .order_by(MarketOffer.created_at.desc(), MarketOffer.id)
        )
    )
    lots = {
        lot.id: lot
        for lot in await session.scalars(
            select(MarketLot).where(MarketLot.id.in_({o.lot_id for o in offers}))
        )
    }
    deals = await _deal_ids(session, [o.id for o in offers])
    return SentInterestsResponse(
        interests=[
            SentInterestOut.model_validate(
                {**_interest(o, deals.get(o.id)), "lot": _brief(lots[o.lot_id])}
            )
            for o in offers
            if o.status != "withdrawn"
        ]
    )


async def _profiles(
    session: DbSession,
    model: type[BuyerProfile] | type[BrokerProfile],
    users: set[uuid.UUID],
    today: date,
) -> dict[uuid.UUID, PublicProfileOut]:
    """Public views (verified only, decision h) by user id."""
    if not users:
        return {}
    kind = "buyer" if model is BuyerProfile else "broker"
    rows = cast(
        list[Subject], list(await session.scalars(select(model).where(model.user_id.in_(users))))
    )
    by_id = {r.id: r.user_id for r in rows}
    views = await public_views(session, kind, rows, today)
    return {cast(uuid.UUID, by_id[v.id]): v for v in views}


@router.get("/lots/{lot_id}/interests", operation_id="market_link_lot_interests")
async def lot_interests(
    lot_id: uuid.UUID, user: CurrentUser, session: DbSession, clock: Clock
) -> LotInterestsResponse:
    """The interests on the caller's own lot, oldest first, to compare side by side. An open
    interest whose trader or broker is no longer verified is left out (decision h)."""
    lot = await _own_lot(session, user, lot_id)
    offers = list(
        await session.scalars(
            select(MarketOffer)
            .where(MarketOffer.lot_id == lot.id, MarketOffer.status != "withdrawn")
            .order_by(MarketOffer.created_at, MarketOffer.id)
        )
    )
    today = india_date(clock())
    traders = await _profiles(session, BuyerProfile, {o.buyer_user_id for o in offers}, today)
    brokers = await _profiles(
        session,
        BrokerProfile,
        {o.broker_user_id for o in offers if o.broker_user_id},
        today,
    )
    deals = await _deal_ids(session, [o.id for o in offers])
    out: list[GrowerInterestOut] = []
    for o in offers:
        trader = traders.get(o.buyer_user_id)
        broker = brokers.get(o.broker_user_id) if o.broker_user_id else None
        if trader is None or (o.broker_user_id is not None and broker is None):
            continue
        item = {**_interest(o, deals.get(o.id)), "trader": trader, "broker": broker}
        out.append(GrowerInterestOut.model_validate(item))
    return LotInterestsResponse(interests=out)
