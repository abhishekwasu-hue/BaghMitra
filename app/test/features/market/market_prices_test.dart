import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.enums.swagger.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:bagmitra/features/market/domain/market_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;

Map<String, Object?> samplePrices({bool stale = false, String? reason}) => {
  'prices': [
    {
      'day': '2026-10-24',
      'market': 'Warud',
      'state': 'Maharashtra',
      'district': 'Amravati',
      'commodity': 'Orange',
      'variety': 'Nagpuri',
      'grade': 'FAQ',
      'min_rs_per_quintal': 2500,
      'max_rs_per_quintal': 4100,
      'modal_rs_per_quintal': 3300,
      'source': 'agmarknet',
      'is_local': true,
      'is_major': false,
    },
    {
      'day': '2026-10-23',
      'market': 'Azadpur',
      'state': 'NCT of Delhi',
      'district': 'North Delhi',
      'commodity': 'Orange',
      'modal_rs_per_quintal': 5200,
      'source': 'agmarknet',
      'is_local': false,
      'is_major': true,
    },
  ],
  'stale': stale,
  'reason': ?reason,
};

Future<void> seedPrices(
  AppDatabase db, {
  V1MarketPricesGetScope scope = V1MarketPricesGetScope.all,
  Map<String, Object?>? body,
}) => db.writeMeta(
  MarketPricesCache.keyFor('santra', scope),
  jsonEncode({
    'saved_at': '2026-10-25T06:00:00.000Z',
    'prices': body ?? samplePrices(),
  }),
);

void main() {
  test(
    'refresh stores prices for crop and scope; load works offline',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      var online = true;
      final requested = <Uri>[];
      final api = createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 't',
        httpClient: MockClient((req) async {
          requested.add(req.url);
          if (!online) throw http.ClientException('offline');
          return http.Response(jsonEncode(samplePrices()), 200);
        }),
      );
      final cache = MarketPricesCache(
        db,
        api: api,
        clock: () => DateTime.utc(2026, 10, 25, 6),
      );
      const local = V1MarketPricesGetScope.local;
      expect(await cache.load('santra', local), isNull);
      expect(await cache.refresh('santra', local), isTrue);
      expect(requested.single.path, '/v1/market/prices');
      expect(requested.single.queryParameters['crop'], 'santra');
      expect(requested.single.queryParameters['scope'], 'local');

      online = false;
      expect(await cache.refresh('santra', local), isFalse);
      final cached = (await cache.load('santra', local))!;
      expect(cached.prices.prices, hasLength(2));
      expect(cached.prices.prices.first.modalRsPerQuintal, 3300);
      expect(cached.savedAt, DateTime.utc(2026, 10, 25, 6));
      expect(await cache.load('santra', V1MarketPricesGetScope.major), isNull);
    },
  );

  testWidgets('market screen shows cached rows, tags and a plain stale note', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/market',
      seed: (db) => seedPrices(
        db,
        body: samplePrices(stale: true, reason: 'source_unreachable'),
      ),
    );
    await settle(tester);
    expect(find.text('Market prices'), findsOneWidget);
    expect(find.text('Warud'), findsOneWidget);
    expect(find.textContaining('Maharashtra'), findsOneWidget);
    expect(find.text('₹3,300'), findsOneWidget);
    expect(find.textContaining('₹2,500 – ₹4,100'), findsOneWidget);
    expect(find.textContaining('Nagpuri'), findsOneWidget);
    expect(find.text('Azadpur'), findsOneWidget);
    expect(find.text('₹5,200'), findsOneWidget);
    expect(find.text('Near you'), findsOneWidget);
    expect(find.text('Major mandi'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    // The server's reason code becomes plain words; the code itself never shows.
    expect(find.textContaining('source_unreachable'), findsNothing);
    expect(
      find.text(
        'Showing the last saved prices; they update on the next successful load.',
      ),
      findsOneWidget,
    );

    // Another scope has its own cache: nothing saved for it yet.
    await tester.tap(find.byKey(const Key('market-scope-major')));
    await settle(tester);
    expect(find.text('Warud'), findsNothing);
    expect(
      find.textContaining('Prices load when the phone is online'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('market opens from tasks and shows the empty note', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/tasks',
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-market')));
    await settle(tester);
    expect(find.text('Market prices'), findsOneWidget);
    expect(
      find.text(
        'Prices load when the phone is online and the price source is '
        'connected.',
      ),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('a source that is not set up yet reads as coming soon', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/market',
      seed: (db) => seedPrices(
        db,
        body: samplePrices(
          stale: true,
          reason: 'no API key configured (MARKET_API_KEY)',
        ),
      ),
    );
    await settle(tester);
    // An older server's free-text reason falls back to the general note.
    expect(find.textContaining('MARKET_API_KEY'), findsNothing);
    expect(find.textContaining('शेवटचे जतन केलेले भाव'), findsOneWidget);
    await unmountApp(tester);

    await pumpApp(
      tester,
      initialLocation: '/market',
      seed: (db) => seedPrices(
        db,
        body: samplePrices(stale: true, reason: 'source_not_configured'),
      ),
    );
    await settle(tester);
    expect(find.text('बाजारभाव सेवा लवकरच सुरू होईल.'), findsOneWidget);
    await unmountApp(tester);
  });

  test('source names map to Marathi / Hindi; unknown ones stay as sent', () {
    expect(marketLabel('Warud', 'mr'), 'वरूड');
    expect(marketLabel(' KALAMNA ', 'hi'), 'कलमना');
    expect(marketLabel('Warud', 'en'), 'Warud');
    expect(marketLabel('Some New Mandi', 'mr'), 'Some New Mandi');
    expect(marketStateLabel('NCT of Delhi', 'mr'), 'दिल्ली');
    expect(marketStateLabel('Atlantis', 'hi'), 'Atlantis');
    expect(marketVarietyLabel('Nagpuri', 'mr'), 'नागपुरी');
    expect(marketVarietyLabel('Other', 'hi'), 'अन्य');
    expect(marketCommodityLabel('Mousambi(Sweet Lime)', 'mr'), 'मोसंबी');
    expect(marketCommodityLabel('Banana', 'mr'), 'Banana');
  });

  testWidgets('in Marathi the rows read mandi, state and variety in Marathi', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/market', seed: seedPrices);
    await settle(tester);
    expect(find.text('वरूड'), findsOneWidget);
    expect(find.text('आझादपूर'), findsOneWidget);
    expect(find.textContaining('महाराष्ट्र ·'), findsOneWidget);
    expect(find.textContaining('दिल्ली ·'), findsOneWidget);
    expect(find.textContaining('नागपुरी'), findsOneWidget);
    expect(find.textContaining('Warud'), findsNothing);
    await unmountApp(tester);
  });
}
