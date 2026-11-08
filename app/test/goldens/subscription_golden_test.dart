@Tags(['golden'])
library;

import 'package:bagmitra/app/router.dart';
import 'package:bagmitra/features/billing/data/subscription_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/billing/fake_play_billing.dart';
import '../features/billing/subscription_screen_test.dart'
    show billingOverrides, increase, offerPlan;
import '../helpers/pump_app.dart';

void main() {
  // Marathi phone screenshots of the subscription page (billing addendum §7).
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = mode == ThemeMode.light ? 'light' : 'dark';
    testWidgets('subscription_offer_mr_$name', (tester) async {
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: Routes.subscription,
        overrides: billingOverrides(plan: offerPlan, play: FakePlayBilling()),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('subscription_offer_mr_$name.png'),
      );
      await unmountApp(tester);
    });
    testWidgets('subscription_notice_mr_$name', (tester) async {
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: Routes.subscription,
        overrides: billingOverrides(
          plan: const PlanOffer(
            inForce: true,
            accountId: 'a',
            productId: 'bagmitra_grower',
            basePlanId: 'monthly',
            covered: true,
            priceChange: increase,
          ),
          play: FakePlayBilling(),
        ),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('subscription_notice_mr_$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
