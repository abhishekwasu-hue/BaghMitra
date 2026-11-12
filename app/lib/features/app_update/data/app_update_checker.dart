import 'dart:async';
import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../domain/app_update.dart';

/// Asks the server which app version is the latest and which is the oldest still allowed.
abstract interface class AppVersionSource {
  Future<AppRelease> fetch();
}

class ApiAppVersionSource implements AppVersionSource {
  ApiAppVersionSource(this._api, {this.timeout = const Duration(seconds: 10)});

  final Bagmitra _api;
  final Duration timeout;

  @override
  Future<AppRelease> fetch() async {
    final resp = await _api.v1AppVersionGet().timeout(timeout);
    final body = resp.body;
    if (!resp.isSuccessful || body == null) {
      throw StateError('app version check failed: ${resp.statusCode}');
    }
    return AppRelease(
      latestCode: body.latestVersionCode,
      latestName: body.latestVersionName,
      minCode: body.minVersionCode,
      downloadUrl: body.downloadUrl,
    );
  }
}

/// The installed APK's version code (Android `versionCode`); 0 when it cannot be read.
typedef InstalledVersionCode = Future<int> Function();

Future<int> platformVersionCode() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  } on Object {
    return 0;
  }
}

Future<({String name, int code})?> platformVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return (name: info.version, code: int.tryParse(info.buildNumber) ?? 0);
  } on Object {
    return null;
  }
}

/// Opens the download link in the phone's browser; false when no app could open it.
typedef UrlOpener = Future<bool> Function(Uri url);

Future<bool> openInBrowser(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}

/// Checks on start, asking the server at most once per [interval]; between checks (and when
/// offline) the last answer from the server is used. Every failure is silent.
class AppUpdateChecker {
  AppUpdateChecker({
    required this.source,
    required this.db,
    required this.installedCode,
    required this.clock,
    this.interval = const Duration(hours: 1),
  });

  static const cacheKey = 'app_update.release';

  final AppVersionSource source;
  final AppDatabase db;
  final InstalledVersionCode installedCode;
  final Clock clock;
  final Duration interval;

  Future<AppUpdateState> check() async {
    final installed = await installedCode();
    if (installed <= 0) return AppUpdateState.none;
    final cached = await _readCache();
    var release = cached?.release;
    final now = clock();
    if (cached == null || now.difference(cached.checkedAt) >= interval) {
      try {
        release = await source.fetch();
        await db.writeMeta(
          cacheKey,
          jsonEncode({
            'checked_at': now.toIso8601String(),
            'release': release.toJson(),
          }),
        );
      } on Object {
        // Offline or the server is away: keep the last answer, say nothing.
      }
    }
    if (release == null) return AppUpdateState.none;
    return AppUpdateState(updateNeed(installed, release), release);
  }

  Future<({DateTime checkedAt, AppRelease release})?> _readCache() async {
    try {
      final raw = await db.readMeta(cacheKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, Object?>;
      return (
        checkedAt: DateTime.parse(json['checked_at']! as String),
        release: AppRelease.fromJson(json['release']! as Map<String, Object?>),
      );
    } on Object {
      return null;
    }
  }
}
