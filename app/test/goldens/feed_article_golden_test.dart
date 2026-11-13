// The AI news article screen (spec v1.6) at phone width, Marathi, 1.3x text, light and dark:
// the top (byline, key points, sections) and the data part (facts table, charts, dates).
// Also the same item as the live server sends it (through the HTTP repository): the level
// chip with the article, and the end with the sources, the source link and the official note.
//   flutter test --update-goldens test/goldens/feed_article_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/data/feed_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/feed/feed_data_test.dart'
    show FakeFeedRepository, feedBody, feedJson;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

const _article = {
  'headline': 'संत्रा उत्पादकांना हेक्टरी ₹६,००० अनुदान',
  'standfirst': 'फळबाग योजनेत संत्रा उत्पादकांसाठी राज्य शासनाचा निर्णय.',
  'key_points': [
    'प्रति हेक्टर ₹६,००० अनुदान',
    'अर्जाची अंतिम मुदत ३० नोव्हेंबर २०२६',
    'एकूण १,२०० शेतकरी पात्र',
  ],
  'sections': [
    {
      'heading': 'काय निर्णय झाला',
      'body':
          'राज्य शासनाने फळबाग योजनेत संत्रा उत्पादकांसाठी प्रति हेक्टर ₹६,००० अनुदान '
          'जाहीर केले आहे.',
    },
    {
      'heading': 'कोणाला लाभ',
      'body': 'नागपूर आणि अमरावती विभागातील संत्रा उत्पादक शेतकरी.',
    },
    {
      'heading': 'शेतकऱ्यांनी पुढे काय करावे',
      'body': 'महाडीबीटी पोर्टलवर ३० नोव्हेंबर २०२६ पर्यंत अर्ज करावा.',
    },
  ],
  'facts': [
    {'label': 'अनुदान', 'value': 'प्रति हेक्टर ₹६,०००'},
    {'label': 'अंतिम मुदत', 'value': '३० नोव्हेंबर २०२६'},
    {'label': 'पात्र शेतकरी', 'value': '१,२००'},
    {'label': 'अर्ज कुठे', 'value': 'महाडीबीटी पोर्टल'},
  ],
  'charts': [
    {
      'type': 'pie',
      'title': 'विभागनिहाय लाभार्थी',
      'unit': '%',
      'data': [
        {'label': 'नागपूर', 'value': 60.0},
        {'label': 'अमरावती', 'value': 40.0},
      ],
    },
    {
      'type': 'bar',
      'title': 'जिल्हानिहाय अर्ज',
      'unit': 'शेतकरी',
      'data': [
        {'label': 'नागपूर', 'value': 700.0},
        {'label': 'अमरावती', 'value': 500.0},
      ],
    },
  ],
  'key_dates': [
    {'date': '2026-11-30', 'label': 'अर्जाची अंतिम मुदत'},
  ],
  'sources': [
    {'title': 'महासंवाद', 'url': 'https://mahasamvad.in/12345/'},
  ],
};

Map<String, Object?> _body() => feedBody([
  {
    ...feedJson(
      'art1',
      trust: 'news',
      level: 'state',
      grNumber: null,
      department: null,
      publishedAt: '2026-10-12T05:00:00Z',
    ),
    'title': _article['headline'],
    'summary': _article['standfirst'],
    'article': _article,
  },
]);

Future<void> _seed(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': DateTime(2026, 10, 12, 6).toUtc().toIso8601String(),
    'page': _body(),
  }),
);

/// The real HTTP repository on a fake `/v1/feed` (nothing leaves the test).
FeedRepository _server() => HttpFeedRepository(
  createApi(
    baseUrl: Uri.parse('https://api.example.test'),
    token: () => 'tok',
    httpClient: MockClient(
      (req) async => http.Response(
        // The server's own Marathi footer (api feed/texts.py), as it sends for lang=mr.
        jsonEncode({
          ..._body(),
          'footer': 'कोणतीही कृती करण्यापूर्वी अधिकृत शासन निर्णय (GR) / पोर्टल तपासा.',
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  ),
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (part, target) in [
      ('top', null),
      ('facts', 'feed-facts'),
      ('charts', 'feed-chart-0'),
    ]) {
      final name = 'feed_article_${part}_mr_${mode.name}';
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: '/feed/art1',
          seed: _seed,
          size: _phone,
          overrides: [
            feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
          ],
        );
        await settle(tester);
        if (target != null) {
          await tester.scrollUntilVisible(
            find.byKey(Key(target)),
            100,
            scrollable: find.byType(Scrollable).first,
          );
          // Bring the panel's top to the top of the list.
          await tester.ensureVisible(find.byKey(Key(target)));
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$name.png'),
        );
        await unmountApp(tester);
      });
    }
    // "end": the sources folded behind "स्रोत (२)" (owner 2026-11-13); "sources_open": the
    // same header opened, its link cards shown.
    for (final part in ['top', 'end', 'sources_open']) {
      final name = 'feed_item_http_${part}_mr_${mode.name}';
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: '/feed/art1',
          size: _phone,
          overrides: [feedRepositoryProvider.overrideWithValue(_server())],
        );
        await settle(tester);
        if (part == 'end') {
          await tester.scrollUntilVisible(
            find.byKey(const Key('feed-footer')),
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -300),
          );
          await settle(tester);
        }
        if (part == 'sources_open') {
          final sources = find.byKey(const Key('feed-article-sources'));
          await tester.scrollUntilVisible(
            sources,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          final toggle = find.descendant(
            of: sources,
            matching: find.byKey(const Key('sources-toggle')),
          );
          await tester.ensureVisible(toggle);
          await settle(tester);
          await tester.tap(toggle);
          await settle(tester);
          // The header at the top, its opened cards below it.
          await tester.drag(
            find.byType(Scrollable).first,
            Offset(0, -(tester.getTopLeft(toggle).dy - 120)),
          );
          await settle(tester);
          expect(find.byKey(const Key('feed-source')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$name.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
