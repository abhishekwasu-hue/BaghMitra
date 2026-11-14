"""Shared daily push budget (owner 2026-11-14, OPEN_QUESTIONS Q157; `push/budget.py`).

- `push_log` (owner data, RLS owner policy): one row per topic of every push a farmer got or
  that the budget held back (status sent / budget / repeat), from all push jobs, so the daily
  budget (PUSH_DAILY_MAX) and the repeat window (PUSH_REPEAT_DAYS) count across jobs.

Revision ID: 0054
Revises: 0053
Create Date: 2026-11-14
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0054"
down_revision = "0053"
branch_labels = None
depends_on = None

LOG = "push_log"


def upgrade() -> None:
    op.create_table(
        LOG,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("push_id", sa.Uuid(), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("source", sa.String(16), nullable=False),
        sa.Column("priority", sa.Integer(), nullable=False),
        sa.Column("topic", sa.String(160), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f(f"pk_{LOG}")),
    )
    op.create_index(op.f(f"ix_{LOG}_owner_id"), LOG, ["owner_id"])
    op.create_index(op.f(f"ix_{LOG}_day"), LOG, ["day"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(LOG, "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(LOG):
            op.execute(stmt)
    op.drop_index(op.f(f"ix_{LOG}_day"), table_name=LOG)
    op.drop_index(op.f(f"ix_{LOG}_owner_id"), table_name=LOG)
    op.drop_table(LOG)
