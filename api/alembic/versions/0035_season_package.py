"""Season sale package (spec v1.5 §4D, §4E; build prompt Addendum 6, L9a).

`company_profile` and `season_package_settings` (single rows, start empty, switch OFF) and
`package_grants` (one recorded outside-the-app payment per row: unique UTR, gapless receipt
number per prefix). `admin_actions` gains a `detail` JSON (old / new values) and the package's
subjects, actions and reason codes. The traders' read policy on `market_lots` gains the package
rule: while the switch is ON a lot needs an active, unrevoked grant of its grower.

RLS: company profile and settings private (admin API only); a grower reads own grants.

Revision ID: 0035
Revises: 0034
Create Date: 2026-11-07
"""

from __future__ import annotations

from typing import Any

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import (
    disable_policy_rls,
    enable_policy_rls,
    enable_private_rls,
)

revision = "0035"
down_revision = "0034"
branch_labels = None
depends_on = None

# The admin_actions subjects as L6 (0033) leaves them ('rating' added there).
_TARGETS = "'buyer', 'broker', 'provider', 'lot', 'rating', 'user'"
_ACTIONS = "'verify', 'warn', 'hide', 'suspend', 'restore'"
_REASONS = (
    "'fake_identity', 'fake_lot', 'impersonation', 'fake_rating', 'abuse', "
    "'duplicate_user', 'checks_passed', 'appeal_upheld'"
)
_CHECKS = {
    "subject_type": (_TARGETS, "'company_profile', 'package_settings', 'package_grant'"),
    "action": (_ACTIONS, "'settings_change', 'grant', 'revoke'"),
    "reason_code": (_REASONS, "'admin_setting', 'payment_recorded', 'grant_revoked'"),
}
LOT_POLICY = "market_lots_verified_read"
_LOT_VISIBLE = (
    "status = 'published' AND deleted_at IS NULL AND ml_viewer_verified()"
    " AND orchard_check IN ('inside', 'near')"
)
PACKAGE_FUNCTION = """CREATE FUNCTION ml_lot_packaged(p_lot uuid, p_owner uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $f$
      SELECT NOT coalesce((SELECT s.enabled FROM season_package_settings s WHERE s.id = 1), false)
          OR EXISTS (SELECT 1 FROM package_grants g
                      WHERE g.grower_id = p_owner AND (g.lot_id IS NULL OR g.lot_id = p_lot)
                        AND g.revoked_at IS NULL
                        AND g.activated_at <= now() AND now() < g.valid_until)
    $f$"""
_PROFILE_TEXT = (
    ("legal_name", 160),
    ("trade_name", 160),
    ("address", 400),
    ("gstin", 15),
    ("pan", 10),
    ("bank_account_name", 160),
    ("bank_ifsc", 11),
    ("bank_account_last4", 4),
    ("upi_id", 80),
)
GRANT_POLICIES = [("grower_read", "SELECT", "grower_id = auth.uid()")]


def _ck(table: str, name: str, sql: str) -> sa.CheckConstraint:
    return sa.CheckConstraint(sql, name=op.f(f"ck_{table}_{name}"))


def _stamps() -> list[sa.Column[Any]]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    ]


def _lot_policy(using: str) -> list[str]:
    return [
        f"DROP POLICY IF EXISTS {LOT_POLICY} ON market_lots",
        f"CREATE POLICY {LOT_POLICY} ON market_lots FOR SELECT USING ({using})",
    ]


def _create_tables() -> None:
    text = sa.String
    op.create_table(
        "company_profile",
        sa.Column("id", sa.Integer(), nullable=False),
        *(sa.Column(c, text(length=n), nullable=True) for c, n in _PROFILE_TEXT),
        sa.Column("merchant_qr", sa.LargeBinary(), nullable=True),
        sa.Column("merchant_qr_type", text(length=16), nullable=True),
        sa.Column("invoice_prefix", text(length=16), nullable=True),
        sa.Column("gst_rate_bp", sa.Integer(), nullable=True),
        *_stamps(),
        _ck("company_profile", "single_row", "id = 1"),
        _ck(
            "company_profile",
            "gst_rate",
            "gst_rate_bp IS NULL OR gst_rate_bp BETWEEN 0 AND 10000",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_company_profile")),
    )
    op.create_table(
        "season_package_settings",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("price_paise", sa.BigInteger(), nullable=True),
        sa.Column("validity_days", sa.Integer(), nullable=True),
        sa.Column("starts_at", sa.Date(), nullable=True),
        *_stamps(),
        _ck("season_package_settings", "single_row", "id = 1"),
        _ck("season_package_settings", "price", "price_paise IS NULL OR price_paise > 0"),
        _ck("season_package_settings", "validity", "validity_days IS NULL OR validity_days > 0"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_season_package_settings")),
    )
    op.create_table(
        "package_grants",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("grower_id", sa.Uuid(), nullable=False),
        sa.Column("lot_id", sa.Uuid(), nullable=True),
        sa.Column("amount_paise", sa.BigInteger(), nullable=False),
        sa.Column("method", text(length=8), nullable=False),
        sa.Column("payment_ref", text(length=40), nullable=False),
        sa.Column("paid_on", sa.Date(), nullable=False),
        sa.Column("activated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("valid_until", sa.DateTime(timezone=True), nullable=False),
        sa.Column("receipt_prefix", text(length=16), nullable=False),
        sa.Column("receipt_seq", sa.Integer(), nullable=False),
        sa.Column("receipt_no", text(length=32), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_reason", text(length=200), nullable=True),
        sa.Column("admin_id", sa.Uuid(), nullable=False),
        sa.Column("notified_at", sa.DateTime(timezone=True), nullable=True),
        *_stamps(),
        _ck("package_grants", "amount", "amount_paise > 0"),
        _ck("package_grants", "receipt_seq", "receipt_seq > 0"),
        _ck("package_grants", "validity", "valid_until > activated_at"),
        _ck("package_grants", "method", "method IN ('upi', 'cash', 'bank')"),
        sa.ForeignKeyConstraint(
            ["lot_id"], ["market_lots.id"], name=op.f("fk_package_grants_lot_id_market_lots")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_package_grants")),
        sa.UniqueConstraint("payment_ref", name=op.f("uq_package_grants_payment_ref")),
        sa.UniqueConstraint("receipt_no", name=op.f("uq_package_grants_receipt_no")),
        sa.UniqueConstraint("receipt_prefix", "receipt_seq", name="uq_package_grants_receipt_seq"),
    )
    for column in ("grower_id", "lot_id", "valid_until"):
        op.create_index(
            op.f(f"ix_package_grants_{column}"), "package_grants", [column], unique=False
        )


def _admin_action_checks(with_package: bool) -> None:
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        for column, (old, new) in _CHECKS.items():
            batch_op.drop_constraint(batch_op.f(f"ck_admin_actions_{column}"), type_="check")
            values = f"{old}, {new}" if with_package else old
            batch_op.create_check_constraint(
                batch_op.f(f"ck_admin_actions_{column}"), f"{column} IN ({values})"
            )


def upgrade() -> None:
    _create_tables()
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        batch_op.add_column(sa.Column("detail", sa.JSON(), nullable=True))
    _admin_action_checks(with_package=True)
    if op.get_bind().dialect.name == "postgresql":
        for table in ("company_profile", "season_package_settings"):
            for stmt in enable_private_rls(table):
                op.execute(stmt)
        for stmt in enable_policy_rls("package_grants", GRANT_POLICIES):
            op.execute(stmt)
        op.execute(PACKAGE_FUNCTION)
        for stmt in _lot_policy(f"{_LOT_VISIBLE} AND ml_lot_packaged(id, owner_id)"):
            op.execute(stmt)


def downgrade() -> None:
    postgres = op.get_bind().dialect.name == "postgresql"
    if postgres:
        for stmt in _lot_policy(_LOT_VISIBLE):
            op.execute(stmt)
        op.execute("DROP FUNCTION IF EXISTS ml_lot_packaged(uuid, uuid)")
        for stmt in disable_policy_rls("package_grants", [n for n, _, _ in GRANT_POLICIES]):
            op.execute(stmt)
    # L6 (0033) makes admin_actions append-only by trigger; only this downgrade removes the
    # package's own rows, with the user triggers paused for that one statement.
    if postgres:
        op.execute("ALTER TABLE admin_actions DISABLE TRIGGER USER")
    op.execute(
        "DELETE FROM admin_actions WHERE subject_type IN "
        "('company_profile', 'package_settings', 'package_grant')"
    )
    if postgres:
        op.execute("ALTER TABLE admin_actions ENABLE TRIGGER USER")
    _admin_action_checks(with_package=False)
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        batch_op.drop_column("detail")
    for column in ("valid_until", "lot_id", "grower_id"):
        op.drop_index(op.f(f"ix_package_grants_{column}"), table_name="package_grants")
    op.drop_table("package_grants")
    op.drop_table("season_package_settings")
    op.drop_table("company_profile")
