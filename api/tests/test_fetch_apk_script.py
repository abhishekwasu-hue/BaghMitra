"""Audit H1: deploy/fetch_test_apk.sh keeps the Test APK and the Release APK in two files.
Runs the real script against a fake `docker` (the newest release per channel) and a fake
`curl` (writes a large enough file), in a temporary folder; nothing is downloaded."""

from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[2] / "deploy" / "fetch_test_apk.sh"
BASH = shutil.which("bash")

pytestmark = pytest.mark.skipif(BASH is None, reason="needs bash")

FAKE_DOCKER = """#!/usr/bin/env bash
channel="${@: -1}"
if [[ "$channel" == test ]]; then
  echo "$FAKE_TEST_CODE https://github.com/o/r/test.apk $FAKE_TEST_SHA"
fi
if [[ "$channel" == release ]]; then
  url=https://github.com/o/r/release.apk
  echo "$FAKE_RELEASE_CODE $url $FAKE_RELEASE_SHA 1.0.$FAKE_RELEASE_CODE"
fi
"""

# curl -fsSL -o FILE URL: the file holds the URL, padded past the script's size check.
FAKE_CURL = """#!/usr/bin/env bash
printf "%s" "$4" > "$3"
truncate -s 10000100 "$3"
"""


def sha_of(url: str) -> str:
    """SHA-256 of what FAKE_CURL writes for this URL."""
    data = url.encode()
    return hashlib.sha256(data + b"\0" * (10000100 - len(data))).hexdigest()


TEST_SHA = sha_of("https://github.com/o/r/test.apk")
RELEASE_SHA = sha_of("https://github.com/o/r/release.apk")


def run(
    tmp_path: Path,
    env_text: str,
    test_code: int = 160,
    release_code: int = 2,
    test_sha: str = TEST_SHA,
    release_sha: str = RELEASE_SHA,
    check: bool = True,
) -> str:
    deploy = tmp_path / "deploy"
    deploy.mkdir(exist_ok=True)
    shutil.copy(SCRIPT, deploy / "fetch_test_apk.sh")
    (deploy / ".env").write_text(env_text)
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(exist_ok=True)
    for name, body in (("docker", FAKE_DOCKER), ("curl", FAKE_CURL)):
        (bin_dir / name).write_text(body)
        (bin_dir / name).chmod(0o755)
    result = subprocess.run(  # noqa: S603 - fixed arguments, test only
        [str(BASH), str(deploy / "fetch_test_apk.sh")],
        capture_output=True,
        text=True,
        check=check,
        env={
            **os.environ,
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "APK_DIR": str(tmp_path / "apk"),
            "FAKE_TEST_CODE": str(test_code),
            "FAKE_RELEASE_CODE": str(release_code),
            "FAKE_TEST_SHA": test_sha,
            "FAKE_RELEASE_SHA": release_sha,
        },
    )
    return result.stdout


def served(tmp_path: Path, name: str) -> str:
    return (tmp_path / "apk" / name).read_bytes().rstrip(b"\0").decode()


def test_both_switches_on_serve_both_files(tmp_path: Path) -> None:
    run(tmp_path, "TEST_APK_MIRROR=on\nRELEASE_APK_MIRROR=on\n")
    apk = tmp_path / "apk"
    assert served(tmp_path, "bagmitra.apk") == "https://github.com/o/r/release.apk"
    assert served(tmp_path, "bagmitra-test.apk") == "https://github.com/o/r/test.apk"
    assert (apk / "release-code").read_text().strip() == "2"
    assert (apk / "test-code").read_text().strip() == "160"
    assert (apk / "release.json").read_text().strip() == '{"code": 2, "name": "1.0.2"}'


def test_the_test_mirror_runs_while_a_release_apk_is_served(tmp_path: Path) -> None:
    apk = tmp_path / "apk"
    apk.mkdir()
    (apk / "bagmitra.apk").write_text("release bytes")
    (apk / "release-code").write_text("2\n")
    run(tmp_path, "TEST_APK_MIRROR=on\n")
    assert (apk / "bagmitra.apk").read_text() == "release bytes"
    assert served(tmp_path, "bagmitra-test.apk") == "https://github.com/o/r/test.apk"
    assert (apk / "test-code").read_text().strip() == "160"


def test_the_test_mirror_never_writes_the_release_file(tmp_path: Path) -> None:
    run(tmp_path, "TEST_APK_MIRROR=on\n")
    apk = tmp_path / "apk"
    assert not (apk / "bagmitra.apk").exists()
    assert not (apk / "release.json").exists()
    assert not (apk / "release-code").exists()


def test_release_only_leaves_the_test_file_alone(tmp_path: Path) -> None:
    run(tmp_path, "RELEASE_APK_MIRROR=on\n")
    apk = tmp_path / "apk"
    assert served(tmp_path, "bagmitra.apk") == "https://github.com/o/r/release.apk"
    assert not (apk / "bagmitra-test.apk").exists()


def test_a_current_code_downloads_nothing(tmp_path: Path) -> None:
    run(tmp_path, "TEST_APK_MIRROR=on\nRELEASE_APK_MIRROR=on\n")
    out = run(tmp_path, "TEST_APK_MIRROR=on\nRELEASE_APK_MIRROR=on\n")
    assert "test APK code 160 is current" in out
    assert "release APK code 2 is current" in out


def test_an_old_test_code_without_the_test_file_downloads_again(tmp_path: Path) -> None:
    """VPS before H1: test-code was written beside bagmitra.apk; bagmitra-test.apk is new."""
    apk = tmp_path / "apk"
    apk.mkdir()
    (apk / "test-code").write_text("160\n")
    run(tmp_path, "TEST_APK_MIRROR=on\n")
    assert served(tmp_path, "bagmitra-test.apk") == "https://github.com/o/r/test.apk"


def test_a_file_that_does_not_match_the_github_digest_is_not_served(tmp_path: Path) -> None:
    """Audit L5: serve nothing when the downloaded file's SHA-256 differs from GitHub's."""
    apk = tmp_path / "apk"
    apk.mkdir()
    (apk / "bagmitra.apk").write_text("release bytes")
    (apk / "release-code").write_text("1\n")
    out = run(
        tmp_path,
        "TEST_APK_MIRROR=on\nRELEASE_APK_MIRROR=on\n",
        test_sha="0" * 64,
        release_sha="f" * 64,
        check=False,
    )
    assert "release checksum mismatch" in out
    assert "test checksum mismatch" in out
    assert (apk / "bagmitra.apk").read_text() == "release bytes"
    assert (apk / "release-code").read_text().strip() == "1"
    assert not (apk / "bagmitra-test.apk").exists()
    assert not list(apk.glob("*.new"))


def test_a_release_without_a_digest_is_not_served(tmp_path: Path) -> None:
    out = run(tmp_path, "TEST_APK_MIRROR=on\n", test_sha="", check=False)
    assert "no test APK found" in out or "no checksum" in out
    assert not (tmp_path / "apk" / "bagmitra-test.apk").exists()
