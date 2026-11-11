// The weather forecast screen (Q134) at 360 x 780, Marathi, 1.3x text, light and dark.
// Regenerate with:
//   flutter test --update-goldens test/goldens/weather_forecast_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/plots/plots_screen_test.dart' show settle;
import '../features/weather/weather_forecast_test.dart' show seedForecast;
import '../helpers/pump_app.dart';

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = 'weather_forecast_mr_${mode.name}';
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/plots/p1/weather',
        seed: seedForecast,
        size: const Size(360, 780),
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
