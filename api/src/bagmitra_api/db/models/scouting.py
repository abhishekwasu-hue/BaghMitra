"""Field scouting log ("पाहणी नोंद"): what the grower looked at on one plot, how bad it was
and a note. A record only, never advice. The photo itself stays on the phone; when the
optional backup is configured (OPEN_QUESTIONS Q34) the phone uploads it to a private bucket
by signed URL and `photo_key` holds the object path `<owner_id>/<record_id>.jpg`. Owner data,
synced."""

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
    # Object path in the private photo bucket; None while the photo is only on the phone.
    photo_key: Mapped[str | None] = mapped_column(String(120))
