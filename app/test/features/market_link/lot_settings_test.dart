import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/lot_settings_store.dart';
import 'package:bagmitra/features/market_link/domain/lot_form_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';

/// The server's `GET /v1/market-link/lot-settings` answer.
String lotSettingsJson({
  int quintalMin = 250000,
  int quintalMax = 1000000,
  int crateMin = 40000,
  int crateMax = 120000,
  int days = 15,
}) => jsonEncode({
  'rate_ranges': [
    {'basis': 'per_quintal', 'min_paise': quintalMin, 'max_paise': quintalMax},
    {'basis': 'per_crate', 'min_paise': crateMin, 'max_paise': crateMax},
  ],
  'harvest_window_days': days,
});

void main() {
  test('ranges per quintal and per crate; the whole orchard has none', () {
    const s = LotFormSettings.bundled;
    expect(s.rangeOf('per_quintal'), (min: 250000, max: 1000000));
    expect(s.rangeOf('per_crate'), (min: 40000, max: 120000));
    expect(s.rangeOf('lump_sum'), isNull);
    expect(s.fits('per_quintal', 249999), isFalse);
    expect(s.fits('per_quintal', 250000), isTrue);
    expect(s.fits('per_quintal', 1000000), isTrue);
    expect(s.fits('per_quintal', 1000001), isFalse);
    expect(s.fits('per_crate', 39999), isFalse);
    expect(s.fits('per_crate', 120001), isFalse);
    expect(s.fits('lump_sum', 1), isTrue);
    expect(s.fits(null, 1), isTrue);
  });

  test('the harvest end is the start plus the settings days', () {
    const s = LotFormSettings.bundled;
    expect(s.harvestEnd(DateTime(2026, 11, 15)), DateTime(2026, 11, 30));
    // Across a month and a year end, in calendar days.
    expect(s.harvestEnd(DateTime(2026, 12, 25)), DateTime(2027, 1, 9));
    final ten = LotFormSettings.fromJson(
      (jsonDecode(lotSettingsJson(days: 10)) as Map).cast(),
    );
    expect(ten.harvestEnd(DateTime(2026, 11, 15)), DateTime(2026, 11, 25));
  });

  group('store', () {
    late AppDatabase db;
    late http.Response Function() answer;
    late LotSettingsStore store;

    setUp(() {
      db = memoryDb();
      addTearDown(db.close);
      answer = () =>
          http.Response(lotSettingsJson(quintalMin: 300000, days: 20), 200);
      store = LotSettingsStore(
        db,
        createApi(
          baseUrl: Uri.parse('https://api.example.test'),
          token: () => 'tok',
          httpClient: MockClient((r) async {
            expect(r.url.path, '/v1/market-link/lot-settings');
            return answer();
          }),
        ),
      );
    });

    test(
      'bundled values until the server answers, then its copy offline',
      () async {
        expect((await store.load()).harvestWindowDays, 15);
        expect(await store.refresh(), isTrue);
        expect(store.refreshed, isTrue);
        // Offline now: the saved copy answers.
        answer = () => throw http.ClientException('offline');
        expect(await store.refresh(), isFalse);
        final saved = await store.load();
        expect(saved.harvestWindowDays, 20);
        expect(saved.rangeOf('per_quintal'), (min: 300000, max: 1000000));
      },
    );

    test('an error or an unreadable answer keeps the last copy', () async {
      answer = () => http.Response('{}', 503);
      expect(await store.refresh(), isFalse);
      answer = () => http.Response('{"rate_ranges": 1}', 200);
      expect(await store.refresh(), isFalse);
      expect((await store.load()).harvestWindowDays, 15);
      await db.writeMeta(LotSettingsStore.key, 'not json');
      expect((await store.load()).harvestWindowDays, 15);
    });
  });
}
