"""Connection pool settings for the Supabase Session pooler (audit OPS-10)."""

from __future__ import annotations

import pytest
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import create_async_engine

from bagmitra_api.core.settings import Settings
from bagmitra_api.db.session import engine_options

PG_URL = "postgresql+asyncpg://postgres.ref:pw@aws-0-region.pooler.supabase.com:5432/postgres"


def test_safe_defaults_for_postgres() -> None:
    options = engine_options(Settings(database_url=PG_URL))
    assert options == {
        "pool_size": 5,
        "max_overflow": 5,
        "pool_timeout": 30.0,
        "pool_recycle": 1800,
        "pool_pre_ping": True,
    }


def test_values_come_from_the_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DATABASE_URL", PG_URL)
    monkeypatch.setenv("DB_POOL_SIZE", "3")
    monkeypatch.setenv("DB_MAX_OVERFLOW", "0")
    monkeypatch.setenv("DB_POOL_TIMEOUT_SECONDS", "10")
    monkeypatch.setenv("DB_POOL_RECYCLE_SECONDS", "600")
    monkeypatch.setenv("DB_POOL_PRE_PING", "false")
    options = engine_options(Settings())
    assert options == {
        "pool_size": 3,
        "max_overflow": 0,
        "pool_timeout": 10.0,
        "pool_recycle": 600,
        "pool_pre_ping": False,
    }


@pytest.mark.parametrize(
    ("name", "value"),
    [
        ("db_pool_size", 0),
        ("db_pool_size", 51),
        ("db_max_overflow", -1),
        ("db_pool_timeout_seconds", 0),
        ("db_pool_recycle_seconds", -2),
    ],
)
def test_out_of_range_values_are_rejected(name: str, value: float) -> None:
    with pytest.raises(ValidationError):
        Settings.model_validate({"database_url": PG_URL, name: value})


def test_sqlite_keeps_its_own_pool() -> None:
    options = engine_options(Settings(database_url="sqlite+aiosqlite:///:memory:"))
    assert options == {"pool_pre_ping": True}


async def test_postgres_engine_accepts_the_options() -> None:
    # Building the engine connects to nothing; it only checks the pool arguments.
    engine = create_async_engine(PG_URL, **engine_options(Settings(database_url=PG_URL)))
    try:
        assert engine.pool.size() == 5  # type: ignore[attr-defined]
        assert engine.pool._max_overflow == 5  # type: ignore[attr-defined]
        assert engine.pool._recycle == 1800
    finally:
        await engine.dispose()
