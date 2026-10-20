import 'dart:convert';

import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'geo_test.dart' show square;

/// Hands out scripted readings, one per tap.
class ScriptedLocation implements LocationService {
  ScriptedLocation(this._readings);
  final List<LocationReading> _readings;
  var taps = 0;

  @override
  Future<LocationReading> current() async =>
      _readings[taps < _readings.length ? taps++ : _readings.length - 1];
}

List<LocationReading> walkOf(List<LatLon> corners) => [
  for (final c in corners) LocationReading.at(c, accuracyM: 6),
];

void main() {
  testWidgets(
    'walking the corners shows the count and the area, then returns',
    (tester) async {
      final corners = square(100);
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/new/boundary',
        seed: seedPlot,
        location: ScriptedLocation(walkOf(corners)),
      );
      await settle(tester);
      expect(find.text('Add this corner'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Add this corner'));
        await settle(tester);
      }
      expect(find.text('4 corners'), findsOneWidget);
      expect(find.textContaining('Area about 2.47 acres'), findsOneWidget);
      expect(find.text('±6 m'), findsWidgets);
      await unmountApp(tester);
    },
  );

  testWidgets('three corners are needed before the grower can finish', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new/boundary',
      seed: seedPlot,
      location: ScriptedLocation(walkOf(square(100))),
    );
    await settle(tester);
    final done = find.widgetWithText(FilledButton, 'Done');
    expect(tester.widget<FilledButton>(done).onPressed, isNull);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Add this corner'));
      await settle(tester);
    }
    expect(tester.widget<FilledButton>(done).onPressed, isNotNull);
    await unmountApp(tester);
  });

  testWidgets('the last corner can be removed', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new/boundary',
      seed: seedPlot,
      location: ScriptedLocation(walkOf(square(100))),
    );
    await settle(tester);
    await tester.tap(find.text('Add this corner'));
    await settle(tester);
    await tester.tap(find.text('Add this corner'));
    await settle(tester);
    expect(find.text('2 corners'), findsOneWidget);
    await tester.tap(find.text('Remove last corner'));
    await settle(tester);
    expect(find.text('1 corners'), findsNothing);
    expect(find.text('1 corner'), findsOneWidget);
    await unmountApp(tester);
  });

  for (final (problem, message) in [
    (LocationProblem.serviceOff, 'Turn on location (GPS) on your phone.'),
    (LocationProblem.denied, 'Allow location to mark the boundary.'),
    (
      LocationProblem.deniedForever,
      "Location is blocked. Allow it in the phone's app settings.",
    ),
    (LocationProblem.failed, 'Could not get your location. Try again outside.'),
  ]) {
    testWidgets(
      'a location problem ($problem) is explained, nothing is added',
      (tester) async {
        await pumpApp(
          tester,
          locale: const Locale('en'),
          initialLocation: '/plots/new/boundary',
          seed: seedPlot,
          location: ScriptedLocation([LocationReading.problem(problem)]),
        );
        await settle(tester);
        await tester.tap(find.text('Add this corner'));
        await settle(tester);
        expect(find.text(message), findsOneWidget);
        expect(find.text('1 corner'), findsNothing);
        await unmountApp(tester);
      },
    );
  }

  testWidgets('a marked boundary fills the area and is saved with the plot', (
    tester,
  ) async {
    final corners = square(100);
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new',
      location: ScriptedLocation(walkOf(corners)),
    );
    await settle(tester);
    await tester.tap(find.text('Mark boundary by walking'));
    await settle(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Add this corner'));
      await settle(tester);
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await settle(tester);
    // Back on the form: area is filled in (about 2.47 acres) and the boundary is noted.
    expect(find.text('Boundary marked: 4 corners'), findsOneWidget);
    final acres = tester.widget<TextFormField>(
      find.byKey(const Key('plot-acres')),
    );
    expect(double.parse(acres.controller!.text), closeTo(2.47, 0.02));
    await tester.enterText(find.byKey(const Key('plot-name')), 'North block');
    await tester.tap(find.text('Save'));
    await settle(tester);

    final rows = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('plot'))).get(),
    );
    final p = jsonDecode(rows!.single.payload) as Map<String, Object?>;
    expect((p['area_sq_m']! as num).toDouble(), closeTo(10000, 60));
    final ring =
        ((p['boundary']! as Map)['coordinates']! as List).first as List;
    expect(ring, hasLength(5));
    expect(p['centroid_lat'], isNotNull);
    expect(p['centroid_lon'], isNotNull);
    await unmountApp(tester);
  });

  testWidgets('typing the area by hand still works without a boundary', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new',
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('plot-name')), 'South block');
    await tester.enterText(find.byKey(const Key('plot-acres')), '3');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final rows = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('plot'))).get(),
    );
    final p = jsonDecode(rows!.single.payload) as Map<String, Object?>;
    expect(p['boundary'], isNull);
    expect(p['centroid_lat'], isNull);
    await unmountApp(tester);
  });
}
