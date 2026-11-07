import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/registration.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/data/place_geocoder.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:bagmitra/features/scouting/data/scouting_photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/boundary_screen_test.dart' show ScriptedLocation;
import '../plots/plots_screen_test.dart' show settle;
import 'market_link_fakes.dart';

const _warud = PlaceAddress(
  place: 'वरुड',
  district: 'अमरावती',
  state: 'महाराष्ट्र',
  postalCode: '444906',
);

ScriptedLocation _at({bool mocked = false}) => ScriptedLocation([
  LocationReading.at(
    const LatLon(21.4717, 78.2667),
    accuracyM: 9,
    isMocked: mocked,
  ),
]);

class _CameraPhotos implements ScoutingPhotos {
  _CameraPhotos(this.path);
  final String path;
  final sources = <PhotoSource>[];

  @override
  Future<String?> pick(PhotoSource source) async {
    sources.add(source);
    return path;
  }

  @override
  Future<String> keep(String pickedPath, String recordId) async => pickedPath;

  @override
  Future<void> discard(String path) async {}
}

/// Scrolls [f] to the middle of its list (clear of the app bar), then taps it.
Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  if (Scrollable.maybeOf(tester.element(f)) != null) {
    unawaited(Scrollable.ensureVisible(tester.element(f), alignment: 0.5));
    await tester.pump();
  }
  await tester.tap(f);
  await settle(tester);
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  final f = find.byKey(Key('ml-field-$key'));
  if (f.evaluate().isEmpty) {
    // Below the built part of the list: scroll down to it.
    await tester.scrollUntilVisible(
      f,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
}

void main() {
  testWidgets('flag off: no market-link menu entry and the routes go home', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/market-link/me');
    expect(find.text('माझी बाजार नोंदणी'), findsNothing);
    await unmountApp(tester);
    await pumpApp(tester, initialLocation: '/more');
    expect(find.byKey(const Key('more-market-link-people')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('flag on: the More screen lists the three market-link pages', (
    tester,
  ) async {
    await pumpMarketLink(tester, '/more', api: FakeRegistrationApi());
    for (final page in ['people', 'services', 'mine']) {
      final entry = find.byKey(Key('more-market-link-$page'));
      await tester.scrollUntilVisible(entry, 200);
      expect(entry, findsOneWidget);
    }
    await unmountApp(tester);
  });

  testWidgets('registration needs the GPS fix first; a denied fix explains', (
    tester,
  ) async {
    final location = ScriptedLocation([
      const LocationReading.problem(LocationProblem.denied),
    ]);
    await pumpMarketLink(
      tester,
      '/market-link/register/broker',
      api: FakeRegistrationApi(),
      overrides: [locationServiceProvider.overrideWithValue(location)],
    );
    expect(find.byKey(const Key('ml-submit')), findsNothing);
    expect(find.byKey(const Key('ml-field-name')), findsNothing);
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    expect(find.byKey(const Key('ml-fix-problem')), findsOneWidget);
    expect(find.byKey(const Key('ml-submit')), findsNothing);
    await _tap(tester, find.text('सेटिंग्ज उघडा'));
    expect(location.openedFor, [LocationProblem.denied]);
    await unmountApp(tester);
  });

  testWidgets('broker registration sends the fix, mock flag and fields', (
    tester,
  ) async {
    final api = FakeRegistrationApi();
    await pumpApp(
      tester,
      config: marketLinkConfig,
      initialLocation: '/market-link/register/broker',
      size: smallPhone,
      location: _at(mocked: true),
      geocoder: FakeGeocoder(_warud),
      seed: seedPlace,
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    expect(find.byKey(const Key('ml-fix-taken')), findsOneWidget);
    await _type(tester, 'phone', '98000 00002');
    await _type(tester, 'areas', 'वरुड, मोर्शी');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    final (role, body) = api.registered.single;
    expect(role, RegistrationRole.broker);
    expect(body['phone'], '+919800000002');
    expect(body['village'], 'वरुड');
    expect(body['district'], 'अमरावती');
    expect(body['service_areas'], ['वरुड', 'मोर्शी']);
    final fix = body['fix']! as Map<String, Object?>;
    expect(
      (fix['is_mocked'], fix['pin'], fix['accuracy_m']),
      (true, '444906', 9.0),
    );
    expect(jsonEncode(body), isNot(matches(RegExp('aadhaar|commission'))));
    // On success the user lands on "my registration".
    expect(find.text('माझी बाजार नोंदणी'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('a trader gives one checkable number; the server code shows', (
    tester,
  ) async {
    final api = FakeRegistrationApi();
    await pumpApp(
      tester,
      config: marketLinkConfig,
      initialLocation: '/market-link/register/trader',
      size: smallPhone,
      location: _at(),
      geocoder: FakeGeocoder(_warud),
      seed: seedPlace,
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    await _type(tester, 'phone', '9800000001');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(find.byKey(const Key('ml-error')), findsOneWidget);
    expect(api.registered, isEmpty);
    await _type(tester, 'gst', '27ABC');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(find.text('15 अक्षरी GSTIN लिहा'), findsOneWidget);
    await _type(tester, 'gst', '27abcde1234f1z5');
    api.refuseWith = const MarketCallException(
      MarketCallProblem.refused,
      'registration_fix_stale',
    );
    await _tap(tester, find.byKey(const Key('ml-submit')));
    // A stale fix sends the user back to take it again.
    expect(find.byKey(const Key('ml-take-fix')), findsOneWidget);
    api.refuseWith = null;
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(api.registered.single.$2['gst_no'], '27ABCDE1234F1Z5');
    expect(api.registered.single.$2['crops'], ['santra']);
    await unmountApp(tester);
  });

  testWidgets('an exporter must give the IEC', (tester) async {
    final api = FakeRegistrationApi();
    await pumpApp(
      tester,
      config: marketLinkConfig,
      initialLocation: '/market-link/register/exporter',
      size: smallPhone,
      location: _at(),
      geocoder: FakeGeocoder(_warud),
      seed: seedPlace,
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    await _type(tester, 'phone', '9800000001');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(api.registered, isEmpty);
    await _type(tester, 'iec', 'ab12345678');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(api.registered.single.$1, RegistrationRole.exporter);
    expect(api.registered.single.$2['iec_no'], 'AB12345678');
    await unmountApp(tester);
  });

  testWidgets('a transporter picks its kind with a big card', (tester) async {
    final api = FakeRegistrationApi();
    await pumpApp(
      tester,
      config: marketLinkConfig,
      initialLocation: '/market-link/register/provider',
      size: smallPhone,
      location: _at(),
      geocoder: FakeGeocoder(_warud),
      seed: seedPlace,
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    await _type(tester, 'phone', '9800000004');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(find.text('तुमची सेवा निवडा'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('ml-kind-transporter')));
    await _type(tester, 'vehicles', 'mh27ab1234');
    await _type(tester, 'capacity', '9');
    await _tap(tester, find.byKey(const Key('ml-refrigerated')));
    await _tap(tester, find.byKey(const Key('ml-submit')));
    final body = api.registered.single.$2;
    expect(body['kind'], 'transporter');
    expect(body['vehicle_numbers'], ['MH27AB1234']);
    expect((body['capacity_t'], body['refrigerated']), (9.0, true));
    await unmountApp(tester);
  });

  testWidgets('a weighbridge needs the certificate date', (tester) async {
    final api = FakeRegistrationApi();
    await pumpApp(
      tester,
      config: marketLinkConfig,
      initialLocation: '/market-link/register/provider',
      size: smallPhone,
      location: _at(),
      geocoder: FakeGeocoder(_warud),
      seed: seedPlace,
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await _tap(tester, find.byKey(const Key('ml-take-fix')));
    await _tap(tester, find.byKey(const Key('ml-kind-weighbridge')));
    await _type(tester, 'phone', '9800000003');
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(find.text('प्रमाणपत्राची वैध तारीख निवडा'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('ml-cert-date')));
    // The date picker's confirm button is its last text button.
    await _tap(
      tester,
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await _tap(tester, find.byKey(const Key('ml-submit')));
    expect(api.registered.single.$2['cert_valid_until'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('my registration: status, camera-only document photo, address', (
    tester,
  ) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('ml'),
    );
    final file = File('${dir!.path}/doc.jpg')
      ..writeAsBytesSync([0xff, 0xd8, 0xff, 0xd9]);
    addTearDown(() => dir.deleteSync(recursive: true));
    final photos = _CameraPhotos(file.path);
    const own = MarketProfile(
      subjectType: 'buyer',
      id: 'b1',
      kind: 'trader',
      name: 'रमेश पाटील',
      phone: '+919800000001',
      district: 'अमरावती',
      status: 'rejected',
      reason: 'GSTIN रद्द',
    );
    final api = FakeRegistrationApi(own: [own]);
    await pumpApp(
      tester,
      config: marketLinkConfig,
      initialLocation: '/market-link/me',
      size: smallPhone,
      photos: photos,
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await settle(tester);
    expect(find.text('परत पाठवले; कारण पहा'), findsOneWidget);
    expect(find.text('GSTIN रद्द'), findsOneWidget);
    // One buyer profile: neither trader nor exporter is offered again (Q89).
    expect(find.byKey(const Key('ml-register-trader')), findsNothing);
    expect(find.byKey(const Key('ml-register-exporter')), findsNothing);
    expect(find.byKey(const Key('ml-register-broker')), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('ml-doc-gst-b1')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await settle(tester);
    expect(photos.sources, [PhotoSource.camera]);
    expect(api.documents.single.$2, DocKind.gst);
    expect(api.documents.single.$3, 4);
    await _tap(tester, find.byKey(const Key('ml-address-b1')));
    await tester.enterText(find.byKey(const Key('ml-address-input')), 'पेठ');
    await _tap(tester, find.byKey(const Key('ml-address-save')));
    await unmountApp(tester);
  });

  testWidgets('my registration: empty shows the role cards; tap opens one', (
    tester,
  ) async {
    await pumpMarketLink(tester, '/market-link/me', api: FakeRegistrationApi());
    expect(find.byKey(const Key('ml-register-trader')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('ml-register-provider')));
    expect(find.byKey(const Key('ml-take-fix')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('people list: role and sort chips, tap-to-call, detail', (
    tester,
  ) async {
    final api = FakeRegistrationApi(listed: [sampleTrader(), sampleBroker()]);
    final dialled = <String>[];
    await pumpMarketLink(
      tester,
      '/market-link/people',
      api: api,
      dialled: dialled,
    );
    await settle(tester);
    // The list starts at the grower's own taluka.
    expect(api.queries.last, {
      'role': 'trader',
      'taluka': 'वरुड',
      'district': 'अमरावती',
      'sort': 'rating',
    });
    expect(find.text('रमेश पाटील'), findsOneWidget);
    expect(find.textContaining('BagMitra ने'), findsWidgets);
    await _tap(tester, find.byKey(const Key('ml-call-b1')));
    expect(dialled, ['+919800000001']);
    await _tap(tester, find.byKey(const Key('ml-sort-deals')));
    await _tap(tester, find.byKey(const Key('ml-role-broker')));
    await _tap(tester, find.byKey(const Key('ml-area-all')));
    expect(api.queries.last, {
      'role': 'broker',
      'taluka': null,
      'district': null,
      'sort': 'deals',
    });
    await _tap(tester, find.text('रमेश पाटील'));
    expect(find.text('रेटिंग'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('ml-call-main')));
    expect(dialled.last, '+919800000001');
    await unmountApp(tester);
  });

  testWidgets('people list: empty and offline states', (tester) async {
    final api = FakeRegistrationApi();
    await pumpMarketLink(tester, '/market-link/people', api: api);
    await settle(tester);
    expect(
      find.text('या भागातील तपासलेले व्यापारी व मध्यस्थ येथे दिसतील.'),
      findsOneWidget,
    );
    await unmountApp(tester);
    await pumpMarketLink(
      tester,
      '/market-link/people',
      api: FakeRegistrationApi(
        error: const MarketCallException(MarketCallProblem.offline),
      ),
    );
    await settle(tester);
    expect(find.text('हे पाहण्यासाठी इंटरनेट सुरू करा'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('services: kinds, distance, expired certificate, no booking', (
    tester,
  ) async {
    final api = FakeRegistrationApi(
      services: [sampleWeighbridge(), sampleTransporter()],
    );
    final dialled = <String>[];
    await pumpMarketLink(
      tester,
      '/market-link/services',
      api: api,
      dialled: dialled,
    );
    await settle(tester);
    expect(find.textContaining('२ कि.मी.'), findsOneWidget);
    expect(find.byKey(const Key('ml-cert-expired-p1')), findsOneWidget);
    expect(find.textContaining('बुक'), findsNothing);
    await _tap(tester, find.byKey(const Key('ml-call-p2')));
    expect(dialled, ['+919800000004']);
    await _tap(tester, find.byKey(const Key('ml-type-transporter')));
    expect(find.text('वरुड वजनकाटा'), findsNothing);
    expect(api.queries.last['type'], 'transporter');
    await unmountApp(tester);
  });
}
