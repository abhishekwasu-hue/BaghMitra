"""The newest Test APK on the repository's GitHub releases (owner 2026-11-08: the app is
handed out from our own address, https://<domain>/app, not GitHub).

`deploy/fetch_test_apk.sh` (cron, with TEST_APK_MIRROR=on or RELEASE_APK_MIRROR=on) runs
`python -m bagmitra_api.app_mirror.latest <owner/repo> [test|release]`, which prints the newest
APK of that channel (`<code> <url> <sha256>` for test, `<code> <url> <sha256> <name>` for
release; the SHA-256 is GitHub's asset digest, audit L5), and the script downloads it when the
code is newer and serves it only if the file matches the digest. Public API, no key.
"""

from __future__ import annotations

import re
import sys
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


def main(repo: str, channel: str) -> int:  # pragma: no cover - thin CLI wrapper
    res = httpx.get(
        releases_url(repo), headers={"Accept": "application/vnd.github+json"}, timeout=20
    )
    res.raise_for_status()
    releases = res.json()
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
