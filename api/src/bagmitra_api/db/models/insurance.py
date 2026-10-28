"""Crop insurance policy record ("पीक विमा नोंद", gap #1): which scheme and bahar one plot is
enrolled in, with whom and under which policy or application number. The grower types it in;
it is a record, never a statement of cover. Amounts are optional, whole paise, and only what
the grower entered. Owner data, synced (OPEN_QUESTIONS Q37)."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import BigInteger, Date, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin


class InsurancePolicy(OwnedSyncedRowMixin, Base):
    __tablename__ = "insurance_policies"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    # pmfby | rwbcis | other | unknown
    scheme: Mapped[str] = mapped_column(String(16))
    # ambia | mrig
    season: Mapped[str] = mapped_column(String(16))
    season_year: Mapped[int | None] = mapped_column(Integer)
    insurer_name: Mapped[str | None] = mapped_column(String(120))
    policy_number: Mapped[str | None] = mapped_column(String(60))
    sum_insured_paise: Mapped[int | None] = mapped_column(BigInteger)
    premium_paid_paise: Mapped[int | None] = mapped_column(BigInteger)
    enrolled_on: Mapped[date | None] = mapped_column(Date)
    note: Mapped[str | None] = mapped_column(String(500))
