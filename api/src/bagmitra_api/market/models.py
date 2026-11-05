from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Date, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base


class MarketPrice(Base):
    """One published mandi price row (₹ per quintal). Public market data, not owner data.
    Variety and grade are '' when the source leaves them blank so they can be part of the key."""

    __tablename__ = "market_prices"
    private_table = True  # service-only (RLS on, no policy); served through the API

    day: Mapped[date] = mapped_column(Date, primary_key=True)
    market: Mapped[str] = mapped_column(String(80), primary_key=True)
    commodity: Mapped[str] = mapped_column(String(80), primary_key=True)
    variety: Mapped[str] = mapped_column(String(80), primary_key=True)
    grade: Mapped[str] = mapped_column(String(40), primary_key=True)
    source: Mapped[str] = mapped_column(String(32), primary_key=True)
    state: Mapped[str] = mapped_column(String(80))
    district: Mapped[str] = mapped_column(String(80))
    min_rs_per_quintal: Mapped[int | None] = mapped_column(Integer)
    max_rs_per_quintal: Mapped[int | None] = mapped_column(Integer)
    modal_rs_per_quintal: Mapped[int] = mapped_column(Integer)
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class MarketPull(Base):
    """Outcome of the scheduled Agmarknet pull per commodity (audit BG-04). The price read path
    never fetches; it uses this row to say whether the stored prices are current, and why not.
    `last_error` is a reason code (agmarknet.REASON_*), null after a successful pull."""

    __tablename__ = "market_pulls"
    private_table = True  # service-only (RLS on, no policy)

    commodity: Mapped[str] = mapped_column(String(80), primary_key=True)
    last_attempt_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    last_success_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_error: Mapped[str | None] = mapped_column(String(32))
    last_rows: Mapped[int] = mapped_column(Integer, default=0)
