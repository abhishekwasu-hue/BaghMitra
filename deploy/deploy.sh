#!/usr/bin/env bash
# One-step update of the BagMitra API on the VPS. You run it on the server (nothing runs there
# for you): first install as in docs/runbooks/vps-deploy.md steps 1-4, then every time:
#   cd /opt/bagmitra && bash deploy/deploy.sh            # update to the latest main
#   cd /opt/bagmitra && bash deploy/deploy.sh --revert   # go back to the previous deploy
# If another project's Caddy already owns ports 80/443, set EDGE_NETWORK=edge in .env: BagMitra
# then runs without its own Caddy and joins that shared network (docker-compose.shared-caddy.yml,
# runbook "Sharing the server").
# It checks .env, pulls the code, rebuilds and restarts the containers (migrations run on
# start), waits until https://$API_DOMAIN/health/ready answers (API and database up), and adds
# the daily weather and nightly backup cron lines once, plus each scheduled job whose switch
# in .env is on (market pull, feed reminders, feed news, knowledge articles, KB re-gate, sync
# retention; install_cron), and keeps the job logs rotated (install_logrotate). After the pull it
# runs the pulled copy of itself, so new steps and cron lines apply in the same deploy. It never
# prints .env values.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$ROOT/deploy"
ENV_FILE="$DEPLOY/.env"
PREVIOUS="$DEPLOY/.previous_commit"
CRON_LINE="0 0 * * * cd $DEPLOY && docker compose exec -T api python -m bagmitra_api.weather.pull_job >> /var/log/bagmitra-weather-pull.log 2>&1"
# Nightly database dump (OPS-06), 21:40 UTC = 03:10 IST, kept 14 days in /var/backups/bagmitra.
BACKUP_CRON_LINE="40 21 * * * bash $DEPLOY/backup.sh >> /var/log/bagmitra-backup.log 2>&1"
# Scheduled jobs from the runbooks (audit BG-02), times in UTC (the server clock), all away from
# the 00:00 weather and 21:40 backup slots. Each is added only while its switch in .env is on
# and removed again when the switch is turned off (install_cron); the module name is the marker.
JOB="cd $DEPLOY && docker compose exec -T api python -m"
# Mandi prices (BG-04, docs/runbooks/market-prices.md): every 6 h at 02:35, 08:35, 14:35, 20:35
# UTC (08:05, 14:05, 20:05, 02:05 IST); on while MARKET_API_KEY is set.
MARKET_CRON_LINE="35 2,8,14,20 * * * $JOB bagmitra_api.market.pull_job >> /var/log/bagmitra-market-pull.log 2>&1"
# Government feed reminders (govt-feed.md §8): 03:17 and 11:17 UTC (08:47, 16:47 IST, outside
# the default quiet hours); on with CRON_FEED_ALERTS=on.
FEED_ALERTS_CRON_LINE="17 3,11 * * * $JOB bagmitra_api.feed.alert_job >> /var/log/bagmitra-feed-alerts.log 2>&1"
# News headlines (govt-feed.md §9): every 6 h at 01:23, 07:23, 13:23, 19:23 UTC; on with
# CRON_FEED_NEWS=on (only after the source terms are recorded).
FEED_NEWS_CRON_LINE="23 1,7,13,19 * * * $JOB bagmitra_api.feed.news_job >> /var/log/bagmitra-feed-news.log 2>&1"
# Knowledge articles (govt-feed.md §13, Q141): daily 02:11 UTC (07:41 IST), after the 00:00 UTC
# weather pull so its risk alerts are fresh; on unless CRON_FEED_KNOWLEDGE=off.
FEED_KNOWLEDGE_CRON_LINE="11 2 * * * $JOB bagmitra_api.feed.knowledge >> /var/log/bagmitra-feed-knowledge.log 2>&1"
# Weather / risk alert pushes (push/deliver.py): 01:37 UTC (07:07 IST), after the 00:00 UTC
# weather pull and just after the default quiet hours (21:00-07:00 IST); on once FCM_PROJECT_ID is set.
PUSH_DELIVER_CRON_LINE="37 1 * * * $JOB bagmitra_api.push.deliver >> /var/log/bagmitra-push-deliver.log 2>&1"
# Nightly KB re-gate (kb/regate.py): 20:50 UTC (02:20 IST); on with CRON_KB_REGATE=on.
KB_REGATE_CRON_LINE="50 20 * * * $JOB bagmitra_api.kb.regate >> /var/log/bagmitra-kb-regate.log 2>&1"
# Sync audit log retention (LD-09, sync/retention.py): 22:13 UTC (03:43 IST), after the
# nightly backup; on unless CRON_SYNC_RETENTION=off. Keeps SYNC_PAYLOAD_RETENTION_DAYS days.
SYNC_RETENTION_CRON_LINE="13 22 * * * $JOB bagmitra_api.sync.retention >> /var/log/bagmitra-sync-retention.log 2>&1"
# Market-link erasure of deleted accounts after 180 days (Q68, market_link/erase_job.py):
# 22:41 UTC (04:11 IST); on unless CRON_MARKET_LINK_ERASE=off.
MARKET_LINK_ERASE_CRON_LINE="41 22 * * * $JOB bagmitra_api.market_link.erase_job >> /var/log/bagmitra-market-link-erase.log 2>&1"
# Market-link yearly re-check list (market_link/recheck_job.py, spec v1.5 §4): 23:19 UTC
# (04:49 IST); on unless CRON_ML_RECHECK=off. Does nothing while MARKET_LINK_ENABLED is off.
ML_RECHECK_CRON_LINE="19 23 * * * $JOB bagmitra_api.market_link.recheck_job >> /var/log/bagmitra-ml-recheck.log 2>&1"
# Photo analysis training samples older than PHOTO_AI_RETENTION_DAYS (Q135,
# photo_ai/retention.py): 22:29 UTC (03:59 IST); on unless CRON_PHOTO_AI_RETENTION=off.
PHOTO_AI_RETENTION_CRON_LINE="29 22 * * * $JOB bagmitra_api.photo_ai.retention >> /var/log/bagmitra-photo-ai-retention.log 2>&1"
# Play billing reconciliation (billing/reconcile_job.py: voided purchases, drift list): 23:47 UTC
# (05:17 IST); on once PLAY_PACKAGE_NAME is set (runbook billing-play.md).
BILLING_RECONCILE_CRON_LINE="47 23 * * * $JOB bagmitra_api.billing.reconcile_job >> /var/log/bagmitra-billing-reconcile.log 2>&1"
# APK mirror (deploy/fetch_test_apk.sh): every 15 minutes, with TEST_APK_MIRROR=on or
# RELEASE_APK_MIRROR=on (release wins; the test mirror never replaces a served Release APK).
TEST_APK_CRON_LINE="*/15 * * * * bash $DEPLOY/fetch_test_apk.sh >> /var/log/bagmitra-test-apk.log 2>&1"
# Job logs (BG-05): every /var/log/bagmitra-*.log above is rotated weekly or past 10 MB, 8 old
# copies kept compressed. Written by install_logrotate; LOGROTATE_FILE is overridable (tests).
LOGROTATE_FILE="${LOGROTATE_FILE:-/etc/logrotate.d/bagmitra}"
LOGROTATE_CONF='/var/log/bagmitra-*.log {
    weekly
    maxsize 10M
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    su root root
}'
REQUIRED=(API_DOMAIN DATABASE_URL ENTITLEMENT_SIGNING_KEY)

say() { printf '\n== %s\n' "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

env_value() { # value of KEY in .env without printing it anywhere
  { grep -E "^$1=" "$ENV_FILE" || true; } | tail -n 1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'
}

check_env() {
  [[ -f "$ENV_FILE" ]] || fail "$ENV_FILE is missing: cp deploy/.env.example deploy/.env and fill it in"
  chmod 600 "$ENV_FILE"
  local key missing=()
  for key in "${REQUIRED[@]}"; do
    [[ -n "$(env_value "$key")" ]] || missing+=("$key")
  done
  if [[ -z "$(env_value SUPABASE_JWKS_URL)" && -z "$(env_value SUPABASE_JWT_SECRET)" ]]; then
    missing+=("SUPABASE_JWKS_URL or SUPABASE_JWT_SECRET")
  fi
  ((${#missing[@]} == 0)) || fail "fill in deploy/.env: ${missing[*]}"
  [[ -n "$(env_value MARKET_API_KEY)" ]] || echo "note: MARKET_API_KEY is empty, mandi prices stay off until it is set"
}

update_code() {
  cd "$ROOT"
  git diff --quiet || fail "the server copy has local edits (git status); undo them first"
  if [[ "${1:-}" == "--revert" ]]; then
    [[ -f "$PREVIOUS" ]] || fail "no previous deploy recorded"
    local target; target="$(cat "$PREVIOUS")"
    say "Reverting to $target"
    downgrade_db_to "$target"
    git rev-parse HEAD > "$PREVIOUS.new"
    git checkout -q "$target"
    mv "$PREVIOUS.new" "$PREVIOUS"
  else
    say "Pulling the latest main"
    git rev-parse HEAD > "$PREVIOUS"
    git checkout -q main
    git pull -q --ff-only origin main
  fi
  echo "now at $(git log --oneline -1)"
}

# Newest migration id (the 4-digit file prefix) in a commit.
migration_head() {
  git ls-tree --name-only "$1" api/alembic/versions/ | sed -n 's#.*/\([0-9]\{4\}\)_.*\.py$#\1#p' | sort | tail -1
}

# The older code cannot start on a database at a revision it does not know, so step the
# database back first, with the current image (which knows both revisions).
downgrade_db_to() {
  local cur prev
  cur="$(migration_head HEAD)"
  prev="$(migration_head "$1")"
  if [[ -n "$cur" && -n "$prev" && "$cur" > "$prev" ]]; then
    say "Stepping the database back from migration $cur to $prev"
    compose run --rm --no-deps api alembic downgrade "$prev" || fail "database downgrade failed; nothing was switched"
  fi
}

compose() {
  local edge
  edge="$(env_value EDGE_NETWORK)"
  if [[ -n "$edge" ]]; then
    docker compose -f "$DEPLOY/docker-compose.yml" -f "$DEPLOY/docker-compose.shared-caddy.yml" "$@"
  else
    docker compose -f "$DEPLOY/docker-compose.yml" "$@"
  fi
}

restart() {
  say "Building and starting (migrations run on start; first build takes 5-10 minutes)"
  cd "$DEPLOY"
  local edge
  edge="$(env_value EDGE_NETWORK)"
  if [[ -n "$edge" ]]; then
    docker network inspect "$edge" > /dev/null 2>&1 || docker network create "$edge" > /dev/null
    echo "sharing the server: no own Caddy, API joins network '$edge' as bagmitra-api"
  fi
  compose up -d --build --remove-orphans
}

wait_healthy() {
  local domain url
  domain="$(env_value API_DOMAIN)"
  url="https://$domain/health/ready"
  say "Waiting for $url"
  for _ in $(seq 1 60); do
    if curl -fsS --max-time 5 "$url" > /dev/null 2>&1; then
      echo "API is up: $(curl -fsS --max-time 5 "$url")"
      return 0
    fi
    sleep 5
  done
  compose logs --tail 60 api || true
  [[ -z "$(env_value EDGE_NETWORK)" ]] || echo "shared Caddy: check that it joined '$(env_value EDGE_NETWORK)' and has the BagMitra site block (runbook)"
  fail "the API did not answer in 5 minutes (logs above). Go back with: bash deploy/deploy.sh --revert"
}

add_cron_line() { # marker, line, label: adds the line once
  if crontab -l 2> /dev/null | grep -Fq "$1"; then
    echo "$3 cron line already present"
  else
    (crontab -l 2> /dev/null || true; echo "$2") | crontab -
    echo "$3 cron line added"
  fi
}

remove_cron_line() { # marker, label: removes the line if it is there
  if crontab -l 2> /dev/null | grep -Fq "$1"; then
    { crontab -l 2> /dev/null | grep -Fv "$1" || true; } | crontab -
    echo "$2 cron line removed (switched off in .env)"
  fi
}

switch_on() { # true unless the .env value of KEY is off / false / no / 0; unset = on (owner default)
  case "$(env_value "$1" | tr '[:upper:]' '[:lower:]')" in
    off | false | no | 0) return 1 ;;
    *) return 0 ;;
  esac
}

cron_job_if() { # condition (0 = on), marker, line, label
  if [[ "$1" == 0 ]]; then
    add_cron_line "$2" "$3" "$4"
  else
    remove_cron_line "$2" "$4"
  fi
}

install_cron() {
  command -v crontab > /dev/null || { echo "note: crontab not found, add the cron lines by hand (runbook 6a, 7)"; return; }
  add_cron_line "bagmitra_api.weather.pull_job" "$CRON_LINE" "weather (daily 00:00 UTC = 05:30 IST)"
  add_cron_line "deploy/backup.sh" "$BACKUP_CRON_LINE" "backup (nightly 21:40 UTC = 03:10 IST)"
  local on
  on=1; [[ -n "$(env_value MARKET_API_KEY)" ]] && on=0
  cron_job_if "$on" "bagmitra_api.market.pull_job" "$MARKET_CRON_LINE" "market prices (every 6 h)"
  on=1; [[ -n "$(env_value FCM_PROJECT_ID)" ]] && on=0
  cron_job_if "$on" "bagmitra_api.push.deliver" "$PUSH_DELIVER_CRON_LINE" "weather alert pushes (01:37 UTC = 07:07 IST)"
  on=1; switch_on CRON_FEED_ALERTS && on=0
  cron_job_if "$on" "bagmitra_api.feed.alert_job" "$FEED_ALERTS_CRON_LINE" "feed reminders (03:17, 11:17 UTC)"
  on=1; switch_on CRON_FEED_NEWS && on=0
  cron_job_if "$on" "bagmitra_api.feed.news_job" "$FEED_NEWS_CRON_LINE" "feed news (every 6 h)"
  on=1; switch_on CRON_FEED_KNOWLEDGE && on=0
  cron_job_if "$on" "bagmitra_api.feed.knowledge" "$FEED_KNOWLEDGE_CRON_LINE" "knowledge articles (daily 02:11 UTC)"
  on=1; switch_on CRON_KB_REGATE && on=0
  cron_job_if "$on" "bagmitra_api.kb.regate" "$KB_REGATE_CRON_LINE" "KB re-gate (nightly 20:50 UTC)"
  on=1; switch_on CRON_SYNC_RETENTION && on=0
  cron_job_if "$on" "bagmitra_api.sync.retention" "$SYNC_RETENTION_CRON_LINE" "sync retention (nightly 22:13 UTC)"
  on=1; switch_on CRON_MARKET_LINK_ERASE && on=0
  cron_job_if "$on" "bagmitra_api.market_link.erase_job" "$MARKET_LINK_ERASE_CRON_LINE" "market-link erasure (nightly 22:41 UTC)"
  on=1; switch_on CRON_ML_RECHECK && on=0
  cron_job_if "$on" "bagmitra_api.market_link.recheck_job" "$ML_RECHECK_CRON_LINE" "market-link re-check list (nightly 23:19 UTC)"
  on=1; switch_on CRON_PHOTO_AI_RETENTION && on=0
  cron_job_if "$on" "bagmitra_api.photo_ai.retention" "$PHOTO_AI_RETENTION_CRON_LINE" "photo analysis retention (nightly 22:29 UTC)"
  on=1; [[ -n "$(env_value PLAY_PACKAGE_NAME)" ]] && on=0
  cron_job_if "$on" "bagmitra_api.billing.reconcile_job" "$BILLING_RECONCILE_CRON_LINE" "Play billing reconciliation (nightly 23:47 UTC)"
  on=1
  for mirror in TEST_APK_MIRROR RELEASE_APK_MIRROR; do
    [[ "$(env_value "$mirror" | tr '[:upper:]' '[:lower:]')" == "on" ]] && on=0
  done
  cron_job_if "$on" "deploy/fetch_test_apk.sh" "$TEST_APK_CRON_LINE" "APK mirror to /app (every 15 min)"
}

install_logrotate() { # writes the drop-in only when it is missing or different
  if [[ -f "$LOGROTATE_FILE" && "$(cat "$LOGROTATE_FILE")" == "$LOGROTATE_CONF" ]]; then
    echo "log rotation already set ($LOGROTATE_FILE)"
  elif printf '%s\n' "$LOGROTATE_CONF" 2> /dev/null > "$LOGROTATE_FILE"; then
    chmod 644 "$LOGROTATE_FILE"
    echo "log rotation set for /var/log/bagmitra-*.log ($LOGROTATE_FILE)"
  else
    echo "note: could not write $LOGROTATE_FILE (run deploy.sh as root); job logs are not rotated"
  fi
  command -v logrotate > /dev/null || echo "note: logrotate is not installed (apt-get install logrotate)"
}

# Admin web (OPS-02, runbook docs/runbooks/admin-web.md): the "Admin web" workflow pushes each
# web build of app/lib/main_admin.dart to the admin-web-build branch. Unpack it in place into
# deploy/admin-web/ (mounted read-only into the API and served at /admin/). Never stops the
# deploy: with no build yet, /admin/ answers 404.
ADMIN_WEB_BRANCH=admin-web-build
update_admin_web() {
  local dir="$DEPLOY/admin-web"
  cd "$ROOT"
  mkdir -p "$dir"
  if ! git fetch -q origin "$ADMIN_WEB_BRANCH" 2> /dev/null; then
    echo "note: could not fetch the $ADMIN_WEB_BRANCH branch (not built yet? run the Admin web workflow); admin web left as it was"
    return 0
  fi
  if ! git cat-file -e FETCH_HEAD:index.html 2> /dev/null; then
    echo "note: $ADMIN_WEB_BRANCH has no index.html; admin web left as it was"
    return 0
  fi
  find "$dir" -mindepth 1 -delete
  git archive FETCH_HEAD | tar -x -C "$dir"
  echo "admin web: $(git log -1 --format=%s FETCH_HEAD)"
}

main() {
  case "${1:-}" in
    "" | --revert | --after-pull) ;;
    status) check_env > /dev/null; compose ps; exit 0 ;;
    *) fail "usage: bash deploy/deploy.sh [--revert|status]" ;;
  esac
  check_env
  if [[ "${1:-}" == "--after-pull" ]]; then
    echo "running the updated deploy script"
  else
    update_code "${1:-}"
    # bash already holds this run's functions from the copy it read before the pull, so a cron
    # line or step added by the pulled code would only run on the next deploy. Run the pulled
    # script for the rest instead (once: the variable stops a second re-run). A revert keeps
    # going with this script: the older one may not know --after-pull.
    if [[ -z "${1:-}" && -z "${BAGMITRA_DEPLOY_REEXEC:-}" ]]; then
      export BAGMITRA_DEPLOY_REEXEC=1
      exec bash "$DEPLOY/deploy.sh" --after-pull
    fi
  fi
  update_admin_web
  restart
  wait_healthy
  install_cron
  install_logrotate
  say "Done. Check the app, then: bash deploy/deploy.sh status"
}

# Run only when executed (tests source this file to call install_cron with a fake crontab).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
