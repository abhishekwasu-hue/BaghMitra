// The AI news article screen (spec v1.6) at phone width, Marathi, 1.3x text, light and dark:
// the top (byline, key points, sections) and the data part (facts table, charts, dates).
//   flutter test --update-goldens test/goldens/feed_article_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> _seed(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': DateTime(2026, 10, 12, 6).toUtc().toIso8601String(),
    'page': feedBody([
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
    ]),
  }),
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
  }
}
