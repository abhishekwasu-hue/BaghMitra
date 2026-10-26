from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base


class WeatherDaily(Base):
    """One provider day for one location cell. Location data, not owner data: plots in the
    same cell share a row, and no plot or owner id is stored."""

    __tablename__ = "weather_daily"

    cell_lat: Mapped[float] = mapped_column(Float, primary_key=True)
    cell_lon: Mapped[float] = mapped_column(Float, primary_key=True)
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    t_max_c: Mapped[float | None] = mapped_column(Float)
    t_min_c: Mapped[float | None] = mapped_column(Float)
    precip_mm: Mapped[float | None] = mapped_column(Float)
    rh_mean_pct: Mapped[float | None] = mapped_column(Float)
    wind_gust_kmh: Mapped[float | None] = mapped_column(Float)
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
