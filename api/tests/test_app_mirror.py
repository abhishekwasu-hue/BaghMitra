"""Test APK mirror (owner 2026-11-08): the newest coded test release on GitHub, so the VPS
cron puts it at https://<domain>/app. Parsing only; GitHub is never called in tests."""

from __future__ import annotations

from bagmitra_api.app_mirror.latest import newest_test_apk

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
