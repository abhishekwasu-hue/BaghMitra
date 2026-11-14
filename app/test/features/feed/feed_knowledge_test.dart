// Knowledge articles, ज्ञान लेख (owner 2026-11-11, Q141): the "Knowledge" chip, the article
// screen (byline, sections, sources with links, the card button, the muted note) and that it
// all works offline from the phone's cache.
import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/core/formatting.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/domain/feed_article.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../architecture/ui_guidelines_test.dart' show contrast;
import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_data_test.dart';

const nhbUrl = 'https://www.nhb.gov.in/pdf/fruits/citrus/cit008.pdf';

Map<String, Object?> knowledgeArticle({String? cardSection = 'psylla'}) => {
  'headline': 'Psylla: watch the new flush',
  'standfirst': 'Warm days favour psylla; look at the new flush.',
  'key_points': <String>[],
  'sections': [
    {'heading': 'What you see', 'body': 'Nymphs crowd on shoot tips.'},
    {'heading': 'What to check', 'body': 'Check every new flush.'},
    {'heading': 'What to do', 'body': 'Hang yellow sticky traps, 30 per acre.'},
    {'heading': 'When to ask the KVK', 'body': 'When you are unsure.'},
  ],
  'facts': <Object>[],
  'charts': <Object>[],
  'key_dates': <Object>[],
  'sources': [
    {'title': 'NHB Citrus: Pests', 'url': nhbUrl},
  ],
  'card_section': cardSection,
};

Map<String, Object?> knowledgeJson(
  String id, {
  String? cardSection = 'psylla',
  String publishedAt = '2026-10-12T02:11:00Z',
}) => {
  ...feedJson(
    id,
    type: 'knowledge',
    grNumber: null,
    department: null,
    publishedAt: publishedAt,
  ),
  'title': 'Psylla: watch the new flush',
  'summary': 'Warm days favour psylla; look at the new flush.',
  'url': nhbUrl,
  'article': knowledgeArticle(cardSection: cardSection),
};

final _page = feedBody([
  feedJson('gr1', publishedAt: '2026-10-11T06:00:00Z'),
  feedJson('news1', type: 'news', trust: 'news', grNumber: null),
  knowledgeJson('k1'),
  knowledgeJson('k2', cardSection: null, publishedAt: '2026-10-09T06:00:00Z'),
]);

Future<void> _seed(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('en'),
  jsonEncode({'saved_at': '2026-10-12T06:00:00.000Z', 'page': _page}),
);

/// The feed with the cache seeded and the network down.
Future<FakeFeedRepository> _pump(
  WidgetTester tester,
  String location, {
  ThemeMode mode = ThemeMode.light,
}) async {
  final repo = FakeFeedRepository(null);
  await pumpApp(
    tester,
    themeMode: mode,
    locale: const Locale('en'),
    initialLocation: location,
    seed: _seed,
    overrides: [feedRepositoryProvider.overrideWithValue(repo)],
  );
  await settle(tester);
  return repo;
}

void main() {
  test(
    'the knowledge chip takes only knowledge; official and news leave it out',
    () {
      final items = FeedPage.fromJson(_page).items;
      List<String> ids(FeedFilter f) => [
        for (final i in filterFeed(items, f)) i.id,
      ];
      expect(ids(FeedFilter.knowledge), ['k1', 'k2']);
      // k1 has trust "official" (all its sources are government sites) but is not a GR.
      expect(ids(FeedFilter.official), ['gr1']);
      expect(ids(FeedFilter.news), ['news1']);
    },
  );

  test('the card section survives the phone cache', () {
    final article = FeedArticle.tryParse(knowledgeArticle())!;
    expect(article.cardSection, 'psylla');
    expect(article.keyPoints, isEmpty);
    final again = FeedArticle.tryParse(
      jsonDecode(jsonEncode(article.toJson())),
    )!;
    expect(again.cardSection, 'psylla');
    expect(again.sources.single.url, nhbUrl);
    // An old cached news article has no card section.
    final old = Map.of(knowledgeArticle())..remove('card_section');
    expect(FeedArticle.tryParse(old)!.cardSection, isNull);
  });

  testWidgets(
    'offline: the knowledge chip lists the articles with their badge',
    (tester) async {
      final repo = await _pump(tester, '/feed');
      expect(repo.calls, contains('en'), reason: 'a refresh was tried');
      expect(find.text('Title gr1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('feed-filter-knowledge')));
      await settle(tester);
      expect(find.text('Psylla: watch the new flush'), findsNWidgets(2));
      expect(find.text('Title gr1'), findsNothing);
      expect(find.text('Title news1'), findsNothing);
      expect(
        find.text(
          'Knowledge article · ${formatDate(DateTime(2026, 10, 12), 'en')}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('feed-filter-official')));
      await settle(tester);
      expect(find.text('Psylla: watch the new flush'), findsNothing);
      await unmountApp(tester);
    },
  );

  testWidgets(
    'offline: the article screen shows sections, sources and the card',
    (tester) async {
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
      await _pump(tester, '/feed/k1');
      // No byline vouching for the text (owner 2026-11-14).
      expect(find.textContaining('written by AI'), findsNothing);
      expect(find.textContaining('checked'), findsNothing);
      expect(
        find.text('Key points'),
        findsNothing,
      ); // none for a knowledge article
      for (final heading in ['What you see', 'What to check', 'What to do']) {
        expect(find.text(heading), findsOneWidget);
      }
      // The sources sit folded behind one "Sources (n)" header (owner 2026-11-13): the
      // article's sources and the item's own link, counted together.
      final source = find.byKey(const Key('feed-knowledge-source-0'));
      final sources = find.byKey(const Key('feed-article-sources'));
      await tester.scrollUntilVisible(
        sources,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(source, findsNothing);
      expect(find.byKey(const Key('feed-source')), findsNothing);
      final toggle = find.descendant(
        of: sources,
        matching: find.byKey(const Key('sources-toggle')),
      );
      expect(
        find.descendant(of: toggle, matching: find.text('Sources (2)')),
        findsOneWidget,
      );
      await tester.ensureVisible(toggle);
      await settle(tester);
      await tester.tap(toggle);
      await settle(tester);
      expect(find.byKey(const Key('feed-source')), findsOneWidget);
      // The copy button sits in the same opened section (still "Sources (2)").
      expect(
        find.descendant(
          of: sources,
          matching: find.byKey(const Key('feed-copy-link')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: toggle, matching: find.text('Sources (2)')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        source,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: source,
          matching: find.textContaining('www.nhb.gov.in'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(source);
      await settle(tester);
      await tester.tap(source);
      await settle(tester);
      expect(copied, nhbUrl);
      // Section cards make the page longer: the note is further down.
      await tester.scrollUntilVisible(
        find.byKey(const Key('feed-knowledge-note')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('feed-knowledge-note')), findsOneWidget);
      // A card-based article is not about a GR: no "check the official GR" line.
      expect(find.byKey(const Key('feed-footer')), findsNothing);
      final card = find.byKey(const Key('feed-knowledge-card'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await settle(tester);
      expect(find.byKey(const Key('feed-knowledge-card')), findsNothing);
      await unmountApp(tester);
    },
  );

  testWidgets(
    'a scheme explainer keeps the official GR line and has no card button',
    (tester) async {
      await _pump(tester, '/feed/k2');
      expect(find.byKey(const Key('feed-knowledge-card')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('feed-footer')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('feed-footer')), findsOneWidget);
      expect(find.byKey(const Key('feed-knowledge-note')), findsOneWidget);
      await unmountApp(tester);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('the knowledge badge is readable in ${mode.name} mode', (
      tester,
    ) async {
      await _pump(tester, '/feed', mode: mode);
      final badge = find.byKey(const Key('feed-badge-k1'));
      final box = tester.widget<DecoratedBox>(badge);
      final fill = (box.decoration as BoxDecoration).color!;
      final text = tester.widget<Text>(
        find.descendant(of: badge, matching: find.byType(Text)),
      );
      expect(contrast(text.style!.color!, fill), greaterThanOrEqualTo(4.5));
      await unmountApp(tester);
    });
  }
}
