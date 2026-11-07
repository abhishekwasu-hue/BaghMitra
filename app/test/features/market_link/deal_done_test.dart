import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/domain/deal_rating.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:bagmitra/features/market_link/presentation/deal_done_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'interest_fakes.dart';
import 'lot_offers_test.dart' show seedPublishedLot;
import 'market_link_fakes.dart';

Future<FakeInterestApi> _pump(
  WidgetTester tester,
  DealState state, {
  bool asGrower = true,
}) async {
  final api = FakeInterestApi(
    intro: sampleIntroduction(state: state),
    tags: sampleTags,
  );
  await pumpMarketLink(
    tester,
    '/market-link/deals/d1${asGrower ? '?as=grower' : ''}',
    api: FakeRegistrationApi(),
    seed: seedPublishedLot,
    overrides: [interestApiProvider.overrideWithValue(api)],
  );
  await settle(tester);
  final card = find.byKey(const Key('ml-deal-done-card'));
  await tester.scrollUntilVisible(
    card,
    200,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

Introduction _deal(String basis, int ratePaise, {double? tonnes = 12}) =>
    Introduction(
      dealId: 'd1',
      acceptedAt: DateTime.utc(2026, 12),
      lot: sampleLotBrief,
      interest: Interest(
        id: 'i1',
        lotId: 'l1',
        basis: basis,
        ratePaise: ratePaise,
        quantityT: tonnes,
        harvestDate: DateTime(2026, 12, 5),
        status: InterestStatus.accepted,
        viaBroker: false,
      ),
      grower: const Contact(name: 'रमेश', phone: null),
      growerPlace: '',
      trader: const Contact(name: 'सुनील', firm: 'शिंदे फ्रुट्स', phone: '1'),
      state: sampleState(),
    );

void main() {
  test('the sale copy keeps the agreed rate per quintal, never payment', () {
    final perTonne = saleFromDeal(_deal('per_tonne', 3200000));
    expect(perTonne.buyer, 'सुनील · शिंदे फ्रुट्स');
    expect(perTonne.kg, 12000);
    expect(perTonne.ratePaisePerQuintal, 320000);
    // A lump sum over the agreed tonnes; the lot's tonnes when none was given.
    expect(
      saleFromDeal(_deal('lump_sum', 36000000)).ratePaisePerQuintal,
      300000,
    );
    final noTonnes = saleFromDeal(_deal('lump_sum', 37500000, tonnes: null));
    expect(noTonnes.kg, 12500);
    expect(noTonnes.ratePaisePerQuintal, 300000);
    // Per crate has no quintal rate: the grower types it (Q114).
    expect(saleFromDeal(_deal('per_crate', 30000)).ratePaisePerQuintal, isNull);
  });

  testWidgets('the grower taps "deal done" after a confirm, then waits', (
    tester,
  ) async {
    final api = await _pump(tester, sampleState());
    expect(find.text('व्यवहार झाला'), findsWidgets);
    await tester.tap(find.byKey(const Key('ml-deal-done')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ml-deal-done-yes')));
    await settle(tester);
    expect(api.doneTaps, ['d1']);
    expect(find.byKey(const Key('ml-deal-done')), findsNothing);
    expect(find.textContaining('दुसऱ्या बाजूनेही'), findsOneWidget);
    expect(find.byKey(const Key('ml-rate-open')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the broker sees the taps and never taps', (tester) async {
    await _pump(
      tester,
      sampleState(role: DealRole.broker, grower: true),
      asGrower: false,
    );
    expect(find.byKey(const Key('ml-deal-done')), findsNothing);
    expect(find.textContaining('दोघांनी'), findsOneWidget);
    expect(find.textContaining('व्यवहार झाला म्हणाले'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('completed: copy opens the filled sale form', (tester) async {
    await _pump(tester, sampleState(grower: true, trader: true));
    expect(find.byKey(const Key('ml-deal-done')), findsNothing);
    await tester.tap(find.byKey(const Key('ml-copy-accounts')));
    await settle(tester);
    expect(find.text('सुनील शिंदे · शिंदे फ्रुट्स'), findsOneWidget);
    expect(find.text('12000'), findsOneWidget);
    expect(find.text('3200.00'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('completed: rate opens the rating', (tester) async {
    await _pump(tester, sampleState(grower: true, trader: true));
    await tester.tap(find.byKey(const Key('ml-rate-open')));
    await settle(tester);
    expect(find.byKey(const Key('ml-rate-save')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('after 7 days the rating is closed', (tester) async {
    await _pump(tester, sampleState(grower: true, trader: true, locked: true));
    expect(find.byKey(const Key('ml-rate-open')), findsNothing);
    expect(find.textContaining('बंद झाले'), findsOneWidget);
    await unmountApp(tester);
  });
}
