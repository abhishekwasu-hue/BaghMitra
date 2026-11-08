import 'dart:convert';

import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/features/app_update/data/app_update_providers.dart';
import 'package:bagmitra/features/app_update/data/test_release_source.dart';
import 'package:bagmitra/features/app_update/domain/app_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _repo = 'owner/BaghMitra';

Map<String, Object?> _release(String tag, String name, {bool apk = true}) => {
  'tag_name': tag,
  'name': name,
  'prerelease': true,
  'assets': [
    if (apk) ...[
      {
        'browser_download_url':
            'https://github.com/$_repo/releases/download/$tag/a-arm64-v8a.apk',
      },
      {
        'browser_download_url':
            'https://github.com/$_repo/releases/download/$tag/a-universal.apk',
      },
    ],
  ],
};

GitHubTestReleaseSource _source(
  List<Map<String, Object?>> releases,
  List<Uri> asked,
) => GitHubTestReleaseSource(
  _repo,
  client: MockClient((req) async {
    asked.add(req.url);
    return http.Response(jsonEncode(releases), 200);
  }),
);

void main() {
  test('the newest test release with a code and its universal APK', () async {
    final asked = <Uri>[];
    final release = await _source([
      _release(
        'test-20261108-aaaa111',
        'Test build test-20261108-aaaa111 · code 412',
        apk: false,
      ),
      _release(
        'test-20261108-bbbb222',
        'Test build test-20261108-bbbb222 · code 411',
      ),
      _release('test-20261107-cccc333', 'Test build test-20261107-cccc333'),
    ], asked).fetch();
    expect(
      asked.single.toString(),
      'https://api.github.com/repos/$_repo/releases?per_page=10',
    );
    expect(release.latestCode, 411); // 412 is still uploading its files
    expect(release.latestName, 'test-20261108-bbbb222');
    expect(
      release.downloadUrl,
      endsWith('/test-20261108-bbbb222/a-universal.apk'),
    );
    expect(updateNeed(410, release), UpdateNeed.available);
    expect(updateNeed(411, release), UpdateNeed.none);
  });

  test('the highest code wins whatever order GitHub lists them in', () async {
    final release = await _source([
      _release(
        'test-20261108-old0001',
        'Test build test-20261108-old0001 · code 148',
      ),
      _release(
        'test-20261109-new0002',
        'Test build test-20261109-new0002 · code 151',
      ),
      _release(
        'test-20261108-mid0003',
        'Test build test-20261108-mid0003 · code 149',
      ),
    ], []).fetch();
    expect(release.latestCode, 151);
    expect(release.latestName, 'test-20261109-new0002');
  });

  test(
    'the button opens our own /app/test address when the build has one',
    () async {
      expect(
        testApkServeUrl('https://bagmitra.aialgodesk.org'),
        'https://bagmitra.aialgodesk.org/app/test',
      );
      expect(testApkServeUrl('http://10.0.2.2:8000'), '');
      final release = await GitHubTestReleaseSource(
        _repo,
        serveUrl: 'https://bagmitra.aialgodesk.org/app/test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              _release('test-1-a', 'Test build test-1-a · code 150'),
            ]),
            200,
          ),
        ),
      ).fetch();
      expect(release.downloadUrl, 'https://bagmitra.aialgodesk.org/app/test');
      expect(release.latestCode, 150);
    },
  );

  test('older releases without a code are no answer (silent)', () async {
    final source = _source([
      _release('test-20261107-cccc333', 'Test build x'),
    ], []);
    expect(source.fetch, throwsStateError);
  });

  test(
    'test builds check GitHub; release builds keep the server; demo nothing',
    () {
      AppConfig config({
        String test = '',
        String repo = '',
        bool demo = false,
      }) => AppConfig(
        productName: 'BagMitra',
        apiBaseUrl: 'https://api.test',
        supabaseUrl: demo ? '' : 'https://x.supabase.co',
        supabaseAnonKey: demo ? '' : 'anon',
        devGallery: false,
        testBuild: test,
        speechEngine: 'on_device',
        testReleasesRepo: repo,
      );
      expect(
        updateSourceKind(config(test: 'abc1234', repo: _repo)),
        UpdateSourceKind.github,
      );
      expect(updateSourceKind(config(test: 'abc1234')), UpdateSourceKind.none);
      expect(updateSourceKind(config()), UpdateSourceKind.server);
      expect(updateSourceKind(config(demo: true)), UpdateSourceKind.none);
    },
  );
}
