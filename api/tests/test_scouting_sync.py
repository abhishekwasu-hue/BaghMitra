"""Field scouting log ("पाहणी नोंद"): what the grower looked at on a plot, how bad it was and a
note. Synced offline-first; the optional photo stays on the phone and is never part of the
payload."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import httpx
from alembic import command
from sqlalchemy import create_engine, inspect

from bagmitra_api.db.models import ScoutingRecord
from bagmitra_api.sync.payloads import ScoutingRecordPayload
from tests.test_accounts_sync import mutation
from tests.test_bahar_sync import cycle_mutation
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, pull, push


def scouting(
    plot_id: uuid.UUID,
    cycle_id: uuid.UUID | None = None,
    entity_id: uuid.UUID | None = None,
    **kw: Any,
) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "observed_on": "2026-11-02",
        "item": "psylla",
        "severity": "medium",
        "note": "नवीन फुटीवर जास्त",
    }
    fields.update(kw)
    return mutation("scouting_record", entity_id or uuid.uuid4(), **fields)


def _scouting(body: dict[str, Any]) -> list[dict[str, Any]]:
    return [c for c in body["changes"] if c["entity"] == "scouting_record"]


async def test_scouting_round_trip_and_delete(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id, record_id = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        cycle_mutation(cycle_id, plot_id),
        scouting(plot_id, cycle_id, entity_id=record_id),
        scouting(plot_id, item="fruit_drop", severity="none", note=None),
    )
    assert [r["status"] for r in results] == ["applied"] * 4
    body = await pull(client, auth_headers)
    rows = _scouting(body)
    assert len(rows) == 2
    first = next(c for c in rows if c["entity_id"] == str(record_id))
    assert first["data"]["item"] == "psylla"
    assert first["data"]["severity"] == "medium"
    assert first["data"]["bahar_cycle_id"] == str(cycle_id)
    assert "photo_path" not in first["data"]

    delete = mutation("scouting_record", record_id)
    delete.update(op="delete", payload={}, client_updated_at="2026-11-03T07:00:00Z")
    assert [r["status"] for r in await push(client, auth_headers, delete)] == ["applied"]
    after = _scouting(await pull(client, auth_headers, since=body["cursor"]))
    assert [(c["entity_id"], c["op"]) for c in after] == [(str(record_id), "delete")]


async def test_references_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client, auth_headers, scouting(uuid.uuid4()), scouting(plot_id, uuid.uuid4())
    )
    assert [r["error"] for r in results] == ["invalid_reference"] * 2


async def test_payloads_are_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        scouting(plot_id, item="Bad Item"),
        scouting(plot_id, severity="severe"),
        scouting(plot_id, observed_on="not-a-date"),
        scouting(plot_id, note="n" * 501),
        scouting(plot_id, photo_path="/data/user/0/photo.jpg"),
    )
    assert [r["status"] for r in results] == ["rejected"] * 5
    assert {r["error"] for r in results} == {"invalid_payload"}


def test_scouting_is_owner_scoped_and_has_no_photo_column() -> None:
    assert ScoutingRecord.owner_column == "owner_id"
    assert "owner_id" in ScoutingRecord.__table__.columns
    assert "photo_path" not in ScoutingRecord.__table__.columns
    assert "photo_path" not in ScoutingRecordPayload.model_fields
    payload = ScoutingRecordPayload(
        plot_id=uuid.uuid4(), observed_on=datetime.now(UTC).date(), item="other", severity="low"
    )
    assert payload.to_columns()["bahar_cycle_id"] is None


def test_migration_0018_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 's.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))
    command.upgrade(cfg, "0018")
    with engine.connect() as conn:
        assert "scouting_records" in inspect(conn).get_table_names()
        columns = {c["name"] for c in inspect(conn).get_columns("scouting_records")}
    assert {"owner_id", "plot_id", "observed_on", "item", "severity"} <= columns
    assert "photo_path" not in columns
    command.downgrade(cfg, "0017")
    with engine.connect() as conn:
        assert "scouting_records" not in inspect(conn).get_table_names()
    engine.dispose()
