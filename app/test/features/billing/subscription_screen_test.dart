import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/app/router.dart';
import 'package:bagmitra/features/app_update/data/app_update_providers.dart';
import 'package:bagmitra/features/billing/data/subscription_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import 'fake_play_billing.dart';

const offerPlan = PlanOffer(
  inForce: true,
  accountId: 'acct-hash',
  productId: 'bagmitra_grower',
  basePlanId: 'monthly',
);

const increase = PriceChangeOut(
  state: 'OUTSTANDING',
  mode: 'PRICE_INCREASE',
  newPricePaise: 14900,
  currency: 'INR',
  chargeTime: '2026-12-20T00:00:00Z',
);

/// Overrides for the subscription page: fake Play, fake server, recorded links.
List<Override> billingOverrides({
  required PlanOffer? plan,
  required FakePlayBilling play,
  FakeBillingServer? server,
  List<Uri>? opened,
}) => [
  playBillingProvider.overrideWithValue(play),
  billingServerProvider.overrideWithValue(
    server ?? FakeBillingServer(offer: plan),
  ),
  planOfferProvider.overrideWith((ref) async => plan),
  urlOpenerProvider.overrideWithValue((uri) async {
    opened?.add(uri);
    return true;
  }),
];

void main() {
  testWidgets('Play price, terms, subscribe with the server account id', (
    tester,
  ) async {
    final play = FakePlayBilling();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.subscription,
      overrides: billingOverrides(plan: offerPlan, play: play),
    );
    expect(find.text('₹99.00 a month'), findsOneWidget);
    expect(
      find.textContaining('Cancel any time in Google Play'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('billing-subscribe')));
    await tester.pumpAndSettle();
    expect(play.calls, contains('buy bagmitra_grower acct-hash'));
    await unmountApp(tester);
  });

  testWidgets('the price-increase notice links to Play', (tester) async {
    final opened = <Uri>[];
    const plan = PlanOffer(
      inForce: true,
      accountId: 'a',
      productId: 'bagmitra_grower',
      basePlanId: 'monthly',
      covered: true,
      priceChange: increase,
    );
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.subscription,
      overrides: billingOverrides(
        plan: plan,
        play: FakePlayBilling(),
        opened: opened,
      ),
    );
    expect(find.byKey(const Key('billing-change-notice')), findsOneWidget);
    expect(find.textContaining('Dec 20, 2026'), findsOneWidget);
    expect(find.byKey(const Key('billing-active')), findsOneWidget);
    expect(find.byKey(const Key('billing-subscribe')), findsNothing);
    await tester.tap(find.byKey(const Key('billing-open-play')));
    await tester.pumpAndSettle();
    expect(opened.single.host, 'play.google.com');
    expect(opened.single.queryParameters['sku'], 'bagmitra_grower');
    expect(opened.single.queryParameters['package'], 'app.bagmitra.bagmitra');
    await unmountApp(tester);
  });

  testWidgets('an accepted (CONFIRMED) increase is not asked to be accepted '
      '(audit L3)', (tester) async {
    const plan = PlanOffer(
      inForce: true,
      accountId: 'a',
      productId: 'bagmitra_grower',
      basePlanId: 'monthly',
      covered: true,
      priceChange: PriceChangeOut(
        state: 'CONFIRMED',
        mode: 'PRICE_INCREASE',
        newPricePaise: 14900,
        currency: 'INR',
        chargeTime: '2026-12-20T00:00:00Z',
      ),
    );
    final play = FakePlayBilling();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.subscription,
      overrides: billingOverrides(plan: plan, play: play),
    );
    expect(find.byKey(const Key('billing-change-notice')), findsOneWidget);
    expect(find.textContaining('already accepted'), findsOneWidget);
    expect(find.textContaining('accept it'), findsNothing);
    expect(play.calls, isNot(contains('message')));
    await unmountApp(tester);
  });

  testWidgets('an OUTSTANDING increase shows Play\'s own message at start '
      '(audit L3)', (tester) async {
    const plan = PlanOffer(
      inForce: true,
      accountId: 'a',
      productId: 'bagmitra_grower',
      basePlanId: 'monthly',
      covered: true,
      priceChange: increase,
    );
    final play = FakePlayBilling();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      overrides: billingOverrides(plan: plan, play: play),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(play.calls.where((c) => c == 'message'), hasLength(1));
    expect(find.textContaining('accept it in Google Play'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('All features lists Subscription only while it is in force', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.more,
      overrides: billingOverrides(
        plan: const PlanOffer(inForce: false, accountId: 'a'),
        play: FakePlayBilling(),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('more-settings')),
      300,
    );
    expect(find.byKey(const Key('more-subscription')), findsNothing);
    await unmountApp(tester);

    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.more,
      overrides: billingOverrides(plan: offerPlan, play: FakePlayBilling()),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('more-subscription')),
      300,
    );
    expect(find.byKey(const Key('more-subscription')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('without Google Play the page says where to open it', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.subscription,
      overrides: billingOverrides(
        plan: offerPlan,
        play: FakePlayBilling(isAvailable: false),
      ),
    );
    expect(find.textContaining('phone with Google Play'), findsOneWidget);
    expect(find.byKey(const Key('billing-subscribe')), findsNothing);
    expect(find.byKey(const Key('billing-manage')), findsOneWidget);
    await unmountApp(tester);
  });
}
