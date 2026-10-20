"""End to end against the local Supabase stack (`supabase start`): a real phone-OTP login
produces a token our API accepts, and a grower's synced rows are visible to them alone.

Skipped unless the stack is configured (`SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_DB_URL`; plus `SUPABASE_JWT_SECRET` for projects that sign with the shared secret).
The same API-and-database flow also runs on plain Postgres with self-made tokens
(`test_sync_round_trip_for_two_growers_on_postgres`), so it is covered even without Supabase.
"""

from __future__ import annotations

import asyncio
import os
import uuid
from pathlib import Path

import httpx
import jwt
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET, make_token
from tests.test_plots_sync import plot_changes, plot_mutation, pull, push

API_DIR = Path(__file__).resolve().parents[1]
GROWER_A = "+919800000001"
GROWER_B = "+919800000002"
OTP = "123456"


def _migrate(url: str) -> None:
    cfg = Config(str(API_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(API_DIR / "alembic"))
    cfg.set_main_option("sqlalchemy.url", url)
    command.upgrade(cfg, "head")


async def exercise_api(settings: Settings, database_url: str, token_a: str, token_b: str) -> None:
    """Two growers push and pull through the real API and database; nobody sees the other's rows."""
    engine = create_async_engine(database_url)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app = create_app(settings)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    app.dependency_overrides[get_settings] = lambda: settings
    a = {"Authorization": f"Bearer {token_a}"}
    b = {"Authorization": f"Bearer {token_b}"}
    plot_id = uuid.uuid4()
    try:
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as client:
            assert (await client.get("/v1/me", headers=a)).status_code == 404  # signed in
            results = await push(client, a, plot_mutation(plot_id))
            assert [r["status"] for r in results] == ["applied"]
            assert [c["entity_id"] for c in plot_changes(await pull(client, a))] == [str(plot_id)]
            assert plot_changes(await pull(client, b)) == []
            # B cannot overwrite A's row either.
            stolen = await push(client, b, plot_mutation(plot_id, name="Stolen"))
            assert stolen[0]["status"] != "applied"
            assert plot_changes(await pull(client, a))[0]["data"]["name"] == "Bag 1"
    finally:
        await engine.dispose()


@pytest.mark.postgres
@pytest.mark.skipif("POSTGRES_TEST_URL" not in os.environ, reason="needs POSTGRES_TEST_URL")
async def test_sync_round_trip_for_two_growers_on_postgres() -> None:
    url = os.environ["POSTGRES_TEST_URL"]
    await asyncio.to_thread(_migrate, url)  # alembic runs its own event loop
    settings = Settings(supabase_jwt_secret=JWT_SECRET)
    await exercise_api(settings, url, make_token(uuid.uuid4()), make_token(uuid.uuid4()))


SUPABASE_ENV = ("SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_DB_URL")


async def sign_in(client: httpx.AsyncClient, base: str, anon_key: str, phone: str) -> str:
    headers = {"apikey": anon_key}
    sent = await client.post(f"{base}/auth/v1/otp", json={"phone": phone}, headers=headers)
    assert sent.status_code == 200, sent.text
    verified = await client.post(
        f"{base}/auth/v1/verify",
        json={"type": "sms", "phone": phone, "token": OTP},
        headers=headers,
    )
    assert verified.status_code == 200, verified.text
    token: str = verified.json()["access_token"]
    return token


@pytest.mark.supabase
@pytest.mark.skipif(
    not all(name in os.environ for name in SUPABASE_ENV), reason="needs the local Supabase stack"
)
async def test_phone_otp_login_and_sync_against_the_local_supabase_stack() -> None:
    base = os.environ["SUPABASE_URL"].rstrip("/")
    anon = os.environ["SUPABASE_ANON_KEY"]
    db_url = os.environ["SUPABASE_DB_URL"]
    await asyncio.to_thread(_migrate, db_url)
    async with httpx.AsyncClient(timeout=20) as client:
        token_a = await sign_in(client, base, anon, GROWER_A)
        token_b = await sign_in(client, base, anon, GROWER_B)
    algorithm = jwt.get_unverified_header(token_a)["alg"]
    settings = Settings(
        supabase_jwt_secret=os.environ.get("SUPABASE_JWT_SECRET", ""),
        supabase_jwks_url=f"{base}/auth/v1/.well-known/jwks.json" if algorithm != "HS256" else "",
    )
    await exercise_api(settings, db_url, token_a, token_b)
