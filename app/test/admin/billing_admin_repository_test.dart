import 'dart:convert';

import 'package:bagmitra/admin/billing_admin_repository.dart';
import 'package:bagmitra/admin/billing_strings.dart';
import 'package:bagmitra/admin/package_admin_repository.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// One role row as `GET /v1/admin/billing/settings` returns it.
Map<String, Object?> billingRoleJson(
  String role, {
  int? amount,
  bool play = false,
}) => {
  'role': role,
  'amount_paise': amount,
  'play_price_paise': play ? amount : null,
  'play_currency': play ? 'INR' : null,
  'play_synced_at': play ? '2026-11-08T05:00:00Z' : null,
};

/// The photo analysis limits block of the same response (Q135): nothing set yet.
const Map<String, Object?> billingPhotoLimitsJson = {
  'free_daily': null,
  'free_monthly': null,
  'daily_total': null,
  'default_daily': 5,
  'default_monthly': 50,
};

void main() {
  test('every string exists in mr, hi and en', () {
    const keys = ['section', 'rule_up_notice', 'broker', 'play_not_set_up'];
    for (final lang in ['mr', 'hi', 'en']) {
      final s = BillingStrings.forLanguage(lang);
      for (final k in keys) {
        expect(s[k], isNot(k), reason: '$lang $k');
      }
    }
  });

  test('the API repository sends role, paise and the confirmation', () async {
    final sent = <http.Request>[];
    final body = jsonEncode({
      'enabled': false,
      'starts_on': null,
      'roles': [for (final r in billingRoles) billingRoleJson(r)],
      'photo_limits': billingPhotoLimitsJson,
    });
    final api = createApi(
      baseUrl: Uri.parse('https://api.test'),
      token: () => 'tok',
      httpClient: MockClient((req) async {
        sent.add(req);
        return http.Response(body, 200);
      }),
    );
    final repo = ApiBillingAdminRepository(api);
    await repo.saveAmount('broker', 14900);
    await repo.migratePrices('broker');
    expect(sent[0].method, 'PUT');
    expect(sent[0].url.path, '/v1/admin/billing/roles/broker/amount');
    expect(jsonDecode(sent[0].body), {'amount_paise': 14900});
    expect(sent[1].url.path, '/v1/admin/billing/roles/broker/migrate-prices');
    expect(jsonDecode(sent[1].body), {'confirm': true});
  });

  test('a 503 from the API becomes play_not_set_up', () async {
    final api = createApi(
      baseUrl: Uri.parse('https://api.test'),
      token: () => 'tok',
      httpClient: MockClient((_) async => http.Response('{}', 503)),
    );
    expect(
      () => ApiBillingAdminRepository(api).saveAmount('grower', 9900),
      throwsA(
        isA<PackageAdminException>().having(
          (e) => e.code,
          'code',
          'play_not_set_up',
        ),
      ),
    );
  });
}
