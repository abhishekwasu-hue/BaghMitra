// Market linkage L2 screens at 360 dp, Marathi, light / dark / 1.3x text. Regenerate with:
//   flutter test --update-goldens test/goldens/market_link_l2_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/features/market_link/domain/registration.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/data/place_geocoder.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/market_link_fakes.dart';
import '../features/plots/boundary_screen_test.dart' show ScriptedLocation;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

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
      'ml_profile_mr_dark',
      '/market-link/profile/buyer/b1',
      ThemeMode.dark,
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
