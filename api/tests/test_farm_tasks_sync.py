"""Farm tasks and reminders sync offline-first. A task may belong to a plot and a bahar, or to
the whole orchard (no plot); done is just a date."""

from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.test_accounts_sync import mutation
from tests.test_bahar_sync import cycle_mutation
from tests.test_plots_sync import plot_mutation, pull, push


def task(
    plot_id: uuid.UUID | None = None, cycle_id: uuid.UUID | None = None, **kw: Any
) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id) if plot_id else None,
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "title": "Check drip lines",
        "kind": "irrigation",
        "due_on": "2026-11-10",
        "done_on": None,
        "source": "manual",
        "note": None,
    }
    fields.update(kw)
    return mutation("farm_task", uuid.uuid4(), **fields)


async def test_tasks_round_trip_with_and_without_a_plot(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        cycle_mutation(cycle_id, plot_id),
        task(plot_id, cycle_id),
        task(plot_id, done_on="2026-11-09", source="mrig-flowering (template)"),
        task(title="Renew the electricity connection", kind="other"),
    )
    assert [r["status"] for r in results] == ["applied"] * 5
    body = await pull(client, auth_headers)
    tasks = [c for c in body["changes"] if c["entity"] == "farm_task"]
    assert len(tasks) == 3
    done = next(c for c in tasks if c["data"]["done_on"])
    assert done["data"]["source"] == "mrig-flowering (template)"
    orchard = next(c for c in tasks if c["data"]["plot_id"] is None)
    assert orchard["data"]["title"] == "Renew the electricity connection"


async def test_references_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(client, auth_headers, task(uuid.uuid4()), task(plot_id, uuid.uuid4()))
    assert [r["error"] for r in results] == ["invalid_reference"] * 2


async def test_payloads_are_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    results = await push(
        client,
        auth_headers,
        task(title=""),
        task(title="x" * 201),
        task(kind="Bad Kind"),
        task(due_on="not-a-date"),
        task(note="n" * 501),
    )
    assert [r["status"] for r in results] == ["rejected"] * 5
    assert {r["error"] for r in results} == {"invalid_payload"}
