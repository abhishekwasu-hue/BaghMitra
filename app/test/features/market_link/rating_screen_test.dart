import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/domain/deal_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'interest_fakes.dart';
import 'market_link_fakes.dart';

Future<FakeInterestApi> _pump(
  WidgetTester tester, {
  DealRatings? ratings,
  String route = '/market-link/deals/d1/rate?as=grower',
}) async {
  final api = FakeInterestApi(dealRatings: ratings, tags: sampleTags);
  await pumpMarketLink(
    tester,
    route,
    api: FakeRegistrationApi(),
    overrides: [interestApiProvider.overrideWithValue(api)],
  );
  await settle(tester);
  return api;
}

Future<void> _show(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ),
  );
}

Future<void> _star(WidgetTester tester, String role, String q, int n) async {
  final star = find.byKey(Key('ml-star-$role-$q-$n'));
  await _show(tester, star);
  await tester.ensureVisible(star);
  await tester.pumpAndSettle();
  await tester.tap(star);
  await tester.pump();
}

void main() {
  testWidgets('stars on every line and ticks; no text field anywhere', (
    tester,
  ) async {
    final api = await _pump(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsOneWidget);
    expect(find.text('व्यापारी · सुनील शिंदे'), findsOneWidget);
    final save = find.byKey(const Key('ml-rate-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    final qs = sampleRatings().questions;
    final tag = find.byKey(const Key('ml-tag-t2'));
    await _show(tester, tag);
    await tester.tap(tag);
    await tester.pump();
    for (final q in qs[DealRole.trader]!) {
      await _star(tester, 'trader', q, 4);
    }
    // Still one line left without stars (the broker's): not saved yet.
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await _show(tester, find.text('मध्यस्थ (दलाल) · सुरेश वानखडे'));
    for (final q in qs[DealRole.broker]!) {
      await _star(tester, 'broker', q, 5);
    }
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await tester.tap(save);
    await settle(tester);
    expect(api.rated.map((r) => r.$1), [DealRole.trader, DealRole.broker]);
    final trader = api.rated.first.$2;
    expect(trader.map((a) => a.stars), [4, 4, 4, 4]);
    expect(trader.first.tagIds, ['t2']);
    expect(find.text('रेटिंग जतन झाले'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a saved rating shows and can be changed', (tester) async {
    final api = await _pump(
      tester,
      ratings: sampleRatings(
        state: sampleState(role: DealRole.trader, grower: true, trader: true),
        given: {
          DealRole.grower: const [
            RatingAnswer('grower_produce_matched', 3, ['x']),
            RatingAnswer('grower_ready_on_date', 2),
          ],
        },
      ),
      route: '/market-link/deals/d1/rate',
    );
    expect(find.text('शेतकरी · रमेश पाटील'), findsOneWidget);
    await _star(tester, 'grower', 'grower_ready_on_date', 5);
    await tester.tap(find.byKey(const Key('ml-rate-save')));
    await settle(tester);
    final [(role, answers)] = api.rated;
    expect(role, DealRole.grower);
    expect(answers.map((a) => '${a.stars}${a.tagIds}'), ['3[x]', '5[]']);
    await unmountApp(tester);
  });

  testWidgets('locked after 7 days: read only, no save', (tester) async {
    await _pump(
      tester,
      ratings: sampleRatings(
        state: sampleState(grower: true, trader: true, locked: true),
      ),
    );
    expect(find.byKey(const Key('ml-rate-save')), findsNothing);
    expect(find.textContaining('रेटिंग'), findsWidgets);
    expect(find.textContaining('बंद झाले'), findsOneWidget);
    final star = find.byKey(const Key('ml-star-trader-trader_on_date-1'));
    expect(tester.widget<IconButton>(star).onPressed, isNull);
    await unmountApp(tester);
  });

  testWidgets('before both tapped: the wait, nothing to rate', (tester) async {
    await _pump(
      tester,
      ratings: sampleRatings(state: sampleState(grower: true)),
    );
    expect(find.textContaining('दोघांनी'), findsOneWidget);
    expect(find.byKey(const Key('ml-rate-save')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('flag off: the rating and deal routes go home', (tester) async {
    for (final route in [
      '/market-link/deals/d1/rate?as=grower',
      '/market-link/deals/d1?as=grower',
    ]) {
      await pumpApp(tester, initialLocation: route);
      expect(find.byKey(const Key('ml-rate-save')), findsNothing);
      expect(find.byKey(const Key('ml-deal-done-card')), findsNothing);
      await unmountApp(tester);
    }
  });
}
