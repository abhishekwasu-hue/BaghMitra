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


def _product(
    name: str, ai: str | None, cost: int, phi: int | None, dose: str | None = None
) -> dict[str, Any]:
    return {
        "product_name": name,
        "active_ingredient": ai,
        "dose": dose,
        "cost_paise": cost,
        "phi_days": phi,
    }


def _sprays(body: dict[str, Any]) -> list[dict[str, Any]]:
    return [c["data"] for c in body["changes"] if c["entity"] == "spray_record"]


async def test_tank_mix_round_trip_keeps_every_product(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Q142: several products in one spray are one record (one count, one water and area
    figure); the record's cost is their sum and its PHI the longest of them."""
    plot_id = uuid.uuid4()
    products = [
        _product("Captan 50 WP", "captan", 45_000, 7, dose="2 g per litre"),
        _product("Imida 17.8 SL", "imidacloprid", 65_000, 15),
        _product("Neem oil", None, 20_000, None),
    ]
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        # Stale top-level figures: the server derives them from the products, so a wrong
        # sum or a shorter PHI is never stored.
        spray(plot_id, products=products, cost_paise=1, phi_days=0, product_name="x"),
    )
    assert [r["status"] for r in results] == ["applied"] * 2
    (mix,) = _sprays(await pull(client, auth_headers))
    assert [p["product_name"] for p in mix["products"]] == [
        "Captan 50 WP",
        "Imida 17.8 SL",
        "Neem oil",
    ]
    assert mix["products"][0]["dose"] == "2 g per litre"
    assert mix["cost_paise"] == 130_000
    assert mix["phi_days"] == 15
    assert mix["product_name"] == "Captan 50 WP"
    assert mix["active_ingredient"] == "captan"
    assert mix["dose"] == "2 g per litre"
    assert mix["water_litres"] == 600.0


async def test_mix_without_any_phi_has_none(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    products = [_product("A", None, 0, None), _product("B", None, 0, None)]
    await push(client, auth_headers, plot_mutation(plot_id), spray(plot_id, products=products))
    (mix,) = _sprays(await pull(client, auth_headers))
    assert mix["phi_days"] is None
    assert mix["cost_paise"] == 0


async def test_single_product_record_reads_as_before(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id), spray(plot_id))
    (one,) = _sprays(await pull(client, auth_headers))
    assert one["products"] is None
    assert one["cost_paise"] == 240_000
    assert one["phi_days"] == 15


async def test_a_write_without_products_keeps_the_stored_mix(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """An app from before Q142 re-sends a record it pulled without the products list (its
    bill photo backup); the mix stored on the server stays whole."""
    plot_id = uuid.uuid4()
    mix = spray(
        plot_id,
        products=[
            _product("Captan 50 WP", "captan", 45_000, 7),
            _product("Imida 17.8 SL", "imidacloprid", 65_000, 15),
        ],
    )
    await push(client, auth_headers, plot_mutation(plot_id), mix)
    old = {
        **mix,
        "client_mutation_id": str(uuid.uuid4()),
        "client_updated_at": "2026-10-14T07:00:00Z",
        "payload": {
            **{k: v for k, v in mix["payload"].items() if k != "products"},
            "product_name": "Captan 50 WP",
            "cost_paise": 110_000,
        },
    }
    (result,) = await push(client, auth_headers, old)
    assert result["status"] == "applied"
    (data,) = _sprays(await pull(client, auth_headers))
    assert [p["product_name"] for p in data["products"]] == ["Captan 50 WP", "Imida 17.8 SL"]
    assert data["cost_paise"] == 110_000
    assert data["phi_days"] == 15


async def test_tank_mix_payload_is_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    good = _product("Captan", "captan", 0, 7)
    results = await push(
        client,
        auth_headers,
        spray(plot_id, products=[]),
        spray(plot_id, products=[good, {**good, "product_name": ""}]),
        spray(plot_id, products=[good, {**good, "phi_days": 400}]),
        spray(plot_id, products=[good, {**good, "cost_paise": -1}]),
        spray(plot_id, products=[good, {**good, "path": "/docs/x"}]),
        spray(plot_id, products=[good] * 21),
    )
    assert [r["status"] for r in results] == ["rejected"] * 6
    assert {r["error"] for r in results} == {"invalid_payload"}
