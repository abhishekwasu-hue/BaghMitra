// Market linkage L5 screens at phone width (360 dp), Marathi, text at 1.3x, light and dark:
// "व्यवहार झाला" on the introduction (waiting for the other side; both done with rating and
// the copy to Accounts) and the rating screen (open with stars and ticks; closed after 7
// days). Regenerate with:
//   flutter test --update-goldens test/goldens/market_link_l5_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/domain/deal_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/market_link/interest_fakes.dart';
import '../features/market_link/lot_offers_test.dart' show seedPublishedLot;
import '../features/market_link/market_link_fakes.dart';
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

final _done = sampleState(grower: true, trader: true);

final _given = {
  DealRole.trader: const [
    RatingAnswer('trader_on_date', 5, ['t1']),
    RatingAnswer('trader_weighing_correct', 4),
    RatingAnswer('trader_paid_as_agreed', 3, ['t4']),
    RatingAnswer('trader_kept_conditions', 4),
  ],
};

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (name, route, state, locked, scrollTo) in [
      (
        'l5_deal_wait',
        '/market-link/deals/d1?as=grower',
        sampleState(grower: true),
        false,
        'ml-deal-done-card',
      ),
      (
        'l5_deal_done',
        '/market-link/deals/d1?as=grower',
        _done,
        false,
        'ml-deal-done-card',
      ),
      ('l5_rate', '/market-link/deals/d1/rate?as=grower', _done, false, null),
      (
        'l5_rate_locked',
        '/market-link/deals/d1/rate?as=grower',
        sampleState(grower: true, trader: true, locked: true),
        true,
        null,
      ),
    ]) {
      testWidgets('${name}_mr_${mode.name}', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final api = FakeInterestApi(
          intro: sampleIntroduction(state: state),
          dealRatings: sampleRatings(state: state, given: _given),
          tags: sampleTags,
        );
        await pumpMarketLink(
          tester,
          route,
          themeMode: mode,
          api: FakeRegistrationApi(),
          seed: seedPublishedLot,
          overrides: [interestApiProvider.overrideWithValue(api)],
        );
        await settle(tester);
        if (scrollTo != null) {
          await tester.scrollUntilVisible(
            find.byKey(Key(scrollTo)),
            300,
            scrollable: find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        expect(locked, state.ratingLocked);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${name}_mr_${mode.name}.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
