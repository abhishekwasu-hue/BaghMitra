"""Pydantic payload schemas for synced entities (validated at the API boundary)."""

from __future__ import annotations

import uuid
from datetime import date
from typing import Annotated, Any, Literal

from pydantic import BaseModel, Field, field_validator


class RowPayload(BaseModel):
    """Payload of an owner-scoped synced row; maps 1:1 to table columns by default."""

    def to_columns(self) -> dict[str, Any]:
        return self.model_dump()


Position = tuple[float, float]  # GeoJSON order: (longitude, latitude)
Slug = Annotated[str, Field(pattern=r"^[a-z][a-z0-9_]{1,31}$")]


class FarmerProfilePayload(BaseModel):
    display_name: str | None = Field(default=None, max_length=120)
    language: str = Field(min_length=2, max_length=12, pattern=r"^[a-z]{2,3}(-[A-Za-z]{2,4})?$")
    village: str | None = Field(default=None, max_length=120)
    taluka: str | None = Field(default=None, max_length=120)
    district: str | None = Field(default=None, max_length=120)
    consent_data_processing: bool = False
    consent_whatsapp: bool = False


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
