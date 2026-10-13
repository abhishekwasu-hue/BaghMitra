"""Grower accounts (spec M2): expenses and sales income per plot, optionally per bahar.

Money is stored as whole paise (BIGINT) so sums are exact; categories and grades are slugs
from admin-managed config lists."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import BigInteger, Date, Float, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin


class Expense(OwnedSyncedRowMixin, Base):
    __tablename__ = "expenses"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    spent_on: Mapped[date] = mapped_column(Date)
    category: Mapped[str] = mapped_column(String(32))
    amount_paise: Mapped[int] = mapped_column(BigInteger)
    note: Mapped[str | None] = mapped_column(String(500))


class Income(OwnedSyncedRowMixin, Base):
    __tablename__ = "incomes"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    sold_on: Mapped[date] = mapped_column(Date)
    buyer_name: Mapped[str] = mapped_column(String(120))
    grade: Mapped[str | None] = mapped_column(String(32))
    quantity_kg: Mapped[float] = mapped_column(Float)
    rate_paise_per_quintal: Mapped[int] = mapped_column(BigInteger)
    deductions_paise: Mapped[int] = mapped_column(BigInteger)
    # pending | partial | paid
    payment_status: Mapped[str] = mapped_column(String(16))
    paid_paise: Mapped[int] = mapped_column(BigInteger)
    paid_on: Mapped[date | None] = mapped_column(Date)
