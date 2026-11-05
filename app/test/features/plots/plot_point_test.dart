import 'dart:async';
import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import 'boundary_screen_test.dart' show ScriptedLocation;
import 'plots_screen_test.dart' show settle;

const here = LatLon(21.24680, 77.75120);
const there = LatLon(21.25010, 77.76030);

LocationReading at(LatLon p, double m) => LocationReading.at(p, accuracyM: m);

Future<Map<String, Object?>> plotPayload(
  WidgetTester tester,
  AppDatabase db,
) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.outboxEntries,
    )..where((t) => t.entity.equals('plot'))).get(),
  );
  return jsonDecode(rows!.last.payload) as Map<String, Object?>;
}

Future<void> fillAndSave(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('plot-name')), 'North block');
  await tester.enterText(find.byKey(const Key('plot-acres')), '2');
  await tester.tap(find.text('Save'));
  await settle(tester);
}

/// Records which plots the weather card asked for.
class RecordingWeatherCache extends PlotWeatherCache {
  RecordingWeatherCache(super.db)
    : super(
        api: createApi(
          baseUrl: Uri.parse('https://api.example.test'),
          token: () => 't',
          httpClient: MockClient((_) async => http.Response('{}', 500)),
        ),
        clock: () => DateTime.utc(2026, 10, 13, 6),
      );

  final asked = <String>[];

  @override
  Future<CachedWeather?> load(String plotId, String lang) {
    asked.add(plotId);
    return super.load(plotId, lang);
  }
}

void main() {
  group('bestFixOf', () {
    Future<LocationReading> best(
      Stream<LocationReading> s, {
      Duration within = const Duration(seconds: 5),
    }) => bestFixOf(s, within: within, goodEnoughM: 15);

    test('keeps the most accurate fix and stops at a good one', () async {
      var asked = 0;
      final r = await best(
        Stream.fromIterable([at(there, 40), at(here, 9), at(there, 3)])
            .map((f) {
              asked++;
              return f;
            }),
      );
      expect(r.position, here);
      expect(r.accuracyM, 9);
      expect(asked, 2, reason: 'a fix within 15 m ends the wait');
    });

    test('a weak fix is kept when nothing better comes in time', () async {
      final c = StreamController<LocationReading>();
      addTearDown(c.close);
      c.add(at(here, 48));
      final r = await best(c.stream, within: const Duration(milliseconds: 50));
      expect(r.position, here);
      expect(r.accuracyM, 48);
    });

    test(
      'a problem before any fix is returned; after one it is ignored',
      () async {
        expect(
          (await best(
            Stream.value(const LocationReading.problem(LocationProblem.denied)),
          )).problem,
          LocationProblem.denied,
        );
        final r = await best(
          Stream.fromIterable([
            at(here, 30),
            const LocationReading.problem(LocationProblem.failed),
          ]),
        );
        expect(r.position, here);
      },
    );

    test('an error or an empty stream reads as failed', () async {
      expect(
        (await best(Stream.error(Exception('gps')))).problem,
        LocationProblem.failed,
      );
      expect(
        (await best(const Stream.empty())).problem,
        LocationProblem.failed,
      );
    });
  });

  testWidgets('a good fix is shown as numbers and saved as the location', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new',
      location: ScriptedLocation(
        const [],
        fixes: [
          [at(there, 35), at(here, 6)],
        ],
      ),
    );
    await settle(tester);
    expect(find.text('Walk the boundary (optional)'), findsOneWidget);
    await tester.tap(find.text('I am in the orchard — take location'));
    await settle(tester);
    expect(find.text('21.24680, 77.75120'), findsOneWidget);
    expect(find.text('±6 m'), findsOneWidget);
    await fillAndSave(tester);

    // The sync payload carries the point; the area stays what the grower typed.
    final p = await plotPayload(tester, db);
    expect(p['centroid_lat'], here.lat);
    expect(p['centroid_lon'], here.lon);
    expect(p['boundary'], isNull);
    expect((p['area_sq_m']! as num).toDouble(), closeTo(2 * 4046.86, 0.1));
    await unmountApp(tester);
  });

  testWidgets('a low-accuracy fix shows its accuracy and still saves', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new',
      location: ScriptedLocation(
        const [],
        fixes: [
          [at(there, 60), at(here, 42)],
        ],
      ),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('point-take')));
    await settle(tester);
    expect(find.text('±42 m'), findsOneWidget);
    expect(find.text('Take location again'), findsOneWidget);
    await fillAndSave(tester);
    final p = await plotPayload(tester, db);
    expect(p['centroid_lat'], here.lat);
    await unmountApp(tester);
  });

  testWidgets(
    'denied location: try again or open settings, saving still works',
    (tester) async {
      final gps = ScriptedLocation(
        const [],
        fixes: const [
          [LocationReading.problem(LocationProblem.denied)],
          [LocationReading.problem(LocationProblem.deniedForever)],
        ],
      );
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/new',
        location: gps,
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('point-take')));
      await settle(tester);
      expect(
        find.text('Allow location to save where this block is.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('point-settings')), findsNothing);
      expect(
        find.text('Save the block now; take the location any time later.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('point-retry')));
      await settle(tester);
      expect(gps.settles, 2);
      expect(
        find.text("Location is blocked. Allow it in the phone's app settings."),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('point-settings')));
      await settle(tester);
      expect(gps.openedFor, [LocationProblem.deniedForever]);

      await fillAndSave(tester);
      final p = await plotPayload(tester, db);
      expect(p['name'], 'North block');
      expect(p['centroid_lat'], isNull);
      await unmountApp(tester);
    },
  );

  testWidgets('GPS off offers the location setting', (tester) async {
    final gps = ScriptedLocation(
      const [],
      fixes: const [
        [LocationReading.problem(LocationProblem.serviceOff)],
      ],
    );
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new',
      location: gps,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('point-take')));
    await settle(tester);
    expect(find.text('Turn on location (GPS) on your phone.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('point-settings')));
    await settle(tester);
    expect(gps.openedFor, [LocationProblem.serviceOff]);
    await unmountApp(tester);
  });

  testWidgets('editing keeps a point-only location', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/edit',
      seed: (db) => seedPlot(db, lat: here.lat, lon: here.lon),
    );
    await settle(tester);
    expect(find.text('21.24680, 77.75120'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await settle(tester);
    final p = await plotPayload(tester, db);
    expect(p['centroid_lat'], here.lat);
    expect(p['centroid_lon'], here.lon);
    await unmountApp(tester);
  });

  testWidgets(
    'plot detail: taking the location again updates it and the weather card uses it',
    (tester) async {
      late RecordingWeatherCache weather;
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1',
        seed: seedPlot,
        location: ScriptedLocation(
          const [],
          fixes: [
            [at(here, 7)],
            [at(there, 5)],
          ],
        ),
        overrides: [
          plotWeatherCacheProvider.overrideWith(
            (ref) =>
                weather = RecordingWeatherCache(ref.watch(databaseProvider)),
          ),
        ],
      );
      await settle(tester);
      expect(find.byKey(const Key('plot-location')), findsOneWidget);
      expect(find.byKey(const Key('plot-weather')), findsNothing);

      await tester.tap(find.text('Take location'));
      await settle(tester);
      expect(find.text('21.24680, 77.75120'), findsOneWidget);
      expect(find.text('±7 m'), findsOneWidget);
      // A block with only a point (no boundary) gets its weather and alerts.
      expect(find.byKey(const Key('plot-weather')), findsOneWidget);
      expect(weather.asked, contains('p1'));

      await tester.tap(find.text('Take location again'));
      await settle(tester);
      expect(find.text('21.25010, 77.76030'), findsOneWidget);
      final saved = await tester.runAsync(
        () => PlotRepository(db).watchAll().first,
      );
      expect(saved!.single.centroidLat, there.lat);
      expect(saved.single.centroidLon, there.lon);
      expect(saved.single.boundary, isNull);
      expect((await plotPayload(tester, db))['centroid_lon'], there.lon);
      await unmountApp(tester);
    },
  );
}
