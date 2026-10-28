"""Crop insurance policy record ("पीक विमा नोंद"): what the grower enrolled one plot in, for
which bahar, with whom and under which number. A record the grower types in, never a
statement of cover; amounts are optional and only what the grower entered."""

from __future__ import annotations

import uuid
from pathlib import Path
from typing import Any

import httpx
from alembic import command
from sqlalchemy import create_engine, inspect

from bagmitra_api.db.models import InsurancePolicy
from bagmitra_api.sync.payloads import InsurancePolicyPayload
from tests.test_accounts_sync import mutation
from tests.test_migrations import _config, _sync_url
from tests.test_plots_sync import plot_mutation, pull, push


def policy(plot_id: uuid.UUID, entity_id: uuid.UUID | None = None, **kw: Any) -> dict[str, Any]:
    fields: dict[str, Any] = {
        "plot_id": str(plot_id),
        "scheme": "rwbcis",
        "season": "ambia",
        "season_year": 2027,
        "insurer_name": "Example General Insurance",
        "policy_number": "APP-12345",
        "sum_insured_paise": None,
        "premium_paid_paise": 123_400,
        "enrolled_on": "2026-10-20",
        "note": "CSC मार्फत भरले",
    }
    fields.update(kw)
    return mutation("insurance_policy", entity_id or uuid.uuid4(), **fields)


def _policies(body: dict[str, Any]) -> list[dict[str, Any]]:
    return [c for c in body["changes"] if c["entity"] == "insurance_policy"]


async def test_policy_round_trip_and_delete(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id, policy_id = uuid.uuid4(), uuid.uuid4()
    results = await push(
        client,
        auth_headers,
        plot_mutation(plot_id),
        policy(plot_id, entity_id=policy_id),
        policy(
            plot_id,
            scheme="unknown",
            season="mrig",
            season_year=None,
            insurer_name=None,
            policy_number=None,
            premium_paid_paise=None,
            enrolled_on=None,
            note=None,
        ),
    )
    assert [r["status"] for r in results] == ["applied"] * 3
    body = await pull(client, auth_headers)
    rows = _policies(body)
    assert len(rows) == 2
    first = next(c for c in rows if c["entity_id"] == str(policy_id))
    assert first["data"]["scheme"] == "rwbcis"
    assert first["data"]["season"] == "ambia"
    assert first["data"]["premium_paid_paise"] == 123_400
    assert first["data"]["sum_insured_paise"] is None
    assert first["data"]["enrolled_on"] == "2026-10-20"

    delete = mutation("insurance_policy", policy_id)
    delete.update(op="delete", payload={}, client_updated_at="2026-11-03T07:00:00Z")
    assert [r["status"] for r in await push(client, auth_headers, delete)] == ["applied"]
    after = _policies(await pull(client, auth_headers, since=body["cursor"]))
    assert [(c["entity_id"], c["op"]) for c in after] == [(str(policy_id), "delete")]


async def test_plot_must_be_the_growers_own(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    results = await push(client, auth_headers, policy(uuid.uuid4()))
    assert [r["error"] for r in results] == ["invalid_reference"]


async def test_payloads_are_validated(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    plot_id = uuid.uuid4()
    await push(client, auth_headers, plot_mutation(plot_id))
    results = await push(
        client,
        auth_headers,
        policy(plot_id, scheme="lic"),
        policy(plot_id, season="kharif"),
        policy(plot_id, premium_paid_paise=-1),
        policy(plot_id, sum_insured_paise=1.5),
        policy(plot_id, enrolled_on="soon"),
        policy(plot_id, policy_number="x" * 61),
        policy(plot_id, note="n" * 501),
        policy(plot_id, photo_path="/data/user/0/p.jpg"),
    )
    assert [r["status"] for r in results] == ["rejected"] * 8
    assert {r["error"] for r in results} == {"invalid_payload"}


def test_policy_is_owner_scoped() -> None:
    assert InsurancePolicy.owner_column == "owner_id"
    assert "owner_id" in InsurancePolicy.__table__.columns
    payload = InsurancePolicyPayload(plot_id=uuid.uuid4(), scheme="pmfby", season="mrig")
    columns = payload.to_columns()
    assert columns["sum_insured_paise"] is None
    assert columns["insurer_name"] is None


def test_migration_0022_up_and_down(tmp_path: Path) -> None:
    url = f"sqlite+aiosqlite:///{tmp_path / 'i.db'}"
    cfg = _config(url)
    engine = create_engine(_sync_url(url))
    command.upgrade(cfg, "0022")
    with engine.connect() as conn:
        assert "insurance_policies" in inspect(conn).get_table_names()
        columns = {c["name"] for c in inspect(conn).get_columns("insurance_policies")}
    assert {"owner_id", "plot_id", "scheme", "season", "policy_number"} <= columns
    command.downgrade(cfg, "0021")
    with engine.connect() as conn:
        assert "insurance_policies" not in inspect(conn).get_table_names()
    engine.dispose()
