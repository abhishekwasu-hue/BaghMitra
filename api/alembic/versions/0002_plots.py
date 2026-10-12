"""Plots (orchard blocks), owner-scoped with soft delete and RLS.

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "plots",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(80), nullable=False),
        sa.Column("crop", sa.String(32), nullable=False),
        sa.Column("variety", sa.String(60), nullable=True),
        sa.Column("area_sq_m", sa.Float(), nullable=False),
        sa.Column("planting_year", sa.Integer(), nullable=True),
        sa.Column("tree_count", sa.Integer(), nullable=True),
        sa.Column("row_spacing_m", sa.Float(), nullable=True),
        sa.Column("plant_spacing_m", sa.Float(), nullable=True),
        sa.Column("irrigation_type", sa.String(32), nullable=True),
        sa.Column("water_source", sa.String(32), nullable=True),
        sa.Column("soil_type", sa.String(32), nullable=True),
        sa.Column("centroid_lat", sa.Float(), nullable=True),
        sa.Column("centroid_lon", sa.Float(), nullable=True),
        sa.Column("boundary", sa.JSON(), nullable=True),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_plots")),
    )
    op.create_index(op.f("ix_plots_owner_id"), "plots", ["owner_id"])
    op.create_index(op.f("ix_plots_last_seq"), "plots", ["last_seq"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls("plots", "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls("plots"):
            op.execute(stmt)
    op.drop_index(op.f("ix_plots_last_seq"), table_name="plots")
    op.drop_index(op.f("ix_plots_owner_id"), table_name="plots")
    op.drop_table("plots")
