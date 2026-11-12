"""Grower accounts (spec M2): expenses and sales income per plot, optionally per bahar.

Money is stored as whole paise (BIGINT) so sums are exact; categories and grades are slugs
from admin-managed config lists."""

from __future__ import annotations

import uuid
from datetime import date
from typing import Any

from sqlalchemy import JSON, BigInteger, Date, Float, Integer, String
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
    # Backed-up bill photo `<owner_id>/bill-<id>.jpg` (OPEN_QUESTIONS Q136); the file itself
    # stays on the phone unless the optional photo backup has uploaded it.
    bill_photo_key: Mapped[str | None] = mapped_column(String(120))


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
    """A spray application, one or several products mixed in one tank (Q142).
    `active_ingredient` drives the offline ban / PHI warning."""

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
    # Backed-up bill photo `<owner_id>/bill-<id>.jpg` (OPEN_QUESTIONS Q136).
    bill_photo_key: Mapped[str | None] = mapped_column(String(120))
    # A tank mix (OPEN_QUESTIONS Q142): every product of the one spray,
    # `[{"product_name", "active_ingredient", "dose", "cost_paise", "phi_days"}, ...]`; the
    # columns above then hold the first product, the summed cost and the longest PHI. Null
    # for a single-product record.
    products: Mapped[list[dict[str, Any]] | None] = mapped_column(JSON)
    # Spraying labour for the whole spray (Q143), whole paise; counted under "labour".
    labour_paise: Mapped[int | None] = mapped_column(BigInteger)


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


class HarvestRecord(OwnedSyncedRowMixin, Base):
    """One lot picked on a day. Grade and size class are config slugs and optional, so a
    grower can first note just the weight."""

    __tablename__ = "harvest_records"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    harvested_on: Mapped[date] = mapped_column(Date)
    grade: Mapped[str | None] = mapped_column(String(32))
    size_class: Mapped[str | None] = mapped_column(String(32))
    quantity_kg: Mapped[float] = mapped_column(Float)
    note: Mapped[str | None] = mapped_column(String(500))


class LabourRecord(OwnedSyncedRowMixin, Base):
    """A worker's day: wage earned, advance already paid, and when it was settled. The wage
    is counted under labour in the bahar summary (so it is not also entered as an expense)."""

    __tablename__ = "labour_records"

    plot_id: Mapped[uuid.UUID] = mapped_column(index=True)
    bahar_cycle_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    worker_name: Mapped[str] = mapped_column(String(120))
    worked_on: Mapped[date] = mapped_column(Date)
    task: Mapped[str | None] = mapped_column(String(32))
    wage_paise: Mapped[int] = mapped_column(BigInteger)
    advance_paise: Mapped[int] = mapped_column(BigInteger)
    settled_on: Mapped[date | None] = mapped_column(Date)
    note: Mapped[str | None] = mapped_column(String(500))
