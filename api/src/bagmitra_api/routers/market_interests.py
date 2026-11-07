"""Market linkage interests and the introduction (spec v1.5 §3 steps 3-5, build prompt L4).
Behind the legal gate (decision j): every path answers 404 while `market_link_enabled` is off.

An admin-verified trader / exporter sends an interest on a published lot, directly or naming a
verified broker; a verified broker may send one for a named verified trader (decision h). An
interest holds only rate and basis, quantity and proposed harvest date (§3 step 3). The grower
compares the interests on their own lot and accepts one: that creates the introduction record
(`market_deals`, no terms), closes the other interests with a notice, closes the lot and
reveals both sides' name, phone and the plot pin to the parties only (decision g). Everything
after that is settled between them off the app (§1 core principle, §3 step 5).
"""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Annotated, Literal, cast

from fastapi import APIRouter, BackgroundTasks, Depends
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import or_, select

from bagmitra_api.auth.jwt import CurrentUser
from bagmitra_api.core.errors import ApiError, ErrorResponse
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.models import Farmer, Plot
from bagmitra_api.db.session import DbSession
from bagmitra_api.market_link.guards import MarketLinkIn, is_verified
from bagmitra_api.market_link.models import (
    ORCHARD_OK,
    BrokerProfile,
    BuyerProfile,
    DealEvent,
    DealParty,
    MarketDeal,
    MarketLot,
    MarketOffer,
)
from bagmitra_api.market_link.notify import messages, send_all
from bagmitra_api.market_link.profiles import PublicProfileOut, Subject, public_views
from bagmitra_api.market_link.registration import india_date
from bagmitra_api.market_link.terms import accepted_roles, current_versions
from bagmitra_api.routers.market_link import Clock, require_market_link
from bagmitra_api.routers.market_lots import (
    GROWER_WRITE,
    Push,
    _own_lot,
    _server_write,
    close_open_offers,
)

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


class PinOut(BaseModel):
    lat: float
    lon: float


class GrowerContactOut(BaseModel):
    name: str | None
    phone: str | None
    village: str | None
    taluka: str | None
    district: str | None
    plot_name: str | None
    # The plot's point, revealed only to the parties of an accepted interest.
    pin: PinOut | None


class PartyContactOut(BaseModel):
    name: str
    firm: str | None
    phone: str


class IntroductionOut(BaseModel):
    """Both sides' contacts after acceptance; nothing about their deal is recorded."""

    deal_id: uuid.UUID
    accepted_at: datetime
    lot: LotBrief
    interest: InterestOut
    grower: GrowerContactOut
    trader: PartyContactOut
    broker: PartyContactOut | None


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
async def send_interest(  # noqa: PLR0913 - body and dependencies
    lot_id: uuid.UUID,
    body: InterestIn,
    user: CurrentUser,
    session: DbSession,
    settings: AppSettings,
    tasks: BackgroundTasks,
    push: Push,
) -> InterestOut:
    """An interest on a published lot from a verified trader / exporter (optionally naming a
    verified broker) or from a verified broker for a named verified trader. A trader's new
    interest replaces their open one on the same lot. The grower gets a push."""
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
    batch = await messages(session, "new_interest", [lot.owner_id], {"lot_id": str(lot.id)})
    await session.commit()
    tasks.add_task(send_all, push, batch)
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


@router.post(
    "/interests/{interest_id}/accept",
    operation_id="market_link_accept_interest",
    dependencies=GROWER_WRITE,
)
async def accept_interest(
    interest_id: uuid.UUID,
    user: CurrentUser,
    session: DbSession,
    tasks: BackgroundTasks,
    push: Push,
) -> IntroductionOut:
    """The lot's grower accepts one open interest: the introduction is recorded, the other
    open interests are closed (their senders get a notice), the lot leaves the traders' list
    and both sides see each other's contacts. Anyone but the lot's grower gets 404."""
    offer = await session.get(MarketOffer, interest_id)
    if offer is None:
        raise ApiError(404, "interest_not_found")
    lot = await session.scalar(
        select(MarketLot).where(MarketLot.id == offer.lot_id).with_for_update()
    )
    if lot is None or lot.owner_id != user.id or lot.deleted_at is not None:
        raise ApiError(404, "interest_not_found")
    if lot.status != "published":
        raise ApiError(409, "lot_not_published")
    if offer.status != "open":
        raise ApiError(409, "interest_not_open")
    trader = await _verified_profile(session, BuyerProfile, user_id=offer.buyer_user_id, pid=None)
    broker = (
        await _verified_profile(session, BrokerProfile, user_id=offer.broker_user_id, pid=None)
        if offer.broker_user_id
        else None
    )
    if trader is None or (offer.broker_user_id is not None and broker is None):
        raise ApiError(409, "party_not_verified")
    deal = MarketDeal(lot_id=lot.id, offer_id=offer.id, status="active")
    session.add(deal)
    await session.flush()
    parties = [("grower", user.id), ("trader", offer.buyer_user_id)]
    if offer.broker_user_id is not None:
        parties.append(("broker", offer.broker_user_id))
    session.add_all(DealParty(deal_id=deal.id, role=r, user_id=u) for r, u in parties)
    session.add(DealEvent(deal_id=deal.id, actor_id=user.id, kind="accepted", detail={}))
    offer.status = "accepted"
    others = await close_open_offers(session, lot.id)
    lot.status = "closed"
    await _server_write(session, user, lot, "close")
    data = {"lot_id": str(lot.id), "deal_id": str(deal.id)}
    batch = await messages(session, "accepted", [u for r, u in parties if r != "grower"], data)
    batch += await messages(session, "closed", others, {"lot_id": str(lot.id)})
    await session.commit()
    tasks.add_task(send_all, push, batch)
    return await _introduction(session, deal)


async def _introduction(session: DbSession, deal: MarketDeal) -> IntroductionOut:
    offer = await session.get(MarketOffer, deal.offer_id)
    lot = await session.get(MarketLot, deal.lot_id)
    if offer is None or lot is None:  # foreign keys: never
        raise ApiError(404, "deal_not_found")
    farmer = await session.get(Farmer, lot.owner_id)
    plot = await session.get(Plot, lot.plot_id)
    buyer = await session.scalar(
        select(BuyerProfile).where(BuyerProfile.user_id == offer.buyer_user_id)
    )
    broker = (
        await session.scalar(
            select(BrokerProfile).where(BrokerProfile.user_id == offer.broker_user_id)
        )
        if offer.broker_user_id
        else None
    )
    pin = (
        PinOut(lat=plot.centroid_lat, lon=plot.centroid_lon)
        if plot is not None and plot.centroid_lat is not None and plot.centroid_lon is not None
        else None
    )
    return IntroductionOut(
        deal_id=deal.id,
        accepted_at=deal.accepted_at,
        lot=_brief(lot),
        interest=InterestOut.model_validate(_interest(offer, deal.id)),
        grower=GrowerContactOut(
            name=farmer.display_name if farmer else None,
            phone=farmer.phone if farmer else None,
            village=lot.village,
            taluka=lot.taluka,
            district=lot.district,
            plot_name=plot.name if plot else None,
            pin=pin,
        ),
        trader=PartyContactOut(
            name=buyer.name if buyer else "",
            firm=buyer.firm if buyer else None,
            phone=buyer.phone if buyer else "",
        ),
        broker=PartyContactOut(name=broker.name, firm=None, phone=broker.phone) if broker else None,
    )


@router.get("/deals/{deal_id}", operation_id="market_link_introduction")
async def introduction(
    deal_id: uuid.UUID, user: CurrentUser, session: DbSession
) -> IntroductionOut:
    """The introduction, for its grower, trader and broker only (404 for anyone else)."""
    deal = await session.get(MarketDeal, deal_id)
    party = await session.scalar(
        select(DealParty.id).where(DealParty.deal_id == deal_id, DealParty.user_id == user.id)
    )
    if deal is None or party is None:
        raise ApiError(404, "deal_not_found")
    return await _introduction(session, deal)
