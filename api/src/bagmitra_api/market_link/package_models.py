"""Season sale package tables (spec v1.5 §4D, §4E; migration 0035).

A grower pays the company a one-time listing fee OUTSIDE the app (UPI / cash / bank); an admin
records it as a `package_grants` row. The fee is for the listing service only, never a share of
a sale, so these tables live apart from the introduction-only market-link tables (which hold no
payment column, `test_market_link_schema.py`) and hold no deal, rate or trader column.

`company_profile` and `season_package_settings` are single rows (id 1) that start empty with the
switch OFF; the API creates them on first read. RLS (0035): both private (admin API only); a
grower reads their own grants (the API returns status and dates only); traders read none.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    LargeBinary,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin

PAYMENT_METHODS = ("upi", "cash", "bank")
# admin_actions subjects / actions / reason codes added for the package (0035).
PACKAGE_SUBJECTS = ("company_profile", "package_settings", "package_grant")
PACKAGE_ACTIONS = ("settings_change", "grant", "revoke")
PACKAGE_REASONS = ("admin_setting", "payment_recorded", "grant_revoked")
# The single rows have no uuid; their admin_actions rows use these fixed subject ids.
COMPANY_PROFILE_SUBJECT = uuid.UUID("00000000-0000-4000-8000-00000000c001")
PACKAGE_SETTINGS_SUBJECT = uuid.UUID("00000000-0000-4000-8000-00000000c002")


class CompanyProfile(TimestampMixin, Base):
    """The company's details for receipts and the representatives' QR card (§4E). Bank
    account: name, IFSC and the last 4 digits only. GST rate in basis points (1800 = 18 %),
    empty until the CA advises."""

    __tablename__ = "company_profile"
    private_table = True
    __table_args__ = (
        CheckConstraint("id = 1", name="single_row"),
        CheckConstraint("gst_rate_bp IS NULL OR gst_rate_bp BETWEEN 0 AND 10000", name="gst_rate"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    legal_name: Mapped[str | None] = mapped_column(String(160))
    trade_name: Mapped[str | None] = mapped_column(String(160))
    address: Mapped[str | None] = mapped_column(String(400))
    gstin: Mapped[str | None] = mapped_column(String(15))
    pan: Mapped[str | None] = mapped_column(String(10))
    bank_account_name: Mapped[str | None] = mapped_column(String(160))
    bank_ifsc: Mapped[str | None] = mapped_column(String(11))
    bank_account_last4: Mapped[str | None] = mapped_column(String(4))
    upi_id: Mapped[str | None] = mapped_column(String(80))
    merchant_qr: Mapped[bytes | None] = mapped_column(LargeBinary)
    merchant_qr_type: Mapped[str | None] = mapped_column(String(16))
    invoice_prefix: Mapped[str | None] = mapped_column(String(16))
    gst_rate_bp: Mapped[int | None] = mapped_column(Integer)


class SeasonPackageSettings(TimestampMixin, Base):
    """Switch (default OFF = every published lot visible free), price, validity, start date."""

    __tablename__ = "season_package_settings"
    private_table = True
    __table_args__ = (
        CheckConstraint("id = 1", name="single_row"),
        CheckConstraint("price_paise IS NULL OR price_paise > 0", name="price"),
        CheckConstraint("validity_days IS NULL OR validity_days > 0", name="validity"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    price_paise: Mapped[int | None] = mapped_column(BigInteger)
    validity_days: Mapped[int | None] = mapped_column(Integer)
    starts_at: Mapped[date | None] = mapped_column(Date)


class PackageGrant(TimestampMixin, Base):
    """One recorded payment: the grower's lot (or every lot when `lot_id` is null) is shown to
    traders while `activated_at <= now < valid_until` and not revoked. `payment_ref` (UTR) is
    unique; `receipt_no` = prefix + running number, gapless per prefix."""

    __tablename__ = "package_grants"
    custom_rls = True
    __table_args__ = (
        UniqueConstraint("receipt_prefix", "receipt_seq", name="uq_package_grants_receipt_seq"),
        CheckConstraint("amount_paise > 0", name="amount"),
        CheckConstraint("receipt_seq > 0", name="receipt_seq"),
        CheckConstraint("valid_until > activated_at", name="validity"),
        CheckConstraint(
            "method IN ({})".format(", ".join(f"'{m}'" for m in PAYMENT_METHODS)), name="method"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    grower_id: Mapped[uuid.UUID] = mapped_column(index=True)
    lot_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("market_lots.id"), index=True)
    amount_paise: Mapped[int] = mapped_column(BigInteger)
    method: Mapped[str] = mapped_column(String(8))
    payment_ref: Mapped[str] = mapped_column(String(40), unique=True)
    paid_on: Mapped[date] = mapped_column(Date)
    activated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    valid_until: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    receipt_prefix: Mapped[str] = mapped_column(String(16))
    receipt_seq: Mapped[int] = mapped_column(Integer)
    receipt_no: Mapped[str] = mapped_column(String(32), unique=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    revoked_reason: Mapped[str | None] = mapped_column(String(200))
    admin_id: Mapped[uuid.UUID] = mapped_column()
    # When the activation push reached at least one of the grower's phones.
    notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


PACKAGE_TABLES = ("company_profile", "season_package_settings", "package_grants")
