// The mandi price trend sheet (owner 2026-11-09, Q130) at phone width, Marathi, 1.3x text,
// light and dark, with a day picked on the chart.
//   flutter test --update-goldens test/goldens/price_trend_golden_test.dart
@Tags(['golden'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market/market_prices_test.dart' show seedPrices;
import '../features/market/price_trend_test.dart' show day, seedHistory;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

/// A price on most days for three months: Sundays closed and one week without a price
/// (2026-09-05 to 09-11), so the chart shows its gap.
Map<String, Object?> _dense() {
  final days = <Map<String, Object?>>[];
  for (
    var d = DateTime(2026, 7, 16);
    d.isBefore(DateTime(2026, 10, 13));
    d = d.add(const Duration(days: 1))
  ) {
    if (d.weekday == DateTime.sunday) continue;
    final gap =
        d.isAfter(DateTime(2026, 9, 4)) && d.isBefore(DateTime(2026, 9, 12));
    if (gap) continue;
    final i = d.difference(DateTime(2026, 7, 16)).inDays;
    final modal = (3000 + 600 * math.sin(i / 14) + 8 * i).round() ~/ 50 * 50;
    final iso = d.toIso8601String().substring(0, 10);
    days.add(day(iso, modal, min: modal - 500, max: modal + 400));
  }
  return {
    'market': 'Warud',
    'variety': 'Nagpuri',
    'grade': 'FAQ',
    'days': days,
    'stale': false,
  };
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = 'price_trend_mr_${mode.name}';
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/market',
        size: _phone,
        seed: (db) async {
          await seedPrices(db);
          await seedHistory(db, body: _dense());
        },
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('market-trend-Warud')));
      await settle(tester);
      // A finger on the chart near the start of October.
      final chart = find.byKey(const Key('trend-chart'));
      final box = tester.getRect(chart);
      await tester.tapAt(Offset(box.left + box.width * 0.86, box.center.dy));
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
