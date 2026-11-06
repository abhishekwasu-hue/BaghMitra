"""Retention of sync_mutations payloads (audit LD-09).

`payload_purged_at` records when the nightly retention job (bagmitra_api.sync.retention)
replaced a row's payload with its `{sha256, bytes}` digest. The row itself is kept: the
duplicate check (owner_id, client_mutation_id) and the pull horizon (LD-08) need it. The
partial index lets the job find the rows still to purge without scanning purged ones.

Idempotent: the column and the index are added only when missing; the downgrade drops them
only when present (purged payloads stay digests: their contents are gone by design).

Revision ID: 0027
Revises: 0026
Create Date: 2026-11-06
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0027"
down_revision = "0026"
branch_labels = None
depends_on = None

TABLE = "sync_mutations"
COLUMN = "payload_purged_at"
INDEX = "ix_sync_mutations_unpurged_received_at"
UNPURGED = sa.text("payload_purged_at IS NULL")


def _columns() -> set[str]:
    return {c["name"] for c in sa.inspect(op.get_bind()).get_columns(TABLE)}


def _indexes() -> set[str]:
    return {str(i["name"]) for i in sa.inspect(op.get_bind()).get_indexes(TABLE)}


def upgrade() -> None:
    if COLUMN not in _columns():
        with op.batch_alter_table(TABLE) as batch:
            batch.add_column(sa.Column(COLUMN, sa.DateTime(timezone=True), nullable=True))
    if INDEX not in _indexes():
        op.create_index(
            INDEX, TABLE, ["received_at"], postgresql_where=UNPURGED, sqlite_where=UNPURGED
        )


def downgrade() -> None:
    if INDEX in _indexes():
        op.drop_index(INDEX, table_name=TABLE)
    if COLUMN in _columns():
        with op.batch_alter_table(TABLE) as batch:
            batch.drop_column(COLUMN)
