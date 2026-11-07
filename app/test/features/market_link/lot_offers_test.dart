import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'interest_fakes.dart';
import 'market_link_fakes.dart';
import 'market_lot_repository_test.dart' show sampleLot;

Future<void> seedPublishedLot(AppDatabase db) async {
  await seedPlot(db);
  final repo = MarketLotRepository(db);
  await repo.save(sampleLot());
  await repo.keepServerState(
    'l1',
    status: 'published',
    publishedAt: DateTime.utc(2026, 10, 12),
    orchardCheck: 'inside',
  );
}

List<LotInterest> twoOffers({bool accepted = false}) => [
  LotInterest(
    sampleInterest(
      status: accepted ? InterestStatus.accepted : InterestStatus.open,
      dealId: accepted ? 'd1' : null,
    ),
    sampleTrader(),
    null,
  ),
  LotInterest(
    sampleInterest(
      id: 'i2',
      ratePaise: 3400000,
      viaBroker: true,
      status: accepted ? InterestStatus.closed : InterestStatus.open,
    ),
    sampleTrader(id: 'b2', deals: 3),
    sampleBroker(),
  ),
];

Future<void> pumpOffers(
  WidgetTester tester,
  FakeInterestApi api, {
  String route = '/market-link/lots/l1/offers',
}) async {
  await pumpMarketLink(
    tester,
    route,
    api: FakeRegistrationApi(),
    seed: seedPublishedLot,
    overrides: [interestApiProvider.overrideWithValue(api)],
  );
  await settle(tester);
}

void main() {
  testWidgets('the grower sees the offers with profile numbers, side by side', (
    tester,
  ) async {
    await pumpOffers(tester, FakeInterestApi(onLotList: twoOffers()));
    expect(find.byKey(const Key('ml-lot-offer-i1')), findsOneWidget);
    expect(find.byKey(const Key('ml-lot-offer-i2')), findsOneWidget);
    expect(find.textContaining('पूर्ण व्यवहार'), findsNWidgets(2));
    expect(find.textContaining('सुरेश वानखडे'), findsOneWidget);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsOneWidget);
    // Nothing chosen yet: the one main action waits.
    final accept = tester.widget<FilledButton>(
      find.byKey(const Key('ml-accept')),
    );
    expect(accept.onPressed, isNull);
    await unmountApp(tester);
  });

  testWidgets('choose, confirm with the disclaimer, accept', (tester) async {
    final api = FakeInterestApi(onLotList: twoOffers());
    await pumpOffers(tester, api);
    await tester.tap(find.byKey(const Key('ml-lot-offer-i2')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-accept')));
    await settle(tester);
    expect(find.text('ही ऑफर स्वीकारायची?'), findsOneWidget);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('ml-accept-yes')));
    await settle(tester);
    expect(api.accepted, ['i2']);
    await unmountApp(tester);
  });

  testWidgets('a refused acceptance asks to open the list again', (
    tester,
  ) async {
    final api = FakeInterestApi(
      onLotList: twoOffers(),
      acceptError: const MarketCallException(
        MarketCallProblem.refused,
        'lot_not_published',
      ),
    );
    await pumpOffers(tester, api);
    await tester.tap(find.byKey(const Key('ml-lot-offer-i1')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-accept')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-accept-yes')));
    await settle(tester);
    expect(find.text('ऑफर बदलली आहे; यादी पुन्हा उघडा.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('no offers yet: the empty state', (tester) async {
    await pumpOffers(tester, FakeInterestApi());
    expect(
      find.text('तपासलेल्या व्यापाऱ्यांच्या ऑफर येथे शेजारी-शेजारी दिसतील.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('a published lot in "my lots" opens its offers', (tester) async {
    await pumpOffers(tester, FakeInterestApi(), route: '/market-link/lots');
    await tester.tap(find.byKey(const Key('lot-offers-l1')));
    await settle(tester);
    expect(find.text('तुमच्या मालावरील ऑफर'), findsOneWidget);
    await unmountApp(tester);
  });
}
