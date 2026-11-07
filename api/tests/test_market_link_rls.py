"""Market linkage RLS per role (spec v1.5 §6, migrations 0029, 0030). Postgres only; CI runs it in
the migrations-postgres job (`pytest -m postgres`) with POSTGRES_TEST_URL set.

The probe role has SELECT on every market-link table, like a client would if a grant ever
slipped; each check sets the JWT `sub` the way Supabase does and lists the visible rows."""

from __future__ import annotations

import os
import uuid
from collections.abc import Iterator
from datetime import UTC, date, datetime, timedelta
from typing import Any

import pytest
from alembic import command
from sqlalchemy import JSON, Connection, DateTime, create_engine, text
from sqlalchemy import exc as sa_exc

from bagmitra_api.db.base import Base
from bagmitra_api.market_link.models import MARKET_LINK_TABLES
from tests.test_migrations import _config

pytestmark = [
    pytest.mark.postgres,
    pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL"),
]
NOW = datetime.now(UTC)


def _insert(conn: Connection, table: str, **values: Any) -> uuid.UUID:
    """Insert one row, filling the other required columns with neutral values."""
    t = Base.metadata.tables[table]
    row: dict[str, Any] = {"id": uuid.uuid4()}
    for c in t.columns:
        if c.name in values or c.nullable or c.name == "id":
            continue
        if isinstance(c.type, JSON):
            row[c.name] = {} if c.name == "detail" else []
        elif isinstance(c.type, DateTime):
            row[c.name] = NOW
        elif c.name == "last_seq":
            row[c.name] = 1
    row.update(values)
    conn.execute(t.insert().values(**row))
    return uuid.UUID(str(row["id"]))


def _verify(conn: Connection, kind: str, subject: uuid.UUID, status: str, at: datetime) -> None:
    _insert(
        conn,
        "party_verifications",
        subject_type=kind,
        subject_id=subject,
        status=status,
        checked_by=uuid.uuid4(),
        checked_at=at,
        created_at=at,
    )


def _terms() -> dict[str, Any]:
    return {
        "basis": "per_tonne",
        "rate_paise": 2_500_000,
        "harvest_date": date(2026, 12, 1),
    }


def _lot(conn: Connection, owner: uuid.UUID, status: str) -> uuid.UUID:
    return _insert(
        conn,
        "market_lots",
        owner_id=owner,
        plot_id=uuid.uuid4(),
        crop="santra",
        quantity_t=10.0,
        harvest_from=date(2026, 12, 1),
        harvest_to=date(2026, 12, 15),
        basis="per_tonne",
        status=status,
    )


def _fixture(conn: Connection) -> dict[str, uuid.UUID]:
    u = {k: uuid.uuid4() for k in ("grower", "grower2", "buyer", "unverified", "broker", "prov")}
    ids: dict[str, uuid.UUID] = dict(u)
    profile = {"phone": "919800000000", "district": "Amravati"}
    ids["buyer_p"] = _insert(conn, "buyer_profiles", user_id=u["buyer"], name="B", **profile)
    ids["unverified_p"] = _insert(
        conn, "buyer_profiles", user_id=u["unverified"], name="U", **profile
    )
    ids["broker_p"] = _insert(conn, "broker_profiles", user_id=u["broker"], name="K", **profile)
    ids["sp"] = _insert(
        conn, "service_providers", user_id=u["prov"], kind="weighbridge", name="P", **profile
    )
    _verify(conn, "buyer", ids["buyer_p"], "approved", NOW)
    _verify(conn, "broker", ids["broker_p"], "approved", NOW)
    _verify(conn, "provider", ids["sp"], "approved", NOW)
    _insert(
        conn,
        "party_verifications",
        subject_type="buyer",
        subject_id=ids["unverified_p"],
        status="pending",
    )
    ids["lot_pub"] = _lot(conn, u["grower"], "published")
    ids["lot_draft"] = _lot(conn, u["grower"], "draft")
    ids["lot_other"] = _lot(conn, u["grower2"], "published")
    photo = {"captured_at": NOW, "lat": 21.1, "lon": 77.7}
    ids["photo_pub"] = _insert(
        conn, "market_lot_photos", owner_id=u["grower"], lot_id=ids["lot_pub"], **photo
    )
    ids["photo_draft"] = _insert(
        conn, "market_lot_photos", owner_id=u["grower"], lot_id=ids["lot_draft"], **photo
    )
    offer = {"buyer_user_id": u["buyer"], "submitted_by": u["broker"], "status": "accepted"}
    ids["offer"] = _insert(
        conn,
        "market_offers",
        lot_id=ids["lot_pub"],
        broker_user_id=u["broker"],
        **offer,
        **_terms(),
    )
    ids["offer_other"] = _insert(
        conn,
        "market_offers",
        lot_id=ids["lot_other"],
        **{**offer, "submitted_by": u["buyer"]},
        **_terms(),
    )
    ids["deal"] = _insert(
        conn,
        "market_deals",
        lot_id=ids["lot_pub"],
        offer_id=ids["offer"],
        status="active",
    )
    ids["deal_other"] = _insert(
        conn,
        "market_deals",
        lot_id=ids["lot_other"],
        offer_id=ids["offer_other"],
        status="active",
    )
    for role, user in (("grower", u["grower"]), ("trader", u["buyer"]), ("broker", u["broker"])):
        _insert(conn, "deal_parties", deal_id=ids["deal"], role=role, user_id=user)
    for role, user in (("grower", u["grower2"]), ("trader", u["buyer"])):
        _insert(conn, "deal_parties", deal_id=ids["deal_other"], role=role, user_id=user)
    _insert(conn, "deal_events", deal_id=ids["deal"], kind="accepted", actor_id=u["grower"])
    ids["rating"] = _insert(
        conn,
        "ratings",
        deal_id=ids["deal"],
        rater_id=u["grower"],
        ratee_id=u["buyer"],
        ratee_role="trader",
        question_key="trader_on_date",
        stars=5,
    )
    # 0030 tables: each user sees only their own rows.
    ids["fix"] = _insert(
        conn,
        "registration_fixes",
        subject_type="buyer",
        subject_id=ids["buyer_p"],
        user_id=u["buyer"],
        lat=21.1,
        lon=77.7,
        accuracy_m=10.0,
        captured_at=NOW,
        is_mocked=False,
    )
    ids["report"] = _insert(
        conn,
        "fraud_reports",
        reporter_id=u["grower"],
        subject_type="buyer",
        subject_id=ids["buyer_p"],
        reason="fake_identity",
        status="open",
    )
    ids["action"] = _insert(
        conn,
        "admin_actions",
        subject_type="buyer",
        subject_id=ids["buyer_p"],
        user_id=u["buyer"],
        action="warn",
        reason_code="fake_identity",
        actor_id=uuid.uuid4(),
        acted_at=NOW,
        appeal_state="none",
    )
    ids["terms"] = _insert(
        conn,
        "terms_acceptances",
        user_id=u["buyer"],
        role="trader",
        doc_kind="terms",
        version="2026-11",
        accepted_at=NOW,
        adult_declared=True,
    )
    ids["block"] = _insert(conn, "user_blocks", blocker_id=u["grower"], blocked_id=u["buyer"])
    ids["rep_upload"] = _insert(
        conn,
        "representative_uploads",
        subject_type="broker",
        subject_id=ids["broker_p"],
        uploaded_by=u["prov"],
        address="Near APMC gate",
    )
    tag = {
        "question_key": "trader_on_date",
        "polarity": "positive",
        "label_mr": "m",
        "label_hi": "h",
        "label_en": "e",
    }
    ids["tag_active"] = _insert(conn, "rating_tags", key="t_active", status="active", **tag)
    _insert(conn, "rating_tags", key="t_draft", status="draft", **tag)
    return ids


@pytest.fixture
def conn() -> Iterator[Connection]:
    url = os.environ["POSTGRES_TEST_URL"]
    command.upgrade(_config(url), "head")
    engine = create_engine(url.replace("+asyncpg", "+psycopg"))
    with engine.connect() as c:
        with c.begin():
            c.execute(
                text(
                    "DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ml_probe') "
                    "THEN DROP OWNED BY ml_probe; DROP ROLE ml_probe; END IF; END $$"
                )
            )
            c.execute(text("CREATE ROLE ml_probe NOLOGIN"))
            c.execute(text(f"GRANT SELECT ON {', '.join(MARKET_LINK_TABLES)} TO ml_probe"))
            c.execute(text("GRANT USAGE ON SCHEMA auth TO ml_probe"))
        yield c
    engine.dispose()


def _seen(conn: Connection, user: uuid.UUID | None, table: str) -> set[uuid.UUID]:
    conn.execute(text("SET LOCAL ROLE ml_probe"))
    conn.execute(
        text("SELECT set_config('request.jwt.claim.sub', :s, true)"),
        {"s": str(user) if user else ""},
    )
    try:
        return set(conn.execute(text(f"SELECT id FROM {table}")).scalars())  # noqa: S608
    finally:
        conn.execute(text("RESET ROLE"))


def test_every_market_link_table_has_rls_and_a_policy(conn: Connection) -> None:
    rows = conn.execute(
        text(
            "SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity, "
            "(SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) "
            "FROM pg_class c WHERE c.relname = ANY(:t)"
        ),
        {"t": list(MARKET_LINK_TABLES)},
    ).all()
    assert len(rows) == len(MARKET_LINK_TABLES)
    assert all(r[1] and r[2] and r[3] >= 1 for r in rows), rows


def test_rls_per_role(conn: Connection) -> None:
    with conn.begin() as tx:
        i = _fixture(conn)
        lots = "market_lots"
        # Grower: own lots (draft too) and the offers / deal on them; not another grower's.
        g = i["grower"]
        assert _seen(conn, g, lots) == {i["lot_pub"], i["lot_draft"]}
        assert _seen(conn, g, "market_lot_photos") == {i["photo_pub"], i["photo_draft"]}
        assert _seen(conn, g, "market_offers") == {i["offer"]}
        assert _seen(conn, g, "market_deals") == {i["deal"]}
        assert len(_seen(conn, g, "deal_parties")) == 3
        assert _seen(conn, g, "fraud_reports") == {i["report"]}
        assert _seen(conn, g, "user_blocks") == {i["block"]}
        for table in ("registration_fixes", "admin_actions", "terms_acceptances"):
            assert _seen(conn, g, table) == set(), table
        assert _seen(conn, g, "party_verifications") == set()
        # Public trader / broker profiles only once verified (decision g, h).
        assert _seen(conn, g, "buyer_profiles") == {i["buyer_p"]}
        assert _seen(conn, g, "broker_profiles") == {i["broker_p"]}
        assert _seen(conn, g, "rating_tags") == {i["tag_active"]}
        # Verified buyer: every published lot and its photos, never a draft; own offers/deals.
        b = i["buyer"]
        assert _seen(conn, b, lots) == {i["lot_pub"], i["lot_other"]}
        assert _seen(conn, b, "market_lot_photos") == {i["photo_pub"]}
        assert _seen(conn, b, "market_offers") == {i["offer"], i["offer_other"]}
        assert _seen(conn, b, "market_deals") == {i["deal"], i["deal_other"]}
        assert _seen(conn, b, "ratings") == {i["rating"]}
        # Own registration fix (exact GPS), the admin action about it, own acceptances.
        assert _seen(conn, b, "registration_fixes") == {i["fix"]}
        assert _seen(conn, b, "admin_actions") == {i["action"]}
        assert _seen(conn, b, "terms_acceptances") == {i["terms"]}
        for table in ("fraud_reports", "user_blocks", "representative_uploads"):
            assert _seen(conn, b, table) == set(), table
        assert len(_seen(conn, b, "party_verifications")) == 1
        # Unverified buyer: no lot, no photo (spec §7); sees own pending record and profile.
        un = i["unverified"]
        assert _seen(conn, un, lots) == set()
        assert _seen(conn, un, "market_lot_photos") == set()
        assert _seen(conn, un, "market_offers") == set()
        assert _seen(conn, un, "buyer_profiles") == {i["buyer_p"], i["unverified_p"]}
        assert len(_seen(conn, un, "party_verifications")) == 1
        # Verified broker: published lots, the offer it brought, its deal only.
        k = i["broker"]
        assert _seen(conn, k, lots) == {i["lot_pub"], i["lot_other"]}
        assert _seen(conn, k, "market_offers") == {i["offer"]}
        assert _seen(conn, k, "market_deals") == {i["deal"]}
        # Provider: a directory entry; no lot, deal or interest. (The same user uploaded the
        # representative row here, so it reads that one only.)
        p = i["prov"]
        assert _seen(conn, p, "representative_uploads") == {i["rep_upload"]}
        for table in (lots, "market_deals", "market_offers", "registration_fixes"):
            assert _seen(conn, p, table) == set(), table
        # Another grower sees only their own lot and deal.
        assert _seen(conn, i["grower2"], lots) == {i["lot_other"]}
        assert _seen(conn, i["grower2"], "market_deals") == {i["deal_other"]}
        # Not signed in: nothing, not even active tags or verified profiles.
        for table in (
            lots,
            "rating_tags",
            "buyer_profiles",
            "service_providers",
            "registration_fixes",
            "fraud_reports",
            "admin_actions",
            "user_blocks",
        ):
            assert _seen(conn, None, table) == set(), table
        # Admin works through the API's privileged role (RLS bypassed), which sees every row.
        assert conn.execute(text("SELECT count(*) FROM market_lots")).scalar_one() == 3
        # A later rejection revokes the badge: the buyer loses every lot it is not party to.
        _verify(conn, "buyer", i["buyer_p"], "rejected", NOW + timedelta(seconds=1))
        assert _seen(conn, b, lots) == {i["lot_pub"], i["lot_other"]}  # deal parties keep theirs
        assert _seen(conn, g, "buyer_profiles") == set()
        conn.execute(
            text("UPDATE market_lots SET status = 'published' WHERE id = :d"), {"d": i["lot_draft"]}
        )
        assert i["lot_draft"] not in _seen(conn, b, lots)
        tx.rollback()


def test_deal_events_are_append_only(conn: Connection) -> None:
    with conn.begin() as tx:
        i = _fixture(conn)
        for stmt in ("UPDATE deal_events SET kind = 'x'", "DELETE FROM deal_events"):
            with (
                pytest.raises(sa_exc.ProgrammingError, match="append-only"),
                conn.begin_nested(),
            ):
                conn.execute(text(stmt))
        _insert(conn, "deal_events", deal_id=i["deal"], kind="version_confirmed")
        assert conn.execute(text("SELECT count(*) FROM deal_events")).scalar_one() == 2
        tx.rollback()
