import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/registration.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/data/place_geocoder.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart' show FakeGeocoder;
import '../plots/boundary_screen_test.dart' show ScriptedLocation;

void main() {
  group('domain', () {
    test('phone numbers become +91 ten digits', () {
      expect(normalisePhone('98000 00001'), '+919800000001');
      expect(normalisePhone('+91 98000-00001'), '+919800000001');
      expect(normalisePhone('919800000001'), '+919800000001');
      expect(normalisePhone('12345'), isNull);
      expect(normalisePhone('5800000001'), isNull);
    });

    test('registration number patterns', () {
      expect(gstinPattern.hasMatch('27ABCDE1234F1Z5'), isTrue);
      expect(gstinPattern.hasMatch('27ABC'), isFalse);
      expect(iecPattern.hasMatch('AB12345678'), isTrue);
      expect(fssaiPattern.hasMatch('12345678901234'), isTrue);
      expect(splitList('Warud, Morshi\n  ,Chandur '), [
        'Warud',
        'Morshi',
        'Chandur',
      ]);
    });

    test('the fix sends a six-digit PIN only and keeps the mock flag', () {
      final fix = RegistrationFix(
        lat: 21.47,
        lon: 78.26,
        accuracyM: 9,
        capturedAt: DateTime.utc(2026, 11, 7, 6),
        pin: '4449',
        isMocked: true,
      );
      expect(fix.toJson()['pin'], isNull);
      expect(fix.toJson()['is_mocked'], isTrue);
      expect(fix.toJson()['captured_at'], '2026-11-07T06:00:00.000Z');
    });

    test('enum lookups', () {
      expect(RegistrationRole.fromName('broker'), RegistrationRole.broker);
      expect(RegistrationRole.fromName('grower'), isNull);
      expect(ProviderKind.fromApi('labour_gang'), ProviderKind.labourGang);
    });
  });

  group('registration fix', () {
    test(
      'one settled fix, named by the phone geocoder, mock flag kept',
      () async {
        final location = ScriptedLocation([
          const LocationReading.at(
            LatLon(21.47, 78.26),
            accuracyM: 8,
            isMocked: true,
          ),
        ]);
        final geocoder = FakeGeocoder(
          const PlaceAddress(
            place: 'वरुड',
            district: 'अमरावती',
            state: 'महाराष्ट्र',
            postalCode: '444906',
          ),
        );
        final fix = await takeRegistrationFix(
          location,
          geocoder,
          languageCode: 'mr',
          now: () => DateTime.utc(2026, 11, 7, 6),
        );
        expect((fix.lat, fix.accuracyM, fix.isMocked), (21.47, 8.0, true));
        expect(
          (fix.place, fix.district, fix.pin),
          ('वरुड', 'अमरावती', '444906'),
        );
        expect(geocoder.asked.single.languageCode, 'mr');
        expect(location.settles + location.taps, 1);
      },
    );

    test('a location problem stops registration', () async {
      final location = ScriptedLocation([
        const LocationReading.problem(LocationProblem.denied),
      ]);
      await expectLater(
        takeRegistrationFix(
          location,
          FakeGeocoder(),
          languageCode: 'mr',
          now: DateTime.now,
        ),
        throwsA(
          isA<FixFailure>().having(
            (f) => f.problem,
            'problem',
            LocationProblem.denied,
          ),
        ),
      );
    });
  });

  group('http', () {
    late List<http.Request> sent;
    HttpRegistrationApi apiAnswering(int status, Object body) {
      sent = [];
      return HttpRegistrationApi(
        createApi(
          baseUrl: Uri.parse('http://api.test'),
          token: () => 'tok',
          httpClient: MockClient((r) async {
            sent.add(r);
            return http.Response(
              jsonEncode(body),
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
    }

    test('register posts JSON to the role path', () async {
      final api = apiAnswering(201, {'id': 'b1'});
      await api.register(RegistrationRole.exporter, {'name': 'R'});
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/v1/market-link/exporters');
      expect(jsonDecode(sent.single.body), {'name': 'R'});
      expect(sent.single.headers['Authorization'], 'Bearer tok');
    });

    test('refusals carry the server code; 5xx is "server"', () async {
      await expectLater(
        apiAnswering(422, {
          'error': {'code': 'exporter_needs_iec', 'message': 'x'},
        }).register(RegistrationRole.exporter, {}),
        throwsA(
          isA<MarketCallException>()
              .having((e) => e.problem, 'problem', MarketCallProblem.refused)
              .having((e) => e.code, 'code', 'exporter_needs_iec'),
        ),
      );
      await expectLater(
        apiAnswering(503, {}).register(RegistrationRole.broker, {}),
        throwsA(
          isA<MarketCallException>().having(
            (e) => e.problem,
            'problem',
            MarketCallProblem.server,
          ),
        ),
      );
      await expectLater(
        apiAnswering(404, 'not json').register(RegistrationRole.broker, {}),
        throwsA(
          isA<MarketCallException>().having((e) => e.code, 'code', isNull),
        ),
      );
    });

    test('no network is "offline"', () async {
      final api = HttpRegistrationApi(
        createApi(
          baseUrl: Uri.parse('http://api.test'),
          token: () => null,
          httpClient: MockClient(
            (_) async => throw const SocketException('down'),
          ),
        ),
      );
      await expectLater(
        api.register(RegistrationRole.trader, {}),
        throwsA(
          isA<MarketCallException>().having(
            (e) => e.problem,
            'problem',
            MarketCallProblem.offline,
          ),
        ),
      );
      expect(
        const MarketCallException(MarketCallProblem.offline).toString(),
        contains('offline'),
      );
    });
  });
}
