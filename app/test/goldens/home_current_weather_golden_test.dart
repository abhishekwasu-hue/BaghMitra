// Owner Q140: the home header with the temperature now, by day and by night, on a 360 px
// phone at 1.3x text, light and dark; and the offline fallback (reading 3 h or older).
// Regenerate with:
//   flutter test --update-goldens test/goldens/home_current_weather_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/home/home_current_weather_test.dart'
    show dayReading, nightReading, pumpHomeWith;
import '../helpers/pump_app.dart' show unmountApp;

void main() {
  const narrow = Size(360, 780);
  final day = DateTime.utc(2026, 10, 13, 11, 40);
  final night = DateTime.utc(2026, 10, 13, 18, 27);
  final cases = <String, (Map<String, Object?>, DateTime, ThemeMode)>{
    'home_now_day_mr_light_360_x13': (dayReading, day, ThemeMode.light),
    'home_now_day_mr_dark_360_x13': (dayReading, day, ThemeMode.dark),
    'home_now_night_mr_light_360_x13': (nightReading, night, ThemeMode.light),
    'home_now_night_mr_dark_360_x13': (nightReading, night, ThemeMode.dark),
    // Offline, the 18:15 reading is 3 h old: today's max / min, labelled.
    'home_now_old_mr_light_360_x13': (
      nightReading,
      DateTime.utc(2026, 10, 13, 21, 15),
      ThemeMode.light,
    ),
  };
  for (final MapEntry(key: name, value: (current, now, mode))
      in cases.entries) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpHomeWith(
        tester,
        current: current,
        now: now,
        themeMode: mode,
        size: narrow,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
