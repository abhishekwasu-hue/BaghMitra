"""Admin alerts raised by importers and the nightly re-gate (service-only).

Revision ID: 0006
Revises: 0005
Create Date: 2026-10-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None

TABLE = "kb_admin_alerts"


def upgrade() -> None:
    op.create_table(
        TABLE,
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column("card_id", sa.Uuid(), nullable=True),
        sa.Column("detail", sa.Text(), nullable=False),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["card_id"], ["kb_cards.id"], name=op.f("fk_kb_admin_alerts_card_id_kb_cards")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_kb_admin_alerts")),
    )
    op.create_index(op.f("ix_kb_admin_alerts_card_id"), TABLE, ["card_id"])
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    op.drop_index(op.f("ix_kb_admin_alerts_card_id"), table_name=TABLE)
    op.drop_table(TABLE)
