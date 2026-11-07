import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'interest_fakes.dart';
import 'market_link_fakes.dart';

Future<void> _pump(
  WidgetTester tester,
  String route, {
  required FakeInterestApi api,
  FakeRegistrationApi? people,
}) async {
  await pumpMarketLink(
    tester,
    route,
    api: people ?? FakeRegistrationApi(own: [ownTrader()]),
    overrides: [interestApiProvider.overrideWithValue(api)],
  );
  await settle(tester);
}

void main() {
  testWidgets('flag off: the trader routes go home and More has no entry', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/market-link/market');
    expect(find.text('विक्रीसाठी माल'), findsNothing);
    await unmountApp(tester);
    await pumpApp(tester, initialLocation: '/more');
    expect(find.byKey(const Key('more-market-browse')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a verified trader sees the lot by place, with the disclaimer', (
    tester,
  ) async {
    await _pump(
      tester,
      '/market-link/market',
      api: FakeInterestApi(buyerLots: [sampleBuyerLot()]),
    );
    expect(find.byKey(const Key('ml-buyer-lot-l1')), findsOneWidget);
    expect(find.text('वरुड, अमरावती'), findsOneWidget);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('before the admin check the list says so', (tester) async {
    await _pump(
      tester,
      '/market-link/market',
      api: FakeInterestApi(
        error: const MarketCallException(
          MarketCallProblem.refused,
          'not_verified',
        ),
      ),
    );
    expect(
      find.text('BagMitra ने तुमची नोंदणी तपासल्यावर माल येथे दिसेल.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('my offers: waiting, accepted and the closed notice', (
    tester,
  ) async {
    await _pump(
      tester,
      '/market-link/offers',
      api: FakeInterestApi(
        sentList: [
          SentInterest(sampleInterest(), sampleLotBrief),
          SentInterest(
            sampleInterest(id: 'i2', status: InterestStatus.closed),
            sampleLotBrief,
          ),
        ],
      ),
    );
    expect(find.text('शेतकऱ्याच्या निर्णयाची वाट'), findsOneWidget);
    expect(
      find.text('बंद: शेतकऱ्याने दुसरी ऑफर निवडली किंवा माल यादीतून काढला.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('my offers: empty state', (tester) async {
    await _pump(tester, '/market-link/offers', api: FakeInterestApi());
    expect(
      find.text('मालावर दिलेल्या तुमच्या ऑफर येथे दिसतील.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
