// The government level and the AI article come from the server through the generated client,
// the phone cache and the screens (bug: the HTTP repository dropped both). The server is a
// fake http client (nothing leaves the test).
import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/design_system/article_reading.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/data/feed_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_article_test.dart' show articleJson;
import 'feed_data_test.dart' show feedBody, feedJson;
import 'feed_threads_test.dart' show threadJson, topic;

/// A news report of [topic] from a state source, with an article.
Map<String, Object?> stateReport(String id, String at) => {
  ...feedJson(
    id,
    type: 'news',
    trust: 'news',
    grNumber: null,
    department: null,
    publishedAt: at,
    level: 'state',
    threadId: topic,
  ),
  'article': articleJson(),
};

/// The feed: a central GR without an article, a state news item with one, an item of an
/// unknown level, and two reports of one topic.
Map<String, Object?> serverFeed() => {
  ...feedBody([
    feedJson('gr1', level: 'central', publishedAt: '2026-10-12T06:00:00Z'),
    {
      ...feedJson(
        'art1',
        trust: 'news',
        type: 'news',
        grNumber: null,
        department: null,
        level: 'state',
        publishedAt: '2026-10-11T06:00:00Z',
      ),
      'article': articleJson(),
    },
    feedJson('odd', level: 'district'),
    stateReport('n2', '2026-10-09T06:00:00Z'),
    stateReport('n1', '2026-10-08T06:00:00Z'),
  ]),
  'threads': [threadJson()],
};

/// The topic page: one report ([n0]) that is only here, not in the feed.
Map<String, Object?> serverThread() => {
  'thread': threadJson(),
  'items': [
    stateReport('n0', '2026-10-01T06:00:00Z'),
    stateReport('n1', '2026-10-08T06:00:00Z'),
    stateReport('n2', '2026-10-09T06:00:00Z'),
  ],
  'footer': 'Check the official GR/portal before acting.',
};

/// The real HTTP repository on a fake server; [online] false answers every call with 503.
class FakeServer {
  bool online = true;
  final paths = <String>[];

  HttpFeedRepository repo() => HttpFeedRepository(
    createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => 'tok',
      httpClient: MockClient((req) async {
        paths.add(req.url.path);
        if (!online) return http.Response('', 503);
        final body = switch (req.url.path) {
          '/v1/feed' => serverFeed(),
          '/v1/feed/threads/$topic' => serverThread(),
          _ => null,
        };
        if (body == null) return http.Response('{}', 404);
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
}

final _list = find.byType(Scrollable).first;

void main() {
  group('data', () {
    test('HTTP repository keeps the level and the article', () async {
      final repo = FakeServer().repo();
      final page = await repo.fetch(lang: 'en');
      final byId = {for (final i in page.items) i.id: i};
      expect(byId['gr1']!.level, 'central');
      expect(byId['gr1']!.article, isNull);
      expect(byId['art1']!.level, 'state');
      expect(byId['odd']!.level, isNull, reason: 'only central / state');
      final article = byId['art1']!.article!;
      expect(article.headline, 'Orange growers: subsidy ₹6,000 per hectare');
      expect(article.keyPoints, hasLength(3));
      expect(article.sections.last.body, 'Apply on MahaDBT.');
      expect(article.facts.last.value, '1,200');
      expect(article.charts.map((c) => c.points.first.value), [60, 700]);
      expect(article.keyDates.single.date, DateTime(2026, 11, 30));
      expect(article.sources.single.url, 'https://mahasamvad.in/12345/');
      // The same article as the cache path reads it.
      expect(article.toJson(), articleJson());

      final topicPage = await repo.fetchThread(lang: 'en', threadId: topic);
      expect(topicPage.items.first.level, 'state');
      expect(topicPage.items.first.article!.sections, hasLength(3));
    });

    test('the cache keeps both offline; an old cached copy without them '
        'still opens', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final server = FakeServer();
      final cache = FeedCache(
        db,
        repository: server.repo(),
        clock: () => DateTime.utc(2026, 10, 12, 6),
      );
      expect(await cache.refreshOrFailure('en'), isNull);
      expect(await cache.refreshThreadOrFailure('en', topic), isNull);
      server.online = false;
      expect(await cache.refreshOrFailure('en'), isNotNull);

      final saved = (await cache.load('en'))!.page.items;
      final art = saved.firstWhere((i) => i.id == 'art1');
      expect(art.level, 'state');
      expect(art.article!.facts, hasLength(3));
      expect(saved.firstWhere((i) => i.id == 'gr1').level, 'central');
      final topicPage = (await cache.loadThread('en', topic))!.page;
      final n0 = topicPage.items.firstWhere((i) => i.id == 'n0');
      expect(n0.level, 'state');
      expect(n0.article!.headline, startsWith('Orange growers'));

      // A copy saved before the fix has neither key.
      final old = feedJson('old');
      old.remove('level');
      await db.writeMeta(
        FeedCache.keyFor('mr'),
        jsonEncode({
          'saved_at': DateTime.utc(2026, 10, 2).toIso8601String(),
          'page': feedBody([old]),
        }),
      );
      final oldItem = (await cache.load('mr'))!.page.items.single;
      expect(oldItem.id, 'old');
      expect(oldItem.level, isNull);
      expect(oldItem.article, isNull);
    });
  });

  group('screens', () {
    Future<FakeServer> pump(WidgetTester tester, String location) async {
      final server = FakeServer();
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: location,
        overrides: [feedRepositoryProvider.overrideWithValue(server.repo())],
      );
      await settle(tester);
      return server;
    }

    testWidgets('the list shows the level chip from the server', (
      tester,
    ) async {
      final server = await pump(tester, '/feed');
      expect(server.paths, contains('/v1/feed'));
      expect(
        find.descendant(
          of: find.byKey(const Key('feed-badge-gr1')),
          matching: find.textContaining('Government of India'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('feed-badge-art1')),
          matching: find.textContaining('Government of Maharashtra'),
        ),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('the item detail shows the level and the article, the source '
        'link and the official check note', (tester) async {
      await pump(tester, '/feed/art1');
      expect(find.textContaining('Government of Maharashtra'), findsOneWidget);
      expect(find.byKey(const Key('feed-article')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is HighlightedText && w.text == '1,200 farmers eligible',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('What farmers can do next'),
        300,
        scrollable: _list,
      );
      expect(find.text('Apply on MahaDBT.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('feed-footer')),
        300,
        scrollable: _list,
      );
      expect(find.textContaining('mahasamvad.in'), findsOneWidget);
      expect(find.textContaining('example.org/art1'), findsWidgets);
      expect(
        find.text('Check the official GR/portal before acting.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });

    testWidgets('a report tapped in the topic timeline opens with its '
        'article', (tester) async {
      final server = await pump(tester, '/feed-thread/$topic');
      expect(server.paths, contains('/v1/feed/threads/$topic'));
      expect(find.textContaining('Government of Maharashtra'), findsWidgets);
      final open = find.byKey(const Key('feed-thread-open-n0'));
      await tester.scrollUntilVisible(open, 200, scrollable: _list);
      await tester.tap(open);
      await settle(tester);
      expect(find.byKey(const Key('feed-article')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is HighlightedText && w.text == '1,200 farmers eligible',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });
  });
}
