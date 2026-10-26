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
    district: Mapped[str] = mapped_column(String(80))
    min_rs_per_quintal: Mapped[int | None] = mapped_column(Integer)
    max_rs_per_quintal: Mapped[int | None] = mapped_column(Integer)
    modal_rs_per_quintal: Mapped[int] = mapped_column(Integer)
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
