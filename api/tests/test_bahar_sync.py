from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.conftest import make_token
from tests.test_plots_sync import plot_changes, plot_mutation, pull, push


def cycle_mutation(
    cycle_id: uuid.UUID,
    plot_id: uuid.UUID,
    *,
    op: str = "upsert",
    updated_at: str = "2026-10-12T07:00:00Z",
    **fields: Any,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar": "mrig",
        "season_year": 2027,
        "template_id": None,
        "status": "planned",
        "planned": {"stress_start": "2027-05-01", "flowering": "2027-06-15"},
        "actual": {},
    }
    payload.update(fields)
    return {
        "client_mutation_id": str(uuid.uuid4()),
        "entity": "bahar_cycle",
        "entity_id": str(cycle_id),
        "op": op,
        "client_updated_at": updated_at,
        "payload": {} if op == "delete" else payload,
    }


def cycle_changes(body: dict[str, Any]) -> list[dict[str, Any]]:
    return [c for c in body["changes"] if c["entity"] == "bahar_cycle"]


async def test_plot_then_cycle_in_one_batch(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client, auth_headers, plot_mutation(plot_id), cycle_mutation(cycle_id, plot_id)
    )
    assert [r["status"] for r in results] == ["applied", "applied"]
    body = await pull(client, auth_headers)
    assert len(plot_changes(body)) == 1
    [change] = cycle_changes(body)
    assert change["data"]["plot_id"] == str(plot_id)
    assert change["data"]["planned"] == {"stress_start": "2027-05-01", "flowering": "2027-06-15"}


async def test_cycle_must_reference_own_existing_plot(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    others_plot = uuid.uuid4()
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    await push(client, other, plot_mutation(others_plot))
    results = await push(
        client,
        auth_headers,
        cycle_mutation(uuid.uuid4(), others_plot),
        cycle_mutation(uuid.uuid4(), uuid.uuid4()),
    )
    assert [r["error"] for r in results] == ["invalid_reference", "invalid_reference"]


async def test_cycle_on_deleted_plot_is_rejected(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    await push(
        client, auth_headers, plot_mutation(plot_id, op="delete", updated_at="2026-10-12T06:30:00Z")
    )
    [r] = await push(client, auth_headers, cycle_mutation(uuid.uuid4(), plot_id))
    assert r["error"] == "invalid_reference"


async def test_rejects_invalid_cycle_payloads(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    bad = [
        cycle_mutation(uuid.uuid4(), plot_id, bahar="Mrig!"),
        cycle_mutation(uuid.uuid4(), plot_id, season_year=1800),
        cycle_mutation(uuid.uuid4(), plot_id, status="growing"),
        cycle_mutation(uuid.uuid4(), plot_id, planned={"flowering": "June"}),
        cycle_mutation(uuid.uuid4(), plot_id, planned={"Bad Key": "2027-06-01"}),
    ]
    results = await push(client, auth_headers, *bad)
    assert {r["error"] for r in results} == {"invalid_payload"}


async def test_cycle_delete_is_a_tombstone(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id), cycle_mutation(cycle_id, plot_id))
    cursor = (await pull(client, auth_headers))["cursor"]
    await push(
        client,
        auth_headers,
        cycle_mutation(cycle_id, plot_id, op="delete", updated_at="2026-10-13T00:00:00Z"),
    )
    [change] = cycle_changes(await pull(client, auth_headers, cursor))
    assert change["op"] == "delete"
