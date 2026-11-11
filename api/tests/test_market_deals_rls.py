"""Market linkage L5 RLS on a completed deal (spec v1.5 §3A, §6). Postgres only
(`pytest -m postgres`). A rating is read only by its rater and its ratee (the public sees the
API's aggregates, never rows); no client role writes a rating or a deal event, and deal events
stay append-only."""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import Connection, text
from sqlalchemy import exc as sa_exc

from tests.test_market_link_rls import NOW, _insert, _lot, _seen, conn, pytestmark

__all__ = ["conn", "pytestmark"]


def test_ratings_visible_to_rater_and_ratee_only(conn: Connection) -> None:
    with conn.begin() as tx:
        u = {k: uuid.uuid4() for k in ("grower", "trader", "broker", "other")}
        lot = _lot(conn, u["grower"], "closed")
        offer = _insert(
            conn,
            "market_offers",
            lot_id=lot,
            buyer_user_id=u["trader"],
            broker_user_id=u["broker"],
            submitted_by=u["trader"],
            status="accepted",
            basis="per_quintal",
            rate_paise=1,
            harvest_date=NOW.date(),
        )
        deal = _insert(
            conn,
            "market_deals",
            lot_id=lot,
            offer_id=offer,
            status="completed",
            grower_done_at=NOW,
            trader_done_at=NOW,
            completed_at=NOW,
        )
        for role in ("grower", "trader", "broker"):
            _insert(conn, "deal_parties", deal_id=deal, role=role, user_id=u[role])
        done = _insert(conn, "deal_events", deal_id=deal, kind="completed")

        def rating(rater: str, ratee: str, q: str) -> uuid.UUID:
            return _insert(
                conn,
                "ratings",
                deal_id=deal,
                rater_id=u[rater],
                ratee_id=u[ratee],
                ratee_role=ratee,
                question_key=q,
                stars=4,
                tag_ids=[],
            )

        g_t = rating("grower", "trader", "trader_on_date")
        g_b = rating("grower", "broker", "broker_honest")
        t_g = rating("trader", "grower", "grower_ready_on_date")
        assert _seen(conn, u["grower"], "ratings") == {g_t, g_b, t_g}
        assert _seen(conn, u["trader"], "ratings") == {g_t, t_g}
        assert _seen(conn, u["broker"], "ratings") == {g_b}
        for viewer in (u["other"], None):
            assert _seen(conn, viewer, "ratings") == set()
            assert _seen(conn, viewer, "deal_events") == set()
        assert _seen(conn, u["broker"], "deal_events") == {done}
        tx.rollback()


def test_client_role_cannot_write_ratings_or_events(conn: Connection) -> None:
    for sql in (
        "INSERT INTO ratings (id) VALUES (gen_random_uuid())",
        "UPDATE ratings SET stars = 5",
        "UPDATE market_deals SET completed_at = now()",
        "INSERT INTO deal_events (id) VALUES (gen_random_uuid())",
    ):
        with conn.begin() as tx:
            conn.execute(text("SET LOCAL ROLE ml_probe"))
            with pytest.raises(sa_exc.ProgrammingError):
                conn.execute(text(sql))
            tx.rollback()
