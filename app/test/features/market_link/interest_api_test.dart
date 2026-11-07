import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _lot = {
  'id': 'l1',
  'crop': 'santra',
  'variety': 'nagpur',
  'quantity_t': 12.5,
  'basis': 'per_tonne',
  'village': 'Warud',
  'taluka': 'Warud',
  'district': 'Amravati',
  'status': 'published',
};

const _interest = {
  'id': 'i1',
  'lot_id': 'l1',
  'basis': 'per_tonne',
  'rate_paise': 3200000,
  'quantity_t': 12.0,
  'harvest_date': '2026-12-05',
  'status': 'open',
  'created_at': '2026-11-07T05:30:00Z',
  'via_broker': true,
  'deal_id': null,
};

Map<String, Object?> traderJson() => {
  'subject_type': 'buyer',
  'id': 'b1',
  'kind': 'trader',
  'name': 'Shinde',
  'firm': null,
  'phone': '+919800000001',
  'village': null,
  'markets': <String>[],
  'taluka': 'Warud',
  'district': 'Amravati',
  'crops': <String>[],
  'areas': <String>[],
  'address': null,
  'badges': [
    {'kind': 'checked', 'on': '2026-11-01', 'place': null},
  ],
  'provider': null,
  'deals_completed': 3,
  'stars': <Object>[],
  'tags': <Object>[],
};

void main() {
  late List<http.Request> sent;
  HttpInterestApi answering(int status, Object body) {
    sent = [];
    return HttpInterestApi(
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

  test('send posts only the interest fields', () async {
    final api = answering(201, _interest);
    final got = await api.send('l1', (
      basis: 'per_tonne',
      ratePaise: 3200000,
      quantityT: 12,
      harvestDate: DateTime(2026, 12, 5),
      brokerId: 'k1',
      traderId: null,
    ));
    expect(sent.single.url.path, '/v1/market-link/lots/l1/interests');
    expect(jsonDecode(sent.single.body), {
      'basis': 'per_tonne',
      'rate_paise': 3200000,
      'quantity_t': 12.0,
      'harvest_date': '2026-12-05',
      'broker_id': 'k1',
    });
    expect(got.status, InterestStatus.open);
    expect(got.viaBroker, isTrue);
  });

  test('mine reads the lot by place only', () async {
    final api = answering(200, {
      'interests': [
        {..._interest, 'status': 'closed', 'lot': _lot},
      ],
    });
    final [one] = await api.mine();
    expect(one.interest.status, InterestStatus.closed);
    expect(one.lot.place, 'Warud, Amravati');
  });

  test('onLot reads the trader profile beside each interest', () async {
    final api = answering(200, {
      'interests': [
        {..._interest, 'trader': traderJson(), 'broker': null},
      ],
    });
    final [one] = await api.onLot('l1');
    expect(one.trader.name, 'Shinde');
    expect(one.trader.dealsCompleted, 3);
    expect(one.broker, isNull);
  });

  test('a refusal carries the server code', () async {
    final api = answering(403, {
      'error': {'code': 'not_verified', 'message': 'x'},
    });
    expect(
      api.lots(),
      throwsA(
        isA<MarketCallException>().having(
          (e) => e.code,
          'code',
          'not_verified',
        ),
      ),
    );
  });
}
