#!/usr/bin/env bash
# Nightly database backup (OPS-06). deploy.sh installs the cron line once; by hand:
#   cd /opt/bagmitra && bash deploy/backup.sh
# Dumps schema `public` (every BagMitra table, with its RLS policies) of DATABASE_URL from
# deploy/.env with a PostgreSQL client container, gzips it into $BACKUP_DIR and deletes dumps
# older than $KEEP_DAYS days. It never prints DATABASE_URL: the value reaches the container only
# through an environment variable, never on a command line. Restore: docs/runbooks/vps-deploy.md
# section 7. Sign-in accounts live in Supabase Auth, not in this dump.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$ROOT/deploy"
ENV_FILE="$DEPLOY/.env"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/bagmitra}"
KEEP_DAYS="${KEEP_DAYS:-14}"
# pg_dump must be at least the server's major version; 17 also reads 15 and 16 servers.
PG_IMAGE="${PG_IMAGE:-postgres:17-alpine}"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

env_value() { # value of KEY in .env without printing it anywhere
  { grep -E "^$1=" "$ENV_FILE" || true; } | tail -n 1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'
}

[[ -f "$ENV_FILE" ]] || fail "$ENV_FILE is missing"
url="$(env_value DATABASE_URL)"
[[ -n "$url" ]] || fail "DATABASE_URL is empty in deploy/.env"
url="${url/postgresql+asyncpg:/postgresql:}"

# Join the API container's network, so a local database (`--profile localdb`, host `db`) is
# reachable too; Supabase is reached over the internet either way.
network=""
api_id="$(docker compose -f "$DEPLOY/docker-compose.yml" ps -q api 2> /dev/null || true)"
if [[ -n "$api_id" ]]; then
  network="$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$api_id" | awk '{print $1}')"
fi

umask 077
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
out="$BACKUP_DIR/bagmitra-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"
tmp="$out.partial"
trap 'rm -f "$tmp"' EXIT

# Tables (with their indexes and RLS policies) of `public`, not the schema itself, so a restore
# goes into the existing empty `public` (runbook section 7). No owners or grants: the
# restoring role owns everything, and the client roles get nothing (migration 0025).
PGURL="$url" docker run --rm -e PGURL ${network:+--network "$network"} "$PG_IMAGE" \
  sh -c "exec pg_dump --table='public.*' --no-owner --no-privileges \"\$PGURL\"" \
  | gzip > "$tmp" || fail "pg_dump failed; no backup written"
zcat "$tmp" | tail -n 5 | grep -q "PostgreSQL database dump complete" || fail "the dump is incomplete; no backup written"
mv "$tmp" "$out"
trap - EXIT

find "$BACKUP_DIR" -maxdepth 1 -name 'bagmitra-*.sql.gz' -mtime +"$KEEP_DAYS" -delete
echo "$(date -u +%FT%TZ) backup written: $out ($(du -h "$out" | cut -f1)); kept: $(find "$BACKUP_DIR" -maxdepth 1 -name 'bagmitra-*.sql.gz' | wc -l)"
