// Q165 (owner 2026-11-20, screenshot: the ज्ञान chip said "ज्ञान लेख परिस्थितीनुसार इथे
// येतील." although articles had been written): the whole feed's saved copy holds only the
// newest items of every kind, so a chip now also lists the server's answer for it, and
// "आणखी जुने दाखवा" fetches older pages; an item from either opens.
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_data_test.dart';

Map<String, Object?> _page(
  List<Map<String, Object?>> items, {
  String? nextBefore,
  String? nextId,
}) => {
  ...feedBody(items),
  if (nextBefore != null) 'next': {'before': nextBefore, 'before_id': nextId},
};

Map<String, Object?> _knowledge(String id, String at) =>
    feedJson(id, type: 'knowledge', publishedAt: at, grNumber: null);

void main() {
  testWidgets('the ज्ञान chip lists articles the whole feed no longer holds, '
      'and older pages on request', (tester) async {
    // The whole feed: only news (the articles were pushed out of its newest items).
    final repo = FakeFeedRepository(
      feedBody([feedJson('n1', type: 'news', trust: 'news', grNumber: null)]),
    );
    repo.pages[(FeedFilter.knowledge, null)] = _page(
      [_knowledge('k1', '2026-10-01T06:00:00Z')],
      nextBefore: '2026-10-01T06:00:00Z',
      nextId: 'k1',
    );
    repo.pages[(FeedFilter.knowledge, 'k1')] = _page([
      _knowledge('k0', '2026-05-01T06:00:00Z'),
    ]);
    await pumpApp(
      tester,
      initialLocation: '/feed',
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    await settle(tester);
    expect(find.text('Title k1'), findsNothing);
    expect(find.byKey(const Key('feed-show-older')), findsNothing);

    await tester.tap(find.byKey(const Key('feed-filter-knowledge')));
    await settle(tester);
    expect(find.text('Title k1'), findsOneWidget);
    expect(find.text('Title n1'), findsNothing);
    expect(find.byKey(const Key('feed-empty')), findsNothing);

    final older = find.byKey(const Key('feed-show-older'));
    await tester.ensureVisible(older);
    await tester.tap(older);
    await settle(tester);
    expect(find.text('Title k0'), findsOneWidget);
    // The last page: no button.
    expect(find.byKey(const Key('feed-show-older')), findsNothing);
    final cursors = [
      for (final (_, f, c) in repo.fetches)
        if (f == FeedFilter.knowledge) c?.beforeId,
    ];
    expect(cursors, containsAllInOrder([null, 'k1']));

    // The older article opens.
    await tester.tap(find.text('Title k0'));
    await settle(tester);
    expect(
      find.text('This message was removed from the saved list.'),
      findsNothing,
    );
    expect(find.text('Summary k0'), findsWidgets);
    expect(find.byKey(const Key('feed-knowledge-note')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('older page offline: a calm line, the list stays', (
    tester,
  ) async {
    final repo = FakeFeedRepository(
      _page(
        [feedJson('g1', publishedAt: '2026-10-12T06:00:00Z')],
        nextBefore: '2026-10-12T06:00:00Z',
        nextId: 'g1',
      ),
    );
    await pumpApp(
      tester,
      initialLocation: '/feed',
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    await settle(tester);
    repo.body = null; // offline from now on
    final older = find.byKey(const Key('feed-show-older'));
    await tester.ensureVisible(older);
    await tester.tap(older);
    await settle(tester);
    expect(find.text('Title g1'), findsOneWidget);
    expect(find.byKey(const Key('feed-show-older-failed')), findsOneWidget);
    expect(find.byKey(const Key('feed-show-older')), findsOneWidget);
    await unmountApp(tester);
  });

  test('a page keeps its cursor through the phone cache', () {
    final page = FeedPage.fromJson(
      _page([], nextBefore: '2026-10-01T06:00:00Z', nextId: 'k1'),
    );
    final again = FeedPage.fromJson(page.toJson());
    expect(again.next?.beforeId, 'k1');
    expect(again.next?.before, DateTime.utc(2026, 10, 1, 6));
    expect(FeedPage.fromJson(feedBody([])).next, isNull);
  });
}
