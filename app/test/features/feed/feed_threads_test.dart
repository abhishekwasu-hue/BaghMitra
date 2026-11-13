// Owner Q139 (2026-11-11): news about one topic is one card in the list; opening it shows a
// dated timeline of every report, oldest first. Works offline from the saved copies; the
// server is a fake (nothing leaves the test).
import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/data/feed_receipts.dart';
import 'package:bagmitra/features/feed/data/feed_repository.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sources.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_data_test.dart';

const topic = 'th1';

Map<String, Object?> threadJson({int count = 3, int unseen = 3}) => {
  'id': topic,
  'title': 'Title n3',
  'summary': 'Summary n3',
  'latest_at': '2026-10-12T06:00:00Z',
  'item_count': count,
  'unseen_count': unseen,
  'has_new': unseen > 0,
};

Map<String, Object?> report(String id, String at, {bool seen = false}) =>
    feedJson(
      id,
      type: 'news',
      trust: 'news',
      grNumber: null,
      department: null,
      publishedAt: at,
      threadId: topic,
      seen: seen,
    );

/// The feed: three reports of one topic, one lone news item and one GR.
Map<String, Object?> threadedFeed({bool seen = false}) => {
  ...feedBody([
    report('n3', '2026-10-12T06:00:00Z', seen: seen),
    feedJson('gr1', publishedAt: '2026-10-11T12:00:00Z'),
    report('n2', '2026-10-11T06:00:00Z', seen: seen),
    feedJson(
      'solo',
      type: 'news',
      trust: 'news',
      grNumber: null,
      publishedAt: '2026-10-10T12:00:00Z',
    ),
    report('n1', '2026-10-10T06:00:00Z', seen: seen),
  ]),
  'threads': [threadJson(unseen: seen ? 0 : 3)],
};

/// The topic answer: the three reports and an older one beyond the feed page.
Map<String, Object?> threadPage() => {
  'thread': threadJson(count: 4, unseen: 4),
  'items': [
    report('n0', '2026-10-01T06:00:00Z'),
    report('n1', '2026-10-10T06:00:00Z'),
    report('n2', '2026-10-11T06:00:00Z'),
    report('n3', '2026-10-12T06:00:00Z'),
  ],
  'footer': 'Check the official GR/portal before acting.',
};

Future<void> seedThreaded(AppDatabase db, {String lang = 'en'}) => db.writeMeta(
  FeedCache.keyFor(lang),
  jsonEncode({'saved_at': '2026-10-12T06:00:00.000Z', 'page': threadedFeed()}),
);

Future<(AppDatabase, FakeFeedRepository)> pumpThreads(
  WidgetTester tester, {
  String location = '/feed',
  FakeFeedRepository? repo,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  final fake = repo ?? FakeFeedRepository(null);
  final db = await pumpApp(
    tester,
    locale: const Locale('en'),
    initialLocation: location,
    seed: seed ?? seedThreaded,
    overrides: [feedRepositoryProvider.overrideWithValue(fake)],
  );
  await settle(tester);
  return (db, fake);
}

void main() {
  group('data', () {
    test('items, threads and topic pages round-trip', () {
      final page = FeedPage.fromJson(threadedFeed());
      expect(page.items.first.threadId, topic);
      expect(page.items[1].threadId, isNull);
      final thread = page.threads[topic]!;
      expect(thread.itemCount, 3);
      expect(thread.unseenCount, 3);
      expect(thread.latestAt, DateTime.utc(2026, 10, 12, 6));
      final again = FeedPage.fromJson(page.toJson());
      expect(again.threads[topic]!.title, 'Title n3');
      expect(again.items.first.threadId, topic);
      final topicPage = FeedThreadPage.fromJson(threadPage());
      expect(topicPage.items.map((i) => i.id), ['n0', 'n1', 'n2', 'n3']);
      expect(FeedThreadPage.fromJson(topicPage.toJson()).thread.itemCount, 4);
      // An older server answer has no threads at all.
      expect(FeedPage.fromJson(feedBody([feedJson('a')])).threads, isEmpty);
    });

    test('one card per topic, placed at its newest report', () {
      final page = FeedPage.fromJson(threadedFeed());
      final entries = feedEntries(page.items, page.threads);
      expect(entries, hasLength(3));
      final card = entries.first as FeedThreadEntry;
      expect(card.id, topic);
      expect(card.count, 3);
      expect(card.items.map((i) => i.id), ['n3', 'n2', 'n1']);
      expect((entries[1] as FeedItemEntry).item.id, 'gr1');
      expect((entries[2] as FeedItemEntry).item.id, 'solo');
      expect(card.hasNew(const {}), isTrue);
      expect(card.hasNew(const {'n1', 'n2', 'n3'}), isFalse);
    });

    test('a topic with one report stays a plain card; meta count wins', () {
      final one = [FeedItem.fromJson(report('n1', '2026-10-10T06:00:00Z'))];
      expect(feedEntries(one, const {}).single, isA<FeedItemEntry>());
      final meta = FeedThread.fromJson(threadJson(count: 5, unseen: 2));
      final card = feedEntries(one, {topic: meta}).single as FeedThreadEntry;
      expect(card.count, 5);
      // One of the two unseen reports is not in the list: still new after opening n1.
      expect(card.serverUnseen, 1);
      expect(card.hasNew(const {'n1'}), isTrue);
    });

    test('topic cache: saved per language and topic, kept offline', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = FakeFeedRepository(threadedFeed());
      repo.threads[topic] = threadPage();
      final cache = FeedCache(
        db,
        repository: repo,
        clock: () => DateTime.utc(2026, 10, 13, 6),
      );
      expect(await cache.loadThread('mr', topic), isNull);
      expect(await cache.refreshThreadOrFailure('mr', topic), isNull);
      expect(repo.threadCalls, ['mr/$topic']);
      final saved = (await cache.loadThread('mr', topic))!;
      expect(saved.page.items, hasLength(4));
      expect(saved.savedAt, DateTime.utc(2026, 10, 13, 6));
      expect(await cache.loadThread('en', topic), isNull);
      repo.body = null; // offline
      expect(await cache.refreshThreadOrFailure('mr', topic), isNotNull);
      expect((await cache.loadThread('mr', topic))!.page.items, hasLength(4));
      // The feed cache keeps the threads of the items it keeps.
      repo.body = threadedFeed();
      await cache.refresh('en');
      expect((await cache.load('en'))!.page.threads.keys, [topic]);
    });

    test('HTTP repository reads threads and the topic endpoint', () async {
      final requests = <http.Request>[];
      final api = createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient((req) async {
          requests.add(req);
          final body = req.url.path == '/v1/feed'
              ? threadedFeed()
              : threadPage();
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final repo = HttpFeedRepository(api);
      final page = await repo.fetch(lang: 'mr');
      expect(page.items.first.threadId, topic);
      expect(page.threads[topic]!.itemCount, 3);
      final topicPage = await repo.fetchThread(lang: 'mr', threadId: topic);
      expect(requests.last.url.path, '/v1/feed/threads/$topic');
      expect(requests.last.url.queryParameters, {'lang': 'mr'});
      expect(topicPage.items.map((i) => i.id), ['n0', 'n1', 'n2', 'n3']);
      expect(topicPage.thread.itemCount, 4);
    });
  });

  group('screens', () {
    testWidgets('offline list: one topic card with its count and dot', (
      tester,
    ) async {
      await pumpThreads(tester);
      expect(find.byKey(const Key('feed-thread-$topic')), findsOneWidget);
      expect(find.text('Title n3'), findsOneWidget);
      expect(find.text('Title n2'), findsNothing);
      expect(find.text('Title n1'), findsNothing);
      expect(find.text('3 reports'), findsOneWidget);
      expect(
        find.byKey(const Key('feed-thread-unseen-$topic')),
        findsOneWidget,
      );
      // Official items and lone news stay as they were.
      expect(find.byKey(const Key('feed-item-gr1')), findsOneWidget);
      expect(find.byKey(const Key('feed-item-solo')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('Marathi card counts in Marathi digits', (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/feed', // pumpApp's default locale is Marathi
        seed: (db) => seedThreaded(db, lang: 'mr'),
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      expect(find.text('३ बातम्या'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('offline topic: timeline from the saved feed, oldest first', (
      tester,
    ) async {
      final (db, repo) = await pumpThreads(tester);
      await tester.tap(find.byKey(const Key('feed-thread-$topic')));
      await settle(tester);
      expect(repo.threadCalls, ['en/$topic'], reason: 'a fetch was tried');
      final ys = [
        for (final id in ['n1', 'n2', 'n3'])
          tester.getTopLeft(find.byKey(Key('feed-thread-item-$id'))).dy,
      ];
      expect(ys[0], lessThan(ys[1]));
      expect(ys[1], lessThan(ys[2]));
      expect(find.text('3 reports · Latest: 12 Oct 2026'), findsOneWidget);
      expect(find.text('Summary n1'), findsOneWidget);
      // Each report's link sits behind its folded "Sources (1)" header.
      expect(find.text('Source: https://example.org/n1'), findsNothing);
      await openAllSources(tester);
      expect(find.text('Source: https://example.org/n1'), findsOneWidget);
      expect(find.byKey(const Key('feed-thread-new-n1')), findsOneWidget);
      expect(
        find.text('Check the official GR/portal before acting.'),
        findsWidgets,
      );
      // Opening the topic marks every report seen on the phone.
      final state = await FeedReceipts(db, repository: repo).load();
      expect(state.seen, containsAll(['n1', 'n2', 'n3']));
      // Back on the list the dot is gone.
      await tester.pageBack();
      await settle(tester);
      expect(find.byKey(const Key('feed-thread-unseen-$topic')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('online topic: the server copy adds older reports and is '
        'saved for offline', (tester) async {
      final repo = FakeFeedRepository(threadedFeed());
      repo.threads[topic] = threadPage();
      final (db, _) = await pumpThreads(
        tester,
        location: '/feed-thread/$topic',
        repo: repo,
      );
      expect(find.byKey(const Key('feed-thread-item-n0')), findsOneWidget);
      expect(find.text('4 reports · Latest: 12 Oct 2026'), findsOneWidget);
      expect(await db.readMeta(FeedCache.threadKeyFor('en', topic)), isNotNull);
      // A report only in the topic's copy opens in full.
      await tester.tap(find.byKey(const Key('feed-thread-open-n0')));
      await settle(tester);
      expect(find.text('Summary n0'), findsOneWidget);
      expect(find.byKey(const Key('feed-dismiss')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('seen reports carry no "New" mark and no list dot', (
      tester,
    ) async {
      await pumpThreads(
        tester,
        seed: (db) => db.writeMeta(
          FeedCache.keyFor('en'),
          jsonEncode({
            'saved_at': '2026-10-12T06:00:00.000Z',
            'page': threadedFeed(seen: true),
          }),
        ),
      );
      expect(find.byKey(const Key('feed-thread-unseen-$topic')), findsNothing);
      await tester.tap(find.byKey(const Key('feed-thread-$topic')));
      await settle(tester);
      expect(find.byKey(const Key('feed-thread-new-n3')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('an unknown topic offline says so', (tester) async {
      await pumpThreads(tester, location: '/feed-thread/nope');
      expect(
        find.text('This message was removed from the saved list.'),
        findsOneWidget,
      );
      await unmountApp(tester);
    });
  });
}
