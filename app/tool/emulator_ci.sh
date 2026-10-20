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
echo no | avdmanager create avd -n ci -k "$image" -d pixel_5 --force || exit 1
printf 'hw.ramSize=2048\ndisk.dataPartition.size=4096M\n' >> "$HOME/.android/avd/ci.avd/config.ini"

# Build first: a Gradle build next to a running emulator exhausts the runner (and the image is installed
# before the build so the disk is not already full by then).
echo "== build debug apk"
flutter build apk --debug --dart-define-from-file=../product.env || { echo "apk build failed"; exit 1; }
df -h / | tail -1

echo "== start emulator"
nohup emulator -avd ci -no-window -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim -no-metrics \
  > "$shots/emulator.log" 2>&1 &
timeout 120 adb wait-for-device || { echo "no device"; tail -n 20 "$shots/emulator.log"; exit 1; }
for i in $(seq 1 90); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] || { echo "boot timed out"; tail -n 20 "$shots/emulator.log"; exit 1; }
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
exit "$status"
