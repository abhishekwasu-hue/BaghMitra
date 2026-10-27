"""Field scouting log ("पाहणी नोंद"): what the grower looked at on one plot, how bad it was
and a note. A record only, never advice. The optional photo stays on the phone and is not
stored here (photo upload needs signed URLs; see OPEN_QUESTIONS Q34). Owner data, synced."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Date, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin


class ScoutingRecord(OwnedSyncedRowMixin, Base):
    __tablename__ = "scouting_records"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    observed_on: Mapped[date] = mapped_column(Date)
    # psylla | leaf_miner | mites_thrips | fruit_drop | gummosis_bark | die_back | other (slug)
    item: Mapped[str] = mapped_column(String(32))
    # none | low | medium | high
    severity: Mapped[str] = mapped_column(String(16))
    note: Mapped[str | None] = mapped_column(String(500))
