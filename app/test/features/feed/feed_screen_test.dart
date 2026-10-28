import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/core/formatting.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/data/text_sharer.dart';
import 'package:bagmitra/features/feed/presentation/feed_screen.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_data_test.dart';

class RecordingTextSharer implements TextSharer {
  final shared = <String>[];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}

// pumpApp's clock is 2026-10-13 06:00 UTC.
final sampleFeed = feedBody([
  feedJson(
    'gr1',
    grNumber: 'GR-2026-101',
    publishedAt: '2026-10-12T06:00:00Z',
    deadline: '2026-10-30',
    eligible: ['you grow oranges'],
  ),
  feedJson(
    'old',
    type: 'circular',
    grNumber: 'CIR-7',
    publishedAt: '2026-10-01T06:00:00Z',
    replacedBy: 'GR-2026-101',
    eligible: ['should not show'],
  ),
  feedJson(
    'expired',
    type: 'scheme',
    grNumber: null,
    publishedAt: '2026-09-01T06:00:00Z',
    validTo: '2026-10-01',
    eligible: ['expired reason'],
  ),
  feedJson(
    'news1',
    type: 'news',
    trust: 'news',
    grNumber: null,
    department: null,
    publishedAt: '2026-10-11T06:00:00Z',
  ),
]);

Future<void> seedFeed(AppDatabase db, {String lang = 'en'}) => db.writeMeta(
  FeedCache.keyFor(lang),
  jsonEncode({'saved_at': '2026-10-12T06:00:00.000Z', 'page': sampleFeed}),
);

/// Opens the feed with the cache seeded and the network down (so what shows is the cache).
Future<(AppDatabase, FakeFeedRepository, RecordingTextSharer)> pumpFeed(
  WidgetTester tester, {
  String location = '/feed',
  Locale locale = const Locale('en'),
}) async {
  final repo = FakeFeedRepository(null);
  final sharer = RecordingTextSharer();
  final db = await pumpApp(
    tester,
    locale: locale,
    initialLocation: location,
    seed: (db) => seedFeed(db, lang: locale.languageCode),
    overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      textSharerProvider.overrideWithValue(sharer),
    ],
  );
  await settle(tester);
  return (db, repo, sharer);
}

String en(DateTime d) => formatDate(d, 'en');

void main() {
  testWidgets('offline: cached items, badges, banners, eligibility, footer', (
    tester,
  ) async {
    final (_, repo, _) = await pumpFeed(tester);
    expect(repo.calls, contains('en'), reason: 'a refresh was tried');
    expect(find.text('Sarkari Sandesh'), findsOneWidget);
    expect(find.text('Title gr1'), findsOneWidget);
    expect(find.text('Title news1'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);

    expect(
      find.text(
        'Official · GR GR-2026-101 · ${en(DateTime(2026, 10, 12))} · '
        'Agriculture Dept',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'News — check the official source · ${en(DateTime(2026, 10, 11))}',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('feed-replaced-old')), findsOneWidget);
    expect(find.text('Withdrawn. Replaced by GR-2026-101'), findsOneWidget);
    expect(find.byKey(const Key('feed-expired-expired')), findsOneWidget);
    expect(
      find.text('You may be eligible because you grow oranges'),
      findsOneWidget,
    );
    // Never offered as available once withdrawn or expired (spec §6).
    expect(find.textContaining('should not show'), findsNothing);
    expect(find.textContaining('expired reason'), findsNothing);
    expect(
      find.text('Last date: ${en(DateTime(2026, 10, 30))}'),
      findsOneWidget,
    );
    expect(
      find.text('Check the official GR/portal before acting.'),
      findsOneWidget,
    );

    // Newest first.
    final y1 = tester.getTopLeft(find.text('Title gr1')).dy;
    final y2 = tester.getTopLeft(find.text('Title news1')).dy;
    final y3 = tester.getTopLeft(find.text('Title old')).dy;
    expect(y1 < y2 && y2 < y3, isTrue);
    await unmountApp(tester);
  });

  testWidgets('filter chips narrow the list; footer stays', (tester) async {
    await pumpFeed(tester);
    Future<void> chip(String v) async {
      await tester.tap(find.byKey(Key('feed-filter-$v')));
      await settle(tester);
    }

    await chip('news');
    expect(find.text('Title news1'), findsOneWidget);
    expect(find.text('Title gr1'), findsNothing);
    await chip('scheme');
    expect(find.text('Title expired'), findsOneWidget);
    expect(find.text('Title news1'), findsNothing);
    await chip('deadline');
    expect(find.text('Title gr1'), findsOneWidget);
    expect(find.text('Title old'), findsNothing);
    await chip('official');
    expect(find.text('Title gr1'), findsOneWidget);
    expect(find.text('Title old'), findsOneWidget);
    expect(find.text('Title news1'), findsNothing);
    await chip('all');
    expect(find.text('Title news1'), findsOneWidget);
    expect(find.byKey(const Key('feed-footer')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('remind me makes one task due on the last date', (tester) async {
    final (db, _, _) = await pumpFeed(tester);
    await tester.tap(find.text('Title gr1'));
    await settle(tester);
    expect(find.text('Summary gr1'), findsOneWidget);
    expect(find.text('Source: https://example.org/gr1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feed-remind')));
    await settle(tester);
    final tasks = (await tester.runAsync(
      () => TasksRepository(db).watchAll().first,
    ))!;
    final task = tasks.single;
    expect(task.title, 'Title gr1');
    expect(task.dueOn, DateTime(2026, 10, 30));
    expect(task.kind, 'other');
    expect(task.plotId, isNull);
    expect(task.source, 'feed:gr1');
    expect(task.note, 'https://example.org/gr1');
    expect(find.textContaining('Added to your tasks'), findsOneWidget);
    // Once added, the button gives way to a note so it is not added twice.
    expect(find.byKey(const Key('feed-remind')), findsNothing);
    expect(find.byKey(const Key('feed-reminded')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('no remind button without a live deadline', (tester) async {
    await pumpFeed(tester, location: '/feed/old');
    expect(find.text('Withdrawn. Replaced by GR-2026-101'), findsOneWidget);
    expect(find.byKey(const Key('feed-remind')), findsNothing);
    expect(find.byKey(const Key('feed-share')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('share hands on short text with the source link', (tester) async {
    final (_, _, sharer) = await pumpFeed(tester, location: '/feed/gr1');
    await tester.tap(find.byKey(const Key('feed-share')));
    await settle(tester);
    expect(sharer.shared, [
      'Title gr1\n'
          'Official · GR GR-2026-101 · ${en(DateTime(2026, 10, 12))} · '
          'Agriculture Dept\n'
          'Last date: ${en(DateTime(2026, 10, 30))}\n'
          'Source: https://example.org/gr1\n'
          'Check the official GR/portal before acting.',
    ]);
    await unmountApp(tester);
  });

  testWidgets('copy link puts the source url on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpFeed(tester, location: '/feed/news1');
    expect(
      find.text(
        'News — check the official source · ${en(DateTime(2026, 10, 11))}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('feed-copy-link')));
    await settle(tester);
    expect(copied, 'https://example.org/news1');
    expect(find.textContaining('Link copied'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an item missing from the cache says so', (tester) async {
    await pumpFeed(tester, location: '/feed/gone');
    expect(
      find.text('This message was removed from the saved list.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('Marathi: demo feed renders with Marathi labels and footer', (
    tester,
  ) async {
    // Demo mode (testConfig): the built-in sample feed, no network needed.
    await pumpApp(tester, initialLocation: '/feed');
    await settle(tester);
    expect(find.text('सरकारी संदेश'), findsOneWidget);
    expect(find.text('काही करण्याआधी अधिकृत GR/पोर्टल तपासा.'), findsOneWidget);
    expect(find.textContaining('नमुना GR'), findsOneWidget);
    expect(find.textContaining('अधिकृत · GR क्र.'), findsWidgets);
    expect(
      find.textContaining('बातमी — अधिकृत स्रोतावर खात्री करा'),
      findsOneWidget,
    );
    expect(find.textContaining('मागे घेतले'), findsOneWidget);
    expect(find.textContaining('तुम्ही पात्र असू शकता कारण'), findsWidgets);
    expect(find.text('शेवटच्या तारखा'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('home tile opens the feed when the flag is on', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));
    await settle(tester);
    final tile = find.byKey(const Key('open-feed'));
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await settle(tester);
    expect(find.byType(FeedScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('flag off: no home tile and /feed goes home', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/feed',
      config: const AppConfig(
        productName: 'BagMitra',
        apiBaseUrl: 'http://localhost:8000',
        supabaseUrl: '',
        supabaseAnonKey: '',
        devGallery: true,
        testBuild: '',
        speechEngine: 'on_device',
        sarkariSandesh: 'off',
      ),
    );
    await settle(tester);
    expect(find.byType(FeedScreen), findsNothing);
    expect(find.byKey(const Key('open-feed')), findsNothing);
    await unmountApp(tester);
  });
}
