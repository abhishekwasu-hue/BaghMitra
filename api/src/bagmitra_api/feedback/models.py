"""In-app feedback (owner 2026-11-08): a problem, a suggestion or a question from a signed-in
user. Owner data (RLS); erased with the account like every `owner_column` table."""

from __future__ import annotations

import uuid

from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin

FEEDBACK_KINDS = ("problem", "suggestion", "question")
FEEDBACK_STATES = ("new", "seen", "done")


class AppFeedback(TimestampMixin, Base):
    __tablename__ = "app_feedback"
    owner_column = "owner_id"

    # The phone's own id for the message, so an offline retry never stores it twice.
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    kind: Mapped[str] = mapped_column(String(16))
    text: Mapped[str] = mapped_column(Text)
    app_version: Mapped[str] = mapped_column(String(40))
    device: Mapped[str] = mapped_column(String(120))
    screenshot_key: Mapped[str | None] = mapped_column(String(200))
    status: Mapped[str] = mapped_column(String(8), default="new", index=True)
