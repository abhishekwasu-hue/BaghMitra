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
    expect(defines.single, contains(r'--dart-define=MARKET_LINK=$MARKET_LINK'));
    final builds = RegExp(r'flutter build apk(?:\\\n|[^\n])*')
        .allMatches(testYml)
        .map((m) => m.group(0)!)
        .toList();
    expect(builds, isNotEmpty);
    for (final build in builds) {
      expect(build, contains(r'$defines'), reason: build);
    }

    final releaseYml = File('$dir/release-apk.yml').readAsStringSync();
    // Owner 2026-11-08 ("1 b"): the Release APK carries the market link too, from the same
    // repository variable as the Test APK (default 'false'); spec v1.5 §5 records still pending.
    expect(
      releaseYml,
      contains(r"MARKET_LINK: ${{ vars.MARKET_LINK || 'false' }}"),
      reason: "the Release APK takes MARKET_LINK from vars, default 'false'",
    );
    expect(releaseYml, contains(r'--dart-define=MARKET_LINK="$MARKET_LINK"'));
  });

  test('the Test APK carries the Sarkari Sandesh feed (owner 2026-11-08), '
      'switchable by a repository variable', () {
    final testYml = File('../.github/workflows/release-test-apk.yml')
        .readAsStringSync();
    expect(
      testYml,
      contains(r"SARKARI_SANDESH: ${{ vars.SARKARI_SANDESH || 'on' }}"),
    );
    final defines = RegExp(r'defines="--dart-define-from-file[^"\n]*"')
        .firstMatch(testYml)!
        .group(0)!;
    expect(
      defines,
      contains(r'--dart-define=SARKARI_SANDESH=$SARKARI_SANDESH'),
    );
  });

  test('Release notes ask for nothing in .env: the VPS mirror updates /app '
      'and release.json (audit L6)', () {
    final releaseYml = File('../.github/workflows/release-apk.yml')
        .readAsStringSync();
    // Setting APP_LATEST_VERSION_CODE would make /v1/app/version ignore release.json.
    expect(releaseYml, isNot(contains('APP_LATEST_VERSION_CODE')));
    expect(releaseYml, contains('nothing to set in .env'));
  });

  test('the Release APK signer is compared with RELEASE_CERT_SHA256; unset '
      'only warns (audit L5)', () {
    final releaseYml = File('../.github/workflows/release-apk.yml')
        .readAsStringSync();
    expect(
      releaseYml,
      contains(
        r'RELEASE_CERT_SHA256: ${{ vars.RELEASE_CERT_SHA256 || '
        "'C4:90:F1:8E:7B:80:C1:B3:1D:50:9B:C9:26:1C:5E:DF:1B:E4:31:74:30:3E:47:B0:B0:56:0A:BE:15:6A:A8:BA' }}",
      ),
    );
    expect(releaseYml, contains('::warning::RELEASE_CERT_SHA256 is not set'));
    expect(releaseYml, contains('is not the release key'));
  });

  group('Play App Bundle (pre-launch checklist §A "App bundle")', () {
    final yml = File('../.github/workflows/release-apk.yml').readAsStringSync();

    /// The text of one workflow step, from its `- name:` line to the next step.
    String step(String name) {
      final start = yml.indexOf('      - name: $name\n');
      expect(start, isNot(-1), reason: 'step "$name"');
      final next = yml.indexOf(RegExp(r'\n      - '), start + 1);
      return yml.substring(start, next == -1 ? yml.length : next);
    }

    /// The `env:` lines of a step (comments dropped), and its dart-define arguments.
    Set<String> envOf(String text) =>
        RegExp(r'^          (\w+): (.+)$', multiLine: true)
            .allMatches(text.split('        run: |').first)
            .map((m) => '${m.group(1)}=${m.group(2)}')
            .toSet();
    Set<String> definesOf(String text) =>
        RegExp(r'--dart-define[^\s\\]*')
            .allMatches(text)
            .map((m) => m.group(0)!)
            .toSet();

    test(
      'built with the same key, run number and dart-defines as the APKs',
      () {
        final apk = step('Build production APKs');
        final aab = step('Build Play App Bundle');
        expect(
          RegExp('flutter build appbundle --release').allMatches(yml),
          hasLength(1),
        );
        expect(envOf(aab), envOf(apk));
        expect(
          envOf(aab),
          contains(r'BUILD_NUMBER=${{ steps.meta.outputs.code }}'),
        );
        expect(
          envOf(aab),
          contains(r'RELEASE_KEY_ALIAS=${{ secrets.RELEASE_KEY_ALIAS }}'),
        );
        expect(definesOf(aab), definesOf(apk));
        expect(
          definesOf(aab),
          contains(r'--dart-define=MARKET_LINK="$MARKET_LINK"'),
        );
        for (final flag in [
          r'--build-number="$BUILD_NUMBER"',
          r'--build-name="$BUILD_NAME"',
          '--obfuscate',
        ]) {
          expect(aab, contains(flag));
        }
      },
    );

    test(
      'its signature and version code are checked; the debug key is refused',
      () {
        final check = step('Check the App Bundle');
        expect(check, contains('jarsigner -verify'));
        expect(check, contains('CN=Android Debug'));
        expect(check, contains(r'$RELEASE_CERT_SHA256'));
        expect(check, contains('versionCode'));
        expect(check, contains('GITHUB_STEP_SUMMARY'));
      },
    );

    test('it is a 30-day workflow artifact only: never on the public release, '
        'never sent to Play', () {
      expect(
        yml,
        contains(
          r'name: bagmitra-play-${{ steps.meta.outputs.name }}-'
          r'${{ steps.meta.outputs.code }}.aab',
        ),
      );
      final upload = yml.substring(yml.indexOf('name: bagmitra-play-'));
      expect(
        upload.substring(0, upload.indexOf('\n      - ')),
        contains('retention-days: 30'),
      );
      expect(step('Publish release'), isNot(contains('.aab')));
      expect(step('Publish release'), isNot(contains('play-files')));
      expect(yml.toLowerCase(), isNot(contains('androidpublisher')));
      expect(yml, isNot(contains('upload-google-play')));
    });
  });
}
