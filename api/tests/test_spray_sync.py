"""M2: spray records sync offline-first, tied to the grower's own plot (and optionally a
bahar). The active ingredient is what the PHI / ban warning keys on, so it is a slug-like
normalised string; cost is whole paise."""

from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.test_accounts_sync import mutation
from tests.test_bahar_sync import cycle_mutation
from tests.test_plots_sync import plot_mutation, pull, push


def spray(plot_id: uuid.UUID, cycle_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "sprayed_on": "2026-11-02",
        "product_name": "Imida 17.8 SL",
        "active_ingredient": "imidacloprid",
        "dose": "0.3 ml per litre",
        "water_litres": 600.0,
        "area_acres": 4.0,
        "cost_paise": 240_000,
        "operator": "Ramesh",
        "phi_days": 15,
        "target": "psylla",
    }
    fields.update(kw)
    return mutation("spray_record", uuid.uuid4(), **fields)


async def test_spray_record_round_trip(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        cycle_mutation(cycle_id, plot_id),
        spray(plot_id, cycle_id),
        spray(plot_id, phi_days=None, operator=None, target=None, water_litres=None),
    )
    assert [r["status"] for r in results] == ["applied"] * 4
    body = await pull(client, auth_headers)
    sprays = [c for c in body["changes"] if c["entity"] == "spray_record"]
    assert len(sprays) == 2
    full = next(s for s in sprays if s["data"]["phi_days"] == 15)
    assert full["data"]["active_ingredient"] == "imidacloprid"
    assert full["data"]["cost_paise"] == 240_000
    assert full["data"]["sprayed_on"] == "2026-11-02"


async def test_spray_must_reference_own_plot_and_cycle(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(client, auth_headers, spray(uuid.uuid4()), spray(plot_id, uuid.uuid4()))
    assert [r["error"] for r in results] == ["invalid_reference"] * 2


async def test_spray_payload_is_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        spray(plot_id, phi_days=-1),
        spray(plot_id, phi_days=400),
        spray(plot_id, cost_paise=1.5),
        spray(plot_id, product_name=""),
        spray(plot_id, water_litres=0),
        spray(plot_id, active_ingredient="x" * 200),
    )
    assert [r["status"] for r in results] == ["rejected"] * 6
    assert {r["error"] for r in results} == {"invalid_payload"}
