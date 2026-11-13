// The reaction bar (owner 2026-11-12, Q146) under a feed article and under an answer of the
// विचारा tab: tap, change and remove with counts and the highlighted choice, the short
// thank-you, the offline queue (and no "will go later" line while online).
import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/reactions/data/reaction_providers.dart';
import 'package:bagmitra/features/reactions/data/reaction_store.dart';
import 'package:bagmitra/features/reactions/domain/reaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';
import '../ask/ask_tab_test.dart' show ask;
import '../feed/feed_data_test.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'reaction_store_test.dart' show FakeReactionServer;

// The old offline line under the bar (owner 2026-11-13: never shown; it waits quietly).
const pendingNote = 'फोनवर ठेवले; इंटरनेट आल्यावर जाईल.';

Future<void> seedFeed(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': '2026-10-13T05:00:00.000Z',
    'page': feedBody([
      {...feedJson('gr1'), 'title': 'फळबाग लागवड अनुदान'},
    ]),
  }),
);

Future<void> openItem(WidgetTester tester, FakeReactionServer server) async {
  await pumpApp(
    tester,
    initialLocation: '/feed/gr1',
    seed: seedFeed,
    overrides: [
      feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
      reactionServerProvider.overrideWithValue(server),
    ],
  );
  await settle(tester);
  await tester.scrollUntilVisible(
    find.byKey(const Key('reaction-unclear')),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await settle(tester);
}

Future<void> tapChip(WidgetTester tester, Reaction r) async {
  await tester.tap(find.byKey(Key('reaction-${r.value}')));
  await settle(tester);
}

String? countOf(WidgetTester tester, Reaction r) {
  final f = find.byKey(Key('reaction-${r.value}-count'));
  return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
}

bool isSelected(WidgetTester tester, Reaction r) => tester
    .getSemantics(find.byKey(Key('reaction-${r.value}')))
    .flagsCollection
    .isSelected
    .toBoolOrNull()!;

void main() {
  testWidgets('feed item: tap, change and remove with counts', (tester) async {
    final server = FakeReactionServer(
      others: {
        'gr1': {Reaction.useful: 2, Reaction.okay: 1},
      },
    );
    await openItem(tester, server);
    expect(find.text('हा लेख कसा वाटला?'), findsOneWidget);
    for (final w in ['उपयोगी', 'धन्यवाद', 'आवडले', 'ठीक', 'समजले नाही']) {
      expect(find.text(w), findsOneWidget);
    }
    // The counts come from the server when the bar opens (Marathi digits).
    expect(countOf(tester, Reaction.useful), '२');
    expect(countOf(tester, Reaction.unclear), isNull);
    final size = tester.getSize(find.byKey(const Key('reaction-useful')));
    expect(size.height, greaterThanOrEqualTo(48));

    await tapChip(tester, Reaction.useful);
    expect(countOf(tester, Reaction.useful), '३');
    expect(isSelected(tester, Reaction.useful), isTrue);
    expect(find.text('धन्यवाद!'), findsOneWidget);
    expect(find.text(pendingNote), findsNothing, reason: 'online: sent');
    expect(server.sent.last, ('gr1', Reaction.useful));

    await tapChip(tester, Reaction.unclear);
    expect(countOf(tester, Reaction.useful), '२');
    expect(countOf(tester, Reaction.unclear), '१');
    expect(isSelected(tester, Reaction.unclear), isTrue);
    expect(isSelected(tester, Reaction.useful), isFalse);

    await tapChip(tester, Reaction.unclear);
    expect(countOf(tester, Reaction.unclear), isNull);
    expect(isSelected(tester, Reaction.unclear), isFalse);
    expect(server.sent.last, ('gr1', null));
    await unmountApp(tester);
  });

  testWidgets(
    'offline: shown at once, queued, sent when the bar opens online',
    (tester) async {
      final server = FakeReactionServer(online: false);
      await openItem(tester, server);
      await tapChip(tester, Reaction.thanks);
      expect(isSelected(tester, Reaction.thanks), isTrue);
      expect(countOf(tester, Reaction.thanks), '१');
      expect(find.text('धन्यवाद!'), findsOneWidget);
      expect(find.text(pendingNote), findsNothing);
      expect(find.byKey(const Key('reaction-pending')), findsNothing);
      expect(server.sent, isEmpty);

      // Back online: opening the item again sends the waiting reaction.
      server.online = true;
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/feed');
      await settle(tester);
      router.go('/feed/gr1');
      await settle(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('reaction-unclear')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await settle(tester);
      expect(server.sent, [('gr1', Reaction.thanks)]);
      expect(find.text(pendingNote), findsNothing);
      expect(isSelected(tester, Reaction.thanks), isTrue);
      expect(countOf(tester, Reaction.thanks), '१');
      await unmountApp(tester);
    },
  );

  testWidgets('a Q&A answer takes a reaction under qa:<id>', (tester) async {
    final server = FakeReactionServer(online: false);
    final db = await pumpApp(
      tester,
      initialLocation: '/ask',
      overrides: [reactionServerProvider.overrideWithValue(server)],
    );
    await settle(tester);
    await ask(tester, 'सायलाची लक्षणे काय?');
    final bar = find.byKey(const Key('reaction-bar-qa:seed-psylla-symptoms'));
    await tester.scrollUntilVisible(
      bar,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('हे उत्तर कसे वाटले?'), findsOneWidget);
    await tapChip(tester, Reaction.liked);
    expect(isSelected(tester, Reaction.liked), isTrue);
    expect(find.text(pendingNote), findsNothing);
    expect(find.byKey(const Key('reaction-pending')), findsNothing);
    final state = await tester.runAsync(() => ReactionStore(db, server).load());
    expect(state!.pending, {'qa:seed-psylla-symptoms': Reaction.liked});

    server.online = true;
    await tester.runAsync(() => ReactionStore(db, server).flush());
    expect(server.sent, [('qa:seed-psylla-symptoms', Reaction.liked)]);
    await unmountApp(tester);
  });
}
