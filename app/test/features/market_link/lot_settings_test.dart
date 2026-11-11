import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/lot_settings_store.dart';
import 'package:bagmitra/features/market_link/domain/lot_form_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';

/// The server's `GET /v1/market-link/lot-settings` answer: santra with these numbers,
/// mosambi with its own (the server's defaults unless given).
String lotSettingsJson({
  int quintalMin = 250000,
  int quintalMax = 1000000,
  int crateMin = 40000,
  int crateMax = 120000,
  int mosambiQuintalMin = 250000,
  int mosambiQuintalMax = 1000000,
  int days = 15,
}) => jsonEncode({
  'rate_ranges': [
    for (final (crop, basis, lo, hi) in [
      ('santra', 'per_quintal', quintalMin, quintalMax),
      ('santra', 'per_crate', crateMin, crateMax),
      ('mosambi', 'per_quintal', mosambiQuintalMin, mosambiQuintalMax),
      ('mosambi', 'per_crate', 40000, 120000),
    ])
      {'crop': crop, 'basis': basis, 'min_paise': lo, 'max_paise': hi},
  ],
  'harvest_window_days': days,
});

void main() {
  test(
    'ranges per crop, per quintal and per crate; the whole orchard has none',
    () {
      const s = LotFormSettings.bundled;
      for (final crop in ['santra', 'mosambi']) {
        expect(s.rangeOf(crop, 'per_quintal'), (min: 250000, max: 1000000));
        expect(s.rangeOf(crop, 'per_crate'), (min: 40000, max: 120000));
        expect(s.rangeOf(crop, 'lump_sum'), isNull);
        expect(s.fits(crop, 'per_quintal', 249999), isFalse);
        expect(s.fits(crop, 'per_quintal', 250000), isTrue);
        expect(s.fits(crop, 'per_quintal', 1000000), isTrue);
        expect(s.fits(crop, 'per_quintal', 1000001), isFalse);
        expect(s.fits(crop, 'per_crate', 39999), isFalse);
        expect(s.fits(crop, 'per_crate', 120001), isFalse);
        expect(s.fits(crop, 'lump_sum', 1), isTrue);
      }
      expect(s.fits('santra', null, 1), isTrue);
      expect(s.fits(null, 'per_quintal', 1), isTrue);
      // Mosambi has its own range ("मोसंबीचे दर वेगळे असू शकतात").
      final own = LotFormSettings.fromJson(
        (jsonDecode(lotSettingsJson(mosambiQuintalMin: 400000)) as Map).cast(),
      );
      expect(own.fits('santra', 'per_quintal', 300000), isTrue);
      expect(own.fits('mosambi', 'per_quintal', 300000), isFalse);
    },
  );

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
        expect(saved.rangeOf('santra', 'per_quintal'), (
          min: 300000,
          max: 1000000,
        ));
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
