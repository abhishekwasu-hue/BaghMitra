// News topic threads (owner Q139) at phone width, Marathi, 1.3x text, light and dark: the
// feed list with one topic card, and the topic's dated timeline.
//   flutter test --update-goldens test/goldens/feed_threads_golden_test.dart
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
const _topic = 'drought';

Map<String, Object?> _report(
  String id,
  String at,
  String title,
  String summary, {
  bool seen = false,
}) => {
  ...feedJson(
    id,
    type: 'news',
    trust: 'news',
    level: 'state',
    grNumber: null,
    department: null,
    publishedAt: at,
    threadId: _topic,
    seen: seen,
  ),
  'title': title,
  'summary': summary,
  'url': 'https://mahasamvad.in/$id/',
};

final _reports = [
  _report(
    'd3',
    '2026-10-12T05:00:00Z',
    'दुष्काळग्रस्त भागात ४८ तासांत टँकर पोहोचवण्याचे निर्देश',
    'टंचाईग्रस्त गावांना २४ ते ४८ तासांत टँकर देण्याचे निर्देश जिल्हाधिकाऱ्यांना दिले.',
  ),
  _report(
    'd2',
    '2026-10-11T05:00:00Z',
    'दिवाळीपूर्वी दुष्काळग्रस्त शेतकऱ्यांना ₹५,००० अग्रिम',
    'दुष्काळग्रस्त शेतकऱ्यांच्या खात्यात दिवाळीपूर्वी ₹५,००० अग्रिम जमा होणार.',
    seen: true,
  ),
  _report(
    'd1',
    '2026-10-10T05:00:00Z',
    'राज्यातील दुष्काळी तालुक्यांसाठी मदतीचा निर्णय',
    'दुष्काळी तालुक्यांतील शेतकऱ्यांसाठी मदतीचा निर्णय मंत्रिमंडळाने घेतला.',
    seen: true,
  ),
];

Future<void> _seed(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': DateTime(2026, 10, 12, 6).toUtc().toIso8601String(),
    'page': {
      ...feedBody([
        _reports[0],
        {
          ...feedJson(
            'gr1',
            grNumber: 'फळबाग-२०२६/प्र.क्र.४५',
            level: 'state',
            publishedAt: '2026-10-11T12:00:00Z',
            deadline: '2026-10-30',
          ),
          'title': 'फळबाग लागवड योजनेत अर्जाची मुदत वाढवली',
          'department': 'कृषी विभाग',
        },
        _reports[1],
        _reports[2],
      ]),
      'threads': [
        {
          'id': _topic,
          'title': _reports[0]['title'],
          'summary': _reports[0]['summary'],
          'latest_at': '2026-10-12T05:00:00Z',
          'item_count': 3,
          'unseen_count': 1,
          'has_new': true,
        },
      ],
    },
  }),
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (part, location) in [
      ('list', '/feed'),
      ('timeline', '/feed-thread/$_topic'),
    ]) {
      final name = 'feed_thread_${part}_mr_${mode.name}';
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: location,
          seed: _seed,
          size: _phone,
          overrides: [
            feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
          ],
        );
        await settle(tester);
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
