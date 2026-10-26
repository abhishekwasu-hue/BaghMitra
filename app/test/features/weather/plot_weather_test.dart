import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

Map<String, Object?> sampleWeather({bool stale = false}) => {
  'days': [
    for (var i = 0; i < 4; i++)
      {
        'day': '2026-10-${13 + i}',
        't_max_c': 34.0 + i,
        't_min_c': 20.0,
        'precip_mm': i == 1 ? 12.5 : 0.0,
        'rh_mean_pct': 50.0,
        'wind_gust_kmh': 20.0,
      },
  ],
  'alerts': [
    {
      'rule_key': 'heat_fruit_drop',
      'first_day': '2026-10-14',
      'value': 35.0,
      'units': null,
      'text': 'Heat of 35 °C or more expected: risk of fruit drop.',
      'source': 'ICAR-CCRI Nagpur monthly guidelines (March)',
      'status': 'draft',
    },
  ],
  'stale': stale,
};

void main() {
  test('refresh stores the response; load works offline', () async {
    final db = memoryDb();
    addTearDown(db.close);
    var online = true;
    final requested = <Uri>[];
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => 't',
      httpClient: MockClient((req) async {
        requested.add(req.url);
        if (!online) throw http.ClientException('offline');
        return http.Response(jsonEncode(sampleWeather()), 200);
      }),
    );
    final cache = PlotWeatherCache(
      db,
      api: api,
      clock: () => DateTime.utc(2026, 10, 13, 6),
    );
    expect(await cache.load('p1', 'mr'), isNull);
    expect(await cache.refresh('p1', 'mr'), isTrue);
    expect(requested.single.path, '/v1/plots/p1/weather');
    expect(requested.single.queryParameters['lang'], 'mr');

    online = false;
    expect(await cache.refresh('p1', 'mr'), isFalse);
    final cached = (await cache.load('p1', 'mr'))!;
    expect(cached.weather.days, hasLength(4));
    expect(cached.weather.alerts.single.ruleKey, 'heat_fruit_drop');
    expect(cached.savedAt, DateTime.utc(2026, 10, 13, 6));
  });

  testWidgets('plot detail shows cached weather, rain and sourced alerts', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: (db) async {
        await seedPlot(db, lat: 21.2468, lon: 77.7512);
        await db.writeMeta(
          PlotWeatherCache.keyFor('p1', 'en'),
          jsonEncode({
            'saved_at': '2026-10-13T06:00:00.000Z',
            'weather': sampleWeather(stale: true),
          }),
        );
      },
    );
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('plot-weather')), 200);
    expect(find.text('Weather'), findsOneWidget);
    expect(find.textContaining('35°'), findsWidgets);
    expect(find.textContaining('12.5 mm'), findsOneWidget);
    expect(find.textContaining('risk of fruit drop'), findsOneWidget);
    expect(find.textContaining('ICAR-CCRI'), findsOneWidget);
    expect(find.textContaining('not yet checked by an expert'), findsOneWidget);
    expect(find.textContaining('could not be updated'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('no weather card without a plot location', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: seedPlot,
    );
    await settle(tester);
    expect(find.byKey(const Key('plot-weather')), findsNothing);
    await unmountApp(tester);
  });
}
