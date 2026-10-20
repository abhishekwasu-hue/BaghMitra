"""Billing tables (billing addendum §2.1). Plans and their features are admin-editable reference
data; subscriptions, the event ledger and entitlement snapshots are private (service only: no
grower or signed-in client can read them, the API returns the computed entitlements)."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin


class BillingPlan(TimestampMixin, Base):
    __tablename__ = "billing_plans"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(32), unique=True)
    names: Mapped[dict[str, str]] = mapped_column(JSON)
    # grower | organisation
    kind: Mapped[str] = mapped_column(String(16))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)


class PlanEntitlement(TimestampMixin, Base):
    """One feature a plan includes; a null limit means included without a limit."""

    __tablename__ = "plan_entitlements"
    __table_args__ = (UniqueConstraint("plan_id", "feature_key"),)
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    plan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("billing_plans.id"), index=True)
    feature_key: Mapped[str] = mapped_column(String(32))
    limit_value: Mapped[int | None] = mapped_column(Integer)


class Subscription(TimestampMixin, Base):
    __tablename__ = "subscriptions"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    # farmer | organisation
    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    plan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("billing_plans.id"), index=True)
    # google_play | web_invoice | manual_grant
    provider: Mapped[str] = mapped_column(String(16))
    provider_product_id: Mapped[str | None] = mapped_column(String(120))
    purchase_token_hash: Mapped[str | None] = mapped_column(String(64), unique=True)
    state: Mapped[str] = mapped_column(String(16))
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    auto_renew: Mapped[bool] = mapped_column(Boolean, default=False)
    grace_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    reason: Mapped[str | None] = mapped_column(Text)
    granted_by: Mapped[uuid.UUID | None] = mapped_column()


class BillingEvent(TimestampMixin, Base):
    """Append-only ledger of every grant, notification and verification (idempotent on
    `notification_id` for provider notifications)."""

    __tablename__ = "billing_events"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    subscription_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("subscriptions.id"), index=True
    )
    provider: Mapped[str] = mapped_column(String(16))
    event_type: Mapped[str] = mapped_column(String(40))
    notification_id: Mapped[str | None] = mapped_column(String(120), unique=True)
    payload: Mapped[dict[str, Any]] = mapped_column(JSON)


class EntitlementSnapshot(TimestampMixin, Base):
    """The latest computed entitlements of a subject: what the app downloads."""

    __tablename__ = "entitlement_snapshots"
    __table_args__ = (UniqueConstraint("subject_type", "subject_id"),)
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    subject_type: Mapped[str] = mapped_column(String(16))
    subject_id: Mapped[uuid.UUID] = mapped_column(index=True)
    computed: Mapped[dict[str, Any]] = mapped_column(JSON)
    valid_until: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    signature: Mapped[str | None] = mapped_column(Text)
