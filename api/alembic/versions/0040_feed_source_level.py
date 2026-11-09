"""Feed sources say Central or State government (owner 2026-11-09).

Revision ID: 0040
Revises: 0039
Create Date: 2026-11-09
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0040"
down_revision = "0039"
branch_labels = None
depends_on = None

# The seeded sources (feed/seed_data/sources.json); later sources carry their level in the seed.
CENTRAL = (
    "pm_kisan",
    "pib_agriculture",
    "pib_agriculture_news",
    "pmfby",
    "icar_ccri",
    "imd_agromet",
)
STATE = (
    "mh_gr_portal",
    "mahadbt",
    "mh_agri_commissionerate",
    "mh_horticulture",
    "mh_input_notices",
)


def upgrade() -> None:
    op.add_column("feed_sources", sa.Column("level", sa.String(16), nullable=True))
    sources = sa.table("feed_sources", sa.column("key", sa.String), sa.column("level", sa.String))
    for level, keys in (("central", CENTRAL), ("state", STATE)):
        op.execute(sources.update().where(sources.c.key.in_(keys)).values(level=level))


def downgrade() -> None:
    op.drop_column("feed_sources", "level")
