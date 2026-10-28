import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import 'plots_screen_test.dart' show settle;

final corners = [
  const LatLon(21.2300, 77.7500),
  const LatLon(21.2300, 77.7512),
  const LatLon(21.2311, 77.7512),
  const LatLon(21.2311, 77.7500),
];

Future<void> seed(AppDatabase db) => PlotRepository(db).save(
  Plot(
    id: 'p1',
    name: 'Shindi block',
    crop: 'santra',
    areaSqM: polygonAreaSqM(corners),
    variety: 'Nagpur',
    treeCount: 450,
    plantingYear: 2014,
    irrigationType: 'drip',
    soilType: 'black',
    boundary: toGeoJsonPolygon(corners),
    centroidLat: 21.2305,
    centroidLon: 77.7506,
  ),
);

void main() {
  test('corners survive the GeoJSON round trip, and bad input gives null', () {
    expect(cornersFromGeoJson(toGeoJsonPolygon(corners)), corners);
    expect(cornersFromGeoJson(null), isNull);
    expect(cornersFromGeoJson(const {'coordinates': <Object>[]}), isNull);
    expect(
      cornersFromGeoJson(toGeoJsonPolygon(corners.take(2).toList())),
      isNull,
    );
  });

  testWidgets('the detail screen shows the block and opens its records', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: seed,
    );
    await settle(tester);
    expect(find.text('Shindi block'), findsOneWidget);
    expect(find.text('Nagpur'), findsOneWidget);
    expect(find.text('450'), findsOneWidget);
    expect(find.text('Boundary marked: 4 corners'), findsOneWidget);
    expect(find.text('21.23050, 77.75060'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-records')));
    await settle(tester);
    expect(find.text('Plan your first bahar'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'editing changes the block, keeps its boundary and what the form hides',
    (tester) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/edit',
        seed: seed,
      );
      await settle(tester);
      expect(find.text('Edit block'), findsOneWidget);
      expect(find.text('Boundary marked: 4 corners'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('plot-name')),
        'Shindi block A',
      );
      await tester.enterText(find.byKey(const Key('plot-trees')), '460');
      await tester.tap(find.text('Save'));
      await settle(tester);

      final saved = await tester.runAsync(
        () => PlotRepository(db).watchAll().first,
      );
      final p = saved!.single;
      expect(p.id, 'p1');
      expect(p.name, 'Shindi block A');
      expect(p.treeCount, 460);
      expect(p.irrigationType, 'drip');
      expect(p.soilType, 'black');
      expect(cornersFromGeoJson(p.boundary), corners);
      expect(p.areaSqM, closeTo(polygonAreaSqM(corners), 1));
      await unmountApp(tester);
    },
  );
}
