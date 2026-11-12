"""Tank mix on spray records (OPEN_QUESTIONS Q142): the products of one spray.

`spray_records.products` is a nullable JSON list of `{product_name, active_ingredient, dose,
cost_paise, phi_days}`. Existing rows keep null and read as single-product records; the row's
own columns keep the first product, the summed cost and the longest PHI. No new table, so the
row-level security of `spray_records` covers it.

Revision ID: 0049
Revises: 0048
Create Date: 2026-11-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0049"
down_revision = "0048"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("spray_records") as batch:
        batch.add_column(sa.Column("products", sa.JSON(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("spray_records") as batch:
        batch.drop_column("products")
