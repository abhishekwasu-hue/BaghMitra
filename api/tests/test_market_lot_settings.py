"""Lot form clarity (owner 2026-11-11, Q138): per quintal instead of per tonne (old phones'
"per_tonne" still read), the admin's rate ranges per crop and harvest window length (empty =
default), the publish check, and migration 0047 converting stored per-tonne rates."""

from __future__ import annotations

import uuid
from pathlib import Path
from typing import Any

import httpx
import pytest
from alembic import command
from sqlalchemy import create_engine, select, text

from bagmitra_api.market_link.lot_rules import LotRules, legacy_basis
from bagmitra_api.market_link.models import AdminAction, MarketLot
from bagmitra_api.routers.market_interests import InterestIn
from tests.conftest import make_token
from tests.test_market_lots_sync import LOTS, accept, draft, headers, lot, ml, storage
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, pull, push

__all__ = ["ml", "storage"]
APP = "/v1/market-link/lot-settings"
ADMIN_PATH = "/v1/admin/market-link/lot-settings"
ADMIN_ID = uuid.uuid4()
ADMIN = {
    "Authorization": "Bearer " + make_token(ADMIN_ID, app_metadata={"roles": ["market_link_admin"]})
}
EMPTY: dict[str, Any] = {"rate_ranges": [], "harvest_window_days": None}
DEFAULT_RANGES = [
    {"crop": c, "basis": b, "min_paise": lo, "max_paise": hi}
    for c in ("santra", "mosambi")
    for b, lo, hi in (("per_quintal", 250_000, 1_000_000), ("per_crate", 40_000, 120_000))
]


async def test_app_reads_the_owner_defaults_for_each_crop(ml: Any) -> None:
    """Mosambi starts at santra's numbers (the owner gave none), editable by the admin."""
    r = await ml.get(APP, headers=headers(uuid.uuid4()))
    assert r.status_code == 200, r.text
    assert r.json() == {"rate_ranges": DEFAULT_RANGES, "harvest_window_days": 15}


async def test_settings_need_sign_in_admin_role_and_the_legal_gate(
    ml: Any, client: httpx.AsyncClient
) -> None:
    assert (await ml.get(APP)).status_code == 401
    for h in ({}, headers(uuid.uuid4())):
        assert (await ml.get(ADMIN_PATH, headers=h)).status_code in (401, 403)
        assert (await ml.put(ADMIN_PATH, json=EMPTY, headers=h)).status_code in (401, 403)
    assert (await client.get(APP, headers=headers(uuid.uuid4()))).status_code == 404
    assert (await client.get(ADMIN_PATH, headers=ADMIN)).status_code == 404


async def test_admin_changes_one_crop_logged_and_reset_by_empty(ml: Any) -> None:
    start = (await ml.get(ADMIN_PATH, headers=ADMIN)).json()
    assert [(r["crop"], r["basis"]) for r in start["rate_ranges"]] == [
        (r["crop"], r["basis"]) for r in DEFAULT_RANGES
    ]
    assert {(r["min_paise"], r["max_paise"]) for r in start["rate_ranges"]} == {(None, None)}
    assert start["rate_ranges"][0]["default_min_paise"] == 250_000
    assert (start["harvest_window_days"], start["harvest_window_days_default"]) == (None, 15)
    assert start["effective"]["rate_ranges"] == DEFAULT_RANGES
    body = {
        "rate_ranges": [{"crop": "mosambi", "basis": "per_quintal", "min_paise": 300_000}],
        "harvest_window_days": 20,
    }
    r = await ml.put(ADMIN_PATH, json=body, headers=ADMIN)
    assert r.status_code == 200, r.text
    served = (await ml.get(APP, headers=headers(uuid.uuid4()))).json()
    ranges = {
        (x["crop"], x["basis"]): (x["min_paise"], x["max_paise"]) for x in served["rate_ranges"]
    }
    assert ranges[("mosambi", "per_quintal")] == (300_000, 1_000_000)
    assert ranges[("santra", "per_quintal")] == (250_000, 1_000_000)  # santra unchanged
    assert served["harvest_window_days"] == 20
    async with ml.maker() as s:
        [log] = (
            await s.scalars(select(AdminAction).where(AdminAction.subject_type == "lot_settings"))
        ).all()
    assert (log.action, log.reason_code, log.actor_id) == (
        "settings_change",
        "admin_setting",
        ADMIN_ID,
    )
    assert log.detail == {
        "old": {"mosambi_per_quintal_min_paise": None, "harvest_window_days": None},
        "new": {"mosambi_per_quintal_min_paise": 300_000, "harvest_window_days": 20},
    }
    # Saving the same values logs nothing; empty goes back to the default.
    assert (await ml.put(ADMIN_PATH, json=body, headers=ADMIN)).status_code == 200
    back = (await ml.put(ADMIN_PATH, json=EMPTY, headers=ADMIN)).json()
    assert back["effective"]["rate_ranges"] == DEFAULT_RANGES
    async with ml.maker() as s:
        logs = await s.scalars(
            select(AdminAction).where(AdminAction.subject_type == "lot_settings")
        )
        assert len(logs.all()) == 2


def _one(**kw: Any) -> dict[str, Any]:
    return {"rate_ranges": [{"crop": "santra", "basis": "per_quintal", **kw}]}


@pytest.mark.parametrize(
    "bad",
    [
        _one(min_paise=1_000_000),  # equals the default maximum
        {
            "rate_ranges": [
                {"crop": "mosambi", "basis": "per_crate", "min_paise": 50_000, "max_paise": 40_000}
            ]
        },
        _one(max_paise=0),
        {"rate_ranges": [{"crop": "kinnow", "basis": "per_quintal"}]},
        {"rate_ranges": [{"crop": "santra", "basis": "lump_sum"}]},
        {"rate_ranges": [_one()["rate_ranges"][0]] * 2},  # given twice
        {"harvest_window_days": -1},
        {"harvest_window_days": 121},
    ],
)
async def test_admin_values_must_make_sense(ml: Any, bad: dict[str, Any]) -> None:
    r = await ml.put(ADMIN_PATH, json={**EMPTY, **bad}, headers=ADMIN)
    assert r.status_code == 422, r.text


async def _set_rate(ml: Any, lot_id: uuid.UUID, basis: str, paise: int | None) -> None:
    async with ml.maker() as s:
        row = await s.get(MarketLot, lot_id)
        row.basis, row.asking_rate_paise = basis, paise
        await s.commit()


@pytest.mark.parametrize(
    ("basis", "paise", "ok"),
    [
        ("per_quintal", 249_900, False),
        ("per_quintal", 250_000, True),
        ("per_quintal", 1_000_000, True),
        ("per_quintal", 1_000_100, False),
        ("per_crate", 39_900, False),
        ("per_crate", 40_000, True),
        ("per_crate", 120_000, True),
        ("per_crate", 120_100, False),
        ("per_quintal", None, True),  # the asking rate is optional
        ("lump_sum", 100, True),  # the whole orchard has no range
        ("lump_sum", 10**11, True),
    ],
)
async def test_publish_checks_the_asking_rate_range(
    ml: Any, basis: str, paise: int | None, ok: bool
) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower)
    await _set_rate(ml, lot_id, basis, paise)
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    if ok:
        assert r.status_code == 200, r.text
    else:
        assert (r.status_code, r.json()["error"]["code"]) == (422, "lot_rate_out_of_range")


async def test_publish_follows_the_admin_range_of_the_plot_crop(ml: Any) -> None:
    body = {"rate_ranges": [{"crop": "mosambi", "basis": "per_quintal", "min_paise": 400_000}]}
    assert (await ml.put(ADMIN_PATH, json=body, headers=ADMIN)).status_code == 200
    # A santra lot at Rs 3,000 per quintal still fits santra's range.
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower)
    assert (await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)).status_code == 200
    # The same rate on a mosambi orchard is below mosambi's range.
    grower = uuid.uuid4()
    h = headers(grower)
    lot_id, _ = await draft(ml, h, grower, crop="mosambi")
    r = await ml.post(f"{LOTS}/{lot_id}/publish", headers=h)
    assert r.json()["error"]["code"] == "lot_rate_out_of_range"


async def test_old_phone_per_tonne_lot_is_stored_per_quintal(ml: Any) -> None:
    grower = uuid.uuid4()
    h = headers(grower)
    await accept(ml, h)
    plot_id, lot_id = uuid.uuid4(), uuid.uuid4()
    await push(ml, h, plot_mutation(plot_id))
    old = lot(plot_id, lot_id, basis="per_tonne", asking_rate_paise=3_000_000)
    [r] = await push(ml, h, old)
    assert r["status"] == "applied", r
    [change] = [c for c in (await pull(ml, h))["changes"] if c["entity"] == "market_lot"]
    assert (change["data"]["basis"], change["data"]["asking_rate_paise"]) == (
        "per_quintal",
        300_000,
    )
    [bad] = await push(ml, h, lot(plot_id, uuid.uuid4(), basis="per_kg"))
    assert bad["status"] == "rejected"


def test_old_phone_per_tonne_interest_is_read_per_quintal() -> None:
    body = {"basis": "per_tonne", "rate_paise": 3_200_005, "harvest_date": "2026-12-05"}
    i = InterestIn.model_validate(body)
    assert (i.basis, i.rate_paise) == ("per_quintal", 320_001)
    assert InterestIn.model_validate({**body, "basis": "per_crate"}).rate_paise == 3_200_005
    assert legacy_basis({"basis": "per_tonne", "rate_paise": 1}, "rate_paise")["rate_paise"] == 1
    assert legacy_basis("x", "rate_paise") == "x"
    assert legacy_basis({"basis": "per_tonne"}, "rate_paise") == {"basis": "per_quintal"}


def test_rules_without_a_range_or_a_rate_pass() -> None:
    rules = LotRules(ranges={("santra", "per_quintal"): (10, 20)}, harvest_window_days=15)
    assert rules.out_of_range("santra", "per_quintal", 9) == (10, 20)
    assert rules.out_of_range("santra", "per_quintal", 15) is None
    assert rules.out_of_range("santra", "per_crate", 1) is None
    assert rules.out_of_range("mosambi", "per_quintal", 1) is None
    assert rules.out_of_range(None, "per_quintal", 1) is None
    assert rules.out_of_range("santra", "per_quintal", None) is None


def _rows(url: str, sql: str, **params: Any) -> list[tuple[Any, ...]]:
    engine = create_engine(_sync_url(url))
    with engine.connect() as conn:
        rows = [tuple(r) for r in conn.execute(text(sql), params)]
    engine.dispose()
    return rows


def _exec(url: str, sql: str, rows: list[dict[str, Any]] | None = None) -> None:
    engine = create_engine(_sync_url(url))
    with engine.begin() as conn:
        conn.execute(text(sql), rows or {})
    engine.dispose()


LOT_INSERT = (
    "INSERT INTO market_lots (id, owner_id, plot_id, crop, quantity_t, harvest_from, harvest_to,"
    " basis, asking_rate_paise, status, client_updated_at, created_at, updated_at, last_seq)"
    " VALUES (:id, :owner, :plot, 'santra', 10, '2026-12-01', '2026-12-16', :basis, :rate,"
    " 'published', :at, :at, :at, 1)"
)
OFFER_INSERT = (
    "INSERT INTO market_offers (id, lot_id, basis, rate_paise, harvest_date, buyer_user_id,"
    " submitted_by, status, created_at, updated_at) VALUES (:id, :lot, 'per_tonne', 3200005,"
    " '2026-12-05', :buyer, :buyer, 'open', :at, :at)"
)
LOT_RATES = "SELECT basis, asking_rate_paise FROM market_lots ORDER BY quantity_t, plot_id"


def test_migration_0047_converts_per_tonne_rows_and_back(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'q.db'}"
    cfg = _config(url)
    command.upgrade(cfg, "0043")
    at = "2026-11-01 00:00:00"
    lot_ids = [uuid.uuid4().hex for _ in range(4)]
    lots = [
        ("per_tonne", 3_000_000),  # Rs 30,000 / t -> Rs 3,000 / q
        ("per_tonne", None),  # no asking rate
        ("per_crate", 50_000),  # untouched
        ("per_tonne", 3),  # never below one paisa
    ]
    # The plot ids sort as the list does, so the rows read back in this order.
    rows = [
        {"id": i, "owner": uuid.uuid4().hex, "plot": f"{n:032x}", "basis": b, "rate": r, "at": at}
        for n, (i, (b, r)) in enumerate(zip(lot_ids, lots, strict=True))
    ]
    _exec(url, LOT_INSERT, rows)
    offer = {"id": uuid.uuid4().hex, "lot": lot_ids[0], "buyer": uuid.uuid4().hex, "at": at}
    _exec(url, OFFER_INSERT, [offer])
    command.upgrade(cfg, "0047")
    assert _rows(url, LOT_RATES) == [
        ("per_quintal", 300_000),
        ("per_quintal", None),
        ("per_crate", 50_000),
        ("per_quintal", 1),
    ]
    assert _rows(url, "SELECT basis, rate_paise FROM market_offers") == [("per_quintal", 320_001)]
    with pytest.raises(Exception, match="CHECK"):
        _exec(url, "UPDATE market_lots SET basis = 'per_tonne'")
    _exec(url, "INSERT INTO market_lot_settings (id, created_at, updated_at) VALUES (1, 'x', 'x')")
    command.downgrade(cfg, "0043")
    assert _rows(url, LOT_RATES) == [
        ("per_tonne", 3_000_000),
        ("per_tonne", None),
        ("per_crate", 50_000),
        ("per_tonne", 10),
    ]
    assert _rows(url, "SELECT basis, rate_paise FROM market_offers") == [("per_tonne", 3_200_010)]
    tables = _rows(url, "SELECT name FROM sqlite_master WHERE name = 'market_lot_settings'")
    assert tables == []
