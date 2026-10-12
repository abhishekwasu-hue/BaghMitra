from __future__ import annotations

from typing import Any

from sqlalchemy import JSON, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from bagmitra_api.db.base import Base, OwnedSyncedRowMixin


class Plot(OwnedSyncedRowMixin, Base):
    """An orchard block. Crop, irrigation, water and soil values are slugs that refer to
    admin-managed configuration lists, never hardcoded enums."""

    __tablename__ = "plots"

    name: Mapped[str] = mapped_column(String(80))
    crop: Mapped[str] = mapped_column(String(32))
    variety: Mapped[str | None] = mapped_column(String(60))
    area_sq_m: Mapped[float] = mapped_column(Float)
    planting_year: Mapped[int | None] = mapped_column(Integer)
    tree_count: Mapped[int | None] = mapped_column(Integer)
    row_spacing_m: Mapped[float | None] = mapped_column(Float)
    plant_spacing_m: Mapped[float | None] = mapped_column(Float)
    irrigation_type: Mapped[str | None] = mapped_column(String(32))
    water_source: Mapped[str | None] = mapped_column(String(32))
    soil_type: Mapped[str | None] = mapped_column(String(32))
    centroid_lat: Mapped[float | None] = mapped_column(Float)
    centroid_lon: Mapped[float | None] = mapped_column(Float)
    # GeoJSON Polygon (WGS84). Mirrored into a PostGIS column when spatial queries arrive.
    boundary: Mapped[dict[str, Any] | None] = mapped_column(JSON)
