import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/app_update.dart';
import 'app_update_checker.dart';

/// The newest Test APK on the repository's GitHub releases (owner 2026-11-08: the app is not
/// on Google Play yet, so the test build tells the owner itself when a newer one exists).
///
/// The Test APK workflow titles each pre-release `Test build <tag> · code <run number>`; the
/// run number is every APK's version code, so the existing update notice compares it with
/// the installed one. The universal APK is offered: it installs on every phone. Public
/// repository, no key; nothing is sent about the user.
class GitHubTestReleaseSource implements AppVersionSource {
  GitHubTestReleaseSource(
    this.repo, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  /// `owner/name`, from the build (`--dart-define=TEST_RELEASES_REPO`).
  final String repo;
  final http.Client _client;
  final Duration timeout;

  static final _code = RegExp(r'· code (\d+)$');

  @override
  Future<AppRelease> fetch() async {
    final res = await _client
        .get(
          Uri.https('api.github.com', '/repos/$repo/releases', {
            'per_page': '10',
          }),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw StateError('test release check failed: ${res.statusCode}');
    }
    for (final r
        in (jsonDecode(res.body) as List).cast<Map<String, dynamic>>()) {
      final tag = r['tag_name'] as String? ?? '';
      final code = _code.firstMatch(r['name'] as String? ?? '')?.group(1);
      if (!tag.startsWith('test-') || code == null) continue;
      final assets = (r['assets'] as List? ?? []).cast<Map<String, dynamic>>();
      final apk = assets
          .map((a) => a['browser_download_url'] as String? ?? '')
          .where((u) => u.endsWith('-universal.apk'))
          .firstOrNull;
      if (apk == null) continue; // still uploading
      return AppRelease(
        latestCode: int.parse(code),
        latestName: tag,
        minCode: 0,
        downloadUrl: apk,
      );
    }
    throw StateError('no test release with a version code yet');
  }
}
