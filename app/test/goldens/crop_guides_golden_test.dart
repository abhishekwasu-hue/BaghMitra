// Owner 2026-11-14 (पीक मार्गदर्शक, Q161): the mustard crop guide and the guide button under a
// feed item that names a crop, on a 360 px phone at 1.3x text, light and dark. Regenerate:
//   flutter test --update-goldens test/goldens/crop_guides_golden_test.dart
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

Future<void> _seedNews(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': '2026-10-12T06:00:00.000Z',
    'page': feedBody([
      {
        ...feedJson(
          'n1',
          type: 'news',
          trust: 'news',
          grNumber: null,
          department: null,
          publishedAt: '2026-10-11T06:00:00Z',
        ),
        'title': 'रब्बी हंगामासाठी बियाणे उपलब्ध',
        'summary':
            'कृषी विभागाकडे हरभरा व मोहरीचे बियाणे अनुदानावर उपलब्ध आहे.',
      },
    ]),
  }),
);

void main() {
  const narrow = Size(360, 780);
  for (final (name, mode) in [
    ('crop_guide_mustard_mr_light_360_x13', ThemeMode.light),
    ('crop_guide_mustard_mr_dark_360_x13', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        size: narrow,
        initialLocation: '/crop-guide/mustard',
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, mode) in [
    ('feed_crop_guide_button_mr_light_360_x13', ThemeMode.light),
    ('feed_crop_guide_button_mr_dark_360_x13', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        size: narrow,
        initialLocation: '/feed/n1',
        seed: _seedNews,
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      final button = find.byKey(const Key('crop-guide-link-gram'));
      await tester.scrollUntilVisible(button, 200);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
