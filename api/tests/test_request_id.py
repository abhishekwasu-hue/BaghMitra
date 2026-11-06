from __future__ import annotations

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.main import create_app


async def test_generates_request_id_when_absent(client: httpx.AsyncClient) -> None:
    resp = await client.get("/health/live")
    rid = resp.headers["X-Request-ID"]
    assert len(rid) == 32


async def test_echoes_valid_incoming_request_id(client: httpx.AsyncClient) -> None:
    resp = await client.get("/health/live", headers={"X-Request-ID": "abc-123"})
    assert resp.headers["X-Request-ID"] == "abc-123"


async def test_replaces_malicious_request_id(client: httpx.AsyncClient) -> None:
    resp = await client.get("/health/live", headers={"X-Request-ID": "bad id\nInjected: 1"})
    assert resp.headers["X-Request-ID"] != "bad id\nInjected: 1"
    assert len(resp.headers["X-Request-ID"]) == 32


async def test_error_envelope_contains_request_id(client: httpx.AsyncClient) -> None:
    resp = await client.get("/does-not-exist", headers={"X-Request-ID": "rid-1"})
    assert resp.status_code == 404
    body = resp.json()
    assert body["error"]["code"] == "not_found"
    assert body["error"]["request_id"] == "rid-1"


async def test_an_unhandled_exception_gets_the_envelope_and_no_details(
    settings: Settings, capsys: pytest.CaptureFixture[str]
) -> None:
    """OPS-13: a bug in a handler answers 500 with the usual envelope and the request id to
    quote; the exception text and the traceback go to the log only."""
    app = create_app(settings)

    @app.get("/boom")
    async def boom() -> None:
        raise RuntimeError("token=do-not-leak")

    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        resp = await c.get("/boom", headers={"X-Request-ID": "rid-500"})
    assert resp.status_code == 500
    assert resp.headers["content-type"] == "application/json"
    assert resp.headers["X-Request-ID"] == "rid-500"
    assert resp.json() == {
        "error": {
            "code": "internal_error",
            "message": "internal server error",
            "request_id": "rid-500",
        }
    }
    assert "do-not-leak" not in resp.text
    assert "Traceback" not in resp.text
    logged = capsys.readouterr().out
    assert "unhandled_exception" in logged
    assert "RuntimeError" in logged
    assert '"request_id": "rid-500"' in logged
