from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import JSON, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin, TimestampMixin


class CropStageTemplate(TimestampMixin, Base):
    """Admin-managed reference data: ordered stages of one bahar for one crop.

    Every stage offset carries source ids (spec §5). Only `published` templates reach the
    app; nothing is published until its sources are verified (docs/agronomy).
    """

    __tablename__ = "crop_stage_templates"
    reference_table = True

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    crop: Mapped[str] = mapped_column(String(32), index=True)
    bahar: Mapped[str] = mapped_column(String(32))
    version: Mapped[int] = mapped_column(Integer)
    labels: Mapped[dict[str, str]] = mapped_column(JSON)
    stages: Mapped[list[dict[str, Any]]] = mapped_column(JSON)
    sources: Mapped[dict[str, str]] = mapped_column(JSON)
    status: Mapped[str] = mapped_column(String(16))


class BaharCycle(OwnedSyncedRowMixin, Base):
    """One flowering cycle (bahar) of one plot in one season, with planned/actual dates."""

    __tablename__ = "bahar_cycles"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar: Mapped[str] = mapped_column(String(32))
    season_year: Mapped[int] = mapped_column(Integer)
    template_id: Mapped[uuid.UUID | None] = mapped_column()
    status: Mapped[str] = mapped_column(String(16))
    planned: Mapped[dict[str, str]] = mapped_column(JSON)
    actual: Mapped[dict[str, str]] = mapped_column(JSON)
