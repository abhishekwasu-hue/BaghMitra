"""Market linkage L6 (spec v1.5 §3A, §4, §4C; Q68, Q82): report and block, the admin action
log with reason codes, one appeal through the grievance officer, account deletion.

- `fraud_reports.acknowledged_at` (grievance timeline: acknowledged within 24 h, closed
  within 15 days); a rating can be reported ("fake rating", §3A).
- `admin_actions`: a rating can be acted on; the one appeal holds a predefined reason
  (no free text), optional photos and its own acknowledged time. On Postgres the action
  columns never change and no row is deleted or truncated (trigger); only the appeal moves.
- `deferred_erasures` (private): the market-link data of a deleted account, hidden at once
  and erased after 180 days (Q68).

Revision ID: 0033
Revises: 0032
Create Date: 2026-11-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

from bagmitra_api.db.rls import disable_private_rls, enable_private_rls

revision = "0033"
down_revision = "0032"
branch_labels = None
depends_on = None

SUBJECTS = "'buyer', 'broker', 'provider', 'lot'"
APPEAL_REASONS = (
    "'identity_genuine', 'lot_genuine', 'rating_genuine', 'behaviour_proper', 'not_duplicate'"
)
APPEND_ONLY = (
    """CREATE FUNCTION admin_actions_append_only() RETURNS trigger
    LANGUAGE plpgsql AS $f$
    BEGIN
      IF TG_OP = 'UPDATE'
         AND (NEW.id, NEW.subject_type, NEW.subject_id, NEW.user_id, NEW.action,
              NEW.reason_code, NEW.actor_id, NEW.acted_at, NEW.created_at)
             IS NOT DISTINCT FROM
             (OLD.id, OLD.subject_type, OLD.subject_id, OLD.user_id, OLD.action,
              OLD.reason_code, OLD.actor_id, OLD.acted_at, OLD.created_at) THEN
        RETURN NEW;
      END IF;
      RAISE EXCEPTION 'admin_actions is append-only';
    END $f$""",
    "CREATE TRIGGER admin_actions_no_change BEFORE UPDATE OR DELETE ON admin_actions "
    "FOR EACH ROW EXECUTE FUNCTION admin_actions_append_only()",
    "CREATE TRIGGER admin_actions_no_truncate BEFORE TRUNCATE ON admin_actions "
    "FOR EACH STATEMENT EXECUTE FUNCTION admin_actions_append_only()",
)
DROP_APPEND_ONLY = (
    "DROP TRIGGER IF EXISTS admin_actions_no_truncate ON admin_actions",
    "DROP TRIGGER IF EXISTS admin_actions_no_change ON admin_actions",
    "DROP FUNCTION IF EXISTS admin_actions_append_only()",
)


def _targets(table: str, targets: str) -> None:
    with op.batch_alter_table(table, schema=None) as batch_op:
        batch_op.drop_constraint(batch_op.f(f"ck_{table}_subject_type"), type_="check")
        batch_op.create_check_constraint(
            batch_op.f(f"ck_{table}_subject_type"), f"subject_type IN ({targets})"
        )


def upgrade() -> None:
    postgres = op.get_bind().dialect.name == "postgresql"
    with op.batch_alter_table("fraud_reports", schema=None) as batch_op:
        batch_op.add_column(sa.Column("acknowledged_at", sa.DateTime(timezone=True), nullable=True))
    _targets("fraud_reports", f"{SUBJECTS}, 'rating', 'user'")
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        batch_op.add_column(sa.Column("appeal_reason", sa.String(length=32), nullable=True))
        batch_op.add_column(
            sa.Column(
                "appeal_photo_keys", sa.JSON(), nullable=False, server_default=sa.text("'[]'")
            )
        )
        batch_op.add_column(
            sa.Column("appeal_acknowledged_at", sa.DateTime(timezone=True), nullable=True)
        )
        batch_op.create_check_constraint(
            batch_op.f("ck_admin_actions_appeal_reason"), f"appeal_reason IN ({APPEAL_REASONS})"
        )
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        batch_op.alter_column("appeal_photo_keys", server_default=None)
    _targets("admin_actions", f"{SUBJECTS}, 'rating', 'user'")
    op.create_table(
        "deferred_erasures",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("erase_after", sa.DateTime(timezone=True), nullable=False),
        sa.Column("erased_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("user_id", name=op.f("pk_deferred_erasures")),
    )
    with op.batch_alter_table("deferred_erasures", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_deferred_erasures_erase_after"), ["erase_after"], unique=False
        )
    if postgres:
        for stmt in (*enable_private_rls("deferred_erasures"), *APPEND_ONLY):
            op.execute(stmt)


def downgrade() -> None:
    postgres = op.get_bind().dialect.name == "postgresql"
    if postgres:
        for stmt in (*DROP_APPEND_ONLY, *disable_private_rls("deferred_erasures")):
            op.execute(stmt)
    with op.batch_alter_table("deferred_erasures", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_deferred_erasures_erase_after"))
    op.drop_table("deferred_erasures")
    # A rating report or action has no place in the older check: drop them first.
    op.execute("DELETE FROM fraud_reports WHERE subject_type = 'rating'")
    op.execute(
        "UPDATE fraud_reports SET admin_action_id = NULL WHERE admin_action_id IN "
        "(SELECT id FROM admin_actions WHERE subject_type = 'rating')"
    )
    op.execute("DELETE FROM admin_actions WHERE subject_type = 'rating'")
    _targets("admin_actions", f"{SUBJECTS}, 'user'")
    with op.batch_alter_table("admin_actions", schema=None) as batch_op:
        batch_op.drop_constraint(batch_op.f("ck_admin_actions_appeal_reason"), type_="check")
        batch_op.drop_column("appeal_acknowledged_at")
        batch_op.drop_column("appeal_photo_keys")
        batch_op.drop_column("appeal_reason")
    _targets("fraud_reports", f"{SUBJECTS}, 'user'")
    with op.batch_alter_table("fraud_reports", schema=None) as batch_op:
        batch_op.drop_column("acknowledged_at")
