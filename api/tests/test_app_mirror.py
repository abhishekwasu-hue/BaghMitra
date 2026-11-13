"""Test APK mirror (owner 2026-11-08): the newest coded test release on GitHub, so the VPS
cron puts it at https://<domain>/app. GitHub is never called in tests (MockTransport)."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from typing import Any

import httpx
import pytest

from bagmitra_api.app_mirror.latest import (
    RateLimitedError,
    asset_sha256,
    cache_path,
    fetch_releases,
    main,
    newest_release_apk,
    newest_test_apk,
    releases_url,
)

REPO = "owner/BaghMitra"


def release(tag: str, name: str, apk: bool = True) -> dict[str, object]:
    base = f"https://github.com/{REPO}/releases/download/{tag}"
    assets = [{"browser_download_url": f"{base}/a-universal.apk"}] if apk else []
    return {"tag_name": tag, "name": name, "assets": assets}


def test_the_highest_code_with_a_universal_apk_wins() -> None:
    found = newest_test_apk(
        [
            release("test-1-old", "Test build test-1-old · code 148"),
            release("test-3-new", "Test build test-3-new · code 150", apk=False),  # uploading
            release("test-2-mid", "Test build test-2-mid · code 149"),
            release("test-0-none", "Test build test-0-none"),
            release("v1.0.0", "Release 1.0.0 · code 999"),
        ]
    )
    assert found == (149, f"https://github.com/{REPO}/releases/download/test-2-mid/a-universal.apk")


def test_nothing_coded_yet_gives_none() -> None:
    assert newest_test_apk([release("test-0", "Test build test-0")]) is None
    assert newest_test_apk([]) is None


def release_build(tag: str, title: str, abi: str = "arm64-v8a") -> dict[str, object]:
    base = f"https://github.com/{REPO}/releases/download/{tag}"
    return {
        "tag_name": tag,
        "name": title,
        "assets": [{"browser_download_url": f"{base}/b-{abi}.apk"}],
    }


def test_the_newest_release_apk_is_the_highest_version_code_arm64() -> None:
    found = newest_release_apk(
        [
            release_build("release-1.0.0-3", "BagMitra 1.0.0 (version code 3)"),
            release_build("release-1.0.1-5", "BagMitra 1.0.1 (version code 5)"),
            release_build("release-1.0.2-6", "BagMitra 1.0.2 (version code 6)", abi="armeabi-v7a"),
            release("test-9", "Test build test-9 · code 999"),
        ]
    )
    assert found == (
        5,
        "1.0.1",
        f"https://github.com/{REPO}/releases/download/release-1.0.1-5/b-arm64-v8a.apk",
    )
    assert newest_release_apk([release("test-9", "Test build test-9 · code 999")]) is None


def test_the_releases_list_asks_for_100() -> None:
    """Audit L7: GitHub lists releases newest-created first, 30 by default; many test builds
    can push the last Release APK off a short page."""
    assert releases_url("o/r") == "https://api.github.com/repos/o/r/releases?per_page=100"


def test_the_asset_digest_is_found_by_its_url() -> None:
    """Audit L5: the mirror compares the downloaded file with GitHub's asset digest."""
    url = f"https://github.com/{REPO}/releases/download/t/a-universal.apk"
    sha = "ab" * 32
    releases: list[dict[str, object]] = [
        {"assets": [{"browser_download_url": "other", "digest": "sha256:" + "cd" * 32}]},
        {"assets": [{"browser_download_url": url, "digest": f"sha256:{sha}"}]},
    ]
    assert asset_sha256(releases, url) == sha
    assert asset_sha256(releases, "missing") is None
    no_digest: list[dict[str, object]] = [{"assets": [{"browser_download_url": url}]}]
    assert asset_sha256(no_digest, url) is None
    bad: list[dict[str, object]] = [{"assets": [{"browser_download_url": url, "digest": "md5:x"}]}]
    assert asset_sha256(bad, url) is None


# --- GitHub rate limit (VPS log 2026-11-13: "403 rate limit exceeded" on a shared IP). The
# releases list is fetched with If-None-Match; a 304 does not count against GitHub's limit.

ETAG = 'W/"abc"'
APK = "https://github.com/o/r/releases/download/test-9/a-universal.apk"
LIST: list[dict[str, Any]] = [
    {
        "tag_name": "test-9",
        "name": "Test build test-9 · code 160",
        "assets": [{"browser_download_url": APK, "digest": "sha256:" + "ab" * 32}],
    }
]


def client_for(
    responses: list[httpx.Response], seen: list[httpx.Request] | None = None
) -> httpx.Client:
    def handler(request: httpx.Request) -> httpx.Response:
        if seen is not None:
            seen.append(request)
        return responses.pop(0)

    return httpx.Client(transport=httpx.MockTransport(handler))


def write_cache(cache: Path, repo: str = "o/r") -> None:
    cache.write_text(json.dumps({"url": releases_url(repo), "etag": ETAG, "releases": LIST}))


def test_a_fresh_list_is_cached_with_its_etag(tmp_path: Path) -> None:
    cache = tmp_path / "cache.json"
    seen: list[httpx.Request] = []
    client = client_for([httpx.Response(200, json=LIST, headers={"ETag": ETAG})], seen)
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST
    assert "if-none-match" not in seen[0].headers
    assert "authorization" not in seen[0].headers
    stored = json.loads(cache.read_text())
    assert stored == {"url": releases_url("o/r"), "etag": ETAG, "releases": LIST}


def test_a_304_reuses_the_cached_list(tmp_path: Path) -> None:
    cache = tmp_path / "cache.json"
    write_cache(cache)
    seen: list[httpx.Request] = []
    client = client_for([httpx.Response(304)], seen)
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST
    assert seen[0].headers["if-none-match"] == ETAG


def test_a_cache_of_another_repo_is_not_used(tmp_path: Path) -> None:
    cache = tmp_path / "cache.json"
    write_cache(cache, repo="x/y")
    seen: list[httpx.Request] = []
    client = client_for([httpx.Response(200, json=[])], seen)
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == []
    assert "if-none-match" not in seen[0].headers


def test_a_broken_cache_file_is_ignored(tmp_path: Path) -> None:
    cache = tmp_path / "cache.json"
    cache.write_text("{not json")
    client = client_for([httpx.Response(200, json=LIST)])
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST


def test_an_unwritable_cache_does_not_stop_the_mirror(tmp_path: Path) -> None:
    cache = tmp_path / "missing-dir" / "cache.json"
    client = client_for([httpx.Response(200, json=LIST, headers={"ETag": ETAG})])
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST
    assert not cache.exists()


def test_the_optional_token_is_sent_as_bearer(tmp_path: Path) -> None:
    seen: list[httpx.Request] = []
    client = client_for([httpx.Response(200, json=LIST)], seen)
    fetch_releases(client, releases_url("o/r"), tmp_path / "c.json", token="tok123")
    assert seen[0].headers["authorization"] == "Bearer tok123"


def rate_limited() -> list[httpx.Response]:
    return [
        httpx.Response(403, headers={"x-ratelimit-remaining": "0"}, json={"message": "x"}),
        httpx.Response(403, json={"message": "API rate limit exceeded for 1.2.3.4."}),
        httpx.Response(429, json={"message": "slow down"}),
        httpx.Response(403, extensions={"reason_phrase": b"rate limit exceeded"}),
    ]


@pytest.mark.parametrize("index", range(4))
def test_a_rate_limit_falls_back_to_the_cached_list(
    tmp_path: Path, index: int, capsys: pytest.CaptureFixture[str]
) -> None:
    cache = tmp_path / "cache.json"
    write_cache(cache)
    client = client_for([rate_limited()[index]])
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST
    err = capsys.readouterr().err
    assert err == "GitHub rate limit; using the last fetched releases list\n"


@pytest.mark.parametrize("index", range(4))
def test_a_rate_limit_without_cache_raises(tmp_path: Path, index: int) -> None:
    client = client_for([rate_limited()[index]])
    with pytest.raises(RateLimitedError):
        fetch_releases(client, releases_url("o/r"), tmp_path / "none.json", token=None)


def test_a_403_that_is_not_a_rate_limit_still_fails(tmp_path: Path) -> None:
    cache = tmp_path / "cache.json"
    write_cache(cache)
    client = client_for([httpx.Response(403, json={"message": "Forbidden"})])
    with pytest.raises(httpx.HTTPStatusError):
        fetch_releases(client, releases_url("o/r"), cache, token=None)


def test_main_prints_the_newest_test_apk_and_the_second_channel_gets_a_304(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    monkeypatch.setenv("APK_MIRROR_CACHE", str(tmp_path / "c.json"))
    monkeypatch.delenv("GITHUB_MIRROR_TOKEN", raising=False)
    client = client_for([httpx.Response(200, json=LIST, headers={"ETag": ETAG})])
    assert main("o/r", "test", client) == 0
    assert capsys.readouterr().out == f"160 {APK} {'ab' * 32}\n"
    # The cron's second call in the same run: a 304 (free against the limit), same list.
    seen: list[httpx.Request] = []
    assert main("o/r", "test", client_for([httpx.Response(304)], seen)) == 0
    assert seen[0].headers["if-none-match"] == ETAG
    assert capsys.readouterr().out == f"160 {APK} {'ab' * 32}\n"


def test_main_prints_the_newest_release_apk_and_fails_without_one(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    monkeypatch.setenv("APK_MIRROR_CACHE", str(tmp_path / "c.json"))
    build = release_build("release-1.0.18-30", "BagMitra 1.0.18 (version code 30)")
    url = build["assets"][0]["browser_download_url"]  # type: ignore[index]
    assert main("o/r", "release", client_for([httpx.Response(200, json=[build])])) == 0
    assert capsys.readouterr().out == f"30 {url} - 1.0.18\n"
    assert main("o/r", "release", client_for([httpx.Response(200, json=LIST)])) == 1
    assert main("o/r", "test", client_for([httpx.Response(200, json=[build])])) == 1
    assert capsys.readouterr().out == ""


def test_a_cache_that_is_not_a_list_is_ignored(tmp_path: Path) -> None:
    cache = tmp_path / "cache.json"
    cache.write_text(json.dumps([1, 2]))
    client = client_for([httpx.Response(200, json=LIST)])
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST
    cache.write_text(json.dumps({"url": releases_url("o/r"), "releases": "x"}))
    client = client_for([httpx.Response(200, json=LIST)])
    assert fetch_releases(client, releases_url("o/r"), cache, token=None) == LIST


def test_main_rate_limited_without_cache_prints_one_line_and_fails(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    monkeypatch.setenv("APK_MIRROR_CACHE", str(tmp_path / "none.json"))
    monkeypatch.setenv("GITHUB_MIRROR_TOKEN", "secret-token-value")
    client = client_for([httpx.Response(403, headers={"x-ratelimit-remaining": "0"})])
    assert main("o/r", "test", client) != 0
    out = capsys.readouterr()
    assert out.out == ""
    assert out.err == "GitHub rate limit; will retry next run\n"


def test_the_default_cache_is_in_the_containers_temp_folder(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """/srv/bagmitra-apk is mounted read-only in the api container; /tmp lives as long as the
    container, which `docker compose exec` reuses on every cron run."""
    monkeypatch.delenv("APK_MIRROR_CACHE", raising=False)
    assert cache_path() == Path(tempfile.gettempdir()) / "bagmitra-apk-mirror.json"
    monkeypatch.setenv("APK_MIRROR_CACHE", "/x/y.json")
    assert cache_path() == Path("/x/y.json")
