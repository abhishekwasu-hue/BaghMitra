"""Production risk from the 2026-11-07 audit: the deploy never seeded the billing plans, and with
an empty plans table GET /v1/billing/entitlements failed. The API start command
(deploy/docker-compose.yml) runs `python -m bagmitra_api.kb.seed`; that seed now also creates the
missing billing plans, idempotently, and the computation tolerates a missing baseline plan."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.billing.entitlements import compute_entitlements
from bagmitra_api.billing.models import BillingPlan
from bagmitra_api.billing.seed import default_plans
from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.kb import seed as kb_seed
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET, make_token

COMPOSE = Path(__file__).resolve().parents[2] / "deploy" / "docker-compose.yml"


def test_the_api_start_command_runs_the_seed_after_migrations() -> None:
    command = next(line for line in COMPOSE.read_text("utf-8").splitlines() if "uvicorn" in line)
    assert command.index("alembic upgrade head") < command.index("python -m bagmitra_api.kb.seed")
    assert command.index("bagmitra_api.kb.seed") < command.index("uvicorn")


async def plan_count(maker: async_sessionmaker) -> int:  # type: ignore[type-arg]
    async with maker() as session:
        return int(await session.scalar(select(func.count()).select_from(BillingPlan)) or 0)


async def test_the_start_seed_creates_the_billing_plans_once(
    engine: AsyncEngine, monkeypatch: pytest.MonkeyPatch
) -> None:
    maker = async_sessionmaker(engine, expire_on_commit=False)
    monkeypatch.setattr(kb_seed, "get_sessionmaker", lambda: maker)
    assert await plan_count(maker) == 0
    await kb_seed.main()
    assert await plan_count(maker) == len(default_plans())
    await kb_seed.main()  # every restart runs it again: nothing is duplicated
    assert await plan_count(maker) == len(default_plans())

    cfg = Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
    )
    app = create_app(cfg)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: cfg
    headers = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.get("/v1/billing/entitlements", headers=headers)
    assert res.status_code == 200, res.text
    assert res.json()["entitlements"]["plans"] == ["free"]


def test_no_plans_at_all_gives_an_empty_snapshot_not_an_error() -> None:
    result = compute_entitlements([], {}, now=datetime.now(UTC))
    assert result.features == {}
    assert result.plans == ("free",)
