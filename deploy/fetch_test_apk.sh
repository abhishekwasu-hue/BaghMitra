#!/usr/bin/env bash
# APK mirror (owner 2026-11-08): keeps https://<domain>/app at the newest APK so the app's update
# button and the link sent to growers use our own address, not GitHub.
# Cron (deploy.sh): every 15 minutes, when TEST_APK_MIRROR=on or RELEASE_APK_MIRROR=on in .env.
# - RELEASE_APK_MIRROR=on: the newest Release APK (arm64-v8a, release key); also writes
#   release.json {code, name}, which GET /v1/app/version reads, so no APP_LATEST_VERSION_* by hand.
# - otherwise TEST_APK_MIRROR=on: the newest Test APK (universal). Once a Release APK has been
#   served here, the test mirror never replaces it.
# Asks the API container for the newest release of the channel (bagmitra_api.app_mirror.latest),
# downloads only a newer version code, checks the size and moves the file in one step. Never
# touches the served file when anything fails.
set -euo pipefail
DEPLOY="$(cd "$(dirname "$0")" && pwd)"
DIR="${APK_DIR:-/srv/bagmitra-apk}"
REPO="${TEST_APK_REPO:-abhishekwasu-hue/BaghMitra}"
cd "$DEPLOY"
env_on() { grep -qiE "^$1=on\$" "$DEPLOY/.env" 2>/dev/null; }
channel=test
if env_on RELEASE_APK_MIRROR; then
  channel=release
elif [[ -f "$DIR/release-code" ]]; then
  echo "a Release APK is served at /app; the test mirror leaves it"; exit 0
fi
read -r code url name < <(docker compose exec -T api python -m bagmitra_api.app_mirror.latest "$REPO" "$channel")
[[ "$code" =~ ^[0-9]+$ && "$url" == https://github.com/* ]] || { echo "no $channel APK found"; exit 1; }
have="$(cat "$DIR/$channel-code" 2>/dev/null || echo 0)"
if [[ "$code" -le "$have" ]]; then echo "$channel APK code $have is current"; exit 0; fi
mkdir -p "$DIR"
curl -fsSL -o "$DIR/bagmitra.apk.new" "$url"
[[ "$(stat -c %s "$DIR/bagmitra.apk.new")" -gt 10000000 ]] || { rm -f "$DIR/bagmitra.apk.new"; echo "download too small"; exit 1; }
chmod 644 "$DIR/bagmitra.apk.new"
mv "$DIR/bagmitra.apk.new" "$DIR/bagmitra.apk"
if [[ "$channel" == release ]]; then
  [[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || name="$code"
  printf '{"code": %s, "name": "%s"}\n' "$code" "$name" > "$DIR/release.json.new"
  chmod 644 "$DIR/release.json.new"
  mv "$DIR/release.json.new" "$DIR/release.json"
fi
echo "$code" > "$DIR/$channel-code"
echo "$channel APK code $code now served at /app"
