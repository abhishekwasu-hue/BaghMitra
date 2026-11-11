"""Market linkage tables (spec v1.5 §6). Records and matching only (decisions a, m).

Introduction only (spec v1.5 §1 core principle, Addendum 5): BagMitra introduces grower, trader
and broker and never enters their transaction or disputes, so no table holds deal terms,
payments, weigh slips, service bookings or disputes (dropped in 0030). An interest's rate is in
whole paise like Accounts. No table has a commission, income, payment or Aadhaar column (Q64,
decision c, addendum 1; `test_market_link_schema.py`). Ratings hold stars and tag ids only (Q66).

RLS kind `custom_rls`: each table has its own policies (migrations 0029, 0030): a grower sees
own lots and the interests on them; verified buyers / brokers see published lots; deal parties
see their deal; each user sees only their own registration fix, reports, blocks, acceptances
and the admin actions about them. Contacts stay in `farmers` / `plots` (owner-only RLS) and are
revealed by the API to the parties of an accepted interest only.
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
from bagmitra_api.market_link.package_models import (
    PACKAGE_ACTIONS,
    PACKAGE_REASONS,
    PACKAGE_SUBJECTS,
)

LOT_STATUSES = ("draft", "published", "closed", "withdrawn")
# Per quintal (owner 2026-11-11, Q138: the same unit as the mandi price shown beside it), per
# crate, or the whole orchard. "per_tonne" was the old name (migration 0046 converted it).
BASES = ("per_quintal", "per_crate", "lump_sum")
OFFER_STATUSES = ("open", "accepted", "closed", "withdrawn")
DEAL_STATUSES = ("active", "completed", "cancelled")
PARTY_ROLES = ("grower", "trader", "broker")
SUBJECT_TYPES = ("buyer", "broker", "provider")
VERIFICATION_STATUSES = ("pending", "approved", "rejected")
PROVIDER_KINDS = ("weighbridge", "transporter", "labour_gang", "crate_supplier")
BUYER_KINDS = ("trader", "exporter")
RATEE_ROLES = ("grower", "trader", "broker")
TAG_POLARITIES = ("positive", "negative")
TAG_STATUSES = ("draft", "active", "retired")
# Who registers with the one GPS fix (spec §4): profiles, plus a representative (user id).
FIX_SUBJECT_TYPES = (*SUBJECT_TYPES, "representative")
# Report / admin action targets (spec §4, §3A, §4C): a profile, a lot, a rating, or a user.
REPORT_SUBJECT_TYPES = (*SUBJECT_TYPES, "lot", "rating", "user")
REPORT_REASONS = ("fake_identity", "fake_lot", "impersonation", "fake_rating", "abuse")
REPORT_STATUSES = ("open", "actioned", "dismissed")
ADMIN_ACTIONS = ("verify", "warn", "hide", "suspend", "restore")
# Reason codes shown to the user (§4C): the report reasons, plus a duplicate registration and
# the two that close a check or an appeal.
ADMIN_REASONS = (*REPORT_REASONS, "duplicate_user", "checks_passed", "appeal_upheld")
# The season sale package logs its settings changes and grants here too (§4E, 0035).
# The lot form settings (Q138, 0046) log their changes as settings_change / admin_setting.
ADMIN_SUBJECT_TYPES = (*REPORT_SUBJECT_TYPES, *PACKAGE_SUBJECTS, "lot_settings")
ADMIN_ACTION_KINDS = (*ADMIN_ACTIONS, *PACKAGE_ACTIONS)
ADMIN_REASON_CODES = (*ADMIN_REASONS, *PACKAGE_REASONS)
APPEAL_STATES = ("none", "appealed", "upheld", "rejected")
# Which reason codes each action may carry (§1 core principle, Addendum 5): warn / hide /
# suspend only on platform rules, never on a payment, weight or quality quarrel.
PLATFORM_REASONS = (*REPORT_REASONS, "duplicate_user")
ACTION_REASONS: dict[str, tuple[str, ...]] = {
    "verify": ("checks_passed",),
    "warn": PLATFORM_REASONS,
    "hide": PLATFORM_REASONS,
    "suspend": PLATFORM_REASONS,
    "restore": ("checks_passed", "appeal_upheld"),
}
APPEALABLE_ACTIONS = ("warn", "hide", "suspend")
# The one appeal: a predefined reason, no free text (§4C, Q92).
APPEAL_REASONS = (
    "identity_genuine",
    "lot_genuine",
    "rating_genuine",
    "behaviour_proper",
    "not_duplicate",
)
TERMS_ROLES = ("grower", "trader", "exporter", "broker", "provider", "representative")
TERMS_DOCS = ("terms", "privacy", "disclaimer")
# A lot is published with 3 to 8 in-app photos (spec v1.5 §3 step 1).
LOT_MIN_PHOTOS = 3
LOT_MAX_PHOTOS = 8
# Real orchard check (spec §4C): only inside / near lots reach traders and brokers.
ORCHARD_CHECKS = ("inside", "near", "outside", "unmapped")
ORCHARD_OK = ("inside", "near")
# One admin check by hand on a free official page (spec §4, L7): the kind, and what was found.
CHECK_KINDS = ("gstin", "apmc", "fssai", "iec", "apeda", "phone_call", "place_photo")
# `cancelled`: GST cancelled / IEC deactivated / licence no longer valid (found on a re-check).
CHECK_RESULTS = ("passed", "failed", "cancelled")


def one_of(column: str, values: tuple[str, ...]) -> CheckConstraint:
    allowed = ", ".join(f"'{v}'" for v in values)
    return CheckConstraint(f"{column} IN ({allowed})", name=column)


class AddressMixin:
    """Optional place address (addendum 2): set by the person or a market_link_rep."""

    address: Mapped[str | None] = mapped_column(String(300))
    address_set_by: Mapped[uuid.UUID | None] = mapped_column()
    address_set_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class _Row(TimestampMixin):
    """A server-created row (not drafted offline): server UUID and timestamps."""

    custom_rls = True
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)


class MarketLot(OwnedSyncedRowMixin, Base):
    """A grower's produce on offer. Drafted offline (ADR 0003 sync columns); owner = grower.
    Place names are copied from the grower's profile at publish so buyers never read it."""

    __tablename__ = "market_lots"
    __table_args__ = (
        one_of("status", LOT_STATUSES),
        one_of("basis", BASES),
        one_of("orchard_check", ORCHARD_CHECKS),
    )
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
    # Set at publish (spec §4C, migration 0032): a lot that is not inside / near the mapped
    # plot stays out of the traders' list and waits for an admin check.
    orchard_check: Mapped[str | None] = mapped_column(String(16))


class MarketLotSettings(TimestampMixin, Base):
    """The admin's lot form settings (owner 2026-11-11, Q138), one row: the rate range per
    crop (santra, mosambi) and basis (per quintal, per crate), for the grower's asking rate and
    a trader's interest, and how many days after the chosen start the harvest window ends by
    default. Empty = the default in `market_link/lot_rules.py`."""

    __tablename__ = "market_lot_settings"
    private_table = True
    __table_args__ = (
        CheckConstraint("id = 1", name="single_row"),
        CheckConstraint(
            "santra_per_quintal_min_paise IS NULL OR santra_per_quintal_min_paise > 0",
            name="santra_per_quintal_min",
        ),
        CheckConstraint(
            "santra_per_quintal_max_paise IS NULL OR santra_per_quintal_max_paise > 0",
            name="santra_per_quintal_max",
        ),
        CheckConstraint(
            "santra_per_crate_min_paise IS NULL OR santra_per_crate_min_paise > 0",
            name="santra_per_crate_min",
        ),
        CheckConstraint(
            "santra_per_crate_max_paise IS NULL OR santra_per_crate_max_paise > 0",
            name="santra_per_crate_max",
        ),
        CheckConstraint(
            "mosambi_per_quintal_min_paise IS NULL OR mosambi_per_quintal_min_paise > 0",
            name="mosambi_per_quintal_min",
        ),
        CheckConstraint(
            "mosambi_per_quintal_max_paise IS NULL OR mosambi_per_quintal_max_paise > 0",
            name="mosambi_per_quintal_max",
        ),
        CheckConstraint(
            "mosambi_per_crate_min_paise IS NULL OR mosambi_per_crate_min_paise > 0",
            name="mosambi_per_crate_min",
        ),
        CheckConstraint(
            "mosambi_per_crate_max_paise IS NULL OR mosambi_per_crate_max_paise > 0",
            name="mosambi_per_crate_max",
        ),
        CheckConstraint(
            "harvest_window_days IS NULL OR harvest_window_days >= 0", name="harvest_days"
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    santra_per_quintal_min_paise: Mapped[int | None] = mapped_column(BigInteger)
    santra_per_quintal_max_paise: Mapped[int | None] = mapped_column(BigInteger)
    santra_per_crate_min_paise: Mapped[int | None] = mapped_column(BigInteger)
    santra_per_crate_max_paise: Mapped[int | None] = mapped_column(BigInteger)
    mosambi_per_quintal_min_paise: Mapped[int | None] = mapped_column(BigInteger)
    mosambi_per_quintal_max_paise: Mapped[int | None] = mapped_column(BigInteger)
    mosambi_per_crate_min_paise: Mapped[int | None] = mapped_column(BigInteger)
    mosambi_per_crate_max_paise: Mapped[int | None] = mapped_column(BigInteger)
    harvest_window_days: Mapped[int | None] = mapped_column(Integer)


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


class BuyerProfile(AddressMixin, _Row, Base):
    """A trader or an exporter (IEC required for an exporter, spec §4). Registration numbers
    are indexed, not unique: a second claim of the same number must reach admin (§4C, Q80)."""

    __tablename__ = "buyer_profiles"
    __table_args__ = (
        one_of("kind", BUYER_KINDS),
        CheckConstraint("kind <> 'exporter' OR iec_no IS NOT NULL", name="exporter_iec"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(unique=True)
    name: Mapped[str] = mapped_column(String(120))
    firm: Mapped[str | None] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(20))
    markets: Mapped[list[str]] = mapped_column(JSON, default=list)
    district: Mapped[str] = mapped_column(String(120), index=True)
    taluka: Mapped[str | None] = mapped_column(String(120), index=True)
    crops: Mapped[list[str]] = mapped_column(JSON, default=list)
    kind: Mapped[str] = mapped_column(String(16), default="trader")
    apmc_licence_no: Mapped[str | None] = mapped_column(String(40), index=True)
    gst_no: Mapped[str | None] = mapped_column(String(20), index=True)
    iec_no: Mapped[str | None] = mapped_column(String(10), index=True)
    # Kept for the admin's manual check on FoSCoS / the APEDA directory (spec §4, 0031).
    fssai_no: Mapped[str | None] = mapped_column(String(14), index=True)
    apeda_no: Mapped[str | None] = mapped_column(String(40), index=True)


class BrokerProfile(AddressMixin, _Row, Base):
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


class ServiceProvider(AddressMixin, _Row, Base):
    """Weighbridge, transporter, labour gang or crate supplier (spec §4). `user_id` is None
    when admin added it. A directory entry with a phone number only, no booking (spec §3
    step 6); providers set their own rates and BagMitra stores none."""

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


class MarketOffer(_Row, Base):
    """A trader's interest in a lot, direct or through a named broker (spec §3 step 3): rate
    and basis, quantity, proposed harvest date; everything else is settled off the app.
    `rate_paise` is per quintal, per crate, or the whole amount for a lump sum, by `basis`."""

    __tablename__ = "market_offers"
    __table_args__ = (one_of("basis", BASES), one_of("status", OFFER_STATUSES))

    basis: Mapped[str] = mapped_column(String(16))
    rate_paise: Mapped[int] = mapped_column(BigInteger)
    quantity_t: Mapped[float | None] = mapped_column(Float)
    harvest_date: Mapped[date] = mapped_column(Date)
    lot_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_lots.id"), index=True)
    buyer_user_id: Mapped[uuid.UUID] = mapped_column(index=True)
    broker_user_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    submitted_by: Mapped[uuid.UUID] = mapped_column()
    status: Mapped[str] = mapped_column(String(16), index=True)


class MarketDeal(_Row, Base):
    """An introduction: the grower accepted an interest (contacts revealed). No terms. It
    completes when both grower and trader tap "deal done" (Q67); rating opens then."""

    __tablename__ = "market_deals"
    __table_args__ = (one_of("status", DEAL_STATUSES),)

    lot_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_lots.id"), index=True)
    offer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_offers.id"), unique=True)
    status: Mapped[str] = mapped_column(String(16), index=True)
    accepted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    grower_done_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    trader_done_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Set when both taps are in (the later of the two).
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DealParty(_Row, Base):
    """Grower, trader and (when there is one) broker of a deal. No commission column (Q64)."""

    __tablename__ = "deal_parties"
    __table_args__ = (UniqueConstraint("deal_id", "role"), one_of("role", PARTY_ROLES))

    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("market_deals.id"), index=True)
    role: Mapped[str] = mapped_column(String(16))
    user_id: Mapped[uuid.UUID] = mapped_column(index=True)


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


class RegistrationFix(_Row, Base):
    """The one foreground GPS fix taken when a trader, exporter, broker, provider or
    representative registers (spec §4, addendum 3): no background or repeated tracking. A
    table of its own, not profile columns, because verified profile rows are readable by any
    signed-in client (RLS cannot hide columns) and exact coordinates are admin-only (Q79)."""

    __tablename__ = "registration_fixes"
    __table_args__ = (one_of("subject_type", FIX_SUBJECT_TYPES),)

    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(index=True)
    lat: Mapped[float] = mapped_column(Float)
    lon: Mapped[float] = mapped_column(Float)
    accuracy_m: Mapped[float] = mapped_column(Float)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    # The phone's own geocoder (place_geocoder.dart); None when it named nothing.
    place: Mapped[str | None] = mapped_column(String(120))
    district: Mapped[str | None] = mapped_column(String(120))
    state: Mapped[str | None] = mapped_column(String(120))
    pin: Mapped[str | None] = mapped_column(String(6))
    # The location plugin reported a mock (fake-GPS) position.
    is_mocked: Mapped[bool] = mapped_column(default=False)


class RepresentativeUpload(_Row, Base):
    """A place photo (in-app camera, capture time + GPS) and / or address a BagMitra
    representative added to a profile they visited (addendum 2); who and when are stored."""

    __tablename__ = "representative_uploads"
    __table_args__ = (
        one_of("subject_type", SUBJECT_TYPES),
        CheckConstraint("photo_key IS NOT NULL OR address IS NOT NULL", name="something"),
        CheckConstraint(
            "photo_key IS NULL OR (captured_at IS NOT NULL AND lat IS NOT NULL "
            "AND lon IS NOT NULL)",
            name="photo_time_gps",
        ),
    )

    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    uploaded_by: Mapped[uuid.UUID] = mapped_column(index=True)
    photo_key: Mapped[str | None] = mapped_column(String(160))
    captured_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    lat: Mapped[float | None] = mapped_column(Float)
    lon: Mapped[float | None] = mapped_column(Float)
    address: Mapped[str | None] = mapped_column(String(300))


class FraudReport(_Row, Base):
    """A report on a profile, lot or user (spec §4): predefined reason, optional photos, no
    free text. Admin acts on platform rules only, never on a business quarrel (§1)."""

    __tablename__ = "fraud_reports"
    __table_args__ = (
        one_of("subject_type", REPORT_SUBJECT_TYPES),
        one_of("reason", REPORT_REASONS),
        one_of("status", REPORT_STATUSES),
    )

    reporter_id: Mapped[uuid.UUID] = mapped_column(index=True)
    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    reason: Mapped[str] = mapped_column(String(32))
    photo_keys: Mapped[list[str]] = mapped_column(JSON, default=list)
    status: Mapped[str] = mapped_column(String(16), index=True)
    decided_by: Mapped[uuid.UUID | None] = mapped_column()
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Grievance timeline (IT Rules 2021, §4C): acknowledged within 24 h, closed (decided)
    # within 15 days; the admin list flags an overdue one.
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    admin_action_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("admin_actions.id"))


class AdminAction(_Row, Base):
    """Every verify / warn / hide / suspend / restore, with a reason code the user sees, the
    actor and the time; one appeal through the grievance officer (spec §4C). The action
    columns never change and no row is deleted (Postgres trigger, 0033); only the appeal
    columns move (none -> appealed -> upheld / rejected). Season package settings changes and
    grants carry `detail` = {"old": ..., "new": ...} (§4E)."""

    __tablename__ = "admin_actions"
    __table_args__ = (
        one_of("subject_type", ADMIN_SUBJECT_TYPES),
        one_of("action", ADMIN_ACTION_KINDS),
        one_of("reason_code", ADMIN_REASON_CODES),
        one_of("appeal_state", APPEAL_STATES),
        one_of("appeal_reason", APPEAL_REASONS),  # NULL passes a CHECK: no appeal yet
    )

    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    # The user the action is about (who sees the reason code and may appeal).
    user_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    action: Mapped[str] = mapped_column(String(16))
    reason_code: Mapped[str] = mapped_column(String(32))
    actor_id: Mapped[uuid.UUID] = mapped_column()
    acted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    appeal_state: Mapped[str] = mapped_column(String(16), default="none")
    appealed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    appeal_reason: Mapped[str | None] = mapped_column(String(32))
    appeal_photo_keys: Mapped[list[str]] = mapped_column(JSON, default=list)
    appeal_acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    appeal_decided_by: Mapped[uuid.UUID | None] = mapped_column()
    appeal_decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    detail: Mapped[dict[str, Any] | None] = mapped_column(JSON)


class TermsAcceptance(_Row, Base):
    """Terms, privacy notice or disclaimer accepted for a role before it is used (spec §4C):
    versioned and time-stamped, with the 18+ declaration (minors cannot contract)."""

    __tablename__ = "terms_acceptances"
    __table_args__ = (
        UniqueConstraint("user_id", "role", "doc_kind", "version"),
        one_of("role", TERMS_ROLES),
        one_of("doc_kind", TERMS_DOCS),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(index=True)
    role: Mapped[str] = mapped_column(String(16))
    doc_kind: Mapped[str] = mapped_column(String(16))
    version: Mapped[str] = mapped_column(String(20))
    accepted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    adult_declared: Mapped[bool] = mapped_column()


class UserBlock(_Row, Base):
    """One user blocked another in the app (Google Play UGC, spec §4C)."""

    __tablename__ = "user_blocks"
    __table_args__ = (
        UniqueConstraint("blocker_id", "blocked_id"),
        CheckConstraint("blocker_id <> blocked_id", name="not_self"),
    )

    blocker_id: Mapped[uuid.UUID] = mapped_column(index=True)
    blocked_id: Mapped[uuid.UUID] = mapped_column(index=True)


class VerificationCheck(_Row, Base):
    """One check the admin did by hand (spec §4, L7): kind, the number checked, the result,
    the official page opened, who and when. Never edited; the latest row per subject and kind
    decides, so a re-check that finds GST cancelled or IEC deactivated removes the badge.
    `recheck_listed_at`: set by the yearly re-check job (recheck_job.py) on a stale pass."""

    __tablename__ = "verification_checks"
    __table_args__ = (
        one_of("subject_type", SUBJECT_TYPES),
        one_of("kind", CHECK_KINDS),
        one_of("result", CHECK_RESULTS),
    )

    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    kind: Mapped[str] = mapped_column(String(16))
    number: Mapped[str | None] = mapped_column(String(40))
    result: Mapped[str] = mapped_column(String(16))
    # GST only: the registration year on the public record ("registered since <year>").
    registered_year: Mapped[int | None] = mapped_column(SmallInteger)
    official_url: Mapped[str | None] = mapped_column(String(300))
    checked_by: Mapped[uuid.UUID] = mapped_column()
    checked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    recheck_listed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DeviceSighting(_Row, Base):
    """An account seen on a phone: the SHA-256 of its push token, written when the phone
    registers for push while the module is on (spec §4C "same phone cannot rate", Q100).
    A push token row moves to the latest account, so this keeps who else used the phone."""

    __tablename__ = "device_sightings"
    __table_args__ = (UniqueConstraint("device_hash", "user_id"),)

    device_hash: Mapped[str] = mapped_column(String(64), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(index=True)


# Every table defined above (the schema and RLS tests walk this list).
MARKET_LINK_TABLES = tuple(
    cls.__tablename__ for cls in Base.__subclasses__() if cls.__module__ == __name__
)
