"""Photo analysis training samples (owner Q135, stage 2): every analysed crop photo with what
the model answered. Owner data (RLS); erased with the account like every `owner_column` table,
and the photo with it (`<owner_id>/analysis-<id>.<ext>` in the photo bucket)."""

from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import JSON, Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, TimestampMixin


class PhotoAnalysisSample(TimestampMixin, Base):
    __tablename__ = "photo_analysis_samples"
    owner_column = "owner_id"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(index=True)
    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    # leaf | fruit | trunk | whole_tree; None when the farmer did not say.
    part: Mapped[str | None] = mapped_column(String(16))
    # The farmer's own scouting entry name (slug), when the app attaches one.
    scouting_item: Mapped[str | None] = mapped_column(String(32))
    model: Mapped[str] = mapped_column(String(64))
    # The validated candidates as returned to the farmer (key, confidence, signs, explanation).
    # `signs` is {en, mr, hi} lists; older rows hold a plain English list (normalised on read).
    candidates: Mapped[list[dict[str, Any]]] = mapped_column(JSON)
    unsure: Mapped[bool] = mapped_column(Boolean)
    # Object key in the photo bucket; None when photo storage is off or the upload failed.
    photo_key: Mapped[str | None] = mapped_column(String(200))
    # A confirmed answer for training (a profile key, `healthy` or `other`) and who gave it.
    label: Mapped[str | None] = mapped_column(String(32), index=True)
    label_source: Mapped[str | None] = mapped_column(String(32))
