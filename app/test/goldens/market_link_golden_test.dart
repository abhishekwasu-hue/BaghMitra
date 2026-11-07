// Market linkage screens at phone width (360 dp), Marathi: L2 (registration, profiles,
// services; light / dark / 1.3x text) and L3 (lots; 1.3x text, light and dark).
// Regenerate with:
//   flutter test --update-goldens test/goldens/market_link_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/api/generated/bagmitra.swagger.dart'
    show V1MarketPricesGetScope;
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/market_link/domain/market_lot.dart';
import 'package:bagmitra/features/market_link/domain/registration.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/data/place_geocoder.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/market_link/lot_form_test.dart' show mlConfig;
import '../features/market_link/market_link_fakes.dart';
import '../features/market_link/market_lot_repository_test.dart' show sampleLot;
import '../features/plots/boundary_screen_test.dart' show ScriptedLocation;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

/// A real image file for the thumbnails (the app icon).
const _image = 'assets/icon/icon.png';

Future<void> _seedLots(AppDatabase db) async {
  await seedPlot(db);
  final repo = MarketLotRepository(db);
  await repo.save(sampleLot());
  await repo.save(sampleLot(id: 'l2'));
  await repo.keepServerState(
    'l2',
    status: 'published',
    publishedAt: DateTime.utc(2026, 10, 12),
    orchardCheck: 'inside',
  );
  for (final (i, lot) in [('a', 'l1'), ('b', 'l1'), ('c', 'l1'), ('d', 'l2')]) {
    await repo.savePhoto(
      LotPhoto(
        id: '$lot-$i',
        lotId: lot,
        capturedAt: DateTime.utc(2026, 10, 12, 5),
        lat: 21.1,
        lon: 79.0,
        photoPath: _image,
      ),
    );
  }
  // Today's (13 Oct) mandi price saved on the phone.
  await db.writeMeta(
    MarketPricesCache.keyFor('santra', V1MarketPricesGetScope.all),
    jsonEncode({
      'saved_at': '2026-10-13T05:00:00.000Z',
      'prices': {
        'stale': false,
        'prices': [
          {
            'day': '2026-10-13',
            'market': 'Warud',
            'state': 'Maharashtra',
            'district': 'Amravati',
            'commodity': 'Orange',
            'modal_rs_per_quintal': 3300,
            'source': 'agmarknet',
            'is_local': true,
            'is_major': false,
          },
        ],
      },
    }),
  );
}

Future<void> _precacheThumbnails(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final width in [88 * 3, 56 * 3]) {
      await precacheImage(
        ResizeImage(FileImage(File(_image)), width: width),
        context,
      );
    }
  });
}

Future<void> _images(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

final _own = [
  MarketProfile(
    subjectType: 'buyer',
    id: 'b1',
    kind: 'trader',
    name: 'रमेश पाटील',
    firm: 'पाटील फ्रुट कंपनी',
    phone: '+919800000001',
    taluka: 'वरुड',
    district: 'अमरावती',
    status: 'pending',
    documents: 1,
    badges: [
      ProfileBadge(
        'registered_from',
        DateTime.utc(2026, 11, 7),
        place: 'वरुड, अमरावती',
      ),
    ],
  ),
  MarketProfile(
    subjectType: 'provider',
    id: 'p1',
    kind: 'weighbridge',
    name: 'वरुड वजनकाटा',
    phone: '+919800000003',
    village: 'वरुड',
    taluka: 'वरुड',
    district: 'अमरावती',
    status: 'approved',
    certValidUntil: DateTime.utc(2026, 11, 6),
    certificateExpired: true,
    hasCertificatePhoto: true,
    documents: 1,
    badges: [ProfileBadge('checked', DateTime.utc(2026, 11, 7))],
  ),
];

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final m = mode.name;
    for (final (name, location, seed, scroll) in [
      ('l3_empty', '/market-link/lots', seedPlot, 0.0),
      ('l3_my_lots', '/market-link/lots', _seedLots, 0.0),
      ('l3_lot_form', '/market-link/lots/l1', _seedLots, 0.0),
      ('l3_photo_strip', '/market-link/lots/l1', _seedLots, 900.0),
    ]) {
      testWidgets('${name}_mr_$m', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          config: mlConfig,
          themeMode: mode,
          initialLocation: location,
          seed: seed,
          size: _phone,
        );
        await settle(tester);
        if (scroll > 0) {
          // Decode the thumbnails in real time first: images first built inside the
          // test's fake time never finish loading.
          await _precacheThumbnails(tester);
          await tester.drag(find.byType(ListView).first, Offset(0, -scroll));
          await tester.pump();
        }
        await _images(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${name}_mr_$m.png'),
        );
        await unmountApp(tester);
      });
    }
  }
  for (final (name, location, mode, scale, tapFix) in [
    (
      'ml_register_fix_mr_light',
      '/market-link/register/trader',
      ThemeMode.light,
      1.0,
      false,
    ),
    (
      'ml_register_trader_mr_light',
      '/market-link/register/trader',
      ThemeMode.light,
      1.0,
      true,
    ),
    (
      'ml_register_trader_mr_x13',
      '/market-link/register/trader',
      ThemeMode.light,
      1.3,
      true,
    ),
    (
      'ml_register_provider_mr_dark',
      '/market-link/register/provider',
      ThemeMode.dark,
      1.0,
      true,
    ),
    ('ml_my_profiles_mr_light', '/market-link/me', ThemeMode.light, 1.0, false),
    ('ml_my_profiles_mr_dark', '/market-link/me', ThemeMode.dark, 1.0, false),
    ('ml_people_mr_light', '/market-link/people', ThemeMode.light, 1.0, false),
    ('ml_people_mr_dark', '/market-link/people', ThemeMode.dark, 1.0, false),
    ('ml_people_mr_x13', '/market-link/people', ThemeMode.light, 1.3, false),
    (
      'ml_profile_mr_light',
      '/market-link/profile/buyer/b1',
      ThemeMode.light,
      1.0,
      false,
    ),
    (
      'ml_services_mr_light',
      '/market-link/services',
      ThemeMode.light,
      1.0,
      false,
    ),
    (
      'ml_services_mr_dark',
      '/market-link/services',
      ThemeMode.dark,
      1.0,
      false,
    ),
    (
      'ml_services_mr_x13',
      '/market-link/services',
      ThemeMode.light,
      1.3,
      false,
    ),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpMarketLink(
        tester,
        location,
        themeMode: mode,
        api: FakeRegistrationApi(
          own: _own,
          listed: [
            sampleTrader(),
            sampleTrader(id: 'b2', deals: 3),
            sampleBroker(),
          ],
          services: [sampleWeighbridge(), sampleTransporter()],
        ),
        location: ScriptedLocation([
          const LocationReading.at(LatLon(21.4717, 78.2667), accuracyM: 9),
        ]),
        geocoder: FakeGeocoder(
          const PlaceAddress(
            place: 'वरुड',
            district: 'अमरावती',
            postalCode: '444906',
          ),
        ),
      );
      await settle(tester);
      if (tapFix) {
        await tester.tap(find.byKey(const Key('ml-take-fix')));
        await settle(tester);
        if (location.endsWith('provider')) {
          await tester.tap(find.byKey(const Key('ml-kind-transporter')));
          await settle(tester);
        }
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
