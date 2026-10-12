"""Knowledge-base tables (addendum v1.3 §5). Reference data: read by signed-in users,
written only by privileged roles (admin API, importers). All grower-facing text is
language-keyed: {"en": ..., "mr": ..., "hi": ...}."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin


class KbSource(TimestampMixin, Base):
    __tablename__ = "kb_sources"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(64), unique=True)
    title: Mapped[str] = mapped_column(String(400))
    publisher: Mapped[str] = mapped_column(String(200))
    url: Mapped[str] = mapped_column(String(1000))
    # tier1 | tier2 | tier1_intl | tier3 | tier4 (addendum §2)
    tier: Mapped[str] = mapped_column(String(16))
    licence: Mapped[str] = mapped_column(String(200))
    # copy | summarise_cite | cite_only | internal_only
    allowed_use: Mapped[str] = mapped_column(String(16))
    # V (fetched and read) | S (search only) | UV (unverified)
    verification: Mapped[str] = mapped_column(String(4))
    fetched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    content_hash: Mapped[str | None] = mapped_column(String(64))
    notes: Mapped[str | None] = mapped_column(Text)


class KbTopic(TimestampMixin, Base):
    __tablename__ = "kb_topics"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(64), unique=True)
    kind: Mapped[str] = mapped_column(String(32))
    labels: Mapped[dict[str, str]] = mapped_column(JSON)


class KbCard(TimestampMixin, Base):
    """Versioned advice card. `content` per language: title, summary, cultural, organic,
    warnings, when_to_call_expert. Chemical options are stored but only ever shown after
    the K1 gate. `sources`: [{"source_id", "locator"}] with page/section."""

    __tablename__ = "kb_cards"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    topic_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("kb_topics.id"), index=True)
    crop: Mapped[str] = mapped_column(String(32))
    version: Mapped[int] = mapped_column(Integer)
    content: Mapped[dict[str, dict[str, str]]] = mapped_column(JSON)
    reviewed_languages: Mapped[list[str]] = mapped_column(JSON)
    chemical_options: Mapped[list[dict[str, Any]]] = mapped_column(JSON)
    sources: Mapped[list[dict[str, str]]] = mapped_column(JSON)
    # draft | expert_reviewed | published | retired
    status: Mapped[str] = mapped_column(String(16))
    review_due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class KbReview(TimestampMixin, Base):
    __tablename__ = "kb_reviews"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    card_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("kb_cards.id"), index=True)
    card_version: Mapped[int] = mapped_column(Integer)
    reviewer_id: Mapped[uuid.UUID] = mapped_column()
    # agronomist | plant_pathologist | entomologist
    reviewer_role: Mapped[str] = mapped_column(String(32))
    decision: Mapped[str] = mapped_column(String(16))
    comments: Mapped[str | None] = mapped_column(Text)
    reviewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class KbConflict(TimestampMixin, Base):
    """Sources disagree: store every value with its source; a reviewer chooses."""

    __tablename__ = "kb_conflicts"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    topic_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("kb_topics.id"))
    description: Mapped[str] = mapped_column(Text)
    values: Mapped[list[dict[str, str]]] = mapped_column(JSON)
    status: Mapped[str] = mapped_column(String(16))
    resolution: Mapped[str | None] = mapped_column(Text)


class KbLabelClaim(TimestampMixin, Base):
    """A CIB&RC 'major uses' row: the only allowed source of dose, interval and PHI."""

    __tablename__ = "kb_label_claims"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    active_ingredient: Mapped[str] = mapped_column(String(120), index=True)
    formulation: Mapped[str] = mapped_column(String(60))
    crop: Mapped[str] = mapped_column(String(60))
    target: Mapped[str] = mapped_column(String(120))
    dose: Mapped[str] = mapped_column(String(200))
    interval_days: Mapped[int | None] = mapped_column(Integer)
    phi_days: Mapped[int | None] = mapped_column(Integer)
    max_sprays: Mapped[int | None] = mapped_column(Integer)
    source_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("kb_sources.id"))
    valid_from: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    valid_to: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class KbRestriction(TimestampMixin, Base):
    """Banned / withdrawn / refused / restricted status from gazette notifications."""

    __tablename__ = "kb_restrictions"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    active_ingredient: Mapped[str] = mapped_column(String(120), index=True)
    kind: Mapped[str] = mapped_column(String(16))
    crops: Mapped[list[str]] = mapped_column(JSON)
    crop_groups: Mapped[list[str]] = mapped_column(JSON)
    notification: Mapped[str] = mapped_column(String(300))
    effective_from: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    source_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("kb_sources.id"))


class KbSynonym(TimestampMixin, Base):
    """Trade/brand name or abbreviation -> active ingredient, for the output filter."""

    __tablename__ = "kb_synonyms"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120), unique=True)
    active_ingredient: Mapped[str] = mapped_column(String(120))


class KbAdminAlert(TimestampMixin, Base):
    """Something an admin must act on, e.g. a published card pulled by the nightly re-gate.
    Service-only: no grower or signed-in client can read these rows."""

    __tablename__ = "kb_admin_alerts"
    private_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    # card_pulled | import_applied
    kind: Mapped[str] = mapped_column(String(32))
    card_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("kb_cards.id"), index=True)
    detail: Mapped[str] = mapped_column(Text)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
