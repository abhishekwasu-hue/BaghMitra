import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/data/lot_settings_store.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'interest_fakes.dart';
import 'lot_settings_test.dart' show lotSettingsJson;
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

  testWidgets('an offer sends rate, basis, quantity and date only', (
    tester,
  ) async {
    final api = FakeInterestApi(buyerLots: [sampleBuyerLot()]);
    await _pump(tester, '/market-link/market/l1/offer', api: api);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ml-offer-send')));
    await settle(tester);
    expect(api.sent, isEmpty); // the rate is needed
    await tester.enterText(find.byKey(const Key('ml-offer-rate')), '450');
    await tester.enterText(find.byKey(const Key('ml-offer-tonnes')), '12');
    await tester.tap(find.byKey(const Key('ml-offer-basis-per_crate')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-offer-send')));
    await settle(tester);
    final (lotId, d) = api.sent.single;
    expect(lotId, 'l1');
    expect((d.basis, d.ratePaise, d.quantityT), ('per_crate', 45000, 12.0));
    expect(d.harvestDate, DateTime(2026, 12));
    expect((d.brokerId, d.traderId), (null, null));
    expect(find.text('माझ्या ऑफर'), findsWidgets); // on to "my offers"
    await unmountApp(tester);
  });

  testWidgets('the offer rate has the range of the lot crop and basis (Q138)', (
    tester,
  ) async {
    final api = FakeInterestApi(
      buyerLots: [
        sampleBuyerLot(),
        sampleBuyerLot(id: 'l2', crop: 'mosambi'),
      ],
    );
    await pumpMarketLink(
      tester,
      '/market-link/market/l1/offer',
      api: FakeRegistrationApi(own: [ownTrader()]),
      overrides: [interestApiProvider.overrideWithValue(api)],
      size: const Size(393, 1400),
      // The admin gave mosambi its own range; the phone saved it.
      seed: (db) => db.writeMeta(
        LotSettingsStore.key,
        lotSettingsJson(mosambiQuintalMin: 400000),
      ),
    );
    await settle(tester);
    // A santra lot per quintal: the muted range line under the field.
    expect(find.text('₹२,५०० – ₹१०,००० प्रति क्विंटल'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('ml-offer-rate')), '20000');
    await tester.tap(find.byKey(const Key('ml-offer-send')));
    await settle(tester);
    expect(api.sent, isEmpty);
    expect(
      find.text('कृपया दर ₹२,५०० ते ₹१०,००० या दरम्यान लिहा.'),
      findsOneWidget,
    );
    // Per crate: its own range, the message follows the typing.
    await tester.tap(find.byKey(const Key('ml-offer-basis-per_crate')));
    await tester.enterText(find.byKey(const Key('ml-offer-rate')), '2000');
    await settle(tester);
    expect(
      find.text('कृपया दर ₹४०० ते ₹१,२०० या दरम्यान लिहा.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('ml-offer-rate')), '450');
    await settle(tester);
    expect(find.textContaining('या दरम्यान लिहा'), findsNothing);
    expect(find.text('₹४०० – ₹१,२०० प्रति क्रेट'), findsOneWidget);
    // The whole orchard has no range.
    await tester.tap(find.byKey(const Key('ml-offer-basis-lump_sum')));
    await settle(tester);
    expect(find.textContaining(' – ₹'), findsNothing);
    // The server's own check (its newer admin values) answers calmly.
    api.sendError = const MarketCallException(
      MarketCallProblem.refused,
      'interest_rate_out_of_range',
    );
    await tester.tap(find.byKey(const Key('ml-offer-send')));
    await settle(tester);
    expect(
      find.text('दर दिलेल्या मर्यादेत लिहा, मग पुन्हा पाठवा.'),
      findsOneWidget,
    );
    await unmountApp(tester);

    // A mosambi lot uses mosambi's range.
    await pumpMarketLink(
      tester,
      '/market-link/market/l2/offer',
      api: FakeRegistrationApi(own: [ownTrader()]),
      overrides: [interestApiProvider.overrideWithValue(api)],
      seed: (db) => db.writeMeta(
        LotSettingsStore.key,
        lotSettingsJson(mosambiQuintalMin: 400000),
      ),
    );
    await settle(tester);
    expect(find.text('₹४,००० – ₹१०,००० प्रति क्विंटल'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a broker must name the trader it brings', (tester) async {
    final api = FakeInterestApi(buyerLots: [sampleBuyerLot()]);
    await _pump(
      tester,
      '/market-link/market/l1/offer',
      api: api,
      people: FakeRegistrationApi(own: [ownBroker()], listed: [sampleTrader()]),
    );
    await tester.enterText(find.byKey(const Key('ml-offer-rate')), '3200');
    await tester.tap(find.byKey(const Key('ml-offer-send')));
    await settle(tester);
    expect(api.sent, isEmpty);
    await tester.scrollUntilVisible(
      find.byKey(const Key('ml-offer-party')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('ml-offer-party')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-party-b1')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('ml-offer-send')));
    await tester.tap(find.byKey(const Key('ml-offer-send')));
    await settle(tester);
    expect(api.sent.single.$2.traderId, 'b1');
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
