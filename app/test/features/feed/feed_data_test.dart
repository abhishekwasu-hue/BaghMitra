import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/features/feed/data/demo_feed_repository.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/data/feed_repository.dart';
import 'package:bagmitra/features/feed/domain/feed_check.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:bagmitra/features/feed/domain/feed_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart' show testConfig;
import '../../helpers/test_db.dart';

/// A server feed item in the `/v1/feed` contract shape.
Map<String, Object?> feedJson(
  String id, {
  String type = 'gr',
  String trust = 'official',
  String publishedAt = '2026-10-10T06:00:00Z',
  String? deadline,
  String? validTo,
  String? replacedBy,
  List<String> eligible = const [],
  String? grNumber = 'GR-1',
  String? department = 'Agriculture Dept',
}) => {
  'id': id,
  'type': type,
  'trust': trust,
  'title': 'Title $id',
  'summary': 'Summary $id',
  'department': department,
  'gr_number': grNumber,
  'published_at': publishedAt,
  'url': 'https://example.org/$id',
  'deadline': deadline,
  'valid_to': validTo,
  'replaced_by': replacedBy,
  'may_be_eligible_because': eligible,
};

Map<String, Object?> feedBody(List<Map<String, Object?>> items) => {
  'items': items,
  'footer': 'Check the official GR/portal before acting.',
};

/// A fake server: offline (every call throws) while [body] is null.
class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository(this.body);

  Map<String, Object?>? body;
  final calls = <String>[];
  final receipts = <(String, FeedReceiptAction)>[];
  FeedPreferences prefs = const FeedPreferences(
    quietStart: '22:00',
    quietEnd: '06:30',
    weeklyCap: 5,
    optedOut: {'payment'},
    digestWeekly: false,
  );
  final savedPrefs = <FeedPreferences>[];
  FeedCheckResult checkResult = const FeedCheckResult(
    verdict: FeedCheckVerdict.noOfficialMatch,
  );
  final checked = <String>[];

  bool get offline => body == null;

  void _online() {
    if (offline) throw const FeedUnavailableException('offline');
  }

  @override
  Future<FeedPage> fetch({required String lang, FeedFilter? filter}) async {
    calls.add(lang);
    _online();
    return FeedPage.fromJson(body!);
  }

  @override
  Future<void> sendReceipt(String itemId, FeedReceiptAction action) async {
    _online();
    receipts.add((itemId, action));
  }

  @override
  Future<FeedPreferences> loadPreferences() async {
    _online();
    return prefs;
  }

  @override
  Future<FeedPreferences> savePreferences(FeedPreferences p) async {
    _online();
    savedPrefs.add(p);
    return prefs = p;
  }

  @override
  Future<FeedCheckResult> check(String text, {String lang = 'en'}) async {
    _online();
    checked.add(text);
    return checkResult;
  }
}

void main() {
  test('parses every contract field, nulls and an absent list', () {
    final item = FeedItem.fromJson(
      feedJson(
        'a',
        deadline: '2026-11-01',
        validTo: '2026-12-31',
        replacedBy: 'GR-2',
        eligible: ['you grow oranges'],
      ),
    );
    expect(item.type, 'gr');
    expect(item.isOfficial, isTrue);
    expect(item.grNumber, 'GR-1');
    expect(item.department, 'Agriculture Dept');
    expect(item.publishedAt, DateTime.utc(2026, 10, 10, 6));
    expect(item.deadline, DateTime(2026, 11));
    expect(item.validTo, DateTime(2026, 12, 31));
    expect(item.replacedBy, 'GR-2');
    expect(item.mayBeEligibleBecause, ['you grow oranges']);
    // Round trip keeps everything.
    final again = FeedItem.fromJson(item.toJson());
    expect(again.toJson(), item.toJson());

    final bare = FeedItem.fromJson(
      feedJson(
          'b',
          trust: 'news',
          type: 'news',
          grNumber: null,
          department: null,
        )
        ..remove('may_be_eligible_because')
        ..remove('summary'),
    );
    expect(bare.isOfficial, isFalse);
    expect(bare.summary, '');
    expect(bare.mayBeEligibleBecause, isEmpty);
    expect(bare.deadline, isNull);
    expect(FeedPage.fromJson(const {}).items, isEmpty);
  });

  test('eligibility and reminders are hidden once withdrawn or expired', () {
    final now = DateTime(2026, 10, 13, 6);
    FeedItem item({String? validTo, String? replacedBy, String? deadline}) =>
        FeedItem.fromJson(
          feedJson(
            'x',
            validTo: validTo,
            replacedBy: replacedBy,
            deadline: deadline,
            eligible: ['reason'],
          ),
        );
    expect(item().showsEligibility(now), isTrue);
    expect(item(validTo: '2026-10-13').showsEligibility(now), isTrue);
    expect(item(validTo: '2026-10-12').isExpired(now), isTrue);
    expect(item(validTo: '2026-10-12').showsEligibility(now), isFalse);
    expect(item(replacedBy: 'GR-9').showsEligibility(now), isFalse);
    expect(item(deadline: '2026-10-13').canRemind(now), isTrue);
    expect(item(deadline: '2026-10-12').canRemind(now), isFalse);
    expect(item().canRemind(now), isFalse);
    expect(
      item(deadline: '2026-10-20', replacedBy: 'GR-9').canRemind(now),
      isFalse,
    );
  });

  test('filters: official, schemes, deadlines, news; newest first', () {
    final items = FeedPage.fromJson(
      feedBody([
        feedJson('old-gr', publishedAt: '2026-10-01T00:00:00Z'),
        feedJson(
          'scheme',
          type: 'scheme',
          deadline: '2026-11-01',
          publishedAt: '2026-10-05T00:00:00Z',
        ),
        feedJson(
          'news',
          type: 'news',
          trust: 'news',
          publishedAt: '2026-10-09T00:00:00Z',
        ),
      ]),
    ).items;
    List<String> ids(FeedFilter? f) => [
      for (final i in filterFeed(items, f)) i.id,
    ];
    expect(ids(null), ['news', 'scheme', 'old-gr']);
    expect(ids(FeedFilter.official), ['scheme', 'old-gr']);
    expect(ids(FeedFilter.scheme), ['scheme']);
    expect(ids(FeedFilter.deadline), ['scheme']);
    expect(ids(FeedFilter.news), ['news']);
  });

  test(
    'HTTP repository calls /v1/feed with lang, type and the bearer token',
    () async {
      final requests = <http.Request>[];
      var status = 200;
      final api = createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient((req) async {
          requests.add(req);
          return http.Response(
            jsonEncode(feedBody([feedJson('a')])),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final repo = HttpFeedRepository(api);
      final page = await repo.fetch(lang: 'mr', filter: FeedFilter.deadline);
      expect(page.items.single.id, 'a');
      expect(page.footer, 'Check the official GR/portal before acting.');
      final req = requests.single;
      expect(req.url.host, 'api.example.test');
      expect(req.url.path, '/v1/feed');
      expect(req.url.queryParameters, {'lang': 'mr', 'type': 'deadline'});
      expect(req.headers['Authorization'], 'Bearer tok');

      await repo.fetch(lang: 'en');
      expect(requests.last.url.queryParameters, {'lang': 'en'});

      status = 503;
      await expectLater(
        repo.fetch(lang: 'en'),
        throwsA(isA<FeedUnavailableException>()),
      );
    },
  );

  test('HTTP repository rejects a body that is not the contract', () async {
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => null,
      httpClient: MockClient((req) async => http.Response('[1,2]', 200)),
    );
    await expectLater(
      HttpFeedRepository(api).fetch(lang: 'en'),
      throwsA(
        isA<FeedUnavailableException>().having(
          (e) => e.toString(),
          'message',
          contains('bad body'),
        ),
      ),
    );
  });

  test(
    'cache keeps the newest 50 per language and survives going offline',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = FakeFeedRepository(
        feedBody([
          for (var i = 0; i < 60; i++)
            feedJson(
              'i$i',
              publishedAt: DateTime.utc(
                2026,
                8,
              ).add(Duration(days: i)).toIso8601String(),
            ),
        ]),
      );
      final cache = FeedCache(
        db,
        repository: repo,
        clock: () => DateTime.utc(2026, 10, 13, 6),
      );
      expect(await cache.load('mr'), isNull);
      expect(await cache.refresh('mr'), isTrue);
      final cached = (await cache.load('mr'))!;
      expect(cached.page.items, hasLength(FeedCache.maxItems));
      expect(cached.page.items.first.id, 'i59');
      expect(cached.page.items.last.id, 'i10');
      expect(cached.page.footer, isNotEmpty);
      expect(cached.savedAt, DateTime.utc(2026, 10, 13, 6));
      expect(await cache.load('hi'), isNull);

      repo.body = null; // offline
      expect(await cache.refresh('mr'), isFalse);
      expect((await cache.load('mr'))!.page.items, hasLength(50));
      expect(repo.calls, ['mr', 'mr']);
    },
  );

  test(
    'demo feed is clearly sample, offline, filterable, in every language',
    () async {
      final repo = DemoFeedRepository(
        clock: () => DateTime.utc(2026, 10, 13, 6),
      );
      for (final lang in ['en', 'mr', 'hi', 'ta']) {
        final page = await repo.fetch(lang: lang);
        expect(page.items, isNotEmpty);
        expect(page.footer, isNotEmpty);
        for (final i in page.items) {
          expect(Uri.parse(i.url).host, 'example.org');
          expect(i.title, matches(RegExp('Sample|नमुना|नमूना')));
        }
        expect(page.items.any((i) => i.isWithdrawn), isTrue);
        expect(page.items.any((i) => !i.isOfficial), isTrue);
      }
      final now = DateTime.utc(2026, 10, 13, 6);
      final deadlines = await repo.fetch(
        lang: 'en',
        filter: FeedFilter.deadline,
      );
      expect(deadlines.items, isNotEmpty);
      expect(deadlines.items.every((i) => i.canRemind(now)), isTrue);
      expect(
        (await repo.fetch(lang: 'mr')).items.first.title,
        startsWith('नमुना GR'),
      );
    },
  );

  test('flag: on in demo and test builds, off with a backend, define wins', () {
    expect(testConfig.sarkariSandeshEnabled, isTrue);
    const backend = AppConfig(
      productName: 'B',
      apiBaseUrl: 'https://api',
      supabaseUrl: 'https://s',
      supabaseAnonKey: 'k',
      devGallery: false,
      testBuild: '',
      speechEngine: 'on_device',
    );
    expect(backend.sarkariSandeshEnabled, isFalse);
    const backendTest = AppConfig(
      productName: 'B',
      apiBaseUrl: 'https://api',
      supabaseUrl: 'https://s',
      supabaseAnonKey: 'k',
      devGallery: false,
      testBuild: 'abc123',
      speechEngine: 'on_device',
    );
    expect(backendTest.sarkariSandeshEnabled, isTrue);
    const forcedOn = AppConfig(
      productName: 'B',
      apiBaseUrl: 'https://api',
      supabaseUrl: 'https://s',
      supabaseAnonKey: 'k',
      devGallery: false,
      testBuild: '',
      speechEngine: 'on_device',
      sarkariSandesh: 'on',
    );
    expect(forcedOn.sarkariSandeshEnabled, isTrue);
    const forcedOff = AppConfig(
      productName: 'B',
      apiBaseUrl: '',
      supabaseUrl: '',
      supabaseAnonKey: '',
      devGallery: false,
      testBuild: '',
      speechEngine: 'on_device',
      sarkariSandesh: 'off',
    );
    expect(forcedOff.sarkariSandeshEnabled, isFalse);
    expect(AppConfig.fromEnvironment().sarkariSandesh, '');
  });
}
