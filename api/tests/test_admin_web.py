"""Admin web at /admin/ (OPS-02): static files when present, a clean 404 when absent, and the
admin endpoints keep their role checks for a page served from the same origin."""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from pathlib import Path

import httpx
import pytest

from bagmitra_api.core.settings import Settings
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET, make_token

INDEX = '<!DOCTYPE html><html><head><base href="/admin/"></head><body>admin</body></html>'


def _settings(**extra: str) -> Settings:
    return Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
        **extra,  # type: ignore[arg-type]
    )


async def _client(settings: Settings) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=create_app(settings))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
def web_dir(tmp_path: Path) -> Path:
    root = tmp_path / "admin-web"
    (root / "assets").mkdir(parents=True)
    (root / "index.html").write_text(INDEX)
    (root / "main.dart.js").write_text("console.log('admin');")
    (root / "assets" / "AssetManifest.json").write_text("{}")
    (tmp_path / "secret.txt").write_text("outside")
    return root


@pytest.fixture
async def web(web_dir: Path) -> AsyncIterator[httpx.AsyncClient]:
    settings = _settings(
        admin_web_dir=str(web_dir),
        admin_web_supabase_url="https://ref.supabase.co",
        admin_web_supabase_anon_key="public-anon-key",
    )
    async for c in _client(settings):
        yield c


async def test_serves_index_and_assets(web: httpx.AsyncClient) -> None:
    res = await web.get("/admin/")
    assert res.status_code == 200
    assert res.text == INDEX
    assert res.headers["content-type"].startswith("text/html")
    assert res.headers["x-content-type-options"] == "nosniff"
    assert res.headers["content-security-policy"] == "frame-ancestors 'none'"
    assert res.headers["cache-control"] == "no-cache"
    js = await web.get("/admin/main.dart.js")
    assert js.status_code == 200
    assert "javascript" in js.headers["content-type"]
    assert (await web.get("/admin/assets/AssetManifest.json")).json() == {}
    # The browser revalidates with the ETag and gets a 304.
    again = await web.get("/admin/main.dart.js", headers={"If-None-Match": js.headers["etag"]})
    assert again.status_code == 304
    assert (await web.head("/admin/")).status_code == 200


async def test_bare_admin_redirects_to_the_slash(web: httpx.AsyncClient) -> None:
    res = await web.get("/admin")
    assert res.status_code in (307, 308)
    assert res.headers["location"].endswith("/admin/")


async def test_unknown_files_and_escapes_are_a_clean_404(web: httpx.AsyncClient) -> None:
    for path in ("/admin/nope.js", "/admin/../secret.txt", "/admin/%2e%2e/secret.txt"):
        res = await web.get(path)
        assert res.status_code == 404, path
        assert "outside" not in res.text
    res = await web.get("/admin/nope.js")
    assert res.json()["error"]["code"] == "not_found"
    assert (await web.post("/admin/index.html")).status_code == 405


async def test_config_hands_out_only_the_public_supabase_values(web: httpx.AsyncClient) -> None:
    res = await web.get("/admin/config.json")
    assert res.status_code == 200
    assert res.json() == {
        "supabase_url": "https://ref.supabase.co",
        "supabase_anon_key": "public-anon-key",
    }
    assert res.headers["cache-control"] == "no-store"
    assert JWT_SECRET not in res.text


@pytest.mark.parametrize("make_dir", [False, True])
async def test_absent_build_is_a_clean_404(tmp_path: Path, make_dir: bool) -> None:
    folder = tmp_path / "admin-web"
    if make_dir:
        folder.mkdir()  # docker creates an empty folder for a missing bind mount
    async for c in _client(_settings(admin_web_dir=str(folder))):
        for path in ("/admin/", "/admin/main.dart.js", "/admin/config.json"):
            res = await c.get(path)
            assert res.status_code == 404, path
            assert res.headers["content-type"] == "application/json"
        assert (await c.get("/health/live")).status_code == 200


async def test_admin_web_unset_is_a_404(client: httpx.AsyncClient) -> None:
    assert (await client.get("/admin/")).status_code == 404
    res = await client.get("/admin/config.json")
    assert res.status_code == 404
    assert res.json()["error"]["code"] == "not_configured"


@pytest.mark.parametrize(
    ("path", "role"),
    [
        ("/v1/admin/feed/sources", "feed_admin"),
        ("/v1/admin/kb/cards", "kb_admin"),
        ("/v1/admin/billing/plans", "billing_admin"),
    ],
)
async def test_admin_endpoints_still_require_the_roles(
    web: httpx.AsyncClient, path: str, role: str
) -> None:
    assert (await web.get(path)).status_code == 401
    grower = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    res = await web.get(path, headers=grower)
    assert res.status_code == 403
    assert res.json()["error"]["message"] == f"requires role {role}"
    others = {"feed_admin", "kb_admin", "market_admin", "billing_admin"} - {role}
    other = make_token(uuid.uuid4(), app_metadata={"roles": sorted(others)})
    assert (await web.get(path, headers={"Authorization": f"Bearer {other}"})).status_code == 403


async def test_market_upload_still_requires_market_admin(web: httpx.AsyncClient) -> None:
    grower = {"Authorization": f"Bearer {make_token(uuid.uuid4())}"}
    res = await web.post("/v1/admin/market/prices", headers=grower, json={"prices": []})
    assert res.status_code == 403
    assert res.json()["error"]["message"] == "requires role market_admin"
