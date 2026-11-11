"""BG-02: deploy/deploy.sh `install_cron` adds every scheduled job whose switch in deploy/.env
is on, once, and removes it again when the switch is off. Runs the real script functions
against a fake `crontab` (a file), so the host's crontab is never touched."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest

DEPLOY = Path(__file__).resolve().parents[2] / "deploy"
BASH = shutil.which("bash")

pytestmark = pytest.mark.skipif(BASH is None, reason="needs bash")

FAKE_CRONTAB = """#!/usr/bin/env bash
store="$FAKE_CRON_FILE"
if [[ "$1" == "-l" ]]; then [[ -f "$store" ]] || exit 1; cat "$store"; exit 0; fi
# Like the real crontab: read all of stdin first, then install (no truncate-while-reading race).
if [[ "$1" == "-" ]]; then new="$(cat)"; printf '%s\n' "$new" > "$store"; exit 0; fi
exit 2
"""

MARKERS = {
    "weather": "bagmitra_api.weather.pull_job",
    "backup": "deploy/backup.sh",
    "market": "bagmitra_api.market.pull_job",
    "alerts": "bagmitra_api.feed.alert_job",
    "news": "bagmitra_api.feed.news_job",
    "regate": "bagmitra_api.kb.regate",
    "retention": "bagmitra_api.sync.retention",
    "push": "bagmitra_api.push.deliver",
    "erase": "bagmitra_api.market_link.erase_job",
    "recheck": "bagmitra_api.market_link.recheck_job",
    "billing": "bagmitra_api.billing.reconcile_job",
    "photo_retention": "bagmitra_api.photo_ai.retention",
    "test_apk": "deploy/fetch_test_apk.sh",
}


def run_install(tmp_path: Path, env_text: str) -> tuple[str, list[str]]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(exist_ok=True)
    fake = bin_dir / "crontab"
    fake.write_text(FAKE_CRONTAB)
    fake.chmod(0o755)
    env_file = tmp_path / ".env"
    env_file.write_text(env_text)
    cron = tmp_path / "cron.txt"
    script = f'source "{DEPLOY / "deploy.sh"}"; ENV_FILE="{env_file}"; install_cron'
    result = subprocess.run(  # noqa: S603 - fixed arguments, test only
        [str(BASH), "-c", script],
        capture_output=True,
        text=True,
        check=True,
        env={**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}", "FAKE_CRON_FILE": str(cron)},
    )
    lines = cron.read_text().splitlines() if cron.exists() else []
    return result.stdout, lines


def jobs(lines: list[str]) -> set[str]:
    return {name for name, marker in MARKERS.items() if any(marker in ln for ln in lines)}


def test_only_weather_and_backup_with_every_switch_off(tmp_path: Path) -> None:
    env = (
        "API_DOMAIN=x\nMARKET_API_KEY=\nCRON_FEED_ALERTS=off\nCRON_FEED_NEWS=no\nCRON_KB_REGATE=0\n"
        "CRON_SYNC_RETENTION=false\nCRON_MARKET_LINK_ERASE=off\nCRON_ML_RECHECK=off\n"
        "CRON_PHOTO_AI_RETENTION=off\n"
    )
    out, lines = run_install(tmp_path, env)
    assert jobs(lines) == {"weather", "backup"}
    assert len(lines) == 2
    assert "market" not in out


def test_unset_switches_are_on_by_default(tmp_path: Path) -> None:
    # Owner default: the feed and KB jobs run unless a switch says off.
    _, lines = run_install(tmp_path, "API_DOMAIN=x\nMARKET_API_KEY=\n")
    assert jobs(lines) == {
        "weather",
        "backup",
        "alerts",
        "news",
        "regate",
        "retention",
        "erase",
        "recheck",
        "photo_retention",
    }


def test_each_switch_adds_its_job_once_and_never_prints_values(tmp_path: Path) -> None:
    env = (
        'MARKET_API_KEY="secret-market-key-123"\n'
        "CRON_FEED_ALERTS=on\nCRON_FEED_NEWS=TRUE\nCRON_KB_REGATE=1\nCRON_SYNC_RETENTION=on\n"
        "FCM_PROJECT_ID=demo-project\nPLAY_PACKAGE_NAME=app.bagmitra.bagmitra\n"
        "TEST_APK_MIRROR=on\n"
    )
    out, lines = run_install(tmp_path, env)
    assert jobs(lines) == set(MARKERS)
    assert len(lines) == 13
    assert "secret-market-key-123" not in out
    assert not any("secret-market-key-123" in ln for ln in lines)
    out_again, lines_again = run_install(tmp_path, env)
    assert lines_again == lines, "idempotent: a second deploy adds nothing"
    assert "already present" in out_again
    market = next(ln for ln in lines if MARKERS["market"] in ln)
    assert market.startswith("35 2,8,14,20 * * * cd ")
    assert market.endswith(">> /var/log/bagmitra-market-pull.log 2>&1")
    # None of the new jobs shares the 00:00 weather or 21:40 backup slot.
    names = (
        "market",
        "alerts",
        "news",
        "regate",
        "retention",
        "push",
        "erase",
        "recheck",
        "photo_retention",
    )
    for name in (*names, "billing"):
        line = next(ln for ln in lines if MARKERS[name] in ln)
        minute, hour = line.split()[:2]
        assert (minute, hour) != ("0", "0")
        assert not (minute == "40" and "21" in hour.split(","))


def test_weather_alert_pushes_run_only_with_fcm_set(tmp_path: Path) -> None:
    """BG-01: the deliver job is added once FCM_PROJECT_ID is set, after the 00:00 UTC weather
    pull and outside the default quiet hours (21:00-07:00 IST); removed when it is cleared."""
    key = "FCM_SERVICE_ACCOUNT_B64=c2VjcmV0LWtleS1ibG9i\n"
    out, lines = run_install(tmp_path, "FCM_PROJECT_ID=demo-project\n" + key)
    line = next(ln for ln in lines if MARKERS["push"] in ln)
    assert line.startswith("37 1 * * * cd ")
    assert line.endswith(">> /var/log/bagmitra-push-deliver.log 2>&1")
    assert "c2VjcmV0LWtleS1ibG9i" not in out
    assert not any("c2VjcmV0LWtleS1ibG9i" in ln for ln in lines)
    out, lines = run_install(tmp_path, "FCM_PROJECT_ID=\n" + key)
    assert "push" not in jobs(lines)
    assert "weather alert pushes (01:37 UTC = 07:07 IST) cron line removed" in out


def test_the_test_apk_mirror_is_opt_in(tmp_path: Path) -> None:
    _, lines = run_install(tmp_path, "API_DOMAIN=x\n")
    assert "test_apk" not in jobs(lines)
    _, lines = run_install(tmp_path, "TEST_APK_MIRROR=on\n")
    line = next(ln for ln in lines if MARKERS["test_apk"] in ln)
    assert line.startswith("*/15 * * * * bash ")
    assert line.endswith(">> /var/log/bagmitra-test-apk.log 2>&1")
    out, lines = run_install(tmp_path, "TEST_APK_MIRROR=off\n")
    assert "test_apk" not in jobs(lines)
    assert "APK mirror to /app (every 15 min) cron line removed" in out
    _, lines = run_install(tmp_path, "RELEASE_APK_MIRROR=on\n")
    assert "test_apk" in jobs(lines)


def test_billing_reconciliation_runs_only_with_play_set_up(tmp_path: Path) -> None:
    _, lines = run_install(tmp_path, "PLAY_PACKAGE_NAME=app.bagmitra.bagmitra\n")
    line = next(ln for ln in lines if MARKERS["billing"] in ln)
    assert line.startswith("47 23 * * * cd ")
    assert line.endswith(">> /var/log/bagmitra-billing-reconcile.log 2>&1")
    out, lines = run_install(tmp_path, "PLAY_PACKAGE_NAME=\n")
    assert "billing" not in jobs(lines)
    assert "Play billing reconciliation (nightly 23:47 UTC) cron line removed" in out


def test_turning_a_switch_off_removes_only_its_line(tmp_path: Path) -> None:
    run_install(tmp_path, "MARKET_API_KEY=k\nCRON_FEED_NEWS=on\nCRON_KB_REGATE=on\n")
    out, lines = run_install(tmp_path, "MARKET_API_KEY=k\nCRON_FEED_NEWS=off\nCRON_KB_REGATE=on\n")
    assert jobs(lines) == {
        "weather",
        "backup",
        "market",
        "alerts",
        "regate",
        "retention",
        "erase",
        "recheck",
        "photo_retention",
    }
    assert "feed news (every 6 h) cron line removed" in out
    _, cleared = run_install(
        tmp_path,
        "MARKET_API_KEY=\nCRON_FEED_ALERTS=off\nCRON_FEED_NEWS=off\nCRON_KB_REGATE=off\n"
        "CRON_SYNC_RETENTION=off\nCRON_MARKET_LINK_ERASE=off\nCRON_ML_RECHECK=off\n"
        "CRON_PHOTO_AI_RETENTION=off\n",
    )
    assert jobs(cleared) == {"weather", "backup"}


def test_other_cron_lines_are_kept(tmp_path: Path) -> None:
    (tmp_path / "cron.txt").write_text("5 4 * * * /usr/local/bin/other-project\n")
    off = (
        "CRON_FEED_ALERTS=off\nCRON_FEED_NEWS=off\nCRON_SYNC_RETENTION=off\n"
        "CRON_MARKET_LINK_ERASE=off\nCRON_ML_RECHECK=off\nCRON_PHOTO_AI_RETENTION=off\n"
    )
    run_install(tmp_path, off + "CRON_KB_REGATE=on\n")
    _, lines = run_install(tmp_path, off + "CRON_KB_REGATE=no\n")
    assert lines[0] == "5 4 * * * /usr/local/bin/other-project"
    assert jobs(lines) == {"weather", "backup"}


def run_logrotate(target: Path) -> str:
    script = f'source "{DEPLOY / "deploy.sh"}"; LOGROTATE_FILE="{target}"; install_logrotate'
    return subprocess.run(  # noqa: S603 - fixed arguments, test only
        [str(BASH), "-c", script], capture_output=True, text=True, check=True
    ).stdout


def test_job_logs_get_a_logrotate_drop_in_once(tmp_path: Path) -> None:
    """BG-05: every /var/log/bagmitra-*.log the cron lines write is rotated and capped."""
    target = tmp_path / "logrotate-bagmitra"
    assert "log rotation set" in run_logrotate(target)
    conf = target.read_text()
    assert conf.startswith("/var/log/bagmitra-*.log {")
    for directive in ("weekly", "maxsize 10M", "rotate 8", "compress", "missingok"):
        assert f"    {directive}\n" in conf
    assert "already set" in run_logrotate(target)
    script = (DEPLOY / "deploy.sh").read_text()
    logs = {part.split()[0] for part in script.split(">> ")[1:]}
    assert len(logs) >= 8, "every cron line appends to a log file"
    assert all(log.startswith("/var/log/bagmitra-") and log.endswith(".log") for log in logs)


def test_an_unwritable_logrotate_path_does_not_stop_the_deploy(tmp_path: Path) -> None:
    assert "could not write" in run_logrotate(tmp_path / "missing-dir" / "bagmitra")


def test_deploy_waits_for_the_database_ready_check() -> None:
    """OPS-08: deploy's wait and the container healthcheck use /health/ready (DB); OPS-11:
    uvicorn no longer trusts forwarded headers from any address."""
    script = (DEPLOY / "deploy.sh").read_text()
    compose = (DEPLOY / "docker-compose.yml").read_text()
    assert 'url="https://$domain/health/ready"' in script
    assert "localhost:8000/health/ready" in compose
    assert "forwarded-allow-ips='*'" not in compose
    assert "--forwarded-allow-ips=$$(python -m bagmitra_api.core.proxy_trust)" in compose
