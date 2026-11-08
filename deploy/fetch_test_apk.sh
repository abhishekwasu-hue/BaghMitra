#!/usr/bin/env bash
# Test APK mirror (owner 2026-11-08): keeps https://<domain>/app at the newest Test APK so the
# app's update button and the link sent to friends use our own address, not GitHub.
# Cron (deploy.sh, only with TEST_APK_MIRROR=on in deploy/.env): every 15 minutes.
# Asks the API container for the newest coded test release (bagmitra_api.app_mirror.latest),
# downloads it only when its version code is newer than the one served, checks the size and
# replaces the file in one move. Never touches the file when anything fails.
set -euo pipefail
DEPLOY="$(cd "$(dirname "$0")" && pwd)"
DIR="${APK_DIR:-/srv/bagmitra-apk}"
REPO="${TEST_APK_REPO:-abhishekwasu-hue/BaghMitra}"
cd "$DEPLOY"
read -r code url < <(docker compose exec -T api python -m bagmitra_api.app_mirror.latest "$REPO")
[[ "$code" =~ ^[0-9]+$ && "$url" == https://github.com/* ]] || { echo "no test release found"; exit 1; }
have="$(cat "$DIR/test-code" 2>/dev/null || echo 0)"
if [[ "$code" -le "$have" ]]; then echo "test APK code $have is current"; exit 0; fi
mkdir -p "$DIR"
curl -fsSL -o "$DIR/bagmitra.apk.new" "$url"
[[ "$(stat -c %s "$DIR/bagmitra.apk.new")" -gt 20000000 ]] || { rm -f "$DIR/bagmitra.apk.new"; echo "download too small"; exit 1; }
chmod 644 "$DIR/bagmitra.apk.new"
mv "$DIR/bagmitra.apk.new" "$DIR/bagmitra.apk"
echo "$code" > "$DIR/test-code"
echo "test APK code $code now served at /app"
