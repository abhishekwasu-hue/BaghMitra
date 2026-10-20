#!/usr/bin/env bash
# Boots a headless emulator (API 33, pixel_5, 2 GB RAM), runs the integration tests and keeps every
# log under ../emulator-shots so a failure can be read from the PR. Run from the app/ directory.
set -u
shots=../emulator-shots
mkdir -p "$shots"
log="$shots/run.log"
exec > >(tee -a "$log") 2>&1
sdk="${ANDROID_HOME:-/usr/local/lib/android/sdk}"
export PATH="$sdk/emulator:$sdk/platform-tools:$sdk/cmdline-tools/latest/bin:$PATH"
image="system-images;android-33;google_apis;x86_64"

echo "== install image"; df -h / | tail -1
yes | sdkmanager --licenses > /dev/null 2>&1
sdkmanager --install "$image" "emulator" "platform-tools" > "$shots/sdkmanager.log" 2>&1 || {
  echo "sdkmanager failed"
  tr '\r' '\n' < "$shots/sdkmanager.log" | grep -iE "error|fail|space|exception|warning: an error" | sort -u | head -n 10
  df -h / | tail -1
  exit 1
}
df -h / | tail -1

echo "== create avd"
export ANDROID_AVD_HOME="$HOME/.android/avd"
mkdir -p "$ANDROID_AVD_HOME"
echo no | avdmanager create avd -n ci -k "$image" -d pixel_5 --force || { echo "avdmanager failed"; exit 1; }
emulator -list-avds
[ -f "$ANDROID_AVD_HOME/ci.avd/config.ini" ] || { echo "no config.ini in $ANDROID_AVD_HOME"; ls -la "$ANDROID_AVD_HOME" "$HOME/.android" 2>&1 | head -n 20; exit 1; }
printf 'hw.ramSize=2048\ndisk.dataPartition.size=4096M\n' >> "$ANDROID_AVD_HOME/ci.avd/config.ini"

# Build first: a Gradle build next to a running emulator exhausts the runner (and the image is installed
# before the build so the disk is not already full by then).
echo "== build debug apk"
flutter build apk --debug --dart-define-from-file=../product.env || { echo "apk build failed"; exit 1; }
df -h / | tail -1

# The release build is the heaviest (R8); like the debug build it must finish before the emulator
# starts, or the two together exhaust the runner's memory and the runner dies mid-job.
echo "== build release apk"
flutter build apk --release --target-platform android-x64 --dart-define-from-file=../product.env || { echo "release build failed"; exit 1; }
free -m | head -2

boot_emulator() {
  nohup emulator -avd ci -no-window -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim -no-metrics \
    > "$shots/emulator-$1.log" 2>&1 &
  timeout 120 adb wait-for-device || return 1
  for _ in $(seq 1 120); do
    [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && return 0
    sleep 5
  done
  return 1
}

# A cold boot without a snapshot is sometimes very slow on a shared runner, so give it two tries.
echo "== start emulator"
if ! boot_emulator 1; then
  echo "boot attempt 1 timed out, retrying"
  adb emu kill > /dev/null 2>&1; pkill -f qemu-system > /dev/null 2>&1; sleep 5
  boot_emulator 2 || { echo "boot timed out twice"; tail -n 20 "$shots/emulator-2.log"; exit 1; }
fi
echo "booted"
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0

echo "== tests"
adb logcat -c
timeout 900 flutter test integration_test --dart-define-from-file=../product.env 2>&1 | tee "$shots/test.log"
status=${PIPESTATUS[0]}
adb exec-out screencap -p > "$shots/final.png"
adb logcat -d -t 2000 > "$shots/logcat.txt"
echo "tests exit status $status"
[ "$status" -eq 0 ] || exit "$status"

# Release-only crashes (R8 stripping a class a plugin needs, a missing permission) never show in
# debug tests, so install the real release build and make sure the app opens and stays up.
echo "== release smoke test"
adb uninstall app.bagmitra.bagmitra > /dev/null 2>&1
adb install -r build/app/outputs/flutter-apk/app-release.apk || { echo "release install failed"; exit 1; }
adb logcat -c
adb shell monkey -p app.bagmitra.bagmitra -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 20
adb exec-out screencap -p > "$shots/release-home.png"
adb logcat -d > "$shots/release-logcat.txt"
if [ -z "$(adb shell pidof app.bagmitra.bagmitra | tr -d '\r')" ]; then
  echo "release app is not running"; grep -E "FATAL|AndroidRuntime" "$shots/release-logcat.txt" | head -n 20; exit 1
fi
if grep -q "FATAL EXCEPTION" "$shots/release-logcat.txt"; then
  echo "release app crashed"; grep -A12 "FATAL EXCEPTION" "$shots/release-logcat.txt" | head -n 30; exit 1
fi
echo "release app opened and stayed up"
exit 0
