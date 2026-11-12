"""Spraying labour on spray records (OPEN_QUESTIONS Q143).

`spray_records.labour_paise` is a nullable BIGINT: what the spray's labour cost, once per
spray, in whole paise. Existing rows keep null. It is counted under "labour", never in
`cost_paise` (the products). No new table, so the row-level security of `spray_records`
covers it.

Revision ID: 0050
Revises: 0049
Create Date: 2026-11-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0050"
down_revision = "0049"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("spray_records") as batch:
        batch.add_column(sa.Column("labour_paise", sa.BigInteger(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("spray_records") as batch:
        batch.drop_column("labour_paise")
