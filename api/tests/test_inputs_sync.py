"""M2: input (fertiliser / manure / micronutrient) and irrigation records sync offline-first,
tied to the grower's own plot and optionally a bahar. Input costs are whole paise."""

from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.test_accounts_sync import mutation
from tests.test_bahar_sync import cycle_mutation
from tests.test_plots_sync import plot_mutation, pull, push


def input_record(
    plot_id: uuid.UUID, cycle_id: uuid.UUID | None = None, **kw: Any
) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "applied_on": "2026-11-05",
        "kind": "fertiliser",
        "product_name": "Urea",
        "quantity": 50.0,
        "unit": "kg",
        "cost_paise": 133_000,
        "note": "after rain",
    }
    fields.update(kw)
    return mutation("input_record", uuid.uuid4(), **fields)


def irrigation(plot_id: uuid.UUID, cycle_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "irrigated_on": "2026-11-06",
        "duration_hours": 3.5,
        "water_litres": 40_000.0,
        "note": None,
    }
    fields.update(kw)
    return mutation("irrigation_record", uuid.uuid4(), **fields)


async def test_inputs_and_irrigation_round_trip(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        cycle_mutation(cycle_id, plot_id),
        input_record(plot_id, cycle_id),
        input_record(plot_id, quantity=None, unit=None, cost_paise=0, note=None),
        irrigation(plot_id, cycle_id),
        irrigation(plot_id, duration_hours=None, water_litres=None),
    )
    assert [r["status"] for r in results] == ["applied"] * 6
    body = await pull(client, auth_headers)
    inputs = [c for c in body["changes"] if c["entity"] == "input_record"]
    irrigations = [c for c in body["changes"] if c["entity"] == "irrigation_record"]
    assert len(inputs) == 2
    assert len(irrigations) == 2
    urea = next(c for c in inputs if c["data"]["quantity"] == 50.0)
    assert urea["data"]["kind"] == "fertiliser"
    assert urea["data"]["cost_paise"] == 133_000
    assert urea["data"]["applied_on"] == "2026-11-05"
    long_run = next(c for c in irrigations if c["data"]["duration_hours"] == 3.5)
    assert long_run["data"]["irrigated_on"] == "2026-11-06"


async def test_references_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        input_record(uuid.uuid4()),
        input_record(plot_id, uuid.uuid4()),
        irrigation(uuid.uuid4()),
        irrigation(plot_id, uuid.uuid4()),
    )
    assert [r["error"] for r in results] == ["invalid_reference"] * 4


async def test_payloads_are_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        input_record(plot_id, kind="Not A Slug"),
        input_record(plot_id, product_name=""),
        input_record(plot_id, quantity=0),
        input_record(plot_id, cost_paise=-5),
        input_record(plot_id, unit="x" * 40),
        irrigation(plot_id, duration_hours=0),
        irrigation(plot_id, duration_hours=500),
        irrigation(plot_id, water_litres=-1),
    )
    assert [r["status"] for r in results] == ["rejected"] * 8
    assert {r["error"] for r in results} == {"invalid_payload"}
