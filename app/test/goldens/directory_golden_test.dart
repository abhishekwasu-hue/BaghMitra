// Look-alike cards, lab directory, market directory and the fair-price check on a sale.
// Regenerate with:
//   flutter test --update-goldens test/goldens/directory_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/accounts/fair_price_test.dart' show pricesOnSaleDay;
import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/market/market_prices_test.dart' show seedPrices;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

Future<void> _plotAndPrices(AppDatabase db) async {
  await seedPlot(db);
  await seedPrices(db, body: pricesOnSaleDay());
}

void main() {
  for (final (name, location, seed) in [
    ('lookalikes_mr_light', '/lookalikes?plot=p1', seedPlot),
    ('labs_mr_light', '/labs', null),
    ('market_directory_mr_light', '/market/directory', null),
    ('add_sale_fair_price_mr_light', '/plots/p1/accounts/sale', _plotAndPrices),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seed);
      await settle(tester);
      if (name.startsWith('add_sale')) {
        await tester.enterText(find.byKey(const Key('sale-rate')), '3630');
        await settle(tester);
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
