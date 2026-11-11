// The weather forecast screen (Q134): the next 15 days of the cached plot weather as a
// table, numbers only, rain and heat coloured by meaning; opened from the home header and
// from the plot weather card.
import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:bagmitra/features/weather/presentation/weather_forecast_screen.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:bagmitra/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../home/home_seed.dart';
import '../plots/plots_screen_test.dart' show settle;

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

/// One past day and 15 days from the test clock's 2026-10-13: day 1 rains (12.5 mm, 80 %),
/// day 4 has a 60 % chance with no rain amount, day 5 a 20 % chance (no colour), day 2 is
/// hot (37 °C), day 3 brings a thunderstorm.
Map<String, Object?> forecastWeather({bool stale = false}) => {
  'days': [
    for (var i = -1; i < 15; i++)
      {
        'day': _iso(DateTime.utc(2026, 10, 13 + i)),
        't_max_c': i == 2 ? 37.0 : 31.0 + (i % 3),
        't_min_c': 19.0,
        'precip_mm': i == 1 ? 12.5 : 0.0,
        'rh_mean_pct': 55.0 + i,
        'wind_gust_kmh': i == 3 ? 61.0 : 18.0,
        'weather_code': switch (i) {
          1 => 61.0,
          3 => 95.0,
          5 => 3.0,
          _ => 0.0,
        },
        'rain_prob_pct': switch (i) {
          -1 => null,
          1 => 80.0,
          4 => 60.0,
          5 => 20.0,
          _ => 5.0,
        },
      },
  ],
  'alerts': <Object?>[],
  'stale': stale,
};

Future<void> seedForecast(
  AppDatabase db, {
  String lang = 'mr',
  bool stale = false,
}) async {
  await seedPlot(db, lat: 21.2468, lon: 77.7512);
  await db.writeMeta(
    PlotWeatherCache.keyFor('p1', lang),
    jsonEncode({
      'saved_at': '2026-10-13T05:00:00.000Z',
      'weather': forecastWeather(stale: stale),
    }),
  );
}

Color? _colour(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).style?.color;

void main() {
  testWidgets('15 rows from today with every value of the day', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/weather',
      seed: (db) => seedForecast(db, lang: 'en'),
    );
    await settle(tester);
    expect(find.text('Weather forecast'), findsOneWidget);
    expect(find.byKey(const Key('forecast-row-2026-10-12')), findsNothing);
    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('forecast-row-'),
      skipOffstage: false,
    );
    expect(rows, findsNWidgets(15));
    expect(find.byKey(const Key('forecast-row-2026-10-27')), findsOneWidget);

    String text(String key) => tester.widget<Text>(find.byKey(Key(key))).data!;
    expect(text('forecast-day-2026-10-14'), 'Wed');
    expect(text('forecast-date-2026-10-14'), '14/10');
    expect(text('forecast-max-2026-10-14'), '32°');
    expect(text('forecast-min-2026-10-14'), '19°');
    expect(text('forecast-rain-mm-2026-10-14'), '12.5');
    expect(text('forecast-rain-prob-2026-10-14'), '80%');
    expect(text('forecast-wind-2026-10-16'), '61');
    expect(text('forecast-rh-2026-10-14'), '56%');
    expect(find.byIcon(Icons.thunderstorm_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Thunderstorm'), findsOneWidget);
    // Numbers only: no advice line on the screen.
    expect(find.textContaining('should'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('rain and heat are coloured by meaning', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/weather',
      seed: (db) => seedForecast(db, lang: 'en'),
    );
    await settle(tester);
    const c = BmColors.light;
    // Rain amount, or a chance of 50 % or more: the info (sky) ink.
    expect(_colour(tester, 'forecast-rain-mm-2026-10-14'), c.info);
    expect(_colour(tester, 'forecast-rain-prob-2026-10-14'), c.info);
    expect(_colour(tester, 'forecast-rain-prob-2026-10-17'), c.info);
    expect(_colour(tester, 'forecast-rain-prob-2026-10-18'), isNot(c.info));
    expect(_colour(tester, 'forecast-rain-mm-2026-10-13'), isNot(c.info));
    // 35 °C and above (the heat rule's threshold): the caution ink on the max.
    expect(_colour(tester, 'forecast-max-2026-10-15'), c.caution);
    expect(_colour(tester, 'forecast-max-2026-10-14'), isNot(c.caution));
    expect(find.text('Rain likely'), findsOneWidget);
    expect(find.text('35° and above'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('offline: the saved days with their time and the stale line', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/weather',
      seed: (db) => seedForecast(db, lang: 'en', stale: true),
    );
    await settle(tester);
    expect(find.byKey(const Key('refresh-updated')), findsOneWidget);
    expect(find.textContaining('Updated 13 Oct 2026'), findsOneWidget);
    expect(find.textContaining('Showing the last saved days'), findsOneWidget);
    expect(find.byKey(const Key('forecast-row-2026-10-13')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('nothing saved yet says when the weather comes', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/weather',
      seed: (db) => seedPlot(db, lat: 21.2468, lon: 77.7512),
    );
    await settle(tester);
    expect(
      find.text('Weather loads when the phone is online.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('forecast-table')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a block without a location asks for it', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/weather',
      seed: seedPlot,
    );
    await settle(tester);
    expect(
      find.text("Add the block's location to see its weather here."),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  for (final lang in ['en', 'mr', 'hi']) {
    testWidgets('fits 360 px at 1.3x text ($lang)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        locale: Locale(lang),
        initialLocation: '/plots/p1/weather',
        seed: (db) => seedForecast(db, lang: lang),
        size: const Size(360, 780),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('forecast-table')), findsOneWidget);
      final table = tester.getRect(find.byKey(const Key('forecast-table')));
      expect(table.right, lessThanOrEqualTo(360));
      await unmountApp(tester);
    });
  }

  testWidgets('home: tapping the weather opens the forecast of the one block', (
    tester,
  ) async {
    await pumpApp(
      tester,
      config: realConfig,
      syncStatus: const SyncStatus(connectivity: Connectivity.online),
      seed: seedHomeData,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-forecast')));
    await settle(tester);
    final screen = tester.widget<WeatherForecastScreen>(
      find.byType(WeatherForecastScreen),
    );
    expect(screen.plotId, homePlotId);
    expect(find.text('हवामान अंदाज'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('plot weather card links to the next 15 days', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: (db) => seedForecast(db, lang: 'en'),
    );
    await settle(tester);
    final link = find.byKey(const Key('weather-forecast-link'));
    await tester.scrollUntilVisible(link, 200);
    expect(find.text('Next 15 days'), findsOneWidget);
    await tester.tap(link);
    await settle(tester);
    expect(find.byType(WeatherForecastScreen), findsOneWidget);
    await unmountApp(tester);
  });
}
