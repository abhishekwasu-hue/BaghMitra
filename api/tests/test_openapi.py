from __future__ import annotations

import json
from pathlib import Path

import httpx

from bagmitra_api.core.settings import Settings
from bagmitra_api.export_openapi import render_openapi
from bagmitra_api.main import create_app

SPEC_PATH = Path(__file__).resolve().parents[2] / "docs" / "api" / "openapi.json"


def test_committed_openapi_matches_code(settings: Settings) -> None:
    """Contract-first: docs/api/openapi.json must be regenerated with every API change."""
    assert SPEC_PATH.exists(), "run: python -m bagmitra_api.export_openapi"
    assert json.loads(SPEC_PATH.read_text()) == json.loads(render_openapi(settings))


def test_operation_ids_are_stable_and_readable(settings: Settings) -> None:
    spec = json.loads(render_openapi(settings))
    ids = {op["operationId"] for path in spec["paths"].values() for op in path.values()}
    assert {"health_live", "health_ready", "me_get", "sync_push", "sync_pull"} <= ids


async def test_docs_and_schema_are_off_in_production_only(settings: Settings) -> None:
    """OPS-07: the production server publishes no /docs, /redoc or /openapi.json; every other
    environment keeps them, and the exported schema (the app client's source) is unchanged."""
    paths = ("/docs", "/redoc", "/openapi.json")
    for environment, expected in (("test", 200), ("production", 404)):
        app = create_app(settings.model_copy(update={"environment": environment}))
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
            for path in paths:
                assert (await c.get(path)).status_code == expected, (environment, path)
    production = settings.model_copy(update={"environment": "production"})
    assert create_app(production).openapi()["paths"] == create_app(settings).openapi()["paths"]
