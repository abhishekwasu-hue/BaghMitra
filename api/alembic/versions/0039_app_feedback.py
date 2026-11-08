"""In-app feedback (owner data, RLS).

Revision ID: 0039
Revises: 0038
Create Date: 2026-11-08
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_owner_rls, enable_owner_rls

revision = "0039"
down_revision = "0038"
branch_labels = None
depends_on = None

TABLE = "app_feedback"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("app_version", sa.String(40), nullable=False),
        sa.Column("device", sa.String(120), nullable=False),
        sa.Column("screenshot_key", sa.String(200), nullable=True),
        sa.Column("status", sa.String(8), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_app_feedback")),
    )
    op.create_index(op.f(f"ix_{TABLE}_owner_id"), TABLE, ["owner_id"])
    op.create_index(op.f(f"ix_{TABLE}_status"), TABLE, ["status"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_owner_rls(TABLE, "owner_id"):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_owner_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f(f"ix_{TABLE}_status"), table_name=TABLE)
    op.drop_index(op.f(f"ix_{TABLE}_owner_id"), table_name=TABLE)
    op.drop_table(TABLE)
