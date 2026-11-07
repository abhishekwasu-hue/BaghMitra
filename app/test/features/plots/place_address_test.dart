// Q59 (owner request): after the location is taken, the add-block form shows the nearby
// place the phone's geocoder names, so the grower sees it was taken in the right place. It is
// display only: never stored or synced (Q53), and a missing name never blocks saving.
import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/place_geocoder.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' show Placemark;

import '../../helpers/pump_app.dart';
import 'boundary_screen_test.dart' show ScriptedLocation, walkOf;
import 'geo_test.dart' show square;
import 'plot_point_test.dart' show at, fillAndSave, here, plotPayload;
import 'plots_screen_test.dart' show settle;

const katol = PlaceAddress(
  place: 'काटोल',
  district: 'नागपूर',
  state: 'महाराष्ट्र',
  postalCode: '441302',
);

Future<String> _allOutbox(WidgetTester tester, AppDatabase db) async {
  final rows = await tester.runAsync(() => db.select(db.outboxEntries).get());
  return rows!.map((r) => r.payload).join('\n');
}

void main() {
  test('a placemark keeps its named parts and drops blank ones', () {
    final a = placeAddressOf(
      const Placemark(
        locality: 'Katol',
        subLocality: ' ',
        subAdministrativeArea: 'Nagpur',
        administrativeArea: 'Maharashtra',
        postalCode: '441302',
      ),
    );
    expect(a.place, 'Katol');
    expect(a.area, isNull);
    expect(a.district, 'Nagpur');
    expect(a.state, 'Maharashtra');
    expect(a.postalCode, '441302');
    final village = placeAddressOf(const Placemark(subLocality: 'Pardi'));
    expect(village.place, 'Pardi');
    expect(village.area, isNull);
    expect(placeAddressOf(const Placemark()).isEmpty, isTrue);
  });

  test('without the platform geocoder the lookup ends as not found', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(
      await const PlatformPlaceGeocoder().addressOf(here, languageCode: 'mr'),
      isNull,
    );
  });

  testWidgets(
    'a fix shows the nearby place in Marathi; nothing of it is saved',
    (tester) async {
      final geocoder = FakeGeocoder(katol);
      final db = await pumpApp(
        tester,
        initialLocation: '/plots/new',
        geocoder: geocoder,
        location: ScriptedLocation(
          const [],
          fixes: [
            [at(here, 6)],
          ],
        ),
      );
      await settle(tester);
      expect(find.byKey(const Key('point-address')), findsNothing);
      await tester.tap(find.byKey(const Key('point-take')));
      await settle(tester);
      expect(
        find.text('जवळचे ठिकाण: काटोल, जि. नागपूर, महाराष्ट्र ४४१३०२'),
        findsOneWidget,
      );
      expect(geocoder.asked.single.point, here);
      expect(geocoder.asked.single.languageCode, 'mr');

      await tester.enterText(find.byKey(const Key('plot-name')), 'उत्तर बाग');
      await tester.enterText(find.byKey(const Key('plot-acres')), '2');
      await tester.tap(find.text('जतन करा'));
      await settle(tester);
      final p = await plotPayload(tester, db);
      expect(p['centroid_lat'], here.lat);
      final sent = await _allOutbox(tester, db);
      for (final part in ['काटोल', 'नागपूर', 'महाराष्ट्र', '441302']) {
        expect(sent, isNot(contains(part)));
        expect(jsonEncode(p), isNot(contains(part)));
      }
      final stored = await tester.runAsync(() => db.select(db.plots).get());
      expect(stored!.single.toString(), isNot(contains('काटोल')));
      await unmountApp(tester);
    },
  );

  testWidgets(
    'no name found: a short line on what to do, and saving still works',
    (tester) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/new',
        geocoder: FakeGeocoder(),
        location: ScriptedLocation(
          const [],
          fixes: [
            [at(here, 6)],
          ],
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('point-take')));
      await settle(tester);
      expect(
        find.text(
          'The location will be saved. For the place name, turn on the '
          "internet and tap 'Take location again'.",
        ),
        findsOneWidget,
      );
      await fillAndSave(tester);
      final p = await plotPayload(tester, db);
      expect(p['name'], 'North block');
      expect(p['centroid_lat'], here.lat);
      await unmountApp(tester);
    },
  );

  testWidgets('a walked boundary asks again for its centre', (tester) async {
    final corners = square(100);
    final geocoder = FakeGeocoder(katol);
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/new',
      geocoder: geocoder,
      location: ScriptedLocation(walkOf(corners)),
    );
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('walk-boundary')));
    await tester.tap(find.byKey(const Key('walk-boundary')));
    await settle(tester);
    for (var i = 0; i < corners.length; i++) {
      await tester.tap(find.text('Add this corner'));
      await settle(tester);
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await settle(tester);
    expect(geocoder.asked.single.point, centroidOf(corners));
    expect(
      find.text('Nearby place: काटोल, Dist. नागपूर, महाराष्ट्र 441302'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
