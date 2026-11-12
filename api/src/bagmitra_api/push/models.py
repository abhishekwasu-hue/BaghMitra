"""Push tables: the phones (push_devices), each grower's update-push switches
(push_topic_prefs), the log of update pushes (push_notices) and the forecast the weather
change check last compared (push_weather_seen). Owner 2026-11-12, OPEN_QUESTIONS Q147."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import JSON, Boolean, Date, DateTime, Float, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin, utcnow

# push_notices.kind
ARTICLE = "article"
MARKET = "market"
WEATHER = "weather"
NOTICE_KINDS = (ARTICLE, MARKET, WEATHER)


class PushDevice(TimestampMixin, Base):
    """A phone's push token, owned by the account signed in on it. Owner data (RLS).

    A token belongs to one phone, so it is unique: when another account signs in on the
    same phone the row moves to that account.
    """

    __tablename__ = "push_devices"
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    token: Mapped[str] = mapped_column(String(512), unique=True)
    platform: Mapped[str] = mapped_column(String(16))


class PushTopicPrefs(TimestampMixin, Base):
    """The grower's three update-push switches (Settings -> सूचना). No row: the defaults
    (PUSH_TOPIC_*_DEFAULT, all on). Owner data (RLS)."""

    __tablename__ = "push_topic_prefs"
    owner_column = "owner_id"

    owner_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    articles: Mapped[bool] = mapped_column(Boolean)
    market: Mapped[bool] = mapped_column(Boolean)
    weather_change: Mapped[bool] = mapped_column(Boolean)


class PushNotice(Base):
    """One thing an update push tells (or will tell) a grower, once: an article, a mandi
    series' price change of one day, or one weather change of one plot and day.

    `subject` is the dedupe key (unique per owner and kind): the item id;
    "market|commodity|variety|grade|day"; "plot id|day|signal". Article and market rows are
    written when their push went out; weather rows are written by the check with
    `notified_at` null and stamped once sent. `day` is the India date a sent row counts
    towards (daily caps; for a weather row the forecast day until it is sent); the rows of
    one push share `push_id`. Owner data (RLS)."""

    __tablename__ = "push_notices"
    __table_args__ = (UniqueConstraint("owner_id", "kind", "subject"),)
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    kind: Mapped[str] = mapped_column(String(16))
    subject: Mapped[str] = mapped_column(String(300))
    plot_id: Mapped[uuid.UUID | None] = mapped_column()
    day: Mapped[date] = mapped_column(Date, index=True)
    data: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    push_id: Mapped[uuid.UUID | None] = mapped_column()
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class PushWeatherSeen(Base):
    """The forecast of one weather cell and day as the weather change check last compared it
    ("the previous forecast"). Location data, no owner: service-only (RLS with a policy that
    matches no row)."""

    __tablename__ = "push_weather_seen"
    private_table = True

    cell_lat: Mapped[float] = mapped_column(Float, primary_key=True)
    cell_lon: Mapped[float] = mapped_column(Float, primary_key=True)
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    rain_prob_pct: Mapped[float | None] = mapped_column(Float)
    precip_mm: Mapped[float | None] = mapped_column(Float)
    wind_gust_kmh: Mapped[float | None] = mapped_column(Float)
    t_max_c: Mapped[float | None] = mapped_column(Float)
    t_min_c: Mapped[float | None] = mapped_column(Float)
    seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
