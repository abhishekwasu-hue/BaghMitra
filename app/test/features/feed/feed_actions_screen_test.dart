import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/data/feed_preferences_store.dart';
import 'package:bagmitra/features/feed/data/feed_receipts.dart';
import 'package:bagmitra/features/feed/data/feed_repository.dart';
import 'package:bagmitra/features/feed/domain/feed_check.dart';
import 'package:bagmitra/features/feed/domain/feed_preferences.dart';
import 'package:bagmitra/features/feed/presentation/feed_check_screen.dart';
import 'package:bagmitra/features/feed/presentation/feed_preferences_screen.dart';
import 'package:bagmitra/features/feed/presentation/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_data_test.dart';
import 'feed_screen_test.dart' show en, sampleFeed;

/// The sample feed with `news1` already seen on the server.
Map<String, Object?> get _feedWithSeen => {
  ...sampleFeed,
  'items': [
    for (final i in sampleFeed['items']! as List)
      if ((i as Map)['id'] == 'news1') {...i, 'seen': true} else i,
  ],
};

/// Opens [location] with the feed cache seeded and [repo] as the server.
Future<AppDatabase> _pump(
  WidgetTester tester,
  FakeFeedRepository repo, {
  String location = '/feed',
  Locale locale = const Locale('en'),
}) async {
  final db = await pumpApp(
    tester,
    locale: locale,
    initialLocation: location,
    seed: (db) => db.writeMeta(
      FeedCache.keyFor(locale.languageCode),
      jsonEncode({
        'saved_at': '2026-10-12T06:00:00.000Z',
        'page': _feedWithSeen,
      }),
    ),
    overrides: [feedRepositoryProvider.overrideWithValue(repo)],
  );
  await settle(tester);
  return db;
}

Future<FeedReceiptState> _receipts(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(
      () => FeedReceipts(db, repository: FakeFeedRepository(null)).load(),
    ))!;

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
}

/// Captures what the app puts on (and serves from) the clipboard.
String? Function() _mockClipboard(WidgetTester tester, {String? paste}) {
  String? copied;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      if (call.method == 'Clipboard.getData') return {'text': paste};
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return () => copied;
}

void main() {
  testWidgets('unseen dot; opening marks seen offline, sent on the next '
      'open', (tester) async {
    final repo = FakeFeedRepository(null);
    final db = await _pump(tester, repo);
    expect(find.byKey(const Key('feed-unseen-gr1')), findsOneWidget);
    expect(find.byKey(const Key('feed-unseen-old')), findsOneWidget);
    expect(
      find.byKey(const Key('feed-unseen-news1')),
      findsNothing,
      reason: 'the server says it was seen',
    );

    await tester.tap(find.text('Title gr1'));
    await settle(tester);
    await _back(tester);
    expect(find.byKey(const Key('feed-unseen-gr1')), findsNothing);
    expect((await _receipts(tester, db)).pending, [
      ('gr1', FeedReceiptAction.seen),
    ]);
    expect(repo.receipts, isEmpty);

    // Opening an item the server already knows is seen sends nothing.
    await tester.tap(find.text('Title news1'));
    await settle(tester);
    await _back(tester);
    expect((await _receipts(tester, db)).pending, hasLength(1));

    // Back online: the next open of the feed sends the queue.
    repo.body = _feedWithSeen;
    ProviderScope.containerOf(tester.element(find.byType(FeedScreen)))
        .invalidate(feedProvider('en'));
    await settle(tester);
    expect(repo.receipts, [('gr1', FeedReceiptAction.seen)]);
    expect((await _receipts(tester, db)).pending, isEmpty);
    expect(find.byKey(const Key('feed-unseen-gr1')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('dismiss hides the item and tells the server', (tester) async {
    final repo = FakeFeedRepository(_feedWithSeen);
    await _pump(tester, repo);
    await tester.tap(find.text('Title old'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('feed-dismiss')));
    await settle(tester);
    expect(find.byType(FeedScreen), findsOneWidget);
    expect(find.text('Title old'), findsNothing);
    expect(find.text('Title gr1'), findsOneWidget);
    expect(find.text('Hidden from your list.'), findsOneWidget);
    expect(repo.receipts, [
      ('old', FeedReceiptAction.seen),
      ('old', FeedReceiptAction.dismiss),
    ]);
    // Hidden under every filter, too.
    await tester.tap(find.byKey(const Key('feed-filter-official')));
    await settle(tester);
    expect(find.text('Title old'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('remind me keeps the local task and calls /remind', (
    tester,
  ) async {
    final repo = FakeFeedRepository(_feedWithSeen);
    await _pump(tester, repo, location: '/feed/gr1');
    await tester.tap(find.byKey(const Key('feed-remind')));
    await settle(tester);
    expect(find.byKey(const Key('feed-reminded')), findsOneWidget);
    expect(repo.receipts, contains(('gr1', FeedReceiptAction.remind)));
    await unmountApp(tester);
  });

  testWidgets('app bar opens the check and settings screens', (tester) async {
    await _pump(tester, FakeFeedRepository(null));
    await tester.tap(find.byKey(const Key('feed-open-check')));
    await settle(tester);
    expect(find.byType(FeedCheckScreen), findsOneWidget);
    await _back(tester);
    await tester.tap(find.byKey(const Key('feed-open-settings')));
    await settle(tester);
    expect(find.byType(FeedPreferencesScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('settings: loads from the server, edits and saves with PUT', (
    tester,
  ) async {
    final repo = FakeFeedRepository(_feedWithSeen);
    final db = await _pump(tester, repo, location: '/feed-settings');
    expect(find.byKey(const Key('feed-prefs-offline')), findsNothing);
    expect(find.text('10:00 PM'), findsOneWidget);
    expect(find.text('6:30 AM'), findsOneWidget);
    expect(find.text('At most 5 alerts a week'), findsOneWidget);
    bool on(String key) =>
        tester.widget<SwitchListTile>(find.byKey(Key(key))).value;
    expect(on('feed-prefs-cat-deadline'), isTrue);
    expect(on('feed-prefs-cat-payment'), isFalse);
    expect(on('feed-prefs-digest'), isFalse);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('feed-prefs-cap-more')));
      await tester.pump();
    }
    expect(find.text('At most 7 alerts a week'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('feed-prefs-cap-more')))
          .onPressed,
      isNull,
    );
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const Key('feed-prefs-cap-less')));
      await tester.pump();
    }
    expect(find.text('At most 1 alerts a week'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feed-prefs-cap-more')));
    await tester.pump();

    // Quiet start: the time picker, typed in.
    await tester.tap(find.byKey(const Key('feed-prefs-quiet-start')));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await settle(tester);
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '11');
    await tester.enterText(fields.at(1), '15');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.text('11:15 PM'), findsOneWidget);
    // Quiet end: opened and cancelled keeps the value.
    await tester.tap(find.byKey(const Key('feed-prefs-quiet-end')));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('6:30 AM'), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-prefs-cat-deadline')));
    await tester.tap(find.byKey(const Key('feed-prefs-cat-payment')));
    await tester.pump();
    final digest = find.byKey(const Key('feed-prefs-digest'));
    await tester.ensureVisible(digest);
    await tester.tap(digest);
    await tester.pump();
    final save = find.byKey(const Key('feed-prefs-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(repo.savedPrefs.single.toJson(), {
      'quiet_start': '23:15',
      'quiet_end': '06:30',
      'weekly_cap': 2,
      'opted_out': ['deadline'],
      'digest_weekly': true,
    });
    expect(find.text('Settings saved.'), findsOneWidget);
    final kept = await tester.runAsync(
      () => db.readMeta(FeedPreferencesStore.key),
    );
    expect(jsonDecode(kept!), repo.savedPrefs.single.toJson());
    await unmountApp(tester);
  });

  testWidgets('settings offline: last saved values, a note, no saving', (
    tester,
  ) async {
    await _pump(tester, FakeFeedRepository(null), location: '/feed-settings');
    // Never loaded: the server defaults.
    expect(find.byKey(const Key('feed-prefs-offline')), findsOneWidget);
    expect(find.textContaining('Saving needs internet'), findsOneWidget);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(find.text('At most 3 alerts a week'), findsOneWidget);
    final save = find.byKey(const Key('feed-prefs-save'));
    await tester.ensureVisible(save);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await unmountApp(tester);
  });

  testWidgets('settings offline with a saved copy shows that copy', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/feed-settings',
      seed: (db) => db.writeMeta(
        FeedPreferencesStore.key,
        jsonEncode(
          const FeedPreferences(quietStart: '20:00', weeklyCap: 6).toJson(),
        ),
      ),
      overrides: [
        feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
      ],
    );
    await settle(tester);
    expect(find.text('8:00 PM'), findsOneWidget);
    expect(find.text('At most 6 alerts a week'), findsOneWidget);
    expect(find.byKey(const Key('feed-prefs-offline')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('settings: a failed save says so', (tester) async {
    final repo = FakeFeedRepository(_feedWithSeen);
    await _pump(tester, repo, location: '/feed-settings');
    repo.body = null; // the network drops after loading
    final save = find.byKey(const Key('feed-prefs-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(find.text('Could not save. Try again when online.'), findsOneWidget);
    expect(repo.savedPrefs, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('check: official match lists GR no, date and copies the link; '
      'the text is not stored', (tester) async {
    final copied = _mockClipboard(tester, paste: 'GR-101 drip anudan');
    final repo = FakeFeedRepository(_feedWithSeen)
      ..checkResult = FeedCheckResult(
        verdict: FeedCheckVerdict.officialMatch,
        matches: [
          FeedCheckMatch(
            id: 'gr1',
            title: 'Drip subsidy GR',
            grNumber: 'GR-101',
            publishedAt: DateTime.utc(2026, 10, 12, 6),
            url: 'https://example.org/gr1',
          ),
        ],
      );
    final db = await _pump(tester, repo, location: '/feed-check');
    final go = find.byKey(const Key('feed-check-go'));
    expect(tester.widget<FilledButton>(go).onPressed, isNull);
    expect(find.text('The text is not saved on your phone.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-check-paste')));
    await settle(tester);
    expect(find.text('GR-101 drip anudan'), findsOneWidget);
    await tester.tap(go);
    await settle(tester);
    expect(repo.checked, ['GR-101 drip anudan']);
    expect(
      find.byKey(const Key('feed-check-result-official_match')),
      findsOneWidget,
    );
    expect(find.text('Official GR found'), findsOneWidget);
    expect(find.text('Drip subsidy GR'), findsOneWidget);
    expect(
      find.text('GR GR-101 · ${en(DateTime(2026, 10, 12))}'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('feed-check-portal')), findsNothing);
    final copy = find.byKey(const Key('feed-check-copy-gr1'));
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await settle(tester);
    expect(copied(), 'https://example.org/gr1');
    expect(find.textContaining('Link copied'), findsOneWidget);

    final rows = (await tester.runAsync(() => db.select(db.syncMeta).get()))!;
    expect(
      rows.where((r) => r.value.contains('drip anudan')),
      isEmpty,
      reason: 'the pasted text never reaches the phone database',
    );
    await unmountApp(tester);
  });

  testWidgets('check: possible match, no match and offline answers', (
    tester,
  ) async {
    final repo = FakeFeedRepository(_feedWithSeen)
      ..checkResult = const FeedCheckResult(
        verdict: FeedCheckVerdict.possibleMatch,
        matches: [
          FeedCheckMatch(
            id: 's1',
            title: 'Orchard scheme',
            url: 'https://example.org/s1',
          ),
        ],
        note: 'Similar wording.',
      );
    await _pump(tester, repo, location: '/feed-check');
    await tester.enterText(
      find.byKey(const Key('feed-check-text')),
      'Scheme message',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('feed-check-go')));
    await settle(tester);
    expect(find.text('Possibly related official items'), findsOneWidget);
    expect(find.text('Orchard scheme'), findsOneWidget);
    expect(find.text('Similar wording.'), findsOneWidget);
    expect(
      find.text('Check the official portal before acting.'),
      findsOneWidget,
    );

    repo.checkResult = const FeedCheckResult(
      verdict: FeedCheckVerdict.noOfficialMatch,
      note: 'No official item in the feed matches this text.',
    );
    await tester.tap(find.byKey(const Key('feed-check-go')));
    await settle(tester);
    expect(
      find.byKey(const Key('feed-check-result-no_official_match')),
      findsOneWidget,
    );
    expect(
      find.text('No official item in the feed matches this text.'),
      findsOneWidget,
    );
    expect(
      find.text('Check the official portal before acting.'),
      findsOneWidget,
    );
    expect(
      find.textContaining(RegExp('fake', caseSensitive: false)),
      findsNothing,
    );

    repo.checkResult = const FeedCheckResult(
      verdict: FeedCheckVerdict.noOfficialMatch,
    );
    await tester.tap(find.byKey(const Key('feed-check-go')));
    await settle(tester);
    expect(find.text('No matching official item was found.'), findsOneWidget);

    repo.body = null;
    await tester.tap(find.byKey(const Key('feed-check-go')));
    await settle(tester);
    expect(find.byKey(const Key('feed-check-failed')), findsOneWidget);
    expect(find.text('Could not check. This needs internet.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Marathi demo: check finds the sample GR; settings and check '
      'open from the feed', (tester) async {
    await pumpApp(tester, initialLocation: '/feed-check');
    await settle(tester);
    expect(find.text('संदेश तपासा'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('feed-check-text')),
      'हा SAMPLE-0001 GR पाहा',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('feed-check-go')));
    await settle(tester);
    expect(find.text('अधिकृत GR सापडला'), findsOneWidget);
    expect(find.textContaining('नमुना GR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);

    await pumpApp(tester, initialLocation: '/feed-settings');
    await settle(tester);
    expect(find.text('सूचना सेटिंग'), findsOneWidget);
    expect(find.text('आठवड्यात जास्तीत जास्त 3 सूचना'), findsOneWidget);
    expect(find.byKey(const Key('feed-prefs-offline')), findsNothing);
    await unmountApp(tester);
  });
}
