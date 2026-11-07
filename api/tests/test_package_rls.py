"""Season sale package RLS (spec v1.5 §4E, migration 0035). Postgres only (CI job
migrations-postgres, POSTGRES_TEST_URL): company profile and settings private, a grower reads
own grants, traders none; the traders' lot policy follows the switch and active grants."""

from __future__ import annotations

import os
import uuid
from datetime import timedelta

import pytest
from sqlalchemy import Connection, text

from bagmitra_api.market_link.package_models import PACKAGE_TABLES
from tests.test_market_link_rls import NOW, _insert, _lot, _seen, _verify, conn

__all__ = ["conn"]
pytestmark = [
    pytest.mark.postgres,
    pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL"),
]


def _grant(conn: Connection, grower: uuid.UUID, ref: str, **kw: object) -> uuid.UUID:
    values: dict[str, object] = {
        "grower_id": grower,
        "amount_paise": 150_000,
        "method": "upi",
        "payment_ref": ref,
        "paid_on": NOW.date(),
        "activated_at": NOW - timedelta(days=1),
        "valid_until": NOW + timedelta(days=30),
        "receipt_prefix": "BM",
        "receipt_seq": int(ref[-1]),
        "receipt_no": f"BM{ref[-1]}",
        "admin_id": uuid.uuid4(),
    }
    values.update(kw)
    return _insert(conn, "package_grants", **values)


def test_package_rls(conn: Connection) -> None:
    with conn.begin() as tx:
        conn.execute(text(f"GRANT SELECT ON {', '.join(PACKAGE_TABLES)} TO ml_probe"))
        grower, grower2, grower3, buyer = (uuid.uuid4() for _ in range(4))
        buyer_p = _insert(
            conn, "buyer_profiles", user_id=buyer, name="B", phone="9", district="Amravati"
        )
        _verify(conn, "buyer", buyer_p, "approved", NOW)
        lot1, lot2, lot3 = (_lot(conn, g, "published") for g in (grower, grower2, grower3))
        conn.execute(
            text(
                "INSERT INTO company_profile (id, created_at, updated_at) VALUES (1, now(), now())"
            )
        )
        conn.execute(
            text(
                "INSERT INTO season_package_settings (id, enabled, created_at, updated_at) "
                "VALUES (1, false, now(), now())"
            )
        )
        g1 = _grant(conn, grower, "UTR1", lot_id=lot1)
        _grant(conn, grower2, "UTR2", revoked_at=NOW)  # revoked
        _grant(
            conn,
            grower3,
            "UTR3",
            valid_until=NOW - timedelta(hours=1),
            activated_at=NOW - timedelta(days=2),
        )  # expired
        # Switch OFF: every published lot, as before.
        assert _seen(conn, buyer, "market_lots") == {lot1, lot2, lot3}
        conn.execute(text("UPDATE season_package_settings SET enabled = true"))
        # Switch ON: only the lot with an active, unrevoked grant.
        assert _seen(conn, buyer, "market_lots") == {lot1}
        # Grower: own grants only; nobody reads the company profile or settings.
        assert _seen(conn, grower, "package_grants") == {g1}
        assert _seen(conn, buyer, "package_grants") == set()
        for user in (grower, buyer):
            conn.execute(text("SET LOCAL ROLE ml_probe"))
            conn.execute(
                text("SELECT set_config('request.jwt.claim.sub', :s, true)"), {"s": str(user)}
            )
            for table in ("company_profile", "season_package_settings"):
                count = conn.execute(text(f"SELECT count(*) FROM {table}"))  # noqa: S608
                assert count.scalar_one() == 0, table
            conn.execute(text("RESET ROLE"))
        tx.rollback()
