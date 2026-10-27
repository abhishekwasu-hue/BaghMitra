#!/usr/bin/env bash
# One-step update of the BagMitra API on the VPS. You run it on the server (nothing runs there
# for you): first install as in docs/runbooks/vps-deploy.md steps 1-4, then every time:
#   cd /opt/bagmitra && bash deploy/deploy.sh            # update to the latest main
#   cd /opt/bagmitra && bash deploy/deploy.sh --revert   # go back to the previous deploy
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
  grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'
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

restart() {
  say "Building and starting (migrations run on start; first build takes 5-10 minutes)"
  cd "$DEPLOY"
  docker compose up -d --build
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
  docker compose -f "$DEPLOY/docker-compose.yml" logs --tail 60 api || true
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
    *) fail "usage: bash deploy/deploy.sh [--revert]" ;;
  esac
  check_env
  update_code "${1:-}"
  restart
  wait_healthy
  install_cron
  say "Done. Check the app, then: docker compose -f deploy/docker-compose.yml ps"
}

main "$@"
