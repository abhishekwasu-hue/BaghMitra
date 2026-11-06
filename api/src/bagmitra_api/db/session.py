from __future__ import annotations

from collections.abc import AsyncIterator
from functools import lru_cache
from typing import Annotated, Any

from fastapi import Depends
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from bagmitra_api.core.settings import Settings, get_settings


def engine_options(settings: Settings) -> dict[str, Any]:
    """Pool settings for `create_async_engine` (audit OPS-10). SQLite keeps SQLAlchemy's own
    pool, which takes no size arguments."""
    if make_url(settings.database_url).get_backend_name() == "sqlite":
        return {"pool_pre_ping": settings.db_pool_pre_ping}
    return {
        "pool_size": settings.db_pool_size,
        "max_overflow": settings.db_max_overflow,
        "pool_timeout": settings.db_pool_timeout_seconds,
        "pool_recycle": settings.db_pool_recycle_seconds,
        "pool_pre_ping": settings.db_pool_pre_ping,
    }


@lru_cache
def get_sessionmaker() -> async_sessionmaker[AsyncSession]:
    settings = get_settings()
    engine = create_async_engine(settings.database_url, **engine_options(settings))
    return async_sessionmaker(engine, expire_on_commit=False)


async def get_session(
    maker: Annotated[async_sessionmaker[AsyncSession], Depends(get_sessionmaker)],
) -> AsyncIterator[AsyncSession]:
    async with maker() as session:
        yield session


DbSession = Annotated[AsyncSession, Depends(get_session)]
