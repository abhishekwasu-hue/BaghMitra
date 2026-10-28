"""Soil, water and leaf test log ("माती / पाणी / पान तपासणी नोंद"): which plot was sampled,
when, by which lab, and the values the grower typed from the report. A record only: the server
never reads, rates or interprets a value. The report photo stays on the phone."""

from __future__ import annotations

import uuid
from pathlib import Path
from typing import Any

import httpx
from alembic import command
from sqlalchemy import create_engine, inspect

from bagmitra_api.db.models import LabTest
from bagmitra_api.sync.payloads import LabTestPayload
from tests.test_accounts_sync import mutation
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, pull, push


def lab_test(plot_id: uuid.UUID, entity_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "test_type": "soil",
        "sampled_on": "2026-10-01",
        "lab_name": "District soil testing lab",
        "reported_on": "2026-10-20",
        "readings": [
            {"parameter": "pH", "value": "7.9", "unit": None},
            {"parameter": "EC", "value": "0.42", "unit": "dS/m"},
            {"parameter": "सेंद्रिय कर्ब", "value": "<0.5", "unit": "%"},
        ],
        "note": "मृदा आरोग्य पत्रिका",
    }
    fields.update(kw)
    return mutation("lab_test", entity_id or uuid.uuid4(), **fields)


def _tests(body: dict[str, Any]) -> list[dict[str, Any]]:
    return [c for c in body["changes"] if c["entity"] == "lab_test"]


async def test_lab_test_round_trip_and_delete(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, test_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        lab_test(plot_id, entity_id=test_id),
        lab_test(
            plot_id,
            test_type="water",
            lab_name=None,
            reported_on=None,
            readings=[],
            note=None,
        ),
    )
    assert [r["status"] for r in results] == ["applied"] * 3
    body = await pull(client, auth_headers)
    rows = _tests(body)
    assert len(rows) == 2
    first = next(c for c in rows if c["entity_id"] == str(test_id))
    assert first["data"]["test_type"] == "soil"
    assert first["data"]["sampled_on"] == "2026-10-01"
    assert first["data"]["reported_on"] == "2026-10-20"
    # Values come back exactly as typed (text, never parsed or rated).
    assert first["data"]["readings"][2] == {
        "parameter": "सेंद्रिय कर्ब",
        "value": "<0.5",
        "unit": "%",
    }
    other = next(c for c in rows if c["entity_id"] != str(test_id))
    assert other["data"]["readings"] == []
    assert other["data"]["lab_name"] is None

    delete = mutation("lab_test", test_id)
    delete.update(op="delete", payload={}, client_updated_at="2026-11-03T07:00:00Z")
    assert [r["status"] for r in await push(client, auth_headers, delete)] == ["applied"]
    after = _tests(await pull(client, auth_headers, since=body["cursor"]))
    assert [(c["entity_id"], c["op"]) for c in after] == [(str(test_id), "delete")]


async def test_plot_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    results = await push(client, auth_headers, lab_test(uuid.uuid4()))
    assert [r["error"] for r in results] == ["invalid_reference"]


async def test_payloads_are_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    one = {"parameter": "pH", "value": "7", "unit": None}
    results = await push(
        client,
        auth_headers,
        lab_test(plot_id, test_type="petiole"),
        lab_test(plot_id, sampled_on=None),
        lab_test(plot_id, sampled_on="soon"),
        lab_test(plot_id, lab_name="x" * 121),
        lab_test(plot_id, note="n" * 501),
        lab_test(plot_id, readings=[{**one, "parameter": ""}]),
        lab_test(plot_id, readings=[{**one, "value": ""}]),
        lab_test(plot_id, readings=[{**one, "value": "1" * 31}]),
        lab_test(plot_id, readings=[{**one, "unit": "u" * 21}]),
        lab_test(plot_id, readings=[{**one, "status": "low"}]),
        lab_test(plot_id, readings=[one] * 41),
        lab_test(plot_id, report_path="/data/user/0/r.jpg"),
    )
    assert [r["status"] for r in results] == ["rejected"] * 12
    assert {r["error"] for r in results} == {"invalid_payload"}


def test_lab_test_is_owner_scoped() -> None:
    assert LabTest.owner_column == "owner_id"
    assert "owner_id" in LabTest.__table__.columns
    payload = LabTestPayload(plot_id=uuid.uuid4(), test_type="leaf", sampled_on="2026-09-01")
    columns = payload.to_columns()
    assert columns["readings"] == []
    assert columns["lab_name"] is None
    assert columns["reported_on"] is None


def test_migration_0024_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'l.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))
    command.upgrade(cfg, "0024")
    with engine.connect() as conn:
        assert "lab_tests" in inspect(conn).get_table_names()
        columns = {c["name"] for c in inspect(conn).get_columns("lab_tests")}
    assert {"owner_id", "plot_id", "test_type", "sampled_on", "readings"} <= columns
    command.downgrade(cfg, "0023")
    with engine.connect() as conn:
        assert "lab_tests" not in inspect(conn).get_table_names()
    engine.dispose()
