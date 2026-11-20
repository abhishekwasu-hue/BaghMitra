// Q165 (owner 2026-11-20): the ज्ञान chip lists older articles and ends with "आणखी जुने
// दाखवा", on a 360 px phone at 1.3x text, light and dark. Regenerate:
//   flutter test --update-goldens test/goldens/feed_older_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/feed/feed_data_test.dart'
    show FakeFeedRepository, feedBody, feedJson;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

Map<String, Object?> _article(
  String id,
  String at,
  String title,
  String summary,
) => {
  ...feedJson(
    id,
    type: 'knowledge',
    publishedAt: at,
    grNumber: null,
    department: null,
  ),
  'title': title,
  'summary': summary,
};

void main() {
  const narrow = Size(360, 780);
  for (final (name, mode) in [
    ('feed_knowledge_older_mr_light_360_x13', ThemeMode.light),
    ('feed_knowledge_older_mr_dark_360_x13', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const footer =
          'कोणतीही कृती करण्यापूर्वी अधिकृत शासन निर्णय (GR) / पोर्टल तपासा.';
      final repo = FakeFeedRepository({...feedBody([]), 'footer': footer});
      repo.pages[(FeedFilter.knowledge, null)] = {
        ...feedBody([
          _article(
            'k2',
            '2026-10-10T06:00:00Z',
            'सायला: नवतीवर लक्ष',
            'नवती फुटताना सायलाची पिल्ले कोवळ्या पानांवर दिसतात; बागेची पाहणी करावी.',
          ),
          _article(
            'k1',
            '2026-09-20T06:00:00Z',
            'आंबिया बहार: ताण संपवताना',
            'ताण सोडताना पहिले पाणी हलके द्यावे.',
          ),
        ]),
        'footer': footer,
        'next': {'before': '2026-09-20T06:00:00Z', 'before_id': 'k1'},
      };
      await pumpApp(
        tester,
        themeMode: mode,
        size: narrow,
        initialLocation: '/feed',
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('feed-filter-knowledge')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('feed-show-older')));
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
