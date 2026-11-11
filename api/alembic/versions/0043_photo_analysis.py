"""Photo analysis (owner Q135, stage 2): training samples (owner data, RLS) and the admin's
photo limits per role plan and for farmers without a plan (empty = the code default).

Revision ID: 0043
Revises: 0042
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0043"
down_revision = "0042"
branch_labels = None
depends_on = None

TABLE = "photo_analysis_samples"
SETTINGS_COLUMNS = ("photo_ai_free_daily", "photo_ai_free_monthly", "photo_ai_daily_total")
ROLE_COLUMNS = ("photo_ai_daily", "photo_ai_monthly")


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("part", sa.String(16), nullable=True),
        sa.Column("scouting_item", sa.String(32), nullable=True),
        sa.Column("model", sa.String(64), nullable=False),
        sa.Column("candidates", sa.JSON(), nullable=False),
        sa.Column("unsure", sa.Boolean(), nullable=False),
        sa.Column("photo_key", sa.String(200), nullable=True),
        sa.Column("label", sa.String(32), nullable=True),
        sa.Column("label_source", sa.String(32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_photo_analysis_samples")),
    )
    for column in ("owner_id", "plot_id", "label"):
        op.create_index(op.f(f"ix_{TABLE}_{column}"), TABLE, [column])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(TABLE, "owner_id"):
            op.execute(stmt)
    for column in SETTINGS_COLUMNS:
        op.add_column("billing_settings", sa.Column(column, sa.Integer(), nullable=True))
    for column in ROLE_COLUMNS:
        op.add_column("billing_role_prices", sa.Column(column, sa.Integer(), nullable=True))


def downgrade() -> None:
    for column in ROLE_COLUMNS:
        op.drop_column("billing_role_prices", column)
    for column in SETTINGS_COLUMNS:
        op.drop_column("billing_settings", column)
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(TABLE):
            op.execute(stmt)
    for column in ("label", "plot_id", "owner_id"):
        op.drop_index(op.f(f"ix_{TABLE}_{column}"), table_name=TABLE)
    op.drop_table(TABLE)
