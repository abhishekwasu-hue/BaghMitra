"""Pydantic payload schemas for synced entities (validated at the API boundary)."""

from __future__ import annotations

import uuid
from datetime import date
from typing import Annotated, Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class RowPayload(BaseModel):
    """Payload of an owner-scoped synced row; maps 1:1 to table columns by default."""

    def to_columns(self) -> dict[str, Any]:
        return self.model_dump()


Position = tuple[float, float]  # GeoJSON order: (longitude, latitude)
Slug = Annotated[str, Field(pattern=r"^[a-z][a-z0-9_]{1,31}$")]
_UUID = r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
PHOTO_KEY_PATTERN = rf"^{_UUID}/{_UUID}\.jpg$"


class FarmerProfilePayload(BaseModel):
    display_name: str | None = Field(default=None, max_length=120)
    language: str = Field(min_length=2, max_length=12, pattern=r"^[a-z]{2,3}(-[A-Za-z]{2,4})?$")
    village: str | None = Field(default=None, max_length=120)
    taluka: str | None = Field(default=None, max_length=120)
    district: str | None = Field(default=None, max_length=120)
    consent_data_processing: bool = False
    consent_whatsapp: bool = False
    # Contact number a Google sign-in may add (a phone sign-in's own number always wins).
    phone: str | None = Field(default=None, pattern=r"^\+91[6-9]\d{9}$")


class GeoJsonPolygon(BaseModel):
    type: Literal["Polygon"]
    coordinates: list[list[Position]] = Field(min_length=1, max_length=20)

    @field_validator("coordinates")
    @classmethod
    def _closed_rings(
        cls, rings: list[list[tuple[float, float]]]
    ) -> list[list[tuple[float, float]]]:
        for ring in rings:
            if len(ring) < 4 or len(ring) > 5000 or ring[0] != ring[-1]:
                raise ValueError("each ring needs >= 4 positions and must be closed")
            for lon, lat in ring:
                if not (-180 <= lon <= 180 and -90 <= lat <= 90):
                    raise ValueError("position out of range")
        return rings


class PlotPayload(RowPayload):
    name: str = Field(min_length=1, max_length=80)
    crop: Slug
    variety: str | None = Field(default=None, max_length=60)
    # Sanity bounds on input only, not agronomy values.
    area_sq_m: float = Field(gt=0, le=10_000_000)
    planting_year: int | None = Field(default=None, ge=1900, le=2100)
    tree_count: int | None = Field(default=None, ge=0, le=1_000_000)
    row_spacing_m: float | None = Field(default=None, gt=0, le=100)
    plant_spacing_m: float | None = Field(default=None, gt=0, le=100)
    irrigation_type: Slug | None = None
    water_source: Slug | None = None
    soil_type: Slug | None = None
    centroid_lat: float | None = Field(default=None, ge=-90, le=90)
    centroid_lon: float | None = Field(default=None, ge=-180, le=180)
    boundary: GeoJsonPolygon | None = None

    def to_columns(self) -> dict[str, Any]:
        data = self.model_dump()
        data["boundary"] = (
            None
            if self.boundary is None
            else {
                "type": "Polygon",
                "coordinates": [[list(p) for p in ring] for ring in self.boundary.coordinates],
            }
        )
        return data


StageKey = Annotated[str, Field(pattern=r"^[a-z][a-z0-9_]{1,31}$")]


class BaharCyclePayload(RowPayload):
    plot_id: uuid.UUID
    bahar: Slug
    season_year: int = Field(ge=2000, le=2100)
    template_id: uuid.UUID | None = None
    status: Literal["planned", "active", "completed", "abandoned"]
    planned: dict[StageKey, date] = Field(default_factory=dict, max_length=40)
    actual: dict[StageKey, date] = Field(default_factory=dict, max_length=40)

    def to_columns(self) -> dict[str, Any]:
        data = self.model_dump()
        data["planned"] = {k: v.isoformat() for k, v in self.planned.items()}
        data["actual"] = {k: v.isoformat() for k, v in self.actual.items()}
        return data


Paise = Annotated[int, Field(ge=0, le=10**12)]  # up to ₹1,000 crore; exact integer money


class ExpensePayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    spent_on: date
    category: Slug
    amount_paise: Paise
    note: str | None = Field(default=None, max_length=500)


class IncomePayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    sold_on: date
    buyer_name: str = Field(min_length=1, max_length=120)
    grade: Slug | None = None
    quantity_kg: float = Field(gt=0, le=10**7)
    rate_paise_per_quintal: Paise
    deductions_paise: Paise = 0
    payment_status: Literal["pending", "partial", "paid"]
    paid_paise: Paise = 0
    paid_on: date | None = None


class SprayRecordPayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    sprayed_on: date
    product_name: str = Field(min_length=1, max_length=120)
    active_ingredient: str | None = Field(default=None, min_length=1, max_length=120)
    dose: str | None = Field(default=None, max_length=200)
    water_litres: float | None = Field(default=None, gt=0, le=10**6)
    area_acres: float | None = Field(default=None, gt=0, le=10**5)
    cost_paise: Paise = 0
    operator: str | None = Field(default=None, max_length=120)
    phi_days: int | None = Field(default=None, ge=0, le=365)
    target: str | None = Field(default=None, max_length=120)


class InputRecordPayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    applied_on: date
    kind: Slug
    product_name: str = Field(min_length=1, max_length=120)
    quantity: float | None = Field(default=None, gt=0, le=10**7)
    unit: str | None = Field(default=None, min_length=1, max_length=16)
    cost_paise: Paise = 0
    note: str | None = Field(default=None, max_length=500)


class IrrigationRecordPayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    irrigated_on: date
    duration_hours: float | None = Field(default=None, gt=0, le=240)
    water_litres: float | None = Field(default=None, gt=0, le=10**8)
    note: str | None = Field(default=None, max_length=500)


class HarvestRecordPayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    harvested_on: date
    grade: Slug | None = None
    size_class: Slug | None = None
    quantity_kg: float = Field(gt=0, le=10**7)
    note: str | None = Field(default=None, max_length=500)


class LabourRecordPayload(RowPayload):
    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    worker_name: str = Field(min_length=1, max_length=120)
    worked_on: date
    task: Slug | None = None
    wage_paise: Paise
    advance_paise: Paise = 0
    settled_on: date | None = None
    note: str | None = Field(default=None, max_length=500)


class FarmTaskPayload(RowPayload):
    plot_id: uuid.UUID | None = None
    bahar_cycle_id: uuid.UUID | None = None
    title: str = Field(min_length=1, max_length=200)
    kind: Slug
    due_on: date
    done_on: date | None = None
    source: str | None = Field(default=None, max_length=80)
    note: str | None = Field(default=None, max_length=500)


class ScoutingRecordPayload(RowPayload):
    """A scouting observation. Extra fields are refused so a phone-only photo path can never
    reach the server by mistake. `photo_key` is the backed-up object path
    `<owner_id>/<record_id>.jpg`; the handler checks it is the caller's own."""

    model_config = ConfigDict(extra="forbid")

    plot_id: uuid.UUID
    bahar_cycle_id: uuid.UUID | None = None
    observed_on: date
    item: Slug
    severity: Literal["none", "low", "medium", "high"]
    note: str | None = Field(default=None, max_length=500)
    photo_key: str | None = Field(default=None, pattern=PHOTO_KEY_PATTERN)


class InsurancePolicyPayload(RowPayload):
    """A crop insurance policy as the grower recorded it. Extra fields are refused; amounts
    are optional and never filled in by the app (no default premium or cover)."""

    model_config = ConfigDict(extra="forbid")

    plot_id: uuid.UUID
    scheme: Literal["pmfby", "rwbcis", "other", "unknown"]
    season: Literal["ambia", "mrig"]
    season_year: int | None = Field(default=None, ge=2000, le=2100)
    insurer_name: str | None = Field(default=None, max_length=120)
    policy_number: str | None = Field(default=None, max_length=60)
    sum_insured_paise: Paise | None = None
    premium_paid_paise: Paise | None = None
    enrolled_on: date | None = None
    note: str | None = Field(default=None, max_length=500)
