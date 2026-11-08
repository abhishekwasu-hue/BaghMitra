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
    this.serveUrl = '',
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  /// `owner/name`, from the build (`--dart-define=TEST_RELEASES_REPO`).
  final String repo;

  /// Our own download address (`https://<domain>/app`, kept at the newest Test APK by the VPS
  /// mirror, deploy/fetch_test_apk.sh); empty: the GitHub file itself.
  final String serveUrl;
  final http.Client _client;
  final Duration timeout;

  static final _code = RegExp(r'· code (\d+)$');

  @override
  Future<AppRelease> fetch() async {
    final res = await _client
        .get(
          Uri.https('api.github.com', '/repos/$repo/releases', {
            'per_page': '100', // audit L7: GitHub's largest page
          }),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw StateError('test release check failed: ${res.statusCode}');
    }
    // GitHub does not list releases strictly newest first: take the highest version code.
    AppRelease? best;
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
      final n = int.parse(code);
      if (best == null || n > best.latestCode) {
        best = AppRelease(
          latestCode: n,
          latestName: tag,
          minCode: 0,
          downloadUrl: serveUrl.isEmpty ? apk : serveUrl,
        );
      }
    }
    if (best != null) return best;
    throw StateError('no test release with a version code yet');
  }
}
