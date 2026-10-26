"""Stored weather risk alerts: what the daily pull found for each plot, kept once per
(plot, rule, first day) so a repeated pull never repeats an alert."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, utcnow


class PlotRiskAlert(Base):
    """One rule-based alert for one plot. Owner data (RLS by `owner_id`).

    `notified_at` stays null until a later delivery step sends a push for every row with
    `notified_at IS NULL` and stamps it.
    """

    __tablename__ = "plot_risk_alerts"
    __table_args__ = (UniqueConstraint("plot_id", "rule_key", "first_day"),)
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    plot_id: Mapped[uuid.UUID] = mapped_column()
    rule_key: Mapped[str] = mapped_column(String(64))
    first_day: Mapped[date] = mapped_column(Date)
    value: Mapped[float] = mapped_column(Float)
    units: Mapped[float | None] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
