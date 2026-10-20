"""M6a: manual grants and plan config feed the one entitlement computation; the app gets a
signed snapshot. No payment provider is involved (billing addendum §2.1, §2.4)."""

from __future__ import annotations

import base64
import json
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta

import httpx
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.billing.models import BillingEvent, EntitlementSnapshot
from bagmitra_api.billing.seed import seed_plans
from bagmitra_api.billing.signing import canonical, generate_signing_key
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET, make_token

ADMIN = {
    "Authorization": f"Bearer {make_token(uuid.uuid4(), app_metadata={'roles': ['billing_admin']})}"
}
KB_ADMIN = {
    "Authorization": f"Bearer {make_token(uuid.uuid4(), app_metadata={'roles': ['kb_admin']})}"
}
BASE = "/v1/admin/billing"


def grower(user_id: uuid.UUID) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user_id)}"}


def in_days(days: int) -> str:
    return (datetime.now(UTC) + timedelta(days=days)).isoformat()


@asynccontextmanager
async def api(engine: AsyncEngine, **settings_kwargs: object) -> AsyncIterator[httpx.AsyncClient]:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        await seed_plans(session)
        await session.commit()
    cfg = Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
        **settings_kwargs,  # type: ignore[arg-type]
    )
    app = create_app(cfg)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client


async def grant(
    client: httpx.AsyncClient, user: uuid.UUID, plan: str = "grower_pro", days: int = 30
) -> httpx.Response:
    return await client.post(
        f"{BASE}/grants",
        headers=ADMIN,
        json={
            "subject_type": "farmer",
            "subject_id": str(user),
            "plan_key": plan,
            "period_end": in_days(days),
            "reason": "course bundle",
        },
    )


async def entitlements(client: httpx.AsyncClient, user: uuid.UUID) -> dict[str, object]:
    res = await client.get("/v1/billing/entitlements", headers=grower(user))
    assert res.status_code == 200, res.text
    body: dict[str, object] = res.json()
    return body


async def test_everyone_starts_on_the_free_plan(engine: AsyncEngine) -> None:
    async with api(engine) as client:
        body = await entitlements(client, uuid.uuid4())
    snapshot = body["entitlements"]
    assert isinstance(snapshot, dict)
    assert snapshot["plans"] == ["free"]
    assert "records" in snapshot["features"]
    assert "ai" not in snapshot["features"]
    assert body["signature"] is None  # no signing key configured


async def test_entitlements_need_a_signed_in_user(engine: AsyncEngine) -> None:
    async with api(engine) as client:
        assert (await client.get("/v1/billing/entitlements")).status_code == 401


async def test_only_billing_admins_may_grant_or_configure(engine: AsyncEngine) -> None:
    async with api(engine) as client:
        someone = grower(uuid.uuid4())
        for headers in (someone, KB_ADMIN):
            assert (await client.get(f"{BASE}/plans", headers=headers)).status_code == 403
            res = await client.post(f"{BASE}/grants", headers=headers, json={})
            assert res.status_code == 403
        assert (await client.get(f"{BASE}/plans")).status_code == 401


async def test_a_manual_grant_unlocks_the_plan_until_it_ends(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    async with api(engine) as client:
        assert "calendar" not in (await entitlements(client, user))["entitlements"]["features"]  # type: ignore[index]
        res = await grant(client, user, days=30)
        assert res.status_code == 201, res.text
        assert res.json()["state"] == "ACTIVE"
        assert res.json()["provider"] == "manual_grant"
        snap = (await entitlements(client, user))["entitlements"]
        assert snap["plans"] == ["free", "grower_pro"]  # type: ignore[index]
        assert "calendar" in snap["features"]  # type: ignore[index]
        valid_until = datetime.fromisoformat(snap["valid_until"].replace("Z", "+00:00"))  # type: ignore[index]
        assert valid_until <= datetime.now(UTC) + timedelta(hours=24, seconds=5)


async def test_revoking_a_grant_removes_access_and_is_audited(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    async with api(engine) as client:
        granted = (await grant(client, user)).json()
        revoked = await client.post(f"{BASE}/grants/{granted['id']}/revoke", headers=ADMIN)
        assert revoked.status_code == 200
        assert revoked.json()["state"] == "REVOKED"
        snap = (await entitlements(client, user))["entitlements"]
        assert snap["plans"] == ["free"]  # type: ignore[index]
        events = (await client.get(f"{BASE}/events", headers=ADMIN)).json()["events"]
        assert [e["event_type"] for e in events] == ["grant_revoked", "grant_created"]
        again = await client.post(f"{BASE}/grants/{granted['id']}/revoke", headers=ADMIN)
        assert again.status_code == 409
        missing = await client.post(f"{BASE}/grants/{uuid.uuid4()}/revoke", headers=ADMIN)
        assert missing.status_code == 404


async def test_grants_are_validated(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    async with api(engine) as client:
        assert (await grant(client, user, plan="nope")).status_code == 404
        assert (await grant(client, user, days=-1)).status_code == 422
        short = await client.post(
            f"{BASE}/grants",
            headers=ADMIN,
            json={
                "subject_type": "farmer",
                "subject_id": str(user),
                "plan_key": "grower_pro",
                "period_end": in_days(5),
                "reason": "x",
            },
        )
        assert short.status_code == 422
        bad_subject = await client.post(
            f"{BASE}/grants",
            headers=ADMIN,
            json={
                "subject_type": "robot",
                "subject_id": str(user),
                "plan_key": "grower_pro",
                "period_end": in_days(5),
                "reason": "course bundle",
            },
        )
        assert bad_subject.status_code == 422


async def test_plan_limits_are_config_not_code(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    async with api(engine) as client:
        await grant(client, user)
        before = (await entitlements(client, user))["entitlements"]["features"]["ai"]  # type: ignore[index]
        plans = (await client.get(f"{BASE}/plans", headers=ADMIN)).json()["plans"]
        pro = next(p for p in plans if p["key"] == "grower_pro")
        features = {f["feature"]: f["limit"] for f in pro["features"]}
        features["ai"] = 7
        res = await client.put(
            f"{BASE}/plans/grower_pro",
            headers=ADMIN,
            json={
                "names": pro["names"],
                "kind": pro["kind"],
                "active": True,
                "sort_order": pro["sort_order"],
                "features": features,
            },
        )
        assert res.status_code == 200, res.text
        after = (await entitlements(client, user))["entitlements"]["features"]["ai"]  # type: ignore[index]
        assert before != after
        assert after == {"enabled": True, "limit": 7}


async def test_plan_config_is_validated_and_inactive_plans_are_not_granted(
    engine: AsyncEngine,
) -> None:
    async with api(engine) as client:
        base = {"names": {"en": "Test"}, "kind": "grower", "active": True, "sort_order": 9}
        bad_feature = await client.put(
            f"{BASE}/plans/promo", headers=ADMIN, json={**base, "features": {"Bad Key": None}}
        )
        assert bad_feature.status_code == 422
        negative = await client.put(
            f"{BASE}/plans/promo", headers=ADMIN, json={**base, "features": {"ai": -1}}
        )
        assert negative.status_code == 422
        no_english = await client.put(
            f"{BASE}/plans/promo",
            headers=ADMIN,
            json={**base, "names": {"mr": "x"}, "features": {}},
        )
        assert no_english.status_code == 422
        created = await client.put(
            f"{BASE}/plans/promo",
            headers=ADMIN,
            json={**base, "active": False, "features": {"ai": 3}},
        )
        assert created.status_code == 200
        res = await grant(client, uuid.uuid4(), plan="promo")
        assert res.status_code == 409  # inactive plan


async def test_the_snapshot_is_signed_and_verifiable(engine: AsyncEngine) -> None:
    seed, public = generate_signing_key()
    user = uuid.uuid4()
    async with api(engine, entitlement_signing_key=seed) as client:
        await grant(client, user)
        body = await entitlements(client, user)
    signature = base64.urlsafe_b64decode(str(body["signature"]) + "==")
    key = Ed25519PublicKey.from_public_bytes(base64.urlsafe_b64decode(public + "=="))
    key.verify(signature, canonical(body["entitlements"]))  # type: ignore[arg-type]
    tampered = {**body["entitlements"], "plans": ["free", "consultant"]}  # type: ignore[dict-item]
    try:
        key.verify(signature, canonical(tampered))
    except InvalidSignature:
        pass
    else:  # pragma: no cover
        raise AssertionError("a tampered snapshot must not verify")
    assert json.loads(canonical(body["entitlements"]))["plans"] == ["free", "grower_pro"]  # type: ignore[arg-type]


async def test_the_latest_snapshot_is_stored_once_per_user(engine: AsyncEngine) -> None:
    user = uuid.uuid4()
    async with api(engine) as client:
        await entitlements(client, user)
        await grant(client, user)
        await entitlements(client, user)
    async with async_sessionmaker(engine)() as session:
        assert await session.scalar(select(func.count()).select_from(EntitlementSnapshot)) == 1
        row = await session.scalar(select(EntitlementSnapshot))
        assert row is not None
        assert row.computed["plans"] == ["free", "grower_pro"]
        events = await session.scalar(select(func.count()).select_from(BillingEvent))
        assert events == 1  # only the grant; reading entitlements writes no ledger entry
