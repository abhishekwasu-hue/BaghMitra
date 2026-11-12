import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/app_update/data/app_update_checker.dart';
import 'package:bagmitra/features/app_update/data/app_update_providers.dart';
import 'package:bagmitra/features/app_update/domain/app_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';

const _release = AppRelease(
  latestCode: 12,
  latestName: '1.2.0',
  minCode: 8,
  downloadUrl: 'https://api.example.test/app',
);

/// Answers from memory; `offline` makes every call fail like a phone without network.
class FakeVersionSource implements AppVersionSource {
  FakeVersionSource([this.release = _release]);

  AppRelease release;
  bool offline = false;
  int calls = 0;

  @override
  Future<AppRelease> fetch() async {
    calls++;
    if (offline) throw StateError('offline');
    return release;
  }
}

/// Records the links the app tried to open.
class FakeOpener {
  FakeOpener({this.opens = true});

  final bool opens;
  final opened = <Uri>[];

  Future<bool> call(Uri url) async {
    opened.add(url);
    return opens;
  }
}

const _realBuild = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: 'https://x.supabase.co',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
);

void main() {
  group('updateNeed', () {
    test('below the minimum blocks, below the latest offers, else nothing', () {
      expect(updateNeed(7, _release), UpdateNeed.required);
      expect(updateNeed(8, _release), UpdateNeed.available);
      expect(updateNeed(11, _release), UpdateNeed.available);
      expect(updateNeed(12, _release), UpdateNeed.none);
      expect(updateNeed(13, _release), UpdateNeed.none);
    });

    test('an unknown installed version or an unset server shows nothing', () {
      expect(updateNeed(0, _release), UpdateNeed.none);
      const unset = AppRelease(
        latestCode: 0,
        latestName: '',
        minCode: 0,
        downloadUrl: 'https://api.example.test/app',
      );
      expect(updateNeed(5, unset), UpdateNeed.none);
      const noLink = AppRelease(
        latestCode: 12,
        latestName: '1.2.0',
        minCode: 12,
        downloadUrl: '',
      );
      expect(updateNeed(5, noLink), UpdateNeed.none);
    });
  });

  group('ApiAppVersionSource', () {
    ApiAppVersionSource source(http.Client client) => ApiAppVersionSource(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => null,
        httpClient: client,
      ),
    );

    test('reads the server answer without signing in', () async {
      late http.Request seen;
      final release = await source(
        MockClient((req) async {
          seen = req;
          return http.Response(
            '{"latest_version_code": 12, "latest_version_name": "1.2.0", '
            '"min_version_code": 8, "download_url": "https://api.example.test/app"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ).fetch();
      expect(seen.url.path, '/v1/app/version');
      expect(seen.headers.containsKey('Authorization'), isFalse);
      expect(release.toJson(), _release.toJson());
    });

    test('a server error is an error (the checker stays silent)', () async {
      final s = source(MockClient((_) async => http.Response('{}', 503)));
      await expectLater(s.fetch(), throwsA(isA<StateError>()));
    });
  });

  test('outside a phone the installed version is unknown', () async {
    expect(await platformVersionCode(), 0);
    expect(await platformVersion(), isNull);
  });

  group('AppUpdateChecker', () {
    late AppDatabase db;
    late FakeVersionSource source;
    var now = DateTime.utc(2026, 11, 1, 6);

    AppUpdateChecker checker({int installed = 10}) => AppUpdateChecker(
      source: source,
      db: db,
      installedCode: () async => installed,
      clock: () => now,
    );

    setUp(() {
      db = memoryDb();
      source = FakeVersionSource();
      now = DateTime.utc(2026, 11, 1, 6);
    });
    tearDown(() => db.close());

    test(
      'asks the server at most once per interval and keeps the answer',
      () async {
        final first = await checker().check();
        expect(first.need, UpdateNeed.available);
        expect(first.release?.latestName, '1.2.0');
        expect(source.calls, 1);

        now = now.add(const Duration(minutes: 59));
        source.release = const AppRelease(
          latestCode: 20,
          latestName: '2.0.0',
          minCode: 20,
          downloadUrl: 'https://api.example.test/app',
        );
        final cached = await checker().check();
        expect(source.calls, 1, reason: 'within the interval: no request');
        expect(cached.need, UpdateNeed.available);

        now = now.add(const Duration(minutes: 1));
        final fresh = await checker().check();
        expect(source.calls, 2);
        expect(fresh.need, UpdateNeed.required);
      },
    );

    test('offline: silent, and the last answer still counts', () async {
      source.offline = true;
      expect((await checker().check()).need, UpdateNeed.none);

      source.offline = false;
      await checker().check();
      source.offline = true;
      now = now.add(const Duration(days: 3));
      final state = await checker(installed: 7).check();
      expect(state.need, UpdateNeed.required);
    });

    test('an unknown installed version never asks the server', () async {
      final state = await checker(installed: 0).check();
      expect(state.need, UpdateNeed.none);
      expect(source.calls, 0);
    });

    test('a broken cache is ignored', () async {
      await db.writeMeta(AppUpdateChecker.cacheKey, '{not json');
      expect((await checker().check()).need, UpdateNeed.available);
    });
  });

  group('when the check runs', () {
    Future<AppUpdateState> stateFor(AppConfig config, FakeVersionSource s) {
      final db = memoryDb();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          databaseProvider.overrideWithValue(db),
          appVersionSourceProvider.overrideWithValue(s),
          installedVersionCodeProvider.overrideWithValue(() async => 10),
        ],
      );
      addTearDown(container.dispose);
      return container.read(appUpdateProvider.future);
    }

    test('a real build checks', () async {
      final s = FakeVersionSource();
      expect((await stateFor(_realBuild, s)).need, UpdateNeed.available);
      expect(s.calls, 1);
    });

    test('test and demo builds never check', () async {
      for (final config in [
        AppConfig(
          productName: 'BagMitra',
          apiBaseUrl: _realBuild.apiBaseUrl,
          supabaseUrl: _realBuild.supabaseUrl,
          supabaseAnonKey: _realBuild.supabaseAnonKey,
          devGallery: true,
          testBuild: 'abc1234',
          speechEngine: 'on_device',
        ),
        testConfig,
      ]) {
        final s = FakeVersionSource();
        expect((await stateFor(config, s)).need, UpdateNeed.none);
        expect(s.calls, 0);
      }
    });
  });

  group('on screen', () {
    Future<void> pumpWith(
      WidgetTester tester,
      UpdateNeed need,
      FakeOpener opener, {
      Locale locale = const Locale('en'),
    }) => pumpApp(
      tester,
      locale: locale,
      overrides: [
        appUpdateProvider.overrideWith(
          (ref) async => AppUpdateState(need, _release),
        ),
        urlOpenerProvider.overrideWithValue(opener.call),
      ],
    );

    testWidgets('a newer version shows a closable notice that opens the link', (
      tester,
    ) async {
      final opener = FakeOpener();
      await pumpWith(tester, UpdateNeed.available, opener);
      expect(find.text('New version available — download'), findsOneWidget);
      expect(find.byKey(const Key('update-required')), findsNothing);

      await tester.tap(find.byKey(const Key('update-banner')));
      await tester.pump();
      expect(opener.opened, [Uri.parse('https://api.example.test/app')]);
      expect(find.byKey(const Key('update-link-note')), findsNothing);

      await tester.tap(find.byKey(const Key('update-banner-close')));
      await tester.pump();
      expect(find.byKey(const Key('update-banner')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('the notice reads in Marathi', (tester) async {
      await pumpWith(
        tester,
        UpdateNeed.available,
        FakeOpener(),
        locale: const Locale('mr'),
      );
      expect(find.text('नवीन आवृत्ती उपलब्ध — डाउनलोड करा'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('without a browser the link is copied and shown', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpWith(tester, UpdateNeed.available, FakeOpener(opens: false));
      await tester.tap(find.byKey(const Key('update-banner')));
      await tester.pump();
      expect(copied, 'https://api.example.test/app');
      expect(
        find.text(
          'Link copied. Paste it in the browser to download: '
          'https://api.example.test/app',
        ),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('below the minimum a blocking screen replaces the app', (
      tester,
    ) async {
      final opener = FakeOpener();
      await pumpWith(tester, UpdateNeed.required, opener);
      expect(find.byKey(const Key('update-required')), findsOneWidget);
      expect(find.text('Please update the app'), findsOneWidget);
      expect(find.byKey(const Key('update-banner')), findsNothing);
      // Nothing of the app is reachable behind it.
      expect(find.text('Home'), findsNothing);

      await tester.tap(find.byKey(const Key('update-download')));
      await tester.pump();
      expect(opener.opened.single.toString(), 'https://api.example.test/app');
      await unmountApp(tester);
    });

    testWidgets('up to date: no notice', (tester) async {
      await pumpWith(tester, UpdateNeed.none, FakeOpener());
      expect(find.byKey(const Key('update-banner')), findsNothing);
      expect(find.byKey(const Key('update-required')), findsNothing);
      await unmountApp(tester);
    });
  });
}
