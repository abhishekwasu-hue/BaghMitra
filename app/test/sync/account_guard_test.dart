import 'dart:io';

// Q36: one phone, two accounts. The phone remembers whose records it holds; another account
// gets a warning, is blocked while the first account still has unsent writes, and otherwise
// starts from a clean phone and a fresh pull.
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/auth/domain/auth.dart';
import 'package:bagmitra/features/walkthrough/data/walkthrough_flag.dart';
import 'package:bagmitra/sync/account_guard.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';
import '../helpers/test_db.dart';

const first = AuthSession(
  userId: 'u1',
  phone: '+919800000000',
  accessToken: 't1',
);
const second = AuthSession(
  userId: 'u2',
  phone: '+919811111111',
  accessToken: 't2',
);

/// A phone that holds [first]'s records: a plot, a pull cursor, the walkthrough flag and,
/// unless [sent], the plot's write still waiting in the outbox.
Future<void> seedFirstAccount(AppDatabase db, {required bool sent}) async {
  await AccountGuard(db).claim(first);
  await seedPlot(db);
  if (sent) await db.delete(db.outboxEntries).go();
  await db.writeMeta(SyncEngine.cursorKey, '42');
  await db.writeMeta('feed.receipts', '{}');
  await WalkthroughFlag(db).markSeen();
}

void main() {
  late AppDatabase db;
  late AccountGuard guard;

  setUp(() {
    db = memoryDb();
    guard = AccountGuard(db);
  });
  tearDown(() => db.close());

  test('a phone with no owner yet is taken by whoever signs in', () async {
    await seedPlot(db);
    expect(await guard.check(second.userId), AccountCheck.same);
    await guard.claim(second);
    expect(await db.readMeta(AccountGuard.ownerKey), 'u2');
    expect(await db.select(db.plots).get(), hasLength(1));
  });

  test('the same account signing in again keeps its records', () async {
    await seedFirstAccount(db, sent: false);
    expect(await guard.check(first.userId), AccountCheck.same);
    await guard.claim(first);
    expect(await db.select(db.plots).get(), hasLength(1));
    expect(await db.select(db.outboxEntries).get(), hasLength(1));
    expect(await db.readMeta(SyncEngine.cursorKey), '42');
  });

  test('another account with nothing unsent gets a clean phone', () async {
    await seedFirstAccount(db, sent: true);
    expect(await guard.check(second.userId), AccountCheck.switchable);
    expect(await guard.ownerPhone(), first.phone);

    await guard.switchTo(second);

    expect(await db.select(db.plots).get(), isEmpty);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
    expect(
      await db.readMeta(SyncEngine.cursorKey),
      isNull,
      reason: 'the next sync pulls from the start',
    );
    expect(await db.readMeta('feed.receipts'), isNull);
    expect(await db.readMeta(AccountGuard.ownerKey), 'u2');
    expect(await guard.ownerPhone(), second.phone);
    expect(await WalkthroughFlag(db).seen(), isTrue, reason: 'phone-level');
    expect(await guard.check(second.userId), AccountCheck.same);
  });

  test('another account is blocked while writes are unsent', () async {
    await seedFirstAccount(db, sent: false);
    expect(await guard.check(second.userId), AccountCheck.blocked);
    expect(await guard.unsentCount(), 1);
    await expectLater(guard.switchTo(second), throwsStateError);
    expect(await db.select(db.plots).get(), hasLength(1));
    expect(await db.readMeta(AccountGuard.ownerKey), 'u1');
    expect(await db.readMeta(SyncEngine.cursorKey), '42');
  });

  test('a switch deletes the previous account\'s photo files', () async {
    final docs = await Directory.systemTemp.createTemp('bm_docs');
    addTearDown(() => docs.delete(recursive: true));
    final photos = Directory('${docs.path}/scouting_photos')..createSync();
    final claims = Directory('${docs.path}/claim_photos')..createSync();
    File('${photos.path}/r1.jpg').writeAsStringSync('x');
    File('${claims.path}/c1.jpg').writeAsStringSync('x');
    final keep = File('${docs.path}/other.txt')..writeAsStringSync('x');
    await seedFirstAccount(db, sent: true);

    await AccountGuard(
      db,
      deletePhotos: AccountGuard.photoFolderDeleter(() async => docs),
    ).switchTo(second);

    expect(photos.existsSync(), isFalse);
    expect(claims.existsSync(), isFalse);
    expect(keep.existsSync(), isTrue, reason: 'only the photo folders go');
  });

  test('a blocked switch keeps the photo files', () async {
    final docs = await Directory.systemTemp.createTemp('bm_docs');
    addTearDown(() => docs.delete(recursive: true));
    final photos = Directory('${docs.path}/scouting_photos')..createSync();
    await seedFirstAccount(db, sent: false);

    await expectLater(
      AccountGuard(
        db,
        deletePhotos: AccountGuard.photoFolderDeleter(() async => docs),
      ).switchTo(second),
      throwsStateError,
    );
    expect(photos.existsSync(), isTrue);
  });

  group('sign-in on the phone', () {
    testWidgets('the same account goes straight in, records kept', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        session: first,
        initialLocation: '/plots',
        seed: (db) => seedFirstAccount(db, sent: false),
      );
      await settle(tester);
      expect(find.byKey(const Key('account-switch')), findsNothing);
      expect(find.text('बाग १'), findsOneWidget);
      expect(
        await tester.runAsync(() => db.select(db.plots).get()),
        hasLength(1),
      );
      await unmountApp(tester);
    });

    testWidgets('another account is warned, then starts clean', (tester) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        session: second,
        initialLocation: '/plots',
        seed: (db) => seedFirstAccount(db, sent: true),
      );
      await settle(tester);
      expect(find.byKey(const Key('account-switch')), findsOneWidget);
      expect(find.text("Another account's records"), findsOneWidget);
      expect(find.text('बाग १'), findsNothing, reason: 'nothing of u1 shows');

      await tester.tap(find.byKey(const Key('account-switch-continue')));
      await settle(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
      expect(find.byKey(const Key('account-switch')), findsNothing);
      expect(await tester.runAsync(() => db.select(db.plots).get()), isEmpty);
      expect(
        await tester.runAsync(() => db.readMeta(AccountGuard.ownerKey)),
        'u2',
      );
      await unmountApp(tester);
    });

    testWidgets('another account is blocked while writes are unsent', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        session: second,
        initialLocation: '/plots',
        seed: (db) => seedFirstAccount(db, sent: false),
      );
      await settle(tester);
      expect(find.byKey(const Key('account-blocked')), findsOneWidget);
      expect(find.textContaining('1 record of the previous'), findsOneWidget);
      expect(
        find.textContaining('Previous account: +919800000000'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('account-switch-continue')), findsNothing);

      await tester.tap(find.byKey(const Key('account-switch-sign-out')));
      await settle(tester);
      expect(find.byKey(const Key('account-blocked')), findsNothing);
      expect(
        await tester.runAsync(() => db.select(db.plots).get()),
        hasLength(1),
        reason: "u1's unsent records stay",
      );
      await unmountApp(tester);
    });
  });
}
