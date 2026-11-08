import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config.dart';
import '../domain/app_update.dart';
import 'app_update_checker.dart';
import 'test_release_source.dart';

enum UpdateSourceKind { server, github, none }

/// Release APK: our server (`GET /v1/app/version`). Test APK: its GitHub pre-releases (a
/// test-key APK cannot install the server's release-key APK, audit BG-07). Demo: nothing.
UpdateSourceKind updateSourceKind(AppConfig config) {
  if (config.demoMode) return UpdateSourceKind.none;
  if (!config.isTestBuild) return UpdateSourceKind.server;
  return config.testReleasesRepo.isEmpty
      ? UpdateSourceKind.none
      : UpdateSourceKind.github;
}

/// `https://<api domain>/app/test` (owner 2026-11-08: our own address, not GitHub; audit H1:
/// the Test APK file, never the Release APK at `/app`); empty for a build without an https
/// server (the GitHub file is offered then).
String testApkServeUrl(String apiBaseUrl) {
  final base = Uri.tryParse(apiBaseUrl);
  if (base == null || base.scheme != 'https' || base.host.isEmpty) return '';
  return '${base.origin}/app/test';
}

final appVersionSourceProvider = Provider<AppVersionSource>((ref) {
  final config = ref.watch(appConfigProvider);
  return updateSourceKind(config) == UpdateSourceKind.github
      ? GitHubTestReleaseSource(
          config.testReleasesRepo,
          serveUrl: testApkServeUrl(config.apiBaseUrl),
        )
      : ApiAppVersionSource(ref.watch(apiProvider));
});

final installedVersionCodeProvider = Provider<InstalledVersionCode>(
  (ref) => platformVersionCode,
);

final urlOpenerProvider = Provider<UrlOpener>((ref) => openInBrowser);

/// Off in demo builds (nothing to ask) and in test builds without the releases repository.
/// A test build checks every 6 hours (new test APKs come several times a day).
final appUpdateCheckerProvider = Provider<AppUpdateChecker?>((ref) {
  final config = ref.watch(appConfigProvider);
  final kind = updateSourceKind(config);
  if (kind == UpdateSourceKind.none) return null;
  return AppUpdateChecker(
    interval: kind == UpdateSourceKind.github
        ? const Duration(hours: 6)
        : const Duration(hours: 24),
    source: ref.watch(appVersionSourceProvider),
    db: ref.watch(databaseProvider),
    installedCode: ref.watch(installedVersionCodeProvider),
    clock: ref.watch(clockProvider),
  );
});

/// Checked once when the app starts.
final appUpdateProvider = FutureProvider<AppUpdateState>((ref) async {
  final checker = ref.watch(appUpdateCheckerProvider);
  if (checker == null) return AppUpdateState.none;
  try {
    return await checker.check();
  } on Object {
    return AppUpdateState.none;
  }
});

/// The installed APK's version name and code for Settings; null when it cannot be read.
final installedVersionProvider = FutureProvider<({String name, int code})?>((
  ref,
) async {
  final read = ref.watch(installedVersionNameProvider);
  return read();
});

typedef InstalledVersionName = Future<({String name, int code})?> Function();

final installedVersionNameProvider = Provider<InstalledVersionName>(
  (ref) => platformVersion,
);
