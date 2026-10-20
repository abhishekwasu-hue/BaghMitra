#!/usr/bin/env bash
# Runs the integration tests on the emulator started by android-emulator-runner (which executes
# each script line in its own shell, hence this file). Keeps logs and a screenshot either way.
set -u
shots=../emulator-shots
mkdir -p "$shots"
adb logcat -c
timeout 900 flutter test integration_test --dart-define-from-file=../product.env 2>&1 | tee "$shots/test.log"
status=${PIPESTATUS[0]}
adb exec-out screencap -p > "$shots/final.png"
adb logcat -d -t 2000 > "$shots/logcat.txt"
exit "$status"
