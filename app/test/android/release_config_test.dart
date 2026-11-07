import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release configuration that Google Play and the update path depend on (audits RL-05, BG-08).
/// Each change here is deliberate: update the reason in the manifest / gradle comment too.
void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const gradlePath = 'android/app/build.gradle.kts';

  test('only the permissions the app uses are declared (RL-05)', () {
    final manifest = File(manifestPath).readAsStringSync();
    final declared = RegExp(r'<uses-permission\s+android:name="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1)!)
        .toSet();
    expect(declared, {
      'android.permission.INTERNET', // API and sync
      'android.permission.ACCESS_FINE_LOCATION', // "Add this corner" on a block boundary
      'android.permission.ACCESS_COARSE_LOCATION', // required next to FINE on Android 12+
      'android.permission.RECORD_AUDIO', // the microphone next to a field (speech_to_text)
      'android.permission.POST_NOTIFICATIONS', // local task reminders, Android 13+
      'android.permission.RECEIVE_BOOT_COMPLETED', // reminders back after a restart
    });
  });

  test(
    'SDK levels are pinned, not taken from the Flutter defaults (RL-05)',
    () {
      final gradle = File(gradlePath).readAsStringSync();
      int level(String name) => int.parse(
        RegExp(
          '^\\s*$name = (\\d+)\$',
          multiLine: true,
        ).firstMatch(gradle)!.group(1)!,
      );
      expect(gradle, isNot(contains('flutter.targetSdkVersion')));
      expect(gradle, isNot(contains('flutter.minSdkVersion')));
      expect(gradle, isNot(contains('flutter.compileSdkVersion')));
      // Google Play: new apps and app updates target Android 16 (API 36) or higher.
      expect(level('targetSdk'), greaterThanOrEqualTo(36));
      expect(level('compileSdk'), greaterThanOrEqualTo(level('targetSdk')));
      expect(level('minSdk'), 24);
    },
  );

  test('every APK of one run carries the run number as its version code '
      '(BG-08)', () {
    for (final workflow in ['release-apk.yml', 'release-test-apk.yml']) {
      final yml = File('../.github/workflows/$workflow').readAsStringSync();
      final builds = RegExp(r'flutter build apk(?:\\\n|[^\n])*')
          .allMatches(yml)
          .map((m) => m.group(0)!)
          .toList();
      expect(builds, isNotEmpty, reason: workflow);
      for (final build in builds) {
        expect(
          build,
          contains(
            '--android-project-arg=force-version-code-ignoring-abi=true',
          ),
          reason: '$workflow: $build',
        );
      }
    }
  });

  test('only the Test APK can carry the market link, and it defaults off '
      '(spec v1.5 §5 legal gate)', () {
    const dir = '../.github/workflows';
    final testYml = File('$dir/release-test-apk.yml').readAsStringSync();
    expect(
      testYml,
      contains(r"MARKET_LINK: ${{ vars.MARKET_LINK || 'false' }}"),
      reason: "the Test APK takes MARKET_LINK from vars, default 'false'",
    );
    final defines = RegExp(r'defines="--dart-define-from-file[^"\n]*"')
        .allMatches(testYml)
        .map((m) => m.group(0)!)
        .toList();
    expect(
      defines,
      hasLength(1),
      reason: 'one base define list feeds every build',
    );
    expect(
      defines.single,
      contains(r'--dart-define=MARKET_LINK=$MARKET_LINK'),
    );
    final builds = RegExp(r'flutter build apk(?:\\\n|[^\n])*')
        .allMatches(testYml)
        .map((m) => m.group(0)!)
        .toList();
    expect(builds, isNotEmpty);
    for (final build in builds) {
      expect(build, contains(r'$defines'), reason: build);
    }

    final releaseYml = File('$dir/release-apk.yml').readAsStringSync();
    expect(
      releaseYml,
      isNot(contains('MARKET_LINK')),
      reason: 'the production release APK never carries the market link',
    );
  });
}
