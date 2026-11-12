// The reaction bar (Q146) on a 360 px phone, Marathi, 1.3x text, light and dark: under a feed
// item with counts and the reader's own choice (online, sent), the same offline with the
// "waits on the phone" line, and under an answer of the विचारा tab.
//   flutter test --update-goldens test/goldens/reactions_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/reactions/data/reaction_providers.dart';
import 'package:bagmitra/features/reactions/domain/reaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/ask/ask_tab_test.dart' show ask;
import '../features/feed/feed_data_test.dart' show FakeFeedRepository;
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/reactions/reaction_bar_test.dart' show seedFeed;
import '../features/reactions/reaction_store_test.dart' show FakeReactionServer;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

Future<void> _toBar(WidgetTester tester, {required bool ask}) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('reaction-unclear')),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  // The feed item: the bar in the middle; the answer: its last lines above the bar.
  await tester.drag(find.byType(Scrollable).first, Offset(0, ask ? 330 : -160));
  await settle(tester);
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final part in ['feed', 'feed_offline', 'ask']) {
      final name =
          '${part == 'ask' ? 'ask' : 'feed'}_reactions'
          '${part == 'feed_offline' ? '_offline' : ''}_mr_${mode.name}_360_x13';
      if (part == 'feed_offline' && mode == ThemeMode.dark) continue;
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final server = FakeReactionServer(
          online: part != 'feed_offline',
          others: {
            'gr1': {Reaction.useful: 11, Reaction.thanks: 4, Reaction.okay: 1},
            'qa:seed-psylla-symptoms': {Reaction.useful: 6, Reaction.liked: 2},
          },
        );
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: part == 'ask' ? '/ask' : '/feed/gr1',
          seed: part == 'ask' ? null : seedFeed,
          size: _phone,
          overrides: [
            feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
            reactionServerProvider.overrideWithValue(server),
          ],
        );
        await settle(tester);
        if (part == 'ask') await ask(tester, 'सायलाची लक्षणे काय?');
        await _toBar(tester, ask: part == 'ask');
        await tester.tap(
          find.byKey(Key('reaction-${part == 'ask' ? 'liked' : 'useful'}')),
        );
        await settle(tester);
        // The thank-you toast has gone; the bar itself is the subject.
        await tester.pump(const Duration(seconds: 3));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$name.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
