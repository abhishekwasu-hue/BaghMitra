"""Farm tasks and reminders (spec M1/M4): a job with a due date, optionally for one plot and
bahar, entered by the grower or generated on the phone from a template. Owner data, synced."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Date, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin


class FarmTask(OwnedSyncedRowMixin, Base):
    __tablename__ = "farm_tasks"

    plot_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    title: Mapped[str] = mapped_column(String(200))
    # irrigation | spray | scouting | fertiliser | pruning | harvest | other (slug, config list)
    kind: Mapped[str] = mapped_column(String(32))
    due_on: Mapped[date] = mapped_column(Date)
    done_on: Mapped[date | None] = mapped_column(Date)
    # 'manual', or a template key plus its source label, so a generated task shows its origin
    source: Mapped[str | None] = mapped_column(String(80))
    note: Mapped[str | None] = mapped_column(String(500))
