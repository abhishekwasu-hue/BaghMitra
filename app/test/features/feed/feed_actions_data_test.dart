import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/feed/data/demo_feed_repository.dart';
import 'package:bagmitra/features/feed/data/feed_preferences_store.dart';
import 'package:bagmitra/features/feed/data/feed_receipts.dart';
import 'package:bagmitra/features/feed/data/feed_repository.dart';
import 'package:bagmitra/features/feed/domain/feed_check.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:bagmitra/features/feed/domain/feed_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';
import 'feed_data_test.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

/// An HTTP repository over a mock server; [answer] decides each response.
(HttpFeedRepository, List<http.Request>) httpRepo(
  http.Response Function(http.Request req) answer,
) {
  final requests = <http.Request>[];
  final api = createApi(
    baseUrl: Uri.parse('https://api.example.test'),
    token: () => 'tok',
    httpClient: MockClient((req) async {
      requests.add(req);
      return answer(req);
    }),
  );
  return (HttpFeedRepository(api), requests);
}

const _prefsJson = {
  'quiet_start': '22:15',
  'quiet_end': '06:00',
  'weekly_cap': 4,
  'opted_out': ['window_open'],
  'digest_weekly': false,
};

void main() {
  test('list call: generated client keeps fields and reads seen', () async {
    final (repo, requests) = httpRepo(
      (_) => http.Response(
        jsonEncode(
          feedBody([
            {...feedJson('a', deadline: '2026-11-01'), 'seen': true},
            feedJson('b', trust: 'news', type: 'news')..remove('summary'),
          ]),
        ),
        200,
        headers: _json,
      ),
    );
    final page = await repo.fetch(lang: 'hi');
    expect(requests.single.url.queryParameters, {'lang': 'hi'});
    expect(requests.single.headers['Authorization'], 'Bearer tok');
    final a = page.items.first;
    expect(a.seen, isTrue);
    expect(a.deadline, DateTime(2026, 11));
    expect(a.grNumber, 'GR-1');
    expect(a.publishedAt, DateTime.utc(2026, 10, 10, 6));
    expect(page.items.last.seen, isFalse);
    expect(page.items.last.isOfficial, isFalse);
    expect(page.items.last.summary, '');
    // seen survives the cache round trip.
    expect(FeedItem.fromJson(a.toJson()).seen, isTrue);
    // A language the API does not know is left out, not sent.
    await repo.fetch(lang: 'ta');
    expect(requests.last.url.queryParameters, isEmpty);
  });

  test('receipts: POST seen / dismiss / remind; gone items are dropped; '
      'server trouble throws', () async {
    var status = 200;
    final (repo, requests) = httpRepo(
      (req) => http.Response(
        jsonEncode({
          'item_id': 'a',
          'seen': true,
          'dismissed': false,
          'remind': false,
        }),
        status,
        headers: _json,
      ),
    );
    for (final a in FeedReceiptAction.values) {
      await repo.sendReceipt('a', a);
    }
    expect(
      [for (final r in requests) '${r.method} ${r.url.path}'],
      [
        'POST /v1/feed/a/seen',
        'POST /v1/feed/a/dismiss',
        'POST /v1/feed/a/remind',
      ],
    );
    status = 404;
    await repo.sendReceipt('a', FeedReceiptAction.seen);
    for (final s in [401, 429, 503]) {
      status = s;
      await expectLater(
        repo.sendReceipt('a', FeedReceiptAction.seen),
        throwsA(isA<FeedUnavailableException>()),
      );
    }
    final (down, _) = httpRepo((_) => throw http.ClientException('no net'));
    await expectLater(
      down.sendReceipt('a', FeedReceiptAction.dismiss),
      throwsA(isA<FeedUnavailableException>()),
    );
  });

  test('preferences: GET and PUT through the generated client', () async {
    var status = 200;
    final (repo, requests) = httpRepo(
      (req) => http.Response(
        req.method == 'PUT' ? req.body : jsonEncode(_prefsJson),
        status,
        headers: _json,
      ),
    );
    final got = await repo.loadPreferences();
    expect(requests.single.url.path, '/v1/me/feed-preferences');
    expect(got.quietStart, '22:15');
    expect(got.quietEnd, '06:00');
    expect(got.weeklyCap, 4);
    expect(got.optedOut, {'window_open'});
    expect(got.digestWeekly, isFalse);

    final saved = await repo.savePreferences(
      got.copyWith(weeklyCap: 2, optedOut: {'deadline', 'payment'}),
    );
    final put = requests.last;
    expect(put.method, 'PUT');
    expect(jsonDecode(put.body), {
      'quiet_start': '22:15',
      'quiet_end': '06:00',
      'weekly_cap': 2,
      'opted_out': ['deadline', 'payment'],
      'digest_weekly': false,
    });
    expect(saved.weeklyCap, 2);
    expect(saved.optedOut, {'deadline', 'payment'});

    status = 422;
    await expectLater(
      repo.savePreferences(got),
      throwsA(isA<FeedUnavailableException>()),
    );
    await expectLater(
      repo.loadPreferences(),
      throwsA(isA<FeedUnavailableException>()),
    );
  });

  test('check: POST /v1/feed/check with the text only; parses every '
      'verdict; trouble throws', () async {
    var status = 200;
    var answer = jsonEncode({
      'verdict': 'official_match',
      'matches': [
        {
          'id': 'gr1',
          'title': 'Drip subsidy',
          'gr_number': 'GR-101',
          'published_at': '2026-10-12T06:00:00Z',
          'url': 'https://example.org/gr1',
          'score': 0.93,
        },
      ],
      'note': 'Matched by GR number.',
    });
    final (repo, requests) = httpRepo(
      (_) => http.Response(answer, status, headers: _json),
    );
    final r = await repo.check('GR-101 drip anudan');
    final req = requests.single;
    expect('${req.method} ${req.url.path}', 'POST /v1/feed/check');
    expect(jsonDecode(req.body), {'text': 'GR-101 drip anudan'});
    expect(req.headers['Authorization'], 'Bearer tok');
    expect(r.verdict, FeedCheckVerdict.officialMatch);
    final m = r.matches.single;
    expect(m.id, 'gr1');
    expect(m.grNumber, 'GR-101');
    expect(m.publishedAt, DateTime.utc(2026, 10, 12, 6));
    expect(m.score, 0.93);
    expect(r.note, 'Matched by GR number.');

    answer = jsonEncode({'verdict': 'possible_match', 'matches': <Object>[]});
    expect((await repo.check('x')).verdict, FeedCheckVerdict.possibleMatch);
    answer = jsonEncode({'verdict': 'something_new'});
    final odd = await repo.check('x');
    expect(odd.verdict, FeedCheckVerdict.noOfficialMatch);
    expect(odd.note, '');

    answer = '[1]';
    await expectLater(
      repo.check('x'),
      throwsA(
        isA<FeedUnavailableException>().having(
          (e) => e.reason,
          'reason',
          contains('bad body'),
        ),
      ),
    );
    status = 503;
    answer = '{}';
    await expectLater(
      repo.check('x'),
      throwsA(isA<FeedUnavailableException>()),
    );
  });

  test('receipts store: applied at once, queued offline, sent in order '
      'later; a second seen is not queued', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeFeedRepository(null); // offline
    final receipts = FeedReceipts(db, repository: server);

    await receipts.record('a', FeedReceiptAction.seen);
    await receipts.record('a', FeedReceiptAction.seen);
    await receipts.record('b', FeedReceiptAction.dismiss);
    await receipts.record('b', FeedReceiptAction.remind);
    var s = await receipts.load();
    expect(s.seen, {'a'});
    expect(s.dismissed, {'b'});
    expect(s.pending, [
      ('a', FeedReceiptAction.seen),
      ('b', FeedReceiptAction.dismiss),
      ('b', FeedReceiptAction.remind),
    ]);
    expect(server.receipts, isEmpty);
    expect(await receipts.flush(), 0);

    server.body = feedBody([]); // online again
    expect(await receipts.flush(), 3);
    expect(server.receipts, [
      ('a', FeedReceiptAction.seen),
      ('b', FeedReceiptAction.dismiss),
      ('b', FeedReceiptAction.remind),
    ]);
    s = await receipts.load();
    expect(s.pending, isEmpty);
    expect(s.seen, {'a'}, reason: 'local state stays after sending');
    expect(s.dismissed, {'b'});

    // Online: sent at once.
    await receipts.record('c', FeedReceiptAction.seen);
    expect(server.receipts.last, ('c', FeedReceiptAction.seen));
    expect((await receipts.load()).pending, isEmpty);
  });

  test('receipts store: a failure part way keeps the rest; old ids are '
      'trimmed; unknown actions in storage are skipped', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = _FlakyRepository(failOn: 'b');
    final receipts = FeedReceipts(db, repository: server);
    await receipts.record('a', FeedReceiptAction.seen);
    await receipts.record('b', FeedReceiptAction.seen);
    await receipts.record('c', FeedReceiptAction.seen);
    expect(server.sent, ['a']);
    expect(
      [for (final (id, _) in (await receipts.load()).pending) id],
      ['b', 'c'],
    );
    server.failOn = null;
    expect(await receipts.flush(), 2);
    expect(server.sent, ['a', 'b', 'c']);

    for (var i = 0; i < FeedReceipts.maxIds + 5; i++) {
      await receipts.record('x$i', FeedReceiptAction.seen);
    }
    final s = await receipts.load();
    expect(s.seen, hasLength(FeedReceipts.maxIds));
    expect(s.seen, contains('x${FeedReceipts.maxIds + 4}'));
    expect(s.seen, isNot(contains('a')));

    await db.writeMeta(
      FeedReceipts.key,
      jsonEncode({
        'pending': [
          {'id': 'z', 'action': 'archive'},
          {'id': 'y', 'action': 'remind'},
        ],
      }),
    );
    expect((await receipts.load()).pending, [('y', FeedReceiptAction.remind)]);
  });

  test('preferences store: online keeps a copy; offline shows it (or the '
      'defaults); save stores what the server took', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeFeedRepository(null);
    final store = FeedPreferencesStore(db, repository: server);

    var loaded = await store.load();
    expect(loaded.online, isFalse);
    expect(loaded.prefs.toJson(), FeedPreferences.defaults.toJson());
    await expectLater(
      store.save(FeedPreferences.defaults),
      throwsA(isA<FeedUnavailableException>()),
    );

    server.body = feedBody([]);
    loaded = await store.load();
    expect(loaded.online, isTrue);
    expect(loaded.prefs.weeklyCap, 5);
    final saved = await store.save(loaded.prefs.copyWith(weeklyCap: 1));
    expect(saved.weeklyCap, 1);

    server.body = null;
    loaded = await store.load();
    expect(loaded.online, isFalse);
    expect(loaded.prefs.toJson(), saved.toJson());
  });

  test('preferences model: json, categories, time strings, cap range', () {
    final p = FeedPreferences.fromJson(_prefsJson);
    expect(p.toJson(), _prefsJson);
    final off = p.withCategory('deadline', on: false);
    expect(off.toJson()['opted_out'], ['deadline', 'window_open']);
    expect(off.withCategory('window_open', on: true).optedOut, {'deadline'});
    expect(FeedPreferences.hhmm(7, 5), '07:05');
    expect(FeedPreferences.parseHhmm('21:30'), (21, 30));
    for (final bad in ['', '25:00', '10:61', 'ab:cd', '1:2:3']) {
      expect(FeedPreferences.parseHhmm(bad), (0, 0));
    }
    expect(p.copyWith(weeklyCap: 0).shownWeeklyCap, 1);
    expect(p.copyWith(weeklyCap: 21).shownWeeklyCap, 7);
    expect(FeedPreferences.defaults.quietStart, '21:00');
    expect(FeedPreferences.defaults.digestWeekly, isTrue);
  });

  test('demo: receipts accepted, preferences kept in memory, check finds '
      'sample items only', () async {
    final demo = DemoFeedRepository(clock: () => DateTime.utc(2026, 10, 13));
    await demo.sendReceipt('sample-gr-1', FeedReceiptAction.seen);
    expect((await demo.loadPreferences()).weeklyCap, 3);
    await demo.savePreferences(const FeedPreferences(weeklyCap: 6));
    expect((await demo.loadPreferences()).weeklyCap, 6);

    final exact = await demo.check('Forwarded: sample-0001 says apply now');
    expect(exact.verdict, FeedCheckVerdict.officialMatch);
    expect(exact.matches.single.id, 'sample-gr-1');
    expect(exact.matches.single.grNumber, 'SAMPLE-0001');

    final maybe = await demo.check('ठिबक सिंचन योजना आली', lang: 'mr');
    expect(maybe.verdict, FeedCheckVerdict.possibleMatch);
    expect(maybe.matches.map((m) => m.id), contains('sample-gr-1'));
    expect(maybe.note, contains('डेमो'));

    final none = await demo.check('sample demo message', lang: 'hi');
    expect(none.verdict, FeedCheckVerdict.noOfficialMatch);
    expect(none.matches, isEmpty);
    expect(none.note, contains('डेमो'));
    expect(none.note.toLowerCase(), isNot(contains('fake')));
  });
}

/// Fails every receipt for [failOn] while it is set.
class _FlakyRepository extends FakeFeedRepository {
  _FlakyRepository({this.failOn}) : super(const {});

  String? failOn;
  final sent = <String>[];

  @override
  Future<void> sendReceipt(String itemId, FeedReceiptAction action) async {
    if (itemId == failOn) throw const FeedUnavailableException('flaky');
    sent.add(itemId);
  }
}
