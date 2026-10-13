"""K0 admin API: only kb_admin / kb_reviewer roles (Supabase app_metadata, server-set)
can review, publish, import and resolve alerts. Publishing also runs the legal gate."""

from __future__ import annotations

import uuid

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.kb.models import KbCard, KbSource, KbTopic
from bagmitra_api.kb.seed import seed_sources
from tests.conftest import make_token
from tests.test_kb_import import CLAIMS_V1

BASE = "/v1/admin/kb"


def headers(*roles: str, reviewer_role: str | None = None) -> dict[str, str]:
    meta: dict[str, object] = {"roles": list(roles)}
    if reviewer_role:
        meta["reviewer_role"] = reviewer_role
    return {"Authorization": f"Bearer {make_token(uuid.uuid4(), app_metadata=meta)}"}


ADMIN = headers("kb_admin")
REVIEWER = headers("kb_reviewer", reviewer_role="agronomist")


async def seed_card(engine: AsyncEngine, *, chemical: bool) -> uuid.UUID:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        src = await session.scalar(
            select(KbSource.id).where(KbSource.allowed_use != "internal_only").limit(1)
        )
        topic = KbTopic(id=uuid.uuid4(), key="psylla", kind="pest", labels={"en": "Psylla"})
        card = KbCard(
            id=uuid.uuid4(),
            topic_id=topic.id,
            crop="santra",
            version=1,
            content={"en": {"title": "Citrus psylla"}},
            reviewed_languages=["en"],
            chemical_options=(
                [
                    {
                        "active_ingredient": "imidacloprid",
                        "formulation": "17.8 SL",
                        "target": "psylla",
                    }
                ]
                if chemical
                else []
            ),
            sources=[{"source_id": str(src), "locator": "p. 3"}],
            status="draft",
        )
        session.add_all([topic, card])
        card_id = card.id
        await session.commit()
        return card_id


async def test_growers_cannot_reach_admin_endpoints(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    assert (await client.get(f"{BASE}/cards")).status_code == 401
    res = await client.get(f"{BASE}/cards", headers=auth_headers)
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "forbidden"
    res = await client.post(f"{BASE}/cards/{uuid.uuid4()}/publish", headers=REVIEWER)
    assert res.status_code == 403


async def test_review_then_publish_card(client: httpx.AsyncClient, engine: AsyncEngine) -> None:
    card_id = await seed_card(engine, chemical=False)
    cards = (await client.get(f"{BASE}/cards?status=draft", headers=ADMIN)).json()["cards"]
    assert [c["id"] for c in cards] == [str(card_id)]
    assert cards[0]["title"] == "Citrus psylla"

    refused = await client.post(f"{BASE}/cards/{card_id}/publish", headers=ADMIN)
    assert refused.status_code == 409
    assert "no_valid_review" in refused.json()["error"]["message"]

    res = await client.post(
        f"{BASE}/cards/{card_id}/reviews", headers=REVIEWER, json={"decision": "approve"}
    )
    assert res.status_code == 201
    assert res.json()["status"] == "expert_reviewed"
    res = await client.post(f"{BASE}/cards/{card_id}/publish", headers=ADMIN)
    assert res.status_code == 200, res.text
    assert res.json()["status"] == "published"


async def test_reviewer_needs_a_reviewer_role(
    client: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    card_id = await seed_card(engine, chemical=False)
    res = await client.post(
        f"{BASE}/cards/{card_id}/reviews",
        headers=headers("kb_reviewer"),
        json={"decision": "approve"},
    )
    assert res.status_code == 403
    missing = await client.post(
        f"{BASE}/cards/{uuid.uuid4()}/reviews", headers=REVIEWER, json={"decision": "approve"}
    )
    assert missing.status_code == 404


async def test_publish_runs_the_legal_gate(client: httpx.AsyncClient, engine: AsyncEngine) -> None:
    card_id = await seed_card(engine, chemical=True)
    await client.post(
        f"{BASE}/cards/{card_id}/reviews", headers=REVIEWER, json={"decision": "approve"}
    )
    blocked = await client.post(f"{BASE}/cards/{card_id}/publish", headers=ADMIN)
    assert blocked.status_code == 409
    assert "no_label_claim" in blocked.json()["error"]["message"]

    imported = await client.post(
        f"{BASE}/imports/claims",
        headers=ADMIN,
        json={"source_key": "cibrc_insecticides_pgr", "csv": CLAIMS_V1},
    )
    assert imported.status_code == 200, imported.text
    assert imported.json()["added"] == 2
    ok = await client.post(f"{BASE}/cards/{card_id}/publish", headers=ADMIN)
    assert ok.status_code == 200, ok.text


async def test_import_errors_and_alerts(client: httpx.AsyncClient, engine: AsyncEngine) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await session.commit()
    bad = await client.post(
        f"{BASE}/imports/restrictions",
        headers=ADMIN,
        json={"source_key": "ppqs_banned_restricted", "csv": "active_ingredient\nx\n"},
    )
    assert bad.status_code == 422
    assert bad.json()["error"]["code"] == "import_rejected"

    ok = await client.post(
        f"{BASE}/imports/restrictions",
        headers=ADMIN,
        json={
            "source_key": "ppqs_banned_restricted",
            "csv": "active_ingredient,kind,crops,crop_groups,notification,effective_from\n"
            "dicofol,banned,,,S.O. 4294(E),2023-10-03\n",
        },
    )
    assert ok.status_code == 200
    alerts = (await client.get(f"{BASE}/alerts", headers=ADMIN)).json()["alerts"]
    assert [a["kind"] for a in alerts] == ["import_applied"]
    res = await client.post(f"{BASE}/alerts/{alerts[0]['id']}/resolve", headers=ADMIN)
    assert res.status_code == 200
    assert (await client.get(f"{BASE}/alerts", headers=ADMIN)).json()["alerts"] == []
    assert (
        await client.post(f"{BASE}/alerts/{uuid.uuid4()}/resolve", headers=ADMIN)
    ).status_code == 404


async def test_sources_are_listed_with_licence(
    client: httpx.AsyncClient, engine: AsyncEngine
) -> None:
    async with async_sessionmaker(engine)() as session:
        await seed_sources(session)
        await session.commit()
    sources = (await client.get(f"{BASE}/sources", headers=ADMIN)).json()["sources"]
    assert len(sources) == 51
    assert {"key", "tier", "allowed_use", "verification"} <= set(sources[0])


async def test_malformed_app_metadata_grants_nothing(client: httpx.AsyncClient) -> None:
    for meta in ("kb_admin", {"roles": "kb_admin"}, {"roles": [1, None]}):
        token = make_token(uuid.uuid4(), app_metadata=meta)
        res = await client.get(f"{BASE}/cards", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 403
    # user_metadata is user-editable in Supabase and must never grant a role.
    token = make_token(uuid.uuid4(), user_metadata={"roles": ["kb_admin"]})
    res = await client.get(f"{BASE}/cards", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 403
