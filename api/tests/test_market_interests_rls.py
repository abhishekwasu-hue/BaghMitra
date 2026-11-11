"""Market linkage L4 RLS per role after an acceptance (spec v1.5 §6: "contacts and plot pin
unlocked only by an accepted interest"). Postgres only (`pytest -m postgres`).

The grower's name, phone and plot pin live in `farmers` / `plots` (owner-only RLS): no client
role reads them, not even the accepted trader; the API reveals them to the deal's parties
only. A trader whose interest was closed sees that interest and nothing of the deal."""

from __future__ import annotations

import uuid

from sqlalchemy import Connection, text

from tests.test_market_link_rls import NOW, _insert, _lot, _seen, _verify, conn, pytestmark

__all__ = ["conn", "pytestmark"]


def test_rls_after_acceptance(conn: Connection) -> None:
    with conn.begin() as tx:
        conn.execute(text("GRANT SELECT ON farmers, plots TO ml_probe"))
        u = {k: uuid.uuid4() for k in ("grower", "chosen", "other", "broker", "unverified")}
        profile = {"phone": "919800000000", "district": "Amravati"}
        for key in ("chosen", "other", "unverified"):
            pid = _insert(conn, "buyer_profiles", user_id=u[key], name=key, **profile)
            if key != "unverified":
                _verify(conn, "buyer", pid, "approved", NOW)
        bid = _insert(conn, "broker_profiles", user_id=u["broker"], name="K", **profile)
        _verify(conn, "broker", bid, "approved", NOW)
        _insert(conn, "farmers", id=u["grower"], language="mr", phone="+919812345678")
        plot = _insert(
            conn,
            "plots",
            owner_id=u["grower"],
            name="Bag 1",
            crop="santra",
            centroid_lat=21.2,
            centroid_lon=78.5,
            area_sq_m=4000.0,
        )
        lot = _lot(conn, u["grower"], "closed")
        terms = {"basis": "per_quintal", "rate_paise": 1, "harvest_date": NOW.date()}
        chosen = _insert(
            conn,
            "market_offers",
            lot_id=lot,
            buyer_user_id=u["chosen"],
            broker_user_id=u["broker"],
            submitted_by=u["chosen"],
            status="accepted",
            **terms,
        )
        closed = _insert(
            conn,
            "market_offers",
            lot_id=lot,
            buyer_user_id=u["other"],
            submitted_by=u["other"],
            status="closed",
            **terms,
        )
        deal = _insert(conn, "market_deals", lot_id=lot, offer_id=chosen, status="active")
        for role in ("grower", "chosen", "broker"):
            _insert(
                conn,
                "deal_parties",
                deal_id=deal,
                role="trader" if role == "chosen" else role,
                user_id=u[role],
            )
        _insert(conn, "deal_events", deal_id=deal, kind="accepted", actor_id=u["grower"])

        g = u["grower"]
        assert _seen(conn, g, "market_offers") == {chosen, closed}
        assert _seen(conn, g, "market_deals") == {deal}
        assert _seen(conn, g, "farmers") == {g}
        assert _seen(conn, g, "plots") == {plot}
        # Accepted trader and the named broker: the deal and the closed lot, never the
        # grower's profile row or plot (the API reveals those contacts).
        for who in ("chosen", "broker"):
            assert _seen(conn, u[who], "market_deals") == {deal}, who
            assert len(_seen(conn, u[who], "deal_parties")) == 3, who
            assert _seen(conn, u[who], "market_lots") == {lot}, who
            assert _seen(conn, u[who], "market_offers") == {chosen}, who
            assert _seen(conn, u[who], "farmers") == set(), who
            assert _seen(conn, u[who], "plots") == set(), who
        # The trader whose interest was closed: their own interest only.
        o = u["other"]
        assert _seen(conn, o, "market_offers") == {closed}
        for table in ("market_deals", "deal_parties", "deal_events", "market_lots", "farmers"):
            assert _seen(conn, o, table) == set(), table
        # Unverified and signed-out: nothing.
        for viewer in (u["unverified"], None):
            for table in ("market_offers", "market_deals", "market_lots", "plots", "farmers"):
                assert _seen(conn, viewer, table) == set(), (viewer, table)
        tx.rollback()
