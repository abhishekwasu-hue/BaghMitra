import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/features/market_link/safety/safety_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A Bagmitra client that records requests and answers [body].
(Bagmitra, List<http.Request>) mockApi(Object body) {
  final sent = <http.Request>[];
  final api = createApi(
    baseUrl: Uri.parse('https://api.example.test'),
    token: () => 'tok',
    httpClient: MockClient((req) async {
      sent.add(req);
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  return (api, sent);
}

void main() {
  test('app repository: report with a photo goes as a raw JPEG', () async {
    final (api, sent) = mockApi({
      'id': 'r9',
      'subject_type': 'lot',
      'subject_id': 'lot-1',
      'reason': 'fake_lot',
      'photo_count': 0,
      'status': 'open',
      'created_at': '2026-11-01T09:00:00Z',
      'decided_at': null,
    });
    final repo = ApiSafetyRepository(api);
    await repo.report('lot', 'lot-1', 'fake_lot', photo: [0xff, 0xd8]);
    expect(jsonDecode(sent.first.body), {
      'subject_type': 'lot',
      'subject_id': 'lot-1',
      'reason': 'fake_lot',
    });
    expect(sent.last.url.path, '/v1/market-link/reports/r9/photos');
    expect(sent.last.headers['content-type'], 'image/jpeg');
    expect(sent.last.bodyBytes, [0xff, 0xd8]);
    await repo.setBlocked('u2', blocked: true);
    expect(sent.last.method, 'PUT');
    await repo.setBlocked('u2', blocked: false);
    expect(sent.last.method, 'DELETE');
  });

  test('app repository: lists, appeal and errors', () async {
    final (api, sent) = mockApi({
      'blocked_user_ids': ['u1'],
      'actions': <Object>[],
      'id': 'a1',
      'subject_type': 'lot',
      'subject_id': 'lot-1',
      'action': 'hide',
      'reason_code': 'fake_lot',
      'acted_at': '2026-11-01T09:00:00Z',
      'appeal_state': 'appealed',
      'appeal_reason': 'lot_genuine',
      'appealed_at': '2026-11-02T09:00:00Z',
      'appeal_photo_count': 0,
      'appeal_decided_at': null,
      'can_appeal': false,
    });
    final repo = ApiSafetyRepository(api);
    expect(await repo.blockedUsers(), {'u1'});
    expect(await repo.myActions(), isEmpty);
    await repo.appeal('a1', 'lot_genuine', photo: [1]);
    expect(jsonDecode(sent[2].body), {'reason': 'lot_genuine'});
    expect(
      sent.last.url.path,
      '/v1/market-link/account-actions/a1/appeal/photos',
    );
    final failing = ApiSafetyRepository(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => null,
        httpClient: MockClient((_) async => http.Response('{}', 503)),
      ),
    );
    await expectLater(failing.myActions(), throwsA(isA<SafetyException>()));
    expect(const SafetyException(503).toString(), contains('503'));
  });
}
