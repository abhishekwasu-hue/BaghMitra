"""Feed tables (addendum v1.4 §5).

RLS kinds: sources and the published feed are reference data (signed-in users may read; the
item tables only expose published or withdrawn items, see migration 0018). Review events are
private (service-only). The app reads the feed through `GET /v1/feed`, never directly.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, time
from typing import Any

from sqlalchemy import (
    JSON,
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    Time,
    UniqueConstraint,
    false,
)
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin, utcnow

# "knowledge": a ज्ञान लेख written by the knowledge job (owner 2026-11-11), never uploaded.
ITEM_TYPES = ("gr", "circular", "scheme", "alert", "news", "knowledge")
ITEM_STATUSES = ("draft", "in_review", "published", "withdrawn", "held")
LANGS = ("en", "mr", "hi")
# feed_deadlines.kind, derived on publish: deadline -> apply_by, valid_from -> window_open,
# valid_to -> window_close, payment_date -> payment.
DEADLINE_KINDS = ("apply_by", "window_open", "window_close", "payment")
# Push categories a farmer may opt out of (feed_preferences.opted_out).
PUSH_CATEGORIES = ("deadline", "payment", "window_open")


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
    # "central" (Government of India) or "state" (Maharashtra); shown on every item (0040).
    level: Mapped[str | None] = mapped_column(String(16))
    # unknown | allowed | disallowed
    terms_status: Mapped[str] = mapped_column(String(16), default="unknown")
    # portal_list | rss | manual
    fetch_method: Mapped[str] = mapped_column(String(16))
    # not_fetched | ok | fetch_failed | disallowed
    fetch_status: Mapped[str] = mapped_column(String(16), default="not_fetched")
    last_ok_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_error: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)


class FeedThread(TimestampMixin, Base):
    """A news topic (owner Q139): related news items about one event or decision, shown as one
    card with a dated timeline. `title` / `summary` are copied from the latest item's checked
    text (never written new); they are what the topic matcher compares a new item with.
    Service-only: the app reads threads through `GET /v1/feed`."""

    __tablename__ = "feed_threads"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(500))
    summary: Mapped[str | None] = mapped_column(Text)
    # published_at of the newest item in the thread.
    last_item_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)


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
    # True: the source gave no date (e.g. PIB RSS), so published_at is when we first stored it.
    date_is_first_seen: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
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
    # Date a payment is released (G2 "payment released" push), as stated in the document.
    payment_date: Mapped[date | None] = mapped_column(Date)
    replaced_by_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("feed_items.id"))
    # Output-check mismatches still open; approval is refused while any remain.
    check_issues: Mapped[list[dict[str, str]]] = mapped_column(JSON, default=list)
    approved_by: Mapped[uuid.UUID | None] = mapped_column()
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # News only (Q139): the topic thread; None until the threading step has decided.
    thread_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("feed_threads.id"), index=True)


class FeedItemI18n(TimestampMixin, Base):
    __tablename__ = "feed_item_i18n"
    __table_args__ = (UniqueConstraint("item_id", "lang"),)
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    lang: Mapped[str] = mapped_column(String(2))
    title: Mapped[str] = mapped_column(String(500))
    summary: Mapped[str | None] = mapped_column(Text)
    # Spec v1.6: the AI article (headline, sections, facts, charts, ...) in this language.
    article: Mapped[dict[str, Any] | None] = mapped_column(JSON)


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
    # created | extracted | edited | output_check_failed | summarised | approved | published |
    # withdrawn
    kind: Mapped[str] = mapped_column(String(32))
    detail: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class FeedDeadline(TimestampMixin, Base):
    """A dated event of a published item, rebuilt from the item's dates on every publish.
    Visible like the item (published / withdrawn); alerts only use published ones."""

    __tablename__ = "feed_deadlines"
    __table_args__ = (UniqueConstraint("item_id", "kind"),)
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    kind: Mapped[str] = mapped_column(String(16))
    due_date: Mapped[date] = mapped_column(Date, index=True)


class FeedReceipt(TimestampMixin, Base):
    """Per farmer and item: seen / dismissed / "remind me", and when each push stage was
    sent (a stage is never sent twice). Owner data (RLS)."""

    __tablename__ = "feed_receipts"
    __table_args__ = (UniqueConstraint("owner_id", "item_id"),)
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    item_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("feed_items.id"), index=True)
    seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    dismissed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    remind_requested_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    t7_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    t2_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    t0_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    payment_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    window_open_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class FeedPreferences(TimestampMixin, Base):
    """A farmer's feed push settings; no row means the defaults. Quiet hours are India
    local times (start inclusive, end exclusive; start == end means none). Owner data."""

    __tablename__ = "feed_preferences"
    owner_column = "owner_id"

    owner_id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    quiet_start: Mapped[time] = mapped_column(Time, default=time(21, 0))
    quiet_end: Mapped[time] = mapped_column(Time, default=time(7, 0))
    weekly_cap: Mapped[int] = mapped_column(Integer, default=3)
    opted_out: Mapped[list[str]] = mapped_column(JSON, default=list)
    digest_weekly: Mapped[bool] = mapped_column(default=True)
    last_digest_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class FeedKnowledgeRun(Base):
    """One decision of the knowledge job for one topic (owner 2026-11-11): what triggered it,
    the hash of the input it would write from, the window the topic is current for and the
    outcome. The dedupe reads it (a topic is not written again while its window is current or
    within 30 days, unless the input changed). Append-only except `window_end`, which a still
    active risk alert extends. Service-only."""

    __tablename__ = "feed_knowledge_runs"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    # e.g. "risk:psylla_degree_days", "stage:santra:ambia:stress_start", "scheme:<item id>"
    topic_key: Mapped[str] = mapped_column(String(160), index=True)
    # risk | stage | scheme
    trigger: Mapped[str] = mapped_column(String(16))
    source_hash: Mapped[str] = mapped_column(String(64))
    window_end: Mapped[date | None] = mapped_column(Date)
    item_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("feed_items.id"), index=True)
    # published | held | review | not_relevant | no_input | retry
    result: Mapped[str] = mapped_column(String(16))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
