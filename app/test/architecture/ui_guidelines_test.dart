// Sunlight and thumb checks on the main list and form screens: every labelled tap target
// is at least 48 dp and text meets WCAG contrast (the santra buttons once failed at 2.4:1).
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/accounts/accounts_screen_test.dart' show seedAccounts;
import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/feed/feed_data_test.dart' show FakeFeedRepository;
import '../features/feed/feed_screen_test.dart' show seedFeed;
import '../features/lab_tests/lab_tests_test.dart' show seedLabTest;
import '../features/market/market_prices_test.dart' show seedPrices;
import '../features/plots/plots_screen_test.dart' show seedTwo, settle;
import '../features/spray/spray_screen_test.dart' show seedWithSpray;
import '../features/tasks/tasks_test.dart' show task;
import '../helpers/pump_app.dart';

Future<void> _seedTask(AppDatabase db) => TasksRepository(
  db,
  clock: () => DateTime.utc(2026, 10, 13, 6),
).save(task('t1', DateTime(2026, 10, 13)));

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  for (final (location, seed) in [
    ('/', null),
    ('/plots', seedTwo),
    ('/tasks', _seedTask),
    ('/tasks/new', seedPlot),
    ('/market', seedPrices),
    ('/feed/gr1', seedFeed),
    ('/plots/p1/sprays', seedWithSpray),
    ('/plots/p1/sprays/new', seedWithSpray),
    ('/plots/p1/accounts', seedAccounts),
    ('/plots/p1/labour/new', seedPlot),
    ('/plots/p1/insurance/new', seedPlot),
    ('/claim-kit?plot=p1', seedPlot),
    ('/plots/p1/lab-tests/new', seedPlot),
    ('/plots/p1/lab-tests/l1', seedLabTest),
    ('/schemes', null),
    ('/schemes/pm_kisan', null),
    ('/lookalikes?plot=p1', seedPlot),
    ('/labs', null),
    ('/market/directory', null),
  ]) {
    testWidgets('tap targets and contrast on $location', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        initialLocation: location,
        seed: seed,
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await unmountApp(tester);
      handle.dispose();
    });
  }

  // Icons on a santra fill (camera button, alert tile) are graphics: WCAG asks 3:1.
  // White on santra is 2.4:1 and washes out in sunlight.
  for (final (name, c) in [
    ('light', BmColors.light),
    ('dark', BmColors.dark),
  ]) {
    test('icons on santra are readable ($name)', () {
      expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(c.onAccent, c.accentSoft), greaterThanOrEqualTo(4.5));
      expect(contrast(c.accentInk, c.card), greaterThanOrEqualTo(3));
    });
  }
}
