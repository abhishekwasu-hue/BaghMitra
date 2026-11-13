"""The newest Test APK on the repository's GitHub releases (owner 2026-11-08: the app is
handed out from our own address, https://<domain>/app, not GitHub).

`deploy/fetch_test_apk.sh` (cron, with TEST_APK_MIRROR=on or RELEASE_APK_MIRROR=on) runs
`python -m bagmitra_api.app_mirror.latest <owner/repo> [test|release]`, which prints the newest
APK of that channel (`<code> <url> <sha256>` for test, `<code> <url> <sha256> <name>` for
release; the SHA-256 is GitHub's asset digest, audit L5), and the script downloads it when the
code is newer and serves it only if the file matches the digest. Public API; no key needed
(GITHUB_MIRROR_TOKEN in deploy/.env is optional: 5000 requests/hour instead of 60 per IP).
The list is cached with its ETag (see fetch_releases), so the second channel of a run and
every unchanged run get a 304, which GitHub does not count against the limit.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

import httpx

_CODE = re.compile(r"· code (\d+)$")
# Release APK titles (release-apk.yml): "BagMitra 1.0.1 (version code 5)".
_RELEASE = re.compile(r"^BagMitra (\d+\.\d+\.\d+) \(version code (\d+)\)$")


def newest_test_apk(releases: list[dict[str, Any]]) -> tuple[int, str] | None:
    """(code, universal APK URL) of the highest-coded test release whose APK is uploaded."""
    best: tuple[int, str] | None = None
    for r in releases:
        match = _CODE.search(str(r.get("name") or ""))
        if not str(r.get("tag_name") or "").startswith("test-") or match is None:
            continue
        urls = [str(a.get("browser_download_url") or "") for a in r.get("assets") or []]
        apk = next((u for u in urls if u.endswith("-universal.apk")), None)
        code = int(match.group(1))
        if apk is not None and (best is None or code > best[0]):
            best = (code, apk)
    return best


def newest_release_apk(releases: list[dict[str, Any]]) -> tuple[int, str, str] | None:
    """(code, version name, arm64-v8a APK URL) of the highest-coded Release APK (owner
    2026-11-08: growers get the release build from /app; arm64-v8a fits almost every phone)."""
    best: tuple[int, str, str] | None = None
    for r in releases:
        match = _RELEASE.match(str(r.get("name") or ""))
        if not str(r.get("tag_name") or "").startswith("release-") or match is None:
            continue
        urls = [str(a.get("browser_download_url") or "") for a in r.get("assets") or []]
        apk = next((u for u in urls if u.endswith("-arm64-v8a.apk")), None)
        code = int(match.group(2))
        if apk is not None and (best is None or code > best[0]):
            best = (code, match.group(1), apk)
    return best


_SHA256 = re.compile(r"^sha256:([0-9a-f]{64})$")


def asset_sha256(releases: list[dict[str, Any]], url: str) -> str | None:
    """GitHub's SHA-256 digest of the asset at [url] (audit L5); None when it has none."""
    for r in releases:
        for a in r.get("assets") or []:
            if a.get("browser_download_url") == url:
                match = _SHA256.match(str(a.get("digest") or ""))
                return match.group(1) if match else None
    return None


def releases_url(repo: str) -> str:
    """GitHub's largest page (audit L7): test builds must not push the last Release APK off it."""
    return f"https://api.github.com/repos/{repo}/releases?per_page=100"


class RateLimitedError(Exception):
    """GitHub refused the list for its rate limit, and no earlier list is cached."""


def cache_path() -> Path:
    """Where the last releases list and its ETag are kept: APK_MIRROR_CACHE, else the api
    container's temp folder (/srv/bagmitra-apk is mounted read-only there; /tmp lives as long
    as the container, which every cron `docker compose exec` reuses)."""
    custom = os.environ.get("APK_MIRROR_CACHE")
    return Path(custom) if custom else Path(tempfile.gettempdir()) / "bagmitra-apk-mirror.json"


def _read_cache(cache: Path, url: str) -> tuple[str | None, list[dict[str, Any]]] | None:
    """(ETag, releases) cached for [url]; None when missing, broken or for another URL."""
    try:
        data = json.loads(cache.read_text())
    except (OSError, ValueError):
        return None
    if not isinstance(data, dict) or data.get("url") != url:
        return None
    releases = data.get("releases")
    etag = data.get("etag")
    if not isinstance(releases, list):
        return None
    return (etag if isinstance(etag, str) else None), releases


def _write_cache(cache: Path, url: str, etag: str | None, releases: list[dict[str, Any]]) -> None:
    """Best effort, in one step (a half-written file is never read): no cache only costs
    the next run a full request."""
    tmp = cache.with_name(cache.name + ".new")
    try:
        tmp.write_text(json.dumps({"url": url, "etag": etag, "releases": releases}))
        tmp.replace(cache)
    except OSError:
        return


def _rate_limited(res: httpx.Response) -> bool:
    if res.status_code == 429:
        return True
    if res.status_code != 403:
        return False
    # The VPS log showed the reason "403 rate limit exceeded"; GitHub's body says the same.
    text = f"{res.reason_phrase} {res.text}".lower()
    return res.headers.get("x-ratelimit-remaining") == "0" or "rate limit" in text


def fetch_releases(
    client: httpx.Client, url: str, cache: Path, token: str | None
) -> list[dict[str, Any]]:
    """The releases list, asked with If-None-Match (a 304 does not count against GitHub's rate
    limit; VPS 2026-11-13: the shared IP's 60/hour was used up by others). On a rate limit the
    last fetched list is used; without one, RateLimitedError. The token is never printed."""
    cached = _read_cache(cache, url)
    headers = {"Accept": "application/vnd.github+json"}
    if cached is not None and cached[0]:
        headers["If-None-Match"] = cached[0]
    if token:
        headers["Authorization"] = f"Bearer {token}"
    res = client.get(url, headers=headers, timeout=20)
    if res.status_code == 304 and cached is not None:
        return cached[1]
    if _rate_limited(res):
        if cached is None:
            raise RateLimitedError
        print("GitHub rate limit; using the last fetched releases list", file=sys.stderr)
        return cached[1]
    res.raise_for_status()
    releases: list[dict[str, Any]] = res.json()
    _write_cache(cache, url, res.headers.get("etag"), releases)
    return releases


def main(repo: str, channel: str, client: httpx.Client | None = None) -> int:
    token = os.environ.get("GITHUB_MIRROR_TOKEN", "").strip() or None
    try:
        with client or httpx.Client() as http:
            releases = fetch_releases(http, releases_url(repo), cache_path(), token)
    except RateLimitedError:
        print("GitHub rate limit; will retry next run", file=sys.stderr)
        return 2
    if channel == "release":
        found = newest_release_apk(releases)
        if found is None:
            return 1
        print(f"{found[0]} {found[2]} {asset_sha256(releases, found[2]) or '-'} {found[1]}")
        return 0
    test = newest_test_apk(releases)
    if test is None:
        return 1
    print(f"{test[0]} {test[1]} {asset_sha256(releases, test[1]) or '-'}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "test"))
