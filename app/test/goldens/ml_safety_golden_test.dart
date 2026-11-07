// Market link trust and safety (L6) at phone size, Marathi, light and dark. Regenerate with:
//   flutter test --update-goldens test/goldens/ml_safety_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/safety_screens_test.dart';
import '../helpers/pump_app.dart';

void main() {
  for (final (name, location, scale) in [
    ('report', '/market-link/report/broker/br1', 1.0),
  ]) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      if (scale > 1 && dark) continue;
      testWidgets('ml_safety_${name}_mr_$mode', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpSafety(
          tester,
          FakeSafety(
            actions: [
              action('a1', 'hide', 'fake_identity'),
              action(
                'a2',
                'warn',
                'abuse',
                state: 'appealed',
                appealReason: 'behaviour_proper',
              ),
              action('a3', 'verify', 'checks_passed'),
            ],
          ),
          location: location,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('ml_safety_${name}_mr_$mode.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
