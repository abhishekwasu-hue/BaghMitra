#!/usr/bin/env bash
# One-step update of the BagMitra API on the VPS. You run it on the server (nothing runs there
# for you): first install as in docs/runbooks/vps-deploy.md steps 1-4, then every time:
#   cd /opt/bagmitra && bash deploy/deploy.sh            # update to the latest main
#   cd /opt/bagmitra && bash deploy/deploy.sh --revert   # go back to the previous deploy
# If another project's Caddy already owns ports 80/443, set EDGE_NETWORK=edge in .env: BagMitra
# then runs without its own Caddy and joins that shared network (docker-compose.shared-caddy.yml,
# runbook "Sharing the server").
# It checks .env, pulls the code, rebuilds and restarts the containers (migrations run on
# start), waits until https://$API_DOMAIN/health/live answers, and adds the daily weather
# cron line once. It never prints .env values.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$ROOT/deploy"
ENV_FILE="$DEPLOY/.env"
PREVIOUS="$DEPLOY/.previous_commit"
CRON_LINE="0 0 * * * cd $DEPLOY && docker compose exec -T api python -m bagmitra_api.weather.pull_job >> /var/log/bagmitra-weather-pull.log 2>&1"
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
  url="https://$domain/health/live"
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

install_cron() {
  command -v crontab > /dev/null || { echo "note: crontab not found, add the weather line by hand (runbook 6a)"; return; }
  if crontab -l 2> /dev/null | grep -Fq "bagmitra_api.weather.pull_job"; then
    echo "weather cron line already present"
  else
    (crontab -l 2> /dev/null || true; echo "$CRON_LINE") | crontab -
    echo "weather cron line added (daily 00:00 UTC = 05:30 IST)"
  fi
}

main() {
  case "${1:-}" in
    "" | --revert) ;;
    status) check_env > /dev/null; compose ps; exit 0 ;;
    *) fail "usage: bash deploy/deploy.sh [--revert|status]" ;;
  esac
  check_env
  update_code "${1:-}"
  restart
  wait_healthy
  install_cron
  say "Done. Check the app, then: bash deploy/deploy.sh status"
}

main "$@"
