"""The newest Test APK on the repository's GitHub releases (owner 2026-11-08: the app is
handed out from our own address, https://<domain>/app, not GitHub).

`deploy/fetch_test_apk.sh` (cron, only with TEST_APK_MIRROR=on) runs
`python -m bagmitra_api.app_mirror.latest <owner/repo>`, which prints `<code> <url>` of the
highest-coded test release (titles end with `· code <run number>`, the APK version code), and
downloads it to /srv/bagmitra-apk/bagmitra.apk when the code is newer. Public API, no key.
"""

from __future__ import annotations

import re
import sys
from typing import Any

import httpx

_CODE = re.compile(r"· code (\d+)$")


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


def main(repo: str) -> int:  # pragma: no cover - thin CLI wrapper
    url = f"https://api.github.com/repos/{repo}/releases?per_page=10"
    res = httpx.get(url, headers={"Accept": "application/vnd.github+json"}, timeout=20)
    res.raise_for_status()
    found = newest_test_apk(res.json())
    if found is None:
        return 1
    print(f"{found[0]} {found[1]}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1]))
