// Screens that had no golden before the UI uniformity pass. Regenerate with:
//   flutter test --update-goldens test/goldens
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart'
    show seedPlot, seedPlotWithCycle;
import '../features/feed/feed_data_test.dart' show FakeFeedRepository;
import '../features/feed/feed_screen_test.dart' show seedFeed;
import '../features/market/market_prices_test.dart' show seedPrices;
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/profile/profile_screen_test.dart' show seedProfile;
import '../features/scouting/scouting_test.dart' show seedScouting;
import '../features/spray/spray_screen_test.dart' show seedWithSpray;
import '../helpers/pump_app.dart';

Future<void> _seedProfile(AppDatabase db) => seedProfile(db);
Future<void> _seedFeed(AppDatabase db) => seedFeed(db, lang: 'mr');
Future<void> _seedPrices(AppDatabase db) => seedPrices(db);

void main() {
  for (final (name, location, seed, mode, scale) in [
    ('tasks_empty_mr_light', '/tasks', seedPlot, ThemeMode.light, 1.0),
    ('add_task_mr_light', '/tasks/new', seedPlot, ThemeMode.light, 1.0),
    ('market_mr_light', '/market', _seedPrices, ThemeMode.light, 1.0),
    ('feed_mr_light', '/feed', _seedFeed, ThemeMode.light, 1.0),
    (
      'plot_detail_mr_light',
      '/plots/p1',
      seedPlotWithCycle,
      ThemeMode.light,
      1.0,
    ),
    (
      'scouting_mr_light',
      '/plots/p1/scouting',
      seedScouting,
      ThemeMode.light,
      1.0,
    ),
    (
      'add_scouting_mr_light',
      '/plots/p1/scouting/new',
      seedPlot,
      ThemeMode.light,
      1.0,
    ),
    (
      'sprays_empty_mr_light',
      '/plots/p1/sprays',
      seedPlot,
      ThemeMode.light,
      1.0,
    ),
    ('profile_mr_light', '/profile', _seedProfile, ThemeMode.light, 1.0),
    (
      'add_spray_mr_dark',
      '/plots/p1/sprays/new',
      seedWithSpray,
      ThemeMode.dark,
      1.0,
    ),
    // Older growers often raise the phone's text size: Marathi must still fit.
    (
      'add_spray_mr_x13',
      '/plots/p1/sprays/new',
      seedWithSpray,
      ThemeMode.light,
      1.3,
    ),
    ('market_mr_x13', '/market', _seedPrices, ThemeMode.light, 1.3),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: location,
        seed: seed,
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
