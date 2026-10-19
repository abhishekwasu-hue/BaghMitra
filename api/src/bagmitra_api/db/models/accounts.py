"""Grower accounts (spec M2): expenses and sales income per plot, optionally per bahar.

Money is stored as whole paise (BIGINT) so sums are exact; categories and grades are slugs
from admin-managed config lists."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import BigInteger, Date, Float, Integer, String
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


class SprayRecord(OwnedSyncedRowMixin, Base):
    """A spray application. `active_ingredient` drives the offline ban / PHI warning."""

    __tablename__ = "spray_records"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    sprayed_on: Mapped[date] = mapped_column(Date)
    product_name: Mapped[str] = mapped_column(String(120))
    active_ingredient: Mapped[str | None] = mapped_column(String(120))
    dose: Mapped[str | None] = mapped_column(String(200))
    water_litres: Mapped[float | None] = mapped_column(Float)
    area_acres: Mapped[float | None] = mapped_column(Float)
    cost_paise: Mapped[int] = mapped_column(BigInteger)
    operator: Mapped[str | None] = mapped_column(String(120))
    phi_days: Mapped[int | None] = mapped_column(Integer)
    target: Mapped[str | None] = mapped_column(String(120))


class InputRecord(OwnedSyncedRowMixin, Base):
    """Fertiliser / manure / micronutrient application. `kind` is a config slug; the cost is
    counted in the bahar summary under that kind (so it is not also entered as an expense)."""

    __tablename__ = "input_records"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    applied_on: Mapped[date] = mapped_column(Date)
    kind: Mapped[str] = mapped_column(String(32))
    product_name: Mapped[str] = mapped_column(String(120))
    quantity: Mapped[float | None] = mapped_column(Float)
    unit: Mapped[str | None] = mapped_column(String(16))
    cost_paise: Mapped[int] = mapped_column(BigInteger)
    note: Mapped[str | None] = mapped_column(String(500))


class IrrigationRecord(OwnedSyncedRowMixin, Base):
    """An irrigation event. A log only: water and power bills are entered as expenses."""

    __tablename__ = "irrigation_records"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    irrigated_on: Mapped[date] = mapped_column(Date)
    duration_hours: Mapped[float | None] = mapped_column(Float)
    water_litres: Mapped[float | None] = mapped_column(Float)
    note: Mapped[str | None] = mapped_column(String(500))
