// Visual regression suite for Home (spec §4A). Regenerate with:
//   flutter test --update-goldens test/goldens
@Tags(['golden'])
library;

import 'package:bagmitra/features/weather/data/alert_switches.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/home/home_seed.dart';
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

void main() {
  final cases = <String, (Locale, ThemeMode)>{
    'home_mr_light': (const Locale('mr'), ThemeMode.light),
    'home_mr_dark': (const Locale('mr'), ThemeMode.dark),
    'home_hi_light': (const Locale('hi'), ThemeMode.light),
    'home_en_light': (const Locale('en'), ThemeMode.light),
  };
  for (final MapEntry(key: name, value: (locale, mode)) in cases.entries) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, locale: locale, themeMode: mode);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  // Q133: the heat alert switched off with its ⚠ button: one muted line remains.
  for (final (name, mode) in [
    ('home_alert_off_mr_light', ThemeMode.light),
    ('home_alert_off_mr_dark', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        themeMode: mode,
        seed: (db) => AlertSwitches(db).setOn('heat_fruit_drop', on: false),
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('home_mr_offline', (tester) async {
    await pumpApp(
      tester,
      syncStatus: const SyncStatus(
        connectivity: Connectivity.offline,
        pending: 2,
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('home_mr_offline.png'),
    );
    await unmountApp(tester);
  });

  // A production build (backend configured): only the grower's own data (B1 / H2 / H3).
  for (final (name, seed, scale) in [
    ('home_real_new_mr_light', null, 1.0),
    ('home_real_data_mr_light', seedHomeData, 1.0),
    ('home_real_data_mr_x13', seedHomeData, 1.3),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        config: realConfig,
        syncStatus: const SyncStatus(connectivity: Connectivity.online),
        seed: seed,
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('login_mr_light', (tester) async {
    await pumpApp(tester, session: null);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('login_mr_light.png'),
    );
    await unmountApp(tester);
  });

  testWidgets('gallery_en_light', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/dev/gallery',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('gallery_en_light.png'),
    );
    await unmountApp(tester);
  });
}
