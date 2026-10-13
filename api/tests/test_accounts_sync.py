"""M2: expenses and incomes sync offline-first, tied to the grower's own plot and
optionally to one of their bahar cycles. Money is whole paise (integers, never floats)."""

from __future__ import annotations

import uuid
from typing import Any

import httpx

from tests.test_bahar_sync import cycle_mutation
from tests.test_plots_sync import plot_mutation, pull, push


def mutation(entity: str, entity_id: uuid.UUID, **payload: Any) -> dict[str, Any]:
    return {
        "client_mutation_id": str(uuid.uuid4()),
        "entity": entity,
        "entity_id": str(entity_id),
        "op": "upsert",
        "client_updated_at": "2026-10-13T07:00:00Z",
        "payload": payload,
    }


def expense(plot_id: uuid.UUID, cycle_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": str(cycle_id) if cycle_id else None,
        "spent_on": "2026-10-10",
        "category": "labour",
        "amount_paise": 150_000,
        "note": "छाटणी",
    }
    fields.update(kw)
    return mutation("expense", uuid.uuid4(), **fields)


def income(plot_id: uuid.UUID, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "bahar_cycle_id": None,
        "sold_on": "2027-01-20",
        "buyer_name": "Kalmeshwar trader",
        "grade": "grade_a",
        "quantity_kg": 2500.0,
        "rate_paise_per_quintal": 320_000,
        "deductions_paise": 50_000,
        "payment_status": "partial",
        "paid_paise": 5_000_000,
        "paid_on": "2027-01-25",
    }
    fields.update(kw)
    return mutation("income", uuid.uuid4(), **fields)


async def test_expense_and_income_round_trip(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, cycle_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        cycle_mutation(cycle_id, plot_id),
        expense(plot_id, cycle_id),
        expense(plot_id),
        income(plot_id),
    )
    assert [r["status"] for r in results] == ["applied"] * 5
    body = await pull(client, auth_headers)
    expenses = [c for c in body["changes"] if c["entity"] == "expense"]
    [sale] = [c for c in body["changes"] if c["entity"] == "income"]
    assert sorted(e["data"]["bahar_cycle_id"] is None for e in expenses) == [False, True]
    assert expenses[0]["data"]["amount_paise"] == 150_000
    assert sale["data"]["rate_paise_per_quintal"] == 320_000
    assert sale["data"]["paid_on"] == "2027-01-25"


async def test_references_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        expense(uuid.uuid4()),
        expense(plot_id, uuid.uuid4()),
        income(uuid.uuid4()),
    )
    assert [r["error"] for r in results] == ["invalid_reference"] * 3


async def test_money_and_categories_are_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        expense(plot_id, amount_paise=-1),
        expense(plot_id, amount_paise=12.5),
        expense(plot_id, category="Not A Slug"),
        income(plot_id, payment_status="maybe"),
        income(plot_id, paid_paise=10**13),
    )
    assert [r["status"] for r in results] == ["rejected"] * 5
    assert {r["error"] for r in results} == {"invalid_payload"}
