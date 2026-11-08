// Market link L1 (spec v1.5 §2.1, §4C): role cards, acceptance and a role home, Marathi,
// light and dark, and at 360 dp with 1.3x text. Regenerate with:
//   flutter test --update-goldens test/goldens/market_link_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/market_link_screens_test.dart'
    show seedAcceptedTrader;
import '../features/market_link/terms_acceptance_test.dart' show marketConfig;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _small = Size(360, 780);

void main() {
  for (final (name, location, seed, mode, scale, size) in [
    ('l1_roles_mr_light', '/roles', null, ThemeMode.light, 1.0, phoneSize),
    ('l1_roles_mr_dark', '/roles', null, ThemeMode.dark, 1.0, phoneSize),
    ('l1_roles_mr_x13', '/roles', null, ThemeMode.light, 1.3, _small),
    (
      'l1_terms_mr_light',
      '/roles/trader',
      null,
      ThemeMode.light,
      1.0,
      phoneSize,
    ),
    ('l1_terms_mr_dark', '/roles/trader', null, ThemeMode.dark, 1.0, phoneSize),
    ('l1_terms_mr_x13', '/roles/trader', null, ThemeMode.light, 1.3, _small),
    (
      'l1_role_home_mr_light',
      '/roles/trader',
      seedAcceptedTrader,
      ThemeMode.light,
      1.0,
      phoneSize,
    ),
    (
      'l1_role_home_mr_dark',
      '/roles/trader',
      seedAcceptedTrader,
      ThemeMode.dark,
      1.0,
      phoneSize,
    ),
    (
      'l1_role_home_mr_x13',
      '/roles/trader',
      seedAcceptedTrader,
      ThemeMode.light,
      1.3,
      _small,
    ),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        config: marketConfig,
        themeMode: mode,
        initialLocation: location,
        seed: seed,
        size: size,
      );
      await settle(tester);
      if (name.startsWith('l1_role_home')) {
        await tester.tap(find.byKey(const Key('grievance')));
        await settle(tester);
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  // Signed out: the welcome band, then the role cards (owner 2026-11-08).
  for (final (name, mode, scale, size) in [
    ('l1_welcome_mr_light', ThemeMode.light, 1.0, phoneSize),
    ('l1_welcome_mr_dark', ThemeMode.dark, 1.0, phoneSize),
    ('l1_welcome_mr_x13', ThemeMode.light, 1.3, _small),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        session: null,
        config: marketConfig,
        themeMode: mode,
        size: size,
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
