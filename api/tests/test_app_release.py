"""App update path (audit BG-06): the version check the app calls on start, and the APK download
served from a read-only host folder."""

from __future__ import annotations

from collections.abc import AsyncIterator
from pathlib import Path

import httpx
import pytest
from pydantic import ValidationError

from bagmitra_api.core.settings import Settings
from bagmitra_api.main import create_app
from tests.conftest import JWT_SECRET


def _settings(**values: object) -> Settings:
    return Settings(
        environment="test",
        database_url="sqlite+aiosqlite://",
        supabase_jwt_secret=JWT_SECRET,
        log_level="WARNING",
        **values,  # type: ignore[arg-type]
    )


async def _client(settings: Settings) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=create_app(settings))
    async with httpx.AsyncClient(transport=transport, base_url="https://api.example.test") as c:
        yield c


@pytest.fixture
def apk_dir(tmp_path: Path) -> Path:
    folder = tmp_path / "apk"
    folder.mkdir()
    return folder


async def test_version_reports_the_configured_release_without_auth() -> None:
    settings = _settings(
        app_latest_version_code=7,
        app_latest_version_name="1.2.0",
        app_min_version_code=5,
    )
    async for c in _client(settings):
        resp = await c.get("/v1/app/version")
    assert resp.status_code == 200
    assert resp.json() == {
        "latest_version_code": 7,
        "latest_version_name": "1.2.0",
        "min_version_code": 5,
        "download_url": "https://api.example.test/app",
    }
    assert resp.headers["cache-control"] == "no-cache"


async def test_version_defaults_mean_no_update_known() -> None:
    async for c in _client(_settings()):
        body = (await c.get("/v1/app/version")).json()
    assert body["latest_version_code"] == 0
    assert body["min_version_code"] == 0
    assert body["latest_version_name"] == ""


async def test_version_uses_the_configured_download_url() -> None:
    settings = _settings(app_download_url="https://downloads.example.test/bagmitra.apk")
    async for c in _client(settings):
        body = (await c.get("/v1/app/version")).json()
    assert body["download_url"] == "https://downloads.example.test/bagmitra.apk"


def test_minimum_above_latest_is_rejected() -> None:
    with pytest.raises(ValidationError, match="APP_MIN_VERSION_CODE"):
        _settings(app_latest_version_code=3, app_min_version_code=4)


def test_negative_version_codes_are_rejected() -> None:
    with pytest.raises(ValidationError):
        _settings(app_latest_version_code=-1)


def test_version_settings_come_from_the_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_LATEST_VERSION_CODE", "12")
    monkeypatch.setenv("APP_LATEST_VERSION_NAME", "1.0.3")
    monkeypatch.setenv("APP_MIN_VERSION_CODE", "10")
    monkeypatch.setenv("APP_DOWNLOAD_DIR", "/data/apk")
    s = Settings()
    assert (s.app_latest_version_code, s.app_latest_version_name) == (12, "1.0.3")
    assert s.app_min_version_code == 10
    assert s.app_download_dir == "/data/apk"


def test_download_dir_default() -> None:
    assert _settings().app_download_dir == "/srv/bagmitra-apk"


async def test_download_serves_the_apk_as_an_attachment(apk_dir: Path) -> None:
    payload = b"PK\x03\x04 fake apk bytes"
    (apk_dir / "bagmitra.apk").write_bytes(payload)
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        resp = await c.get("/app")
        head = await c.head("/app")
    assert resp.status_code == 200
    assert resp.content == payload
    assert resp.headers["content-type"] == "application/vnd.android.package-archive"
    assert resp.headers["content-disposition"] == 'attachment; filename="bagmitra.apk"'
    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["cache-control"] == "no-cache"
    assert head.status_code == 200
    assert head.headers["content-length"] == str(len(payload))


async def test_download_without_a_file_says_not_available(apk_dir: Path) -> None:
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        resp = await c.get("/app")
    assert resp.status_code == 404
    assert resp.headers["content-type"].startswith("text/plain")
    assert "BagMitra" in resp.text


async def test_download_ignores_other_files_and_folders(apk_dir: Path) -> None:
    (apk_dir / "other.apk").write_bytes(b"x")
    (apk_dir / "bagmitra.apk").mkdir()
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        assert (await c.get("/app")).status_code == 404
        assert (await c.get("/app/other.apk")).status_code == 404


async def test_download_is_not_in_the_api_contract() -> None:
    async for c in _client(_settings()):
        spec = (await c.get("/openapi.json")).json()
    assert "/app" not in spec["paths"]
    assert spec["paths"]["/v1/app/version"]["get"]["operationId"] == "app_version"
    assert "security" not in spec["paths"]["/v1/app/version"]["get"]


async def test_without_env_numbers_the_mirrored_release_file_answers(apk_dir: Path) -> None:
    """Owner 2026-11-08: the VPS mirror writes release.json beside the Release APK, so a new
    release needs no hand-typed APP_LATEST_VERSION_* in .env."""
    (apk_dir / "release.json").write_text('{"code": 12, "name": "1.0.1"}', "utf-8")
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        body = (await c.get("/v1/app/version")).json()
    assert (body["latest_version_code"], body["latest_version_name"]) == (12, "1.0.1")
    # Values set in .env still win (the manual path keeps working).
    settings = _settings(
        app_download_dir=str(apk_dir), app_latest_version_code=9, app_latest_version_name="0.9.0"
    )
    async for c in _client(settings):
        body = (await c.get("/v1/app/version")).json()
    assert (body["latest_version_code"], body["latest_version_name"]) == (9, "0.9.0")


async def test_an_unreadable_release_file_means_no_update_known(apk_dir: Path) -> None:
    (apk_dir / "release.json").write_text("not json", "utf-8")
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        body = (await c.get("/v1/app/version")).json()
    assert body["latest_version_code"] == 0


async def test_app_test_serves_only_the_test_apk(apk_dir: Path) -> None:
    """Audit H1: Test APKs update from /app/test (bagmitra-test.apk), never the Release APK."""
    (apk_dir / "bagmitra.apk").write_bytes(b"release")
    (apk_dir / "bagmitra-test.apk").write_bytes(b"PK test apk")
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        resp = await c.get("/app/test")
        head = await c.head("/app/test")
        release = await c.get("/app")
    assert resp.status_code == 200
    assert resp.content == b"PK test apk"
    assert resp.headers["content-type"] == "application/vnd.android.package-archive"
    assert resp.headers["content-disposition"] == 'attachment; filename="bagmitra-test.apk"'
    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["cache-control"] == "no-cache"
    assert head.status_code == 200
    assert head.headers["content-length"] == str(len(b"PK test apk"))
    assert release.content == b"release"


async def test_app_test_without_its_file_says_not_available(apk_dir: Path) -> None:
    (apk_dir / "bagmitra.apk").write_bytes(b"release")
    async for c in _client(_settings(app_download_dir=str(apk_dir))):
        resp = await c.get("/app/test")
        spec = (await c.get("/openapi.json")).json()
    assert resp.status_code == 404
    assert resp.headers["content-type"].startswith("text/plain")
    assert "BagMitra" in resp.text
    assert "/app/test" not in spec["paths"]
