"""A first pull on a new phone must not ship every row in one response (2 GB phones decode
the whole body at once): pages of at most `sync_pull_page_size`, cursor at the last row."""

from __future__ import annotations

import uuid

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from tests.conftest import JWT_SECRET
from tests.test_plots_sync import plot_mutation, pull, push


@pytest.fixture
def settings() -> Settings:
    return Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
        sync_pull_page_size=2,
    )


async def test_pull_is_paged_and_the_cursor_walks_every_row(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    ids = [uuid.uuid4() for _ in range(5)]
    await push(client, auth_headers, *(plot_mutation(i) for i in ids))
    seen: list[str] = []
    since = 0
    for _ in range(10):
        body = await pull(client, auth_headers, since)
        assert len(body["changes"]) <= 2
        seen += [c["entity_id"] for c in body["changes"]]
        if not body["changes"]:
            break
        assert body["cursor"] == body["changes"][-1]["seq"]
        since = body["cursor"]
    assert sorted(seen) == sorted(str(i) for i in ids)
