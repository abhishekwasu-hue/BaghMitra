import 'dart:convert';
import 'dart:typed_data';

import 'package:bagmitra/admin/kb_admin_repository.dart';
import 'package:bagmitra/admin/package_admin_repository.dart';
import 'package:bagmitra/admin/package_strings.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _empty = {
  'legal_name': null,
  'trade_name': null,
  'address': null,
  'gstin': null,
  'pan': null,
  'bank_account_name': null,
  'bank_ifsc': null,
  'bank_account_last4': null,
  'upi_id': null,
  'invoice_prefix': null,
  'gst_rate_percent': null,
  'merchant_qr': false,
};

PackageGrantOut grantOut(String id, {String? revokedAt, int days = 45}) =>
    PackageGrantOut.fromJson({
      'id': id,
      'grower_id': 'g1',
      'lot_id': null,
      'amount_paise': 150000,
      'method': 'upi',
      'payment_ref': 'UTR$id',
      'paid_on': '2026-11-19',
      'activated_at': '2026-11-20T06:00:00Z',
      'valid_until': DateTime.now().add(Duration(days: days)).toIso8601String(),
      'receipt_no': 'BM/26-27/0000$id',
      'revoked_at': revokedAt,
      'revoked_reason': null,
      'admin_id': 'a1',
    });

void main() {
  test('every language has the same package strings', () {
    final tables = packageStringTables;
    expect(tables.keys, ['mr', 'hi', 'en']);
    for (final lang in ['hi', 'en']) {
      expect(
        tables[lang]!.keys.toSet(),
        tables['mr']!.keys.toSet(),
        reason: lang,
      );
    }
  });

  test('the API repository calls the package endpoints', () async {
    final sent = <http.Request>[];
    Object body = _empty;
    var status = 200;
    final repo = ApiPackageAdminRepository(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient((req) async {
          sent.add(req);
          return http.Response(
            jsonEncode(body),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    expect((await repo.company()).merchantQr, isFalse);
    await repo.saveCompany(const PackageCompanyIn(gstin: ''));
    expect(jsonDecode(sent.last.body), {'gstin': ''});
    await repo.uploadQr(Uint8List.fromList([1, 2]), 'image/png');
    expect(sent.last.headers['Content-Type'], startsWith('image/png'));
    expect(sent.last.bodyBytes, [1, 2]);
    body = {'growers': <Object>[]};
    expect(await repo.findGrower('9812345678'), isEmpty);
    expect(sent.last.url.queryParameters['phone'], '9812345678');
    body = {
      'error': {'code': 'duplicate_payment_ref', 'message': 'recorded'},
    };
    status = 409;
    await expectLater(
      repo.recordGrant(
        PackageGrantIn(
          growerId: 'g1',
          amountPaise: 100,
          method: PackageGrantInMethod.cash,
          paymentRef: 'R123',
          paidOn: DateTime(2026, 11, 19),
        ),
      ),
      throwsA(
        isA<PackageAdminException>().having(
          (e) => e.code,
          'code',
          'duplicate_payment_ref',
        ),
      ),
    );
    await expectLater(repo.merchantQr(), throwsA(isA<KbAdminException>()));
    status = 200;
    body = {'grants': <Object>[]};
    expect(await repo.grants('g1'), isEmpty);
    body = grantOut('1').toJson();
    expect((await repo.revoke('1', 'bounced')).id, '1');
    body = {...stubSettings};
    expect((await repo.settings()).missing, ['gstin']);
    expect(
      (await repo.saveSettings(const PackageSettingsIn(enabled: false)))
          .enabled,
      isFalse,
    );
  });
}

const stubSettings = {
  'enabled': false,
  'price_paise': null,
  'validity_days': null,
  'starts_at': null,
  'missing': ['gstin'],
};
