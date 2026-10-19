"""M2: harvest records and the labour register sync offline-first, tied to the grower's own
plot and optionally a bahar. Wages, advances and settlement are whole paise."""

from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.test_accounts_sync import mutation
from tests.test_bahar_sync import cycle_mutation
from tests.test_plots_sync import plot_mutation, pull, push


def harvest(plot_id: uuid.UUID, cycle_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "harvested_on": "2027-01-20",
        "grade": "grade_a",
        "size_class": "large",
        "quantity_kg": 1250.5,
        "note": None,
    }
    fields.update(kw)
    return mutation("harvest_record", uuid.uuid4(), **fields)


def labour(plot_id: uuid.UUID, cycle_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "worker_name": "Sunita",
        "worked_on": "2026-11-05",
        "task": "weeding",
        "wage_paise": 40_000,
        "advance_paise": 10_000,
        "settled_on": None,
        "note": None,
    }
    fields.update(kw)
    return mutation("labour_record", uuid.uuid4(), **fields)


async def test_harvest_and_labour_round_trip(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        cycle_mutation(cycle_id, plot_id),
        harvest(plot_id, cycle_id),
        harvest(plot_id, grade=None, size_class=None),
        labour(plot_id, cycle_id),
        labour(plot_id, task=None, advance_paise=0, settled_on="2026-11-30"),
    )
    assert [r["status"] for r in results] == ["applied"] * 6
    body = await pull(client, auth_headers)
    harvests = [c for c in body["changes"] if c["entity"] == "harvest_record"]
    labours = [c for c in body["changes"] if c["entity"] == "labour_record"]
    assert len(harvests) == 2
    assert len(labours) == 2
    graded = next(c for c in harvests if c["data"]["grade"] == "grade_a")
    assert graded["data"]["quantity_kg"] == 1250.5
    assert graded["data"]["size_class"] == "large"
    settled = next(c for c in labours if c["data"]["settled_on"])
    assert settled["data"]["settled_on"] == "2026-11-30"
    assert settled["data"]["wage_paise"] == 40_000


async def test_references_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        harvest(uuid.uuid4()),
        harvest(plot_id, uuid.uuid4()),
        labour(uuid.uuid4()),
        labour(plot_id, uuid.uuid4()),
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
        harvest(plot_id, quantity_kg=0),
        harvest(plot_id, quantity_kg=-3),
        harvest(plot_id, grade="Not A Slug"),
        harvest(plot_id, size_class="X"),
        labour(plot_id, worker_name=""),
        labour(plot_id, wage_paise=-1),
        labour(plot_id, advance_paise=-1),
        labour(plot_id, task="Bad Task"),
    )
    assert [r["status"] for r in results] == ["rejected"] * 8
    assert {r["error"] for r in results} == {"invalid_payload"}
