#!/usr/bin/env bash
# APK mirror (owner 2026-11-08): keeps our own addresses at the newest APKs so the app's update
# button and the link sent to growers use our own address, not GitHub.
# Cron (deploy.sh): every 15 minutes, when TEST_APK_MIRROR=on or RELEASE_APK_MIRROR=on in .env.
# Two channels in two files (audit H1: a Test APK cannot install a Release APK, and back):
# - RELEASE_APK_MIRROR=on: the newest Release APK (arm64-v8a, release key) → bagmitra.apk
#   (GET /app), release-code, and release.json {code, name}, which GET /v1/app/version reads.
# - TEST_APK_MIRROR=on: the newest Test APK (universal) → bagmitra-test.apk (GET /app/test),
#   test-code. It never touches the Release files.
# Asks the API container for the newest release of each channel (bagmitra_api.app_mirror.latest),
# downloads only a newer version code, checks the size and that the file's SHA-256 equals
# GitHub's asset digest (audit L5), and moves the file in one step. Never touches a served file
# when anything fails.
set -euo pipefail
DEPLOY="$(cd "$(dirname "$0")" && pwd)"
DIR="${APK_DIR:-/srv/bagmitra-apk}"
REPO="${TEST_APK_REPO:-abhishekwasu-hue/BaghMitra}"
cd "$DEPLOY"
env_on() { grep -qiE "^$1=on\$" "$DEPLOY/.env" 2>/dev/null; }

# mirror <channel> <served file name>
mirror() {
  local channel="$1" file="$2" code url sha name have got
  read -r code url sha name < <(docker compose exec -T api python -m bagmitra_api.app_mirror.latest "$REPO" "$channel") || true
  [[ "${code:-}" =~ ^[0-9]+$ && "${url:-}" == https://github.com/* ]] || { echo "no $channel APK found"; return 1; }
  [[ "${sha:-}" =~ ^[0-9a-f]{64}$ ]] || { echo "no checksum for the $channel APK; not served"; return 1; }
  have=0
  [[ -f "$DIR/$file" ]] && have="$(cat "$DIR/$channel-code" 2>/dev/null || echo 0)"
  if [[ "$code" -le "$have" ]]; then echo "$channel APK code $have is current"; return 0; fi
  mkdir -p "$DIR"
  curl -fsSL -o "$DIR/$file.new" "$url" || { rm -f "$DIR/$file.new"; echo "$channel download failed"; return 1; }
  [[ "$(stat -c %s "$DIR/$file.new")" -gt 10000000 ]] || { rm -f "$DIR/$file.new"; echo "$channel download too small"; return 1; }
  got="$(sha256sum "$DIR/$file.new" | cut -d' ' -f1)"
  [[ "$got" == "$sha" ]] || { rm -f "$DIR/$file.new"; echo "$channel checksum mismatch; not served"; return 1; }
  chmod 644 "$DIR/$file.new"
  mv "$DIR/$file.new" "$DIR/$file"
  if [[ "$channel" == release ]]; then
    [[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || name="$code"
    printf '{"code": %s, "name": "%s"}\n' "$code" "$name" > "$DIR/release.json.new"
    chmod 644 "$DIR/release.json.new"
    mv "$DIR/release.json.new" "$DIR/release.json"
  fi
  echo "$code" > "$DIR/$channel-code"
  echo "$channel APK code $code now served at /app${3:-}"
}

failed=0
if env_on RELEASE_APK_MIRROR; then mirror release bagmitra.apk || failed=1; fi
if env_on TEST_APK_MIRROR; then mirror test bagmitra-test.apk /test || failed=1; fi
exit "$failed"
