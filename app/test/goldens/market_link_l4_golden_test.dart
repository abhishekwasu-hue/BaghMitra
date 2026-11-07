// Market linkage L4 screens at phone width (360 dp), Marathi, text at 1.3x, light and dark:
// the traders' produce list, the offer form, "my offers", the grower's compare and accept,
// and the introduction (contacts). Regenerate with:
//   flutter test --update-goldens test/goldens/market_link_l4_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';

import 'package:bagmitra/api/generated/bagmitra.swagger.dart'
    show V1MarketPricesGetScope;
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/interest_fakes.dart';
import '../features/market_link/lot_offers_test.dart'
    show seedPublishedLot, twoOffers;
import '../features/market_link/market_link_fakes.dart';
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

Future<void> _seed(AppDatabase db) async {
  await seedPublishedLot(db);
  // Today's mandi price saved on the phone (the stored modal price, Q48).
  await db.writeMeta(
    MarketPricesCache.keyFor('santra', V1MarketPricesGetScope.all),
    jsonEncode({
      'saved_at': '2026-10-13T05:00:00.000Z',
      'prices': {
        'stale': false,
        'prices': [
          {
            'day': '2026-10-13',
            'market': 'Warud',
            'state': 'Maharashtra',
            'district': 'Amravati',
            'commodity': 'Orange',
            'modal_rs_per_quintal': 3300,
            'source': 'agmarknet',
            'is_local': true,
            'is_major': false,
          },
        ],
      },
    }),
  );
}

FakeInterestApi _api() => FakeInterestApi(
  buyerLots: [
    sampleBuyerLot(),
    sampleBuyerLot(id: 'l2'),
  ],
  onLotList: twoOffers(),
  sentList: [
    SentInterest(
      sampleInterest(status: InterestStatus.accepted, dealId: 'd1'),
      sampleLotBrief,
    ),
    SentInterest(sampleInterest(id: 'i2'), sampleLotBrief),
    SentInterest(
      sampleInterest(id: 'i3', status: InterestStatus.closed),
      sampleLotBrief,
    ),
  ],
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (name, route, tap) in [
      ('l4_browse', '/market-link/market', null),
      ('l4_offer_form', '/market-link/market/l1/offer', null),
      ('l4_my_offers', '/market-link/offers', null),
      ('l4_compare', '/market-link/lots/l1/offers', 'ml-lot-offer-i1'),
      ('l4_contacts', '/market-link/deals/d1?as=grower', null),
    ]) {
      testWidgets('${name}_mr_${mode.name}', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpMarketLink(
          tester,
          route,
          themeMode: mode,
          api: FakeRegistrationApi(own: [ownTrader()], listed: samplePeople),
          seed: _seed,
          overrides: [interestApiProvider.overrideWithValue(_api())],
        );
        await settle(tester);
        if (tap != null) {
          await tester.tap(find.byKey(Key(tap)));
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${name}_mr_${mode.name}.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
