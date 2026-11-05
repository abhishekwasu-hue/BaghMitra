import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/app_update.dart';
import 'app_update_checker.dart';

final appVersionSourceProvider = Provider<AppVersionSource>(
  (ref) => ApiAppVersionSource(ref.watch(apiProvider)),
);

final installedVersionCodeProvider = Provider<InstalledVersionCode>(
  (ref) => platformVersionCode,
);

final urlOpenerProvider = Provider<UrlOpener>((ref) => openInBrowser);

/// Off in test builds (a test-key APK cannot install the release-key APK over itself, audit
/// BG-07) and in demo builds (no server to ask).
final appUpdateCheckerProvider = Provider<AppUpdateChecker?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.isTestBuild || config.demoMode) return null;
  return AppUpdateChecker(
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
