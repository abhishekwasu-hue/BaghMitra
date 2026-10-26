"""Stored weather risk alerts per plot (M4 daily pull; owner data, RLS).

Revision ID: 0016
Revises: 0015
Create Date: 2026-10-26
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0016"
down_revision = "0015"
branch_labels = None
depends_on = None

TABLE = "plot_risk_alerts"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("plot_id", sa.Uuid(), nullable=False),
        sa.Column("rule_key", sa.String(64), nullable=False),
        sa.Column("first_day", sa.Date(), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("units", sa.Float(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notified_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_plot_risk_alerts")),
        sa.UniqueConstraint(
            "plot_id", "rule_key", "first_day", name=op.f("uq_plot_risk_alerts_plot_id")
        ),
    )
    op.create_index(op.f(f"ix_{TABLE}_owner_id"), TABLE, ["owner_id"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(TABLE, "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f(f"ix_{TABLE}_owner_id"), table_name=TABLE)
    op.drop_table(TABLE)
