@Tags(['golden'])
library;

import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/accounts/accounts_screen_test.dart' show seedAccounts;
import '../features/accounts/compare_screen_test.dart' show seedTwoSeasons;
import '../features/bahar/bahar_screen_test.dart' show seedPlotWithCycle;
import '../features/field_work/field_work_screens_test.dart' show seedWork;
import '../features/inputs/field_log_test.dart' show seedLog;
import '../features/plots/boundary_screen_test.dart'
    show ScriptedLocation, walkOf;
import '../features/plots/geo_test.dart' show square;
import '../features/plots/place_address_test.dart' show katol;
import '../features/plots/plots_screen_test.dart' show seedTwo, settle;
import '../features/spray/spray_screen_test.dart' show seedWithSpray;
import '../helpers/pump_app.dart';

void main() {
  for (final (name, mode) in [
    ('plots_mr_light', ThemeMode.light),
    ('plots_mr_dark', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/plots',
        seed: seedTwo,
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('plots_empty_mr_light', (tester) async {
    await pumpApp(tester, initialLocation: '/plots');
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('plots_empty_mr_light.png'),
    );
    await unmountApp(tester);
  });

  // Older growers often raise the phone's text size: Marathi must still fit.
  for (final (name, scale) in [
    ('add_plot_mr_light', 1.0),
    ('add_plot_mr_x13', 1.3),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, initialLocation: '/plots/new');
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  // After standing in the block: the point as numbers, with its accuracy and the nearby
  // place the phone's geocoder names (display only, Q59).
  testWidgets('add_plot_point_mr_light', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/plots/new',
      geocoder: FakeGeocoder(katol),
      location: ScriptedLocation(
        const [],
        fixes: const [
          [LocationReading.at(LatLon(21.2468, 77.7512), accuracyM: 6)],
        ],
      ),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('point-take')));
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('add_plot_point_mr_light.png'),
    );
    await unmountApp(tester);
  });

  for (final (name, location) in [
    ('bahar_mr_light', '/plots/p1/bahar'),
    ('start_bahar_mr_light', '/plots/p1/bahar/new'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedPlotWithCycle);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, location) in [
    ('accounts_mr_light', '/plots/p1/accounts'),
    ('add_expense_mr_light', '/plots/p1/accounts/expense'),
    ('add_sale_mr_light', '/plots/p1/accounts/sale'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedAccounts);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, location) in [
    ('spray_log_mr_light', '/plots/p1/sprays'),
    ('add_spray_mr_light', '/plots/p1/sprays/new'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedWithSpray);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, location) in [
    ('labour_mr_light', '/plots/p1/labour'),
    ('add_labour_mr_light', '/plots/p1/labour/new'),
    ('harvest_mr_light', '/plots/p1/harvest'),
    ('add_harvest_mr_light', '/plots/p1/harvest/new'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedWork);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, location) in [
    ('field_log_mr_light', '/plots/p1/log'),
    ('add_input_mr_light', '/plots/p1/log/input'),
    ('add_irrigation_mr_light', '/plots/p1/log/irrigation'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedLog);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('compare_mr_light', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/plots/p1/compare',
      seed: seedTwoSeasons,
    );
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('compare_mr_light.png'),
    );
    await unmountApp(tester);
  });

  testWidgets('onboarding_mr_light', (tester) async {
    await pumpApp(tester, locale: null, onboarded: false);
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('onboarding_mr_light.png'),
    );
    await unmountApp(tester);
  });

  testWidgets('boundary_mr_light', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/plots/new/boundary',
      location: ScriptedLocation(walkOf(square(100))),
    );
    await settle(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(FilledButton).first);
      await settle(tester);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('boundary_mr_light.png'),
    );
    await unmountApp(tester);
  });
}
