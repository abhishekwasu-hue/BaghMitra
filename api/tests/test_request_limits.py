"""Request-body cap (S-06), sync payload caps (S-07) and log hygiene (S-08 / OPS-01)."""

from __future__ import annotations

import json
import logging
import uuid
from collections.abc import AsyncIterator
from typing import Any, cast

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker

from bagmitra_api.core.body_limit import BodyLimitMiddleware
from bagmitra_api.core.logging import QUIET_LOGGERS, configure_logging
from bagmitra_api.core.settings import Settings
from bagmitra_api.db.models import SyncMutation
from bagmitra_api.db.session import get_sessionmaker
from bagmitra_api.main import create_app
from bagmitra_api.sync.service import payload_size
from tests.conftest import JWT_SECRET
from tests.test_accounts_sync import mutation
from tests.test_plots_sync import plot_mutation, push

SMALL = 8192


@pytest.fixture
async def small_client(engine: AsyncEngine) -> AsyncIterator[httpx.AsyncClient]:
    settings = Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
        max_request_body_bytes=SMALL,
        max_admin_request_body_bytes=SMALL * 4,
        sync_max_payload_bytes=1024,
        sync_max_batch_payload_bytes=2048,
    )
    app = create_app(settings)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    app.dependency_overrides[get_sessionmaker] = lambda: maker
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


def test_defaults() -> None:
    s = Settings()
    assert s.max_request_body_bytes == 3 * 1024 * 1024
    assert s.max_admin_request_body_bytes == 40 * 1024 * 1024
    assert s.sync_max_payload_bytes == 64 * 1024
    assert s.sync_max_batch_payload_bytes == 2 * 1024 * 1024


async def test_declared_oversized_body_is_refused_before_auth(
    small_client: httpx.AsyncClient,
) -> None:
    # No token: the body cap answers first, so nothing is parsed for an anonymous caller.
    r = await small_client.post(
        "/v1/sync/push",
        content=b"{" + b" " * SMALL + b"}",
        headers={"Content-Type": "application/json"},
    )
    assert r.status_code == 413
    error = r.json()["error"]
    assert error["code"] == "payload_too_large"
    assert error["request_id"] == r.headers["x-request-id"]


async def test_streamed_oversized_body_is_refused(small_client: httpx.AsyncClient) -> None:
    async def chunks() -> AsyncIterator[bytes]:
        for _ in range(12):
            yield b" " * 1024

    r = await small_client.post(
        "/v1/sync/push", content=chunks(), headers={"Content-Type": "application/json"}
    )
    assert "content-length" not in r.request.headers
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "payload_too_large"


async def test_admin_routes_have_their_own_cap(small_client: httpx.AsyncClient) -> None:
    body = b"{" + b" " * (SMALL * 2) + b"}"
    headers = {"Content-Type": "application/json"}
    admin = await small_client.post("/v1/admin/feed/items", content=body, headers=headers)
    assert admin.status_code == 401  # under the admin cap: reaches auth
    over = await small_client.post(
        "/v1/admin/feed/items", content=b" " * (SMALL * 5), headers=headers
    )
    assert over.status_code == 413


async def test_bad_content_length_is_a_400() -> None:
    sent: list[dict[str, Any]] = []

    async def app(scope: Any, receive: Any, send: Any) -> None:  # pragma: no cover
        raise AssertionError("must not be reached")

    async def send(message: dict[str, Any]) -> None:
        sent.append(message)

    async def receive() -> dict[str, Any]:  # pragma: no cover
        return {"type": "http.request", "body": b"", "more_body": False}

    guard = BodyLimitMiddleware(app, default_limit=10, admin_limit=20)
    scope = {"type": "http", "path": "/x", "headers": [(b"content-length", b"ten")]}
    await guard(scope, receive, cast(Any, send))
    assert sent[0]["status"] == 400
    assert json.loads(sent[1]["body"])["error"]["code"] == "invalid_content_length"


async def test_non_http_scopes_pass_through() -> None:
    seen: list[str] = []

    async def app(scope: Any, receive: Any, send: Any) -> None:
        seen.append(scope["type"])

    guard = BodyLimitMiddleware(app, default_limit=10, admin_limit=20)
    await guard({"type": "lifespan"}, cast(Any, None), cast(Any, None))
    assert seen == ["lifespan"]


async def test_a_too_large_mutation_is_rejected_and_only_its_digest_is_kept(
    small_client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    plot_id = uuid.uuid4()
    big = plot_mutation(plot_id, name="x" * 80, variety="v" * 60)
    big["payload"]["note_padding"] = "p" * 1200
    unknown = mutation("no_such_entity", uuid.uuid4(), secret="private text")
    results = await push(small_client, auth_headers, big, unknown)
    assert [(r["status"], r["error"]) for r in results] == [
        ("rejected", "payload_too_large"),
        ("rejected", "unknown_entity"),
    ]
    maker = async_sessionmaker(engine)
    async with maker() as session:
        rows = (await session.scalars(select(SyncMutation).order_by(SyncMutation.seq))).all()
    for row, original in zip(rows, (big, unknown), strict=True):
        assert set(row.payload) == {"sha256", "bytes"}
        assert row.payload["bytes"] == payload_size(original["payload"])
        assert "private text" not in json.dumps(row.payload)


async def test_applied_payloads_are_kept(
    small_client: httpx.AsyncClient, auth_headers: dict[str, str], engine: AsyncEngine
) -> None:
    plot_id = uuid.uuid4()
    [r] = await push(small_client, auth_headers, plot_mutation(plot_id))
    assert r["status"] == "applied"
    maker = async_sessionmaker(engine)
    async with maker() as session:
        row = (await session.scalars(select(SyncMutation))).one()
    assert row.payload["name"] == "Bag 1"


async def test_a_batch_over_the_total_cap_is_refused_whole(
    small_client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    mutations = [plot_mutation(uuid.uuid4(), note_padding="p" * 600) for _ in range(4)]
    r = await small_client.post(
        "/v1/sync/push", json={"mutations": mutations}, headers=auth_headers
    )
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "sync_batch_too_large"


def test_payload_size_is_compact_utf8() -> None:
    assert payload_size({"a": "ब"}) == len('{"a":"ब"}'.encode())


def test_http_client_loggers_never_log_urls() -> None:
    configure_logging("DEBUG")
    assert set(QUIET_LOGGERS) >= {"httpx", "httpcore"}
    for name in QUIET_LOGGERS:
        assert logging.getLogger(name).getEffectiveLevel() == logging.WARNING
        assert not logging.getLogger(name).isEnabledFor(logging.INFO)
