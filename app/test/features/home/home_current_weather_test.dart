// Owner Q140: the home header's big number is the temperature now (with "आत्ता" and its
// reading time), and today's max / min are labelled on the second line. Without a fresh
// reading (offline, 3 hours or more) the header shows the labelled max / min, never "आत्ता".
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'home_seed.dart';

/// The saved reading: 18:15 at night, clear sky, 22.4 °C (the test zone is UTC).
const nightReading = {
  'temperature_c': 22.4,
  'weather_code': 0,
  'is_day': false,
  'observed_at': '2026-10-13T18:15:00Z',
};

/// The saved reading: 11:30 by day, partly cloudy, 31.6 °C.
const dayReading = {
  'temperature_c': 31.6,
  'weather_code': 2,
  'is_day': true,
  'observed_at': '2026-10-13T11:30:00Z',
};

Future<void> pumpHomeWith(
  WidgetTester tester, {
  required Map<String, Object?>? current,
  required DateTime now,
  ThemeMode themeMode = ThemeMode.light,
  Size size = phoneSize,
}) async {
  await pumpApp(
    tester,
    config: realConfig,
    themeMode: themeMode,
    size: size,
    clock: () => now,
    // The test server answers 503: the saved copy is what shows (offline).
    syncStatus: const SyncStatus(connectivity: Connectivity.online),
    seed: (db) => seedHomeData(db, current: current),
  );
  await settle(tester);
}

String _label(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('night: the reading now, its time, a moon, and the labelled '
      "day's max / min", (tester) async {
    await pumpHomeWith(
      tester,
      current: nightReading,
      now: DateTime.utc(2026, 10, 13, 18, 27),
    );
    expect(_label(tester, 'weather-temperature'), '२२°');
    expect(_label(tester, 'weather-temperature-label'), 'आत्ता');
    expect(_label(tester, 'weather-temperature-time'), '१८:१५ ला');
    expect(find.byKey(const Key('weather-sky-clear-night')), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_rounded), findsNothing);
    expect(
      _label(tester, 'weather-details'),
      'बाग १ · आज कमाल ३५° · किमान २१°',
    );
    await unmountApp(tester);
  });

  testWidgets('day: the reading now with the sun-and-cloud sky', (
    tester,
  ) async {
    await pumpHomeWith(
      tester,
      current: dayReading,
      now: DateTime.utc(2026, 10, 13, 11, 40),
    );
    expect(_label(tester, 'weather-temperature'), '३२°');
    expect(_label(tester, 'weather-temperature-label'), 'आत्ता');
    expect(_label(tester, 'weather-temperature-time'), '११:३० ला');
    expect(find.byKey(const Key('weather-sky-cloudy')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('offline, fresh: a reading 2 h 50 min old still stands as now', (
    tester,
  ) async {
    await pumpHomeWith(
      tester,
      current: nightReading,
      now: DateTime.utc(2026, 10, 13, 21, 5),
    );
    expect(_label(tester, 'weather-temperature-label'), 'आत्ता');
    expect(_label(tester, 'weather-temperature-time'), '१८:१५ ला');
    await unmountApp(tester);
  });

  testWidgets('offline, old: 3 hours on, the labelled max / min and no '
      '"आत्ता"', (tester) async {
    await pumpHomeWith(
      tester,
      current: nightReading,
      now: DateTime.utc(2026, 10, 13, 21, 15),
    );
    expect(_label(tester, 'weather-temperature'), '३५°');
    expect(_label(tester, 'weather-temperature-label'), 'आज कमाल');
    expect(find.byKey(const Key('weather-temperature-time')), findsNothing);
    expect(find.text('आत्ता'), findsNothing);
    expect(find.byKey(const Key('weather-sky-none')), findsOneWidget);
    expect(_label(tester, 'weather-details'), 'बाग १ · किमान २१°');
    await unmountApp(tester);
  });

  testWidgets('no reading saved (older server): the labelled max / min', (
    tester,
  ) async {
    await pumpHomeWith(
      tester,
      current: null,
      now: DateTime.utc(2026, 10, 13, 6),
    );
    expect(_label(tester, 'weather-temperature-label'), 'आज कमाल');
    expect(find.text('आत्ता'), findsNothing);
    await unmountApp(tester);
  });
}
