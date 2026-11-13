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
    "knowledge": "bagmitra_api.feed.knowledge",
    "portals": "bagmitra_api.feed.portal_job",
    "regate": "bagmitra_api.kb.regate",
    "retention": "bagmitra_api.sync.retention",
    "push": "bagmitra_api.push.deliver",
    "updates": "bagmitra_api.push.updates",
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
        "CRON_PHOTO_AI_RETENTION=off\nCRON_FEED_KNOWLEDGE=off\nCRON_FEED_PORTALS=off\n"
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
        "knowledge",
        "portals",
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
    assert len(lines) == 16
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
        "knowledge",
        "portals",
        "regate",
        "retention",
        "push",
        "updates",
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


def test_update_pushes_run_with_fcm_set_unless_switched_off(tmp_path: Path) -> None:
    """Q147: the update push job (articles, market, weather changes) comes with FCM, 12 min
    after the 02:35 / 08:35 / 14:35 UTC market pulls and outside the default quiet hours;
    CRON_PUSH_UPDATES=off removes it while the risk-alert deliver job stays."""
    key = "FCM_SERVICE_ACCOUNT_B64=c2VjcmV0LWtleS1ibG9i\n"
    _, lines = run_install(tmp_path, "FCM_PROJECT_ID=demo-project\n" + key)
    line = next(ln for ln in lines if MARKERS["updates"] in ln)
    assert line.startswith("47 2,8,14 * * * cd ")
    assert line.endswith(">> /var/log/bagmitra-push-updates.log 2>&1")
    # 02:47 / 08:47 / 14:47 UTC = 08:17 / 14:17 / 20:17 IST, all before 21:00 IST.
    out, lines = run_install(tmp_path, "FCM_PROJECT_ID=demo-project\nCRON_PUSH_UPDATES=off\n" + key)
    assert {"push"} <= jobs(lines)
    assert "updates" not in jobs(lines)
    assert "update pushes (02:47, 08:47, 14:47 UTC) cron line removed" in out
    _, lines = run_install(tmp_path, "FCM_PROJECT_ID=\nCRON_PUSH_UPDATES=on\n")
    assert "updates" not in jobs(lines)


def test_the_test_apk_mirror_is_opt_in(tmp_path: Path) -> None:
    _, lines = run_install(tmp_path, "API_DOMAIN=x\n")
    assert "test_apk" not in jobs(lines)
    _, lines = run_install(tmp_path, "TEST_APK_MIRROR=on\n")
    line = next(ln for ln in lines if MARKERS["test_apk"] in ln)
    # Owner 2026-11-13: hourly at a fixed minute (was every 15 minutes).
    assert line.startswith("7 * * * * bash ")
    assert line.endswith(">> /var/log/bagmitra-test-apk.log 2>&1")
    out, lines = run_install(tmp_path, "TEST_APK_MIRROR=off\n")
    assert "test_apk" not in jobs(lines)
    assert "APK mirror to /app (every hour) cron line removed" in out
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
        "knowledge",
        "portals",
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
        "CRON_PHOTO_AI_RETENTION=off\nCRON_FEED_KNOWLEDGE=off\nCRON_FEED_PORTALS=off\n",
    )
    assert jobs(cleared) == {"weather", "backup"}


def test_other_cron_lines_are_kept(tmp_path: Path) -> None:
    (tmp_path / "cron.txt").write_text("5 4 * * * /usr/local/bin/other-project\n")
    off = (
        "CRON_FEED_ALERTS=off\nCRON_FEED_NEWS=off\nCRON_SYNC_RETENTION=off\n"
        "CRON_MARKET_LINK_ERASE=off\nCRON_ML_RECHECK=off\nCRON_PHOTO_AI_RETENTION=off\n"
        "CRON_FEED_KNOWLEDGE=off\nCRON_FEED_PORTALS=off\n"
    )
    run_install(tmp_path, off + "CRON_KB_REGATE=on\n")
    _, lines = run_install(tmp_path, off + "CRON_KB_REGATE=no\n")
    assert lines[0] == "5 4 * * * /usr/local/bin/other-project"
    assert jobs(lines) == {"weather", "backup"}


def test_a_changed_cron_line_is_replaced_in_place_once(tmp_path: Path) -> None:
    """add_cron_line only looked for the marker, so the VPS kept an older deploy's `*/15` APK
    mirror line after the schedule changed. A line with the marker but other text is now
    replaced (once, in its place); other lines stay as they were; an identical one is kept."""
    log = ">> /var/log/bagmitra-test-apk.log 2>&1"
    old = f"*/15 * * * * bash /opt/bagmitra/deploy/fetch_test_apk.sh {log}"
    before = ["5 4 * * * /usr/local/bin/other-project", old, "# a comment", "9 9 * * * other-job"]
    (tmp_path / "cron.txt").write_text("\n".join(before) + "\n")
    out, lines = run_install(tmp_path, "TEST_APK_MIRROR=on\n")
    assert "APK mirror to /app (every hour) cron line updated" in out
    mirror = [ln for ln in lines if MARKERS["test_apk"] in ln]
    assert len(mirror) == 1
    assert mirror[0] == f"7 * * * * bash {DEPLOY}/fetch_test_apk.sh {log}"
    assert old not in lines
    # The other lines are untouched and in their order; the new line took the old one's place.
    assert lines[:4] == [before[0], mirror[0], before[2], before[3]]
    out_again, lines_again = run_install(tmp_path, "TEST_APK_MIRROR=on\n")
    assert lines_again == lines
    assert "APK mirror to /app (every hour) cron line already present" in out_again
    assert "updated" not in out_again


def test_a_doubled_cron_line_is_collapsed_to_one(tmp_path: Path) -> None:
    weather = (
        f"0 0 * * * cd {DEPLOY} && docker compose exec -T api python -m "
        "bagmitra_api.weather.pull_job"
    )
    old = weather + " >> /var/log/old.log 2>&1"
    (tmp_path / "cron.txt").write_text(f"{old}\n{old}\n")
    out, lines = run_install(tmp_path, "API_DOMAIN=x\n")
    assert "weather (daily 00:00 UTC = 05:30 IST) cron line updated" in out
    weather_lines = [ln for ln in lines if MARKERS["weather"] in ln]
    assert weather_lines == [weather + " >> /var/log/bagmitra-weather-pull.log 2>&1"]


def run_compose_file(tmp_path: Path, env_text: str) -> tuple[str, str]:
    env_file = tmp_path / ".env"
    if not env_file.exists() or env_text:
        env_file.write_text(env_text)
        env_file.chmod(0o600)
    script = f'source "{DEPLOY / "deploy.sh"}"; ENV_FILE="{env_file}"; set_compose_file'
    out = subprocess.run(  # noqa: S603 - fixed arguments, test only
        [str(BASH), "-c", script], capture_output=True, text=True, check=True
    ).stdout
    return out, env_file.read_text()


BASE = f"{DEPLOY}/docker-compose.yml"
SHARED = f"{BASE}:{DEPLOY}/docker-compose.shared-caddy.yml"


def test_compose_file_includes_the_shared_caddy_file_with_edge_network(tmp_path: Path) -> None:
    """Incident 2026-11-12: a plain `docker compose up -d api` in deploy/ read only
    docker-compose.yml, recreated the API without the shared Caddy's network, and the app
    answered 502. deploy.sh now keeps COMPOSE_FILE in .env, which Compose reads from there."""
    env = 'API_DOMAIN=x\nDATABASE_URL="postgresql://u:secret-db-pass@h/db"\nEDGE_NETWORK=edge\n'
    out, text = run_compose_file(tmp_path, env)
    assert text == env + f"COMPOSE_FILE={SHARED}\n"
    assert "secret-db-pass" not in out
    assert "docker-compose.yml:docker-compose.shared-caddy.yml" in out
    assert (tmp_path / ".env").stat().st_mode & 0o777 == 0o600
    assert sorted(p.name for p in tmp_path.iterdir()) == [".env"], "no temp file left"


def test_compose_file_without_edge_network_is_only_the_main_file(tmp_path: Path) -> None:
    _, text = run_compose_file(tmp_path, "API_DOMAIN=x\nEDGE_NETWORK=\n")
    assert text == f"API_DOMAIN=x\nEDGE_NETWORK=\nCOMPOSE_FILE={BASE}\n"


def test_compose_file_line_is_replaced_in_place_never_doubled(tmp_path: Path) -> None:
    # EDGE_NETWORK turned on after a deploy without it (and a stray second line): one line,
    # in place.
    env = f"API_DOMAIN=x\nCOMPOSE_FILE={BASE}\nEDGE_NETWORK=edge\nCOMPOSE_FILE=old.yml\nLAST=1\n"
    out, text = run_compose_file(tmp_path, env)
    assert text == f"API_DOMAIN=x\nCOMPOSE_FILE={SHARED}\nEDGE_NETWORK=edge\nLAST=1\n"
    assert "set:" in out
    out_again, text_again = run_compose_file(tmp_path, "")
    assert text_again == text, "idempotent: a second deploy changes nothing"
    assert "already set" in out_again
    # Switched back off: the line drops the shared Caddy file again.
    _, text_off = run_compose_file(tmp_path, f"EDGE_NETWORK=\nCOMPOSE_FILE={SHARED}\n")
    assert text_off == f"EDGE_NETWORK=\nCOMPOSE_FILE={BASE}\n"


def test_deploy_sets_compose_file_before_the_containers_restart() -> None:
    script = (DEPLOY / "deploy.sh").read_text()
    assert "  update_admin_web\n  set_compose_file\n  restart\n" in script


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


FAKE_GIT = """#!/usr/bin/env bash
# Enough git for deploy.sh: a clean tree, a commit id, and `pull` replaces deploy.sh with the
# pulled version by rename (as git does), while the running bash still reads the old copy.
case "$1" in
  diff) exit 0 ;;
  rev-parse) echo 1111111 ;;
  checkout) exit 0 ;;
  pull) cp "$PULLED_SCRIPT" "$FAKE_ROOT/deploy/deploy.sh.new"
        mv "$FAKE_ROOT/deploy/deploy.sh.new" "$FAKE_ROOT/deploy/deploy.sh"
        echo pulled >> "$FAKE_ROOT/pulls" ;;
  log) echo "2222222 pulled commit" ;;
  *) exit 1 ;;  # fetch of the admin web branch: none here
esac
"""


def test_a_cron_line_added_by_the_pulled_code_is_installed_in_the_same_deploy(
    tmp_path: Path,
) -> None:
    """deploy.sh used to add cron lines with the functions bash read before `git pull`, so a
    new job's line came only with the second deploy. Now it runs the pulled copy of itself
    once (--after-pull, guarded by BAGMITRA_DEPLOY_REEXEC), and the line is added at once."""
    root = tmp_path / "root"
    (root / "deploy").mkdir(parents=True)
    current = (DEPLOY / "deploy.sh").read_text()
    install = (
        '  on=1; switch_on CRON_FEED_KNOWLEDGE && on=0\n  cron_job_if "$on" '
        '"bagmitra_api.feed.knowledge" "$FEED_KNOWLEDGE_CRON_LINE" '
        '"knowledge articles (daily 02:11 UTC)"\n'
    )
    assert install in current
    # The copy on the server before the pull: the same script without the new job.
    (root / "deploy" / "deploy.sh").write_text(current.replace(install, ""))
    (root / "deploy" / ".env").write_text(
        "API_DOMAIN=api.example.test\nDATABASE_URL=x\nENTITLEMENT_SIGNING_KEY=x\n"
        "SUPABASE_JWT_SECRET=x\nMARKET_API_KEY=k\n"
    )
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    fakes = {
        "crontab": FAKE_CRONTAB,
        "git": FAKE_GIT,
        "docker": "#!/usr/bin/env bash\nexit 0\n",
        "curl": '#!/usr/bin/env bash\necho \'{"status":"ok"}\'\n',
    }
    for name, body in fakes.items():
        (bin_dir / name).write_text(body)
        (bin_dir / name).chmod(0o755)
    cron = tmp_path / "cron.txt"
    env = {k: v for k, v in os.environ.items() if k != "BAGMITRA_DEPLOY_REEXEC"}
    result = subprocess.run(  # noqa: S603 - fixed arguments, test only
        [str(BASH), str(root / "deploy" / "deploy.sh")],
        capture_output=True,
        text=True,
        check=False,
        env={
            **env,
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "FAKE_CRON_FILE": str(cron),
            "FAKE_ROOT": str(root),
            "PULLED_SCRIPT": str(DEPLOY / "deploy.sh"),
            "LOGROTATE_FILE": str(tmp_path / "logrotate"),
        },
    )
    assert result.returncode == 0, result.stderr
    assert (root / "pulls").read_text() == "pulled\n", "pulled once, no loop"
    assert result.stdout.count("running the updated deploy script") == 1
    lines = cron.read_text().splitlines()
    assert "knowledge" in jobs(lines)
    line = next(ln for ln in lines if MARKERS["knowledge"] in ln)
    assert line.startswith("11 2 * * * cd ")
    assert line.endswith(">> /var/log/bagmitra-feed-knowledge.log 2>&1")
    assert "Done." in result.stdout
