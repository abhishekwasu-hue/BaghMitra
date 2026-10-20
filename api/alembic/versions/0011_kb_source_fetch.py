"""Track fetching of knowledge-base source documents (status, size, error).

Revision ID: 0011
Revises: 0010
Create Date: 2026-10-20
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0011"
down_revision = "0010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("kb_sources") as batch:
        batch.add_column(
            sa.Column("fetch_status", sa.String(16), nullable=False, server_default="not_fetched")
        )
        batch.add_column(sa.Column("fetch_bytes", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("fetch_error", sa.Text(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("kb_sources") as batch:
        batch.drop_column("fetch_error")
        batch.drop_column("fetch_bytes")
        batch.drop_column("fetch_status")
