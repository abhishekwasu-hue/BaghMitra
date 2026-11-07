"""Market linkage tables (spec v1.5 §6). Records and matching only (decisions a, m).

BagMitra never holds money: amounts are what the parties agreed or what the grower records as
received, in whole paise like Accounts. No table has a commission or income column (Q64,
decision c; `test_market_link_schema.py`). Ratings hold stars and tag ids only (Q66, decision d).

RLS kind `custom_rls`: each table has its own policies (migration 0029): a grower sees own
lots and the offers on them; verified buyers / brokers see published lots; deal parties see
their deal; a provider sees only requests sent to it. Contacts stay in `farmers` / `plots`
(owner-only RLS) and are revealed by the API to deal parties only.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import (
    JSON,
    BigInteger,
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    SmallInteger,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin, TimestampMixin, utcnow

LOT_STATUSES = ("draft", "published", "closed", "withdrawn")
BASES = ("per_tonne", "per_crate", "lump_sum")
PAYERS = ("grower", "trader", "none")
OFFER_STATUSES = ("open", "accepted", "closed", "withdrawn")
DEAL_STATUSES = ("active", "completed", "cancelled")
PARTY_ROLES = ("grower", "trader", "broker")
SUBJECT_TYPES = ("buyer", "broker", "provider")
VERIFICATION_STATUSES = ("pending", "approved", "rejected")
PROVIDER_KINDS = ("weighbridge", "transporter", "labour_gang", "crate_supplier")
REQUEST_STATUSES = ("sent", "confirmed", "declined", "cancelled")
PAYMENT_KINDS = ("advance", "balance")
RATEE_ROLES = ("grower", "trader", "broker", "provider")
TAG_POLARITIES = ("positive", "negative")
TAG_STATUSES = ("draft", "active", "retired")
DISPUTE_KINDS = ("non_payment", "weight", "quality", "terms", "other")
DISPUTE_STATUSES = ("open", "resolved")


def one_of(column: str, values: tuple[str, ...]) -> CheckConstraint:
    allowed = ", ".join(f"'{v}'" for v in values)
    return CheckConstraint(f"{column} IN ({allowed})", name=column)


class _Row(TimestampMixin):
    """A server-created row (not drafted offline): server UUID and timestamps."""

    custom_rls = True
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)


class MarketLot(OwnedSyncedRowMixin, Base):
    """A grower's produce on offer. Drafted offline (ADR 0003 sync columns); owner = grower.
    Place names are copied from the grower's profile at publish so buyers never read it."""

    __tablename__ = "market_lots"
    __table_args__ = (one_of("status", LOT_STATUSES), one_of("basis", BASES))
    custom_rls = True

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    crop: Mapped[str] = mapped_column(String(32))
    variety: Mapped[str | None] = mapped_column(String(60))
    quantity_t: Mapped[float] = mapped_column(Float)
    quality: Mapped[str | None] = mapped_column(String(500))
    harvest_from: Mapped[date] = mapped_column(Date)
    harvest_to: Mapped[date] = mapped_column(Date)
    basis: Mapped[str] = mapped_column(String(16))
    asking_rate_paise: Mapped[int | None] = mapped_column(BigInteger)
    village: Mapped[str | None] = mapped_column(String(120))
    taluka: Mapped[str | None] = mapped_column(String(120), index=True)
    district: Mapped[str | None] = mapped_column(String(120), index=True)
    status: Mapped[str] = mapped_column(String(16), index=True)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class MarketLotPhoto(OwnedSyncedRowMixin, Base):
    """In-app camera photo of a lot: capture time and GPS point (no accuracy, as Q53)."""

    __tablename__ = "market_lot_photos"
    custom_rls = True

    lot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    lat: Mapped[float] = mapped_column(Float)
    lon: Mapped[float] = mapped_column(Float)
    # Object path in the private photo bucket; None while the photo is only on the phone.
    photo_key: Mapped[str | None] = mapped_column(String(160))


class BuyerProfile(_Row, Base):
    __tablename__ = "buyer_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(unique=True)
    name: Mapped[str] = mapped_column(String(120))
    firm: Mapped[str | None] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(20))
    markets: Mapped[list[str]] = mapped_column(JSON, default=list)
    district: Mapped[str] = mapped_column(String(120), index=True)
    taluka: Mapped[str | None] = mapped_column(String(120), index=True)
    crops: Mapped[list[str]] = mapped_column(JSON, default=list)
    apmc_licence_no: Mapped[str | None] = mapped_column(String(40))
    gst_no: Mapped[str | None] = mapped_column(String(20))


class BrokerProfile(_Row, Base):
    __tablename__ = "broker_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(unique=True)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(20))
    village: Mapped[str | None] = mapped_column(String(120))
    district: Mapped[str] = mapped_column(String(120), index=True)
    taluka: Mapped[str | None] = mapped_column(String(120), index=True)
    service_areas: Mapped[list[str]] = mapped_column(JSON, default=list)
    crops: Mapped[list[str]] = mapped_column(JSON, default=list)


class PartyVerification(_Row, Base):
    """One admin check of a buyer / broker / provider. The latest row decides (decision h).
    `document_keys` are private-bucket object paths, shown to admin only."""

    __tablename__ = "party_verifications"
    __table_args__ = (
        one_of("subject_type", SUBJECT_TYPES),
        one_of("status", VERIFICATION_STATUSES),
    )

    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    document_keys: Mapped[list[str]] = mapped_column(JSON, default=list)
    status: Mapped[str] = mapped_column(String(16), index=True)
    reason: Mapped[str | None] = mapped_column(String(500))
    checked_by: Mapped[uuid.UUID | None] = mapped_column()
    checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class ServiceProvider(_Row, Base):
    """Weighbridge, transporter, labour gang or crate supplier (spec §4). `user_id` is None
    when admin added it. Providers set their own rates; BagMitra stores none."""

    __tablename__ = "service_providers"
    __table_args__ = (one_of("kind", PROVIDER_KINDS),)

    user_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    added_by: Mapped[uuid.UUID | None] = mapped_column()
    kind: Mapped[str] = mapped_column(String(16), index=True)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(20))
    village: Mapped[str | None] = mapped_column(String(120))
    district: Mapped[str] = mapped_column(String(120), index=True)
    taluka: Mapped[str | None] = mapped_column(String(120), index=True)
    service_areas: Mapped[list[str]] = mapped_column(JSON, default=list)
    lat: Mapped[float | None] = mapped_column(Float)
    lon: Mapped[float | None] = mapped_column(Float)
    cert_photo_key: Mapped[str | None] = mapped_column(String(160))
    cert_valid_until: Mapped[date | None] = mapped_column(Date)
    vehicle_numbers: Mapped[list[str]] = mapped_column(JSON, default=list)
    capacity_t: Mapped[float | None] = mapped_column(Float)
    refrigerated: Mapped[bool | None] = mapped_column()
    carrier_reg_no: Mapped[str | None] = mapped_column(String(40))


class DealTermsMixin:
    """Terms shared by an offer and a deal version (spec §3 steps 3 and 5). `rate_paise` is
    per tonne, per crate, or the whole amount for a lump sum, by `basis`."""

    basis: Mapped[str] = mapped_column(String(16))
    rate_paise: Mapped[int] = mapped_column(BigInteger)
    quantity_t: Mapped[float | None] = mapped_column(Float)
    harvest_date: Mapped[date] = mapped_column(Date)
    weighing_provider_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("service_providers.id")
    )
    labour_paid_by: Mapped[str] = mapped_column(String(16))
    crates_paid_by: Mapped[str] = mapped_column(String(16))
    transport_paid_by: Mapped[str] = mapped_column(String(16))
    advance_paise: Mapped[int | None] = mapped_column(BigInteger)
    advance_date: Mapped[date | None] = mapped_column(Date)
    balance_date: Mapped[date | None] = mapped_column(Date)
    rejection_rule: Mapped[str | None] = mapped_column(String(1000))


def _terms_checks() -> tuple[CheckConstraint, ...]:
    payers = (one_of(c, PAYERS) for c in ("labour_paid_by", "crates_paid_by", "transport_paid_by"))
    return (one_of("basis", BASES), *payers)


class MarketOffer(DealTermsMixin, _Row, Base):
    """A buyer's offer on a lot, direct or through a named broker."""

    __tablename__ = "market_offers"
    __table_args__ = (*_terms_checks(), one_of("status", OFFER_STATUSES))

    lot_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_lots.id"), index=True)
    buyer_user_id: Mapped[uuid.UUID] = mapped_column(index=True)
    broker_user_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    submitted_by: Mapped[uuid.UUID] = mapped_column()
    status: Mapped[str] = mapped_column(String(16), index=True)


class MarketDeal(_Row, Base):
    """An accepted offer. Terms live in versioned `deal_versions` rows."""

    __tablename__ = "market_deals"
    __table_args__ = (one_of("status", DEAL_STATUSES),)

    lot_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_lots.id"), index=True)
    offer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_offers.id"), unique=True)
    status: Mapped[str] = mapped_column(String(16), index=True)
    current_version: Mapped[int] = mapped_column(Integer, default=1)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DealParty(_Row, Base):
    """Grower, trader and (when there is one) broker of a deal. No commission column (Q64).
    `closed_at`: when this party marked the deal closed (completion default, Q67)."""

    __tablename__ = "deal_parties"
    __table_args__ = (UniqueConstraint("deal_id", "role"), one_of("role", PARTY_ROLES))

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    role: Mapped[str] = mapped_column(String(16))
    user_id: Mapped[uuid.UUID] = mapped_column(index=True)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DealVersion(DealTermsMixin, _Row, Base):
    """One immutable set of deal terms; a change is a new version every party confirms."""

    __tablename__ = "deal_versions"
    __table_args__ = (UniqueConstraint("deal_id", "version"), *_terms_checks())

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    version: Mapped[int] = mapped_column(Integer)
    created_by: Mapped[uuid.UUID] = mapped_column()
    other_conditions: Mapped[str | None] = mapped_column(String(1000))
    paper_note_photo_key: Mapped[str | None] = mapped_column(String(160))


class DealConfirmation(_Row, Base):
    __tablename__ = "deal_confirmations"
    __table_args__ = (UniqueConstraint("deal_version_id", "user_id"),)

    deal_version_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("deal_versions.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column()
    confirmed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class DealEvent(Base):
    """Append-only deal history; Postgres rejects UPDATE and DELETE (trigger in 0029)."""

    __tablename__ = "deal_events"
    custom_rls = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    actor_id: Mapped[uuid.UUID | None] = mapped_column()
    kind: Mapped[str] = mapped_column(String(32))
    detail: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ServiceRequest(_Row, Base):
    __tablename__ = "service_requests"
    __table_args__ = (one_of("status", REQUEST_STATUSES),)

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    provider_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("service_providers.id"), index=True)
    requested_by: Mapped[uuid.UUID] = mapped_column()
    needed_on: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(16))
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class WeighSlip(_Row, Base):
    """Weighbridge slip: kg typed by hand from the photo, confirmed by each side."""

    __tablename__ = "weigh_slips"

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    weighbridge_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("service_providers.id"))
    photo_key: Mapped[str | None] = mapped_column(String(160))
    gross_kg: Mapped[int] = mapped_column(Integer)
    tare_kg: Mapped[int] = mapped_column(Integer)
    net_kg: Mapped[int] = mapped_column(Integer)
    truck_number: Mapped[str | None] = mapped_column(String(20))
    dispatched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    entered_by: Mapped[uuid.UUID] = mapped_column()
    grower_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    trader_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DealPayment(_Row, Base):
    """A payment the grower marks as received (buyer -> grower directly, decision a).
    `accounts_sale_id` is the Accounts sale row (`incomes.id`) it flows into."""

    __tablename__ = "deal_payments"
    __table_args__ = (one_of("kind", PAYMENT_KINDS),)

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    kind: Mapped[str] = mapped_column(String(16))
    amount_paise: Mapped[int] = mapped_column(BigInteger)
    received_on: Mapped[date] = mapped_column(Date)
    accounts_sale_id: Mapped[uuid.UUID | None] = mapped_column()
    recorded_by: Mapped[uuid.UUID] = mapped_column()


class Rating(_Row, Base):
    """Stars for one question plus ticked tag ids. No text column (Q66, decision d)."""

    __tablename__ = "ratings"
    __table_args__ = (
        UniqueConstraint("deal_id", "rater_id", "ratee_id", "question_key"),
        CheckConstraint("stars BETWEEN 1 AND 5", name="stars"),
        one_of("ratee_role", RATEE_ROLES),
    )

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    rater_id: Mapped[uuid.UUID] = mapped_column(index=True)
    ratee_id: Mapped[uuid.UUID] = mapped_column(index=True)
    ratee_role: Mapped[str] = mapped_column(String(16))
    question_key: Mapped[str] = mapped_column(String(40))
    stars: Mapped[int] = mapped_column(SmallInteger)
    tag_ids: Mapped[list[str]] = mapped_column(JSON, default=list)


class RatingTag(_Row, Base):
    """Admin-edited tick list under each rating question (spec §3A). Signed-in users read
    only active tags; drafts wait for native-speaker review."""

    __tablename__ = "rating_tags"
    __table_args__ = (one_of("polarity", TAG_POLARITIES), one_of("status", TAG_STATUSES))

    key: Mapped[str] = mapped_column(String(64), unique=True)
    question_key: Mapped[str] = mapped_column(String(40), index=True)
    polarity: Mapped[str] = mapped_column(String(16))
    label_mr: Mapped[str] = mapped_column(String(120))
    label_hi: Mapped[str] = mapped_column(String(120))
    label_en: Mapped[str] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(String(16), index=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)


class Dispute(_Row, Base):
    """A dispute goes to admin only (spec §3 step 9)."""

    __tablename__ = "disputes"
    __table_args__ = (one_of("kind", DISPUTE_KINDS), one_of("status", DISPUTE_STATUSES))

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    raised_by: Mapped[uuid.UUID] = mapped_column(index=True)
    against_user_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    kind: Mapped[str] = mapped_column(String(16))
    status: Mapped[str] = mapped_column(String(16), index=True)
    photo_keys: Mapped[list[str]] = mapped_column(JSON, default=list)
    decision_note: Mapped[str | None] = mapped_column(String(1000))
    decided_by: Mapped[uuid.UUID | None] = mapped_column()
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


# Every table defined above (the schema and RLS tests walk this list).
MARKET_LINK_TABLES = tuple(
    cls.__tablename__ for cls in Base.__subclasses__() if cls.__module__ == __name__
)
