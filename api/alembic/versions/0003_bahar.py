"""Crop stage templates (reference data) and bahar cycles (owner data), with RLS.

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-12
"""

from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import (
    disable_owner_rls,
    disable_reference_rls,
    enable_owner_rls,
    enable_reference_rls,
)

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def _timestamps() -> list[sa.Column[datetime]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "crop_stage_templates",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("crop", sa.String(32), nullable=False),
        sa.Column("bahar", sa.String(32), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("labels", sa.JSON(), nullable=False),
        sa.Column("stages", sa.JSON(), nullable=False),
        sa.Column("sources", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        *_timestamps(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_crop_stage_templates")),
    )
    op.create_index(op.f("ix_crop_stage_templates_crop"), "crop_stage_templates", ["crop"])
    op.create_table(
        "bahar_cycles",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("bahar", sa.String(32), nullable=False),
        sa.Column("season_year", sa.Integer(), nullable=False),
        sa.Column("template_id", sa.Uuid(), nullable=True),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("planned", sa.JSON(), nullable=False),
        sa.Column("actual", sa.JSON(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seq", sa.BigInteger(), nullable=False),
        *_timestamps(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_bahar_cycles")),
    )
    for column in ("owner_id", "plot_id", "last_seq"):
        op.create_index(op.f(f"ix_bahar_cycles_{column}"), "bahar_cycles", [column])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_reference_rls("crop_stage_templates"):
            op.execute(stmt)
        for stmt in enable_owner_rls("bahar_cycles", "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls("bahar_cycles"):
            op.execute(stmt)
        for stmt in disable_reference_rls("crop_stage_templates"):
            op.execute(stmt)
    for column in ("last_seq", "plot_id", "owner_id"):
        op.drop_index(op.f(f"ix_bahar_cycles_{column}"), table_name="bahar_cycles")
    op.drop_table("bahar_cycles")
    op.drop_index(op.f("ix_crop_stage_templates_crop"), table_name="crop_stage_templates")
    op.drop_table("crop_stage_templates")
