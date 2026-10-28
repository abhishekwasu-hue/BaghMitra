"""Soil, water and leaf test log ("माती / पाणी / पान तपासणी", gap #6): which plot was sampled,
when, by which lab, and the values the grower typed from the report. A record only: values
are kept as typed text and never read, rated or interpreted. The report photo or file stays on
the phone. Owner data, synced (OPEN_QUESTIONS Q40)."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import JSON, Date, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin


class LabTest(OwnedSyncedRowMixin, Base):
    __tablename__ = "lab_tests"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    # soil | water | leaf
    test_type: Mapped[str] = mapped_column(String(16))
    sampled_on: Mapped[date] = mapped_column(Date)
    lab_name: Mapped[str | None] = mapped_column(String(120))
    reported_on: Mapped[date | None] = mapped_column(Date)
    # [{"parameter": "pH", "value": "7.9", "unit": null}, ...] exactly as typed.
    readings: Mapped[list[dict[str, str | None]]] = mapped_column(JSON)
    note: Mapped[str | None] = mapped_column(String(500))
