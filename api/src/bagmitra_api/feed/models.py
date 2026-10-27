"""Feed tables (addendum v1.4 §5).

RLS kinds: sources and the published feed are reference data (signed-in users may read; the
item tables only expose published or withdrawn items, see migration 0018). Review events are
private (service-only). The app reads the feed through `GET /v1/feed`, never directly.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import (
    JSON,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin, utcnow

ITEM_TYPES = ("gr", "circular", "scheme", "alert", "news")
ITEM_STATUSES = ("draft", "in_review", "published", "withdrawn")
LANGS = ("en", "mr", "hi")


class FeedSource(TimestampMixin, Base):
    """A registered source. `tier` is official | news. Nothing is fetched automatically unless
    `terms_status` is allowed (terms of use and robots checked and recorded by the owner)."""

    __tablename__ = "feed_sources"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(64), unique=True)
    name: Mapped[str] = mapped_column(String(300))
    url: Mapped[str] = mapped_column(String(1000))
    tier: Mapped[str] = mapped_column(String(16))
    # unknown | allowed | disallowed
    terms_status: Mapped[str] = mapped_column(String(16), default="unknown")
    # portal_list | rss | manual
    fetch_method: Mapped[str] = mapped_column(String(16))
    # not_fetched | ok | fetch_failed | disallowed
    fetch_status: Mapped[str] = mapped_column(String(16), default="not_fetched")
    last_ok_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_error: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)


class FeedItem(TimestampMixin, Base):
    """One GR / circular / scheme / alert / news item. News never stores article text."""

    __tablename__ = "feed_items"
    __table_args__ = (UniqueConstraint("source_id", "external_id"),)
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    type: Mapped[str] = mapped_column(String(16))
    source_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_sources.id"), index=True)
    # The portal's unique code (Maharashtra GRs carry one) or another stable id.
    external_id: Mapped[str | None] = mapped_column(String(120))
    gr_number: Mapped[str | None] = mapped_column(String(120))
    department: Mapped[str | None] = mapped_column(String(200))
    published_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    url: Mapped[str] = mapped_column(String(1000))
    raw_hash: Mapped[str | None] = mapped_column(String(64), index=True)
    raw_bytes: Mapped[int | None] = mapped_column(Integer)
    extracted_text: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(16), index=True)
    # official | news
    trust_level: Mapped[str] = mapped_column(String(16))
    valid_from: Mapped[date | None] = mapped_column(Date)
    valid_to: Mapped[date | None] = mapped_column(Date)
    deadline: Mapped[date | None] = mapped_column(Date)
    replaced_by_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("feed_items.id"))
    # Output-check mismatches still open; approval is refused while any remain.
    check_issues: Mapped[list[dict[str, str]]] = mapped_column(JSON, default=list)
    approved_by: Mapped[uuid.UUID | None] = mapped_column()
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class FeedItemI18n(TimestampMixin, Base):
    __tablename__ = "feed_item_i18n"
    __table_args__ = (UniqueConstraint("item_id", "lang"),)
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    lang: Mapped[str] = mapped_column(String(2))
    title: Mapped[str] = mapped_column(String(500))
    summary: Mapped[str | None] = mapped_column(Text)


class FeedSchemeCard(TimestampMixin, Base):
    """Structured scheme fields. `fields`: {name: {"value": str | "not_stated", "page": str |
    null}}; every stated value cites the source page it was read from."""

    __tablename__ = "feed_scheme_cards"
    __table_args__ = (UniqueConstraint("item_id", "version"),)
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    version: Mapped[int] = mapped_column(Integer)
    fields: Mapped[dict[str, dict[str, Any]]] = mapped_column(JSON)


class FeedItemTarget(TimestampMixin, Base):
    """Who an item is for. Empty fields mean "any"; several rows mean any of them."""

    __tablename__ = "feed_item_targets"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    district: Mapped[str | None] = mapped_column(String(120))
    crop: Mapped[str | None] = mapped_column(String(32))
    min_ha: Mapped[float | None] = mapped_column(Float)
    max_ha: Mapped[float | None] = mapped_column(Float)


class FeedReviewEvent(Base):
    """Append-only review trail: rows are only ever inserted (service-only)."""

    __tablename__ = "feed_review_events"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    actor_id: Mapped[uuid.UUID | None] = mapped_column()
    # created | edited | output_check_failed | summarised | approved | published | withdrawn
    kind: Mapped[str] = mapped_column(String(32))
    detail: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
