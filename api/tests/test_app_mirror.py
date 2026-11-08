"""Test APK mirror (owner 2026-11-08): the newest coded test release on GitHub, so the VPS
cron puts it at https://<domain>/app. Parsing only; GitHub is never called in tests."""

from __future__ import annotations

from bagmitra_api.app_mirror.latest import newest_release_apk, newest_test_apk

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
