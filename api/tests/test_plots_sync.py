from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.conftest import make_token

SQUARE = {
    "type": "Polygon",
    "coordinates": [
        [[78.58, 21.27], [78.59, 21.27], [78.59, 21.28], [78.58, 21.28], [78.58, 21.27]]
    ],
}


def plot_mutation(
    plot_id: uuid.UUID,
    *,
    op: str = "upsert",
    updated_at: str = "2026-10-12T06:00:00Z",
    **fields: Any,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "name": "Bag 1",
        "crop": "santra",
        "variety": "nagpur",
        "area_sq_m": 16187.4,
        "planting_year": 2014,
        "tree_count": 440,
        "row_spacing_m": 6.0,
        "plant_spacing_m": 6.0,
        "irrigation_type": "drip",
        "water_source": "well",
        "soil_type": "black_medium",
        "centroid_lat": 21.275,
        "centroid_lon": 78.585,
        "boundary": SQUARE,
    }
    payload.update(fields)
    return {
        "client_mutation_id": str(uuid.uuid4()),
        "entity": "plot",
        "entity_id": str(plot_id),
        "op": op,
        "client_updated_at": updated_at,
        "payload": {} if op == "delete" else payload,
    }


async def push(
    client: httpx.AsyncClient, headers: dict[str, str], *mutations: dict[str, Any]
) -> list[dict[str, Any]]:
    resp = await client.post("/v1/sync/push", json={"mutations": list(mutations)}, headers=headers)
    assert resp.status_code == 200, resp.text
    results: list[dict[str, Any]] = resp.json()["results"]
    return results


async def pull(
    client: httpx.AsyncClient, headers: dict[str, str], since: int = 0
) -> dict[str, Any]:
    resp = await client.get("/v1/sync/pull", params={"since": since}, headers=headers)
    assert resp.status_code == 200
    body: dict[str, Any] = resp.json()
    return body


def plot_changes(body: dict[str, Any]) -> list[dict[str, Any]]:
    return [c for c in body["changes"] if c["entity"] == "plot"]


async def test_create_and_pull_plot(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    [r] = await push(client, auth_headers, plot_mutation(plot_id))
    assert r["status"] == "applied"
    [change] = plot_changes(await pull(client, auth_headers))
    assert change["entity_id"] == str(plot_id)
    assert change["op"] == "upsert"
    assert change["data"]["tree_count"] == 440
    assert change["data"]["boundary"] == SQUARE


async def test_last_writer_wins_on_plot(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id, updated_at="2026-10-12T08:00:00Z", name="New"),
        plot_mutation(plot_id, updated_at="2026-10-12T07:00:00Z", name="Old"),
    )
    assert [r["status"] for r in results] == ["applied", "stale"]
    [change] = plot_changes(await pull(client, auth_headers))
    assert change["data"]["name"] == "New"


async def test_delete_is_synced_as_tombstone(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    cursor = (await pull(client, auth_headers))["cursor"]
    [r] = await push(
        client, auth_headers, plot_mutation(plot_id, op="delete", updated_at="2026-10-13T00:00:00Z")
    )
    assert r["status"] == "applied"
    [change] = plot_changes(await pull(client, auth_headers, cursor))
    assert change["op"] == "delete"
    assert change["data"] == {}


async def test_deleting_an_unknown_plot_is_a_no_op(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    [r] = await push(client, auth_headers, plot_mutation(uuid.uuid4(), op="delete"))
    assert r["status"] == "applied"
    assert plot_changes(await pull(client, auth_headers)) == []


async def test_cannot_touch_another_farmers_plot(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    other = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    await push(client, other, plot_mutation(plot_id))
    [r] = await push(
        client, auth_headers, plot_mutation(plot_id, updated_at="2026-10-14T00:00:00Z")
    )
    assert r == {
        "client_mutation_id": r["client_mutation_id"],
        "status": "rejected",
        "error": "forbidden",
    }
    assert plot_changes(await pull(client, auth_headers)) == []


async def test_rejects_invalid_plot_payloads(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    open_ring = {
        "type": "Polygon",
        "coordinates": [[[78.5, 21.2], [78.6, 21.2], [78.6, 21.3], [78.5, 21.3]]],
    }
    bad = [
        plot_mutation(uuid.uuid4(), area_sq_m=0),
        plot_mutation(uuid.uuid4(), crop="Santra!"),
        plot_mutation(uuid.uuid4(), centroid_lat=123),
        plot_mutation(uuid.uuid4(), boundary=open_ring),
        plot_mutation(uuid.uuid4(), boundary={"type": "Point", "coordinates": [78.5, 21.2]}),
        plot_mutation(uuid.uuid4(), name=""),
    ]
    results = await push(client, auth_headers, *bad)
    assert {r["error"] for r in results} == {"invalid_payload"}


async def test_plot_entity_id_must_be_a_uuid(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    m = plot_mutation(uuid.uuid4()) | {"entity_id": "plot-1"}
    [r] = await push(client, auth_headers, m)
    assert r["error"] == "invalid_entity_id"


async def test_profile_still_rejects_delete(
    client: httpx.AsyncClient, auth_headers: dict[str, str], user_id: uuid.UUID
) -> None:
    m = plot_mutation(user_id, op="delete") | {"entity": "farmer_profile"}
    [r] = await push(client, auth_headers, m)
    assert r["error"] == "unsupported_op"
