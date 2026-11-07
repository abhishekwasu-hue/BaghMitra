import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:bagmitra/features/market_link/presentation/introduction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'interest_fakes.dart';
import 'lot_offers_test.dart' show pumpOffers, seedPublishedLot, twoOffers;
import 'market_link_fakes.dart';

void main() {
  testWidgets('the trader sees the grower, the pin and calls the grower', (
    tester,
  ) async {
    final dialled = <String>[];
    final maps = <(double, double)>[];
    await pumpMarketLink(
      tester,
      '/market-link/deals/d1',
      api: FakeRegistrationApi(),
      dialled: dialled,
      overrides: [
        interestApiProvider.overrideWithValue(FakeInterestApi()),
        mapOpenerProvider.overrideWithValue((lat, lon) async {
          maps.add((lat, lon));
          return true;
        }),
      ],
    );
    await settle(tester);
    expect(find.text('रमेश पाटील'), findsOneWidget);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ml-intro-map')));
    await tester.tap(find.byKey(const Key('ml-intro-call')));
    await settle(tester);
    expect(maps, [(21.2751, 78.5853)]);
    expect(dialled, ['+919812345678']);
    await unmountApp(tester);
  });

  testWidgets('the grower, after accepting, lands on the contacts', (
    tester,
  ) async {
    final dialled = <String>[];
    await pumpMarketLink(
      tester,
      '/market-link/lots/l1/offers',
      api: FakeRegistrationApi(),
      dialled: dialled,
      seed: seedPublishedLot,
      overrides: [
        interestApiProvider.overrideWithValue(
          FakeInterestApi(onLotList: twoOffers()),
        ),
      ],
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-lot-offer-i1')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-accept')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-accept-yes')));
    await settle(tester);
    expect(find.byKey(const Key('ml-intro-trader')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ml-intro-call')));
    expect(dialled, ['+919800000001']); // the grower calls the trader
    await unmountApp(tester);
  });

  testWidgets('an accepted offer opens its contacts from both sides', (
    tester,
  ) async {
    await pumpOffers(
      tester,
      FakeInterestApi(onLotList: twoOffers(accepted: true)),
    );
    expect(find.byKey(const Key('ml-accept')), findsNothing);
    await tester.tap(find.byKey(const Key('ml-intro-open')));
    await settle(tester);
    expect(find.byKey(const Key('ml-intro-grower')), findsOneWidget);
    await unmountApp(tester);
    await pumpMarketLink(
      tester,
      '/market-link/offers',
      api: FakeRegistrationApi(),
      overrides: [
        interestApiProvider.overrideWithValue(
          FakeInterestApi(
            sentList: [
              SentInterest(
                sampleInterest(status: InterestStatus.accepted, dealId: 'd1'),
                sampleLotBrief,
              ),
            ],
          ),
        ),
      ],
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-sent-intro-i1')));
    await settle(tester);
    expect(find.byKey(const Key('ml-intro-grower')), findsOneWidget);
    await unmountApp(tester);
  });
}
