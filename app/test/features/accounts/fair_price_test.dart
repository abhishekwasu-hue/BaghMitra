import 'package:bagmitra/features/accounts/data/accounts_repository.dart';
import 'package:bagmitra/features/accounts/domain/fair_price.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../market/market_prices_test.dart' show samplePrices, seedPrices;
import '../plots/plots_screen_test.dart' show settle;
import 'accounts_summary_test.dart' show sale;

MandiPrice _p(
  String market,
  DateTime day,
  int modal, {
  bool local = false,
  bool major = false,
}) => MandiPrice(
  market: market,
  day: day,
  modalRsPerQuintal: modal,
  isLocal: local,
  isMajor: major,
);

/// pumpApp's clock is 2026-10-13: the sample prices moved to that day.
Map<String, Object?> pricesOnSaleDay() {
  final body = samplePrices();
  for (final p in body['prices']! as List) {
    (p as Map)['day'] = '2026-10-13';
  }
  return body;
}

void main() {
  final day = DateTime(2026, 10, 24);

  test('compares the rate with the modal price on the sale day', () {
    final c = compareWithMandi(
      ratePaisePerQuintal: 363000,
      soldOn: day,
      prices: [_p('Warud', day, 3300, local: true)],
    )!;
    expect(c.market, 'Warud');
    expect(c.day, day);
    expect(c.modalRsPerQuintal, 3300);
    expect(c.percent, 10);
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 297000,
        soldOn: day,
        prices: [_p('Warud', day, 3300)],
      )!.percent,
      -10,
    );
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 330000,
        soldOn: day,
        prices: [_p('Warud', day, 3300)],
      )!.percent,
      0,
    );
  });

  test('prefers a local market, then a major one, then the first listed', () {
    final prices = [
      _p('Indore', day, 4000),
      _p('Azadpur', day, 5200, major: true),
      _p('Kalamna', day, 3000, local: true),
    ];
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 300000,
        soldOn: day,
        prices: prices,
      )!.market,
      'Kalamna',
    );
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 300000,
        soldOn: day,
        prices: prices.take(2),
      )!.market,
      'Azadpur',
    );
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 300000,
        soldOn: day,
        prices: prices.take(1),
      )!.market,
      'Indore',
    );
  });

  test('no price on the sale day, no rate or no modal: nothing to show', () {
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 300000,
        soldOn: day,
        prices: [_p('Warud', DateTime(2026, 10, 23), 3300)],
      ),
      isNull,
    );
    expect(
      compareWithMandi(ratePaisePerQuintal: 300000, soldOn: day, prices: []),
      isNull,
    );
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 0,
        soldOn: day,
        prices: [_p('Warud', day, 3300)],
      ),
      isNull,
    );
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 300000,
        soldOn: day,
        prices: [_p('Warud', day, 0)],
      ),
      isNull,
    );
    // The sale day matches the price day by calendar date, whatever the time.
    expect(
      compareWithMandi(
        ratePaisePerQuintal: 300000,
        soldOn: DateTime(2026, 10, 24, 18),
        prices: [_p('Warud', DateTime.utc(2026, 10, 24), 3000)],
      )!.percent,
      0,
    );
  });

  testWidgets('add sale shows the mandi comparison as the rate is typed', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts/sale',
      seed: (db) async {
        await seedPlot(db);
        await seedPrices(db, body: pricesOnSaleDay());
      },
    );
    await settle(tester);
    expect(find.byKey(const Key('fair-price')), findsNothing);
    await tester.enterText(find.byKey(const Key('sale-rate')), '3630');
    await settle(tester);
    expect(find.byKey(const Key('fair-price')), findsOneWidget);
    final mandi = tester.widget<Text>(find.textContaining('Warud mandi, '));
    expect(mandi.data, endsWith(': modal price ₹3,300 per quintal'));
    expect(mandi.data, contains('2026'));
    expect(
      find.text('Your rate is 10% above the mandi modal price.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('sale-rate')), '2970');
    await settle(tester);
    expect(
      find.text('Your rate is 10% below the mandi modal price.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('sale-rate')), '3300');
    await settle(tester);
    expect(
      find.text('Your rate is the same as the mandi modal price.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('no mandi price for the day: the sale form shows nothing extra', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts/sale',
      seed: (db) async {
        await seedPlot(db);
        await seedPrices(db); // prices for 23–24 Oct, the sale is on 13 Oct
      },
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('sale-rate')), '3630');
    await settle(tester);
    expect(find.byKey(const Key('fair-price')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a recorded sale in accounts shows its comparison', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts',
      seed: (db) async {
        await seedPlot(db);
        final body = samplePrices();
        for (final p in body['prices']! as List) {
          (p as Map)['day'] = '2027-01-20'; // the sale() helper's day
        }
        await seedPrices(db, body: body);
        await AccountsRepository(db).saveIncome(sale('i1'));
      },
    );
    await settle(tester);
    // rate ₹3,200 vs Warud modal ₹3,300: 3% below.
    expect(
      find.text('Your rate is 3% below the mandi modal price.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
