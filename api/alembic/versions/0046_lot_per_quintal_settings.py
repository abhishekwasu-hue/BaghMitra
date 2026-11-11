"""Lot form clarity (owner 2026-11-11, Q138): the sale basis "per_tonne" becomes "per_quintal",
the unit of the mandi price shown beside the asking rate, and the admin's lot form settings.

- `market_lots` and `market_offers`: every per-tonne row is converted to per quintal
  (rate / 10, rounded to the paisa) and the basis CHECK allows per_quintal instead. The
  downgrade converts back (rate x 10, exact for every rate that was converted from whole
  rupees per tonne).
- `market_lot_settings` (one row, private): the rate ranges per crop (santra, mosambi) and
  basis (per quintal, per crate) and the default harvest window length; empty = the default in `market_link/lot_rules.py`.
- `admin_actions` gains the subject `lot_settings` for their change log.

Revision ID: 0046
Revises: 0045
Create Date: 2026-11-11
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0046"
down_revision = "0045"
branch_labels = None
depends_on = None

TABLE = "market_lot_settings"
# Each table with a basis, and its rate column.
RATES = {"market_lots": "asking_rate_paise", "market_offers": "rate_paise"}
_TARGETS = (
    "'buyer', 'broker', 'provider', 'lot', 'rating', 'user', "
    "'company_profile', 'package_settings', 'package_grant'"
)
_PAISE = tuple(
    f"{c}_{b}_{e}_paise"
    for c in ("santra", "mosambi")
    for b in ("per_quintal", "per_crate")
    for e in ("min", "max")
)


def _basis_check(table: str, unit: str) -> None:
    with op.batch_alter_table(table, schema=None) as batch_op:
        batch_op.create_check_constraint(
            batch_op.f(f"ck_{table}_basis"), f"basis IN ('{unit}', 'per_crate', 'lump_sum')"
        )


def _drop_basis_check(table: str) -> None:
    with op.batch_alter_table(table, schema=None) as batch_op:
        batch_op.drop_constraint(batch_op.f(f"ck_{table}_basis"), type_="check")


def convert_up_sql(table: str, rate: str) -> str:
    """Rs / tonne -> Rs / quintal: rate / 10, rounded half up (integer division). The names
    are this module's constants, never input."""
    new = f"CASE WHEN ({rate} + 5) / 10 < 1 THEN 1 ELSE ({rate} + 5) / 10 END"
    return f"UPDATE {table} SET basis = 'per_quintal', {rate} = {new} WHERE basis = 'per_tonne'"  # noqa: S608


def convert_down_sql(table: str, rate: str) -> str:
    return (
        f"UPDATE {table} SET basis = 'per_tonne', {rate} = {rate} * 10 WHERE basis = 'per_quintal'"  # noqa: S608
    )


def _subject_check(extra: str) -> None:
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        batch_op.drop_constraint(batch_op.f("ck_admin_actions_subject_type"), type_="check")
        batch_op.create_check_constraint(
            batch_op.f("ck_admin_actions_subject_type"), f"subject_type IN ({_TARGETS}{extra})"
        )


def upgrade() -> None:
    for table, rate in RATES.items():
        _drop_basis_check(table)
        op.execute(convert_up_sql(table, rate))
        _basis_check(table, "per_quintal")
    op.create_table(
        TABLE,
        sa.Column("id", sa.Integer(), nullable=False),
        *(sa.Column(c, sa.BigInteger(), nullable=True) for c in _PAISE),
        sa.Column("harvest_window_days", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("id = 1", name=op.f(f"ck_{TABLE}_single_row")),
        *(
            sa.CheckConstraint(
                f"{c} IS NULL OR {c} > 0", name=op.f(f"ck_{TABLE}_{c.removesuffix('_paise')}")
            )
            for c in _PAISE
        ),
        sa.CheckConstraint(
            "harvest_window_days IS NULL OR harvest_window_days >= 0",
            name=op.f(f"ck_{TABLE}_harvest_days"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f(f"pk_{TABLE}")),
    )
    _subject_check(", 'lot_settings'")
    if op.get_bind().dialect.name == "postgresql":
        for stmt in enable_private_rls(TABLE):
            op.execute(stmt)


def downgrade() -> None:
    postgres = op.get_bind().dialect.name == "postgresql"
    if postgres:
        for stmt in disable_private_rls(TABLE):
            op.execute(stmt)
    # admin_actions is append-only by trigger (0033); only this downgrade removes the lot
    # settings' own rows, with the user triggers paused for that one statement.
    if postgres:
        op.execute("ALTER TABLE admin_actions DISABLE TRIGGER USER")
    op.execute("DELETE FROM admin_actions WHERE subject_type = 'lot_settings'")
    if postgres:
        op.execute("ALTER TABLE admin_actions ENABLE TRIGGER USER")
    _subject_check("")
    op.drop_table(TABLE)
    for table, rate in RATES.items():
        _drop_basis_check(table)
        op.execute(convert_down_sql(table, rate))
        _basis_check(table, "per_tonne")
