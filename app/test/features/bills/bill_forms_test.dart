import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/data/accounts_repository.dart';
import 'package:bagmitra/features/bills/data/bill_read_api.dart';
import 'package:bagmitra/features/photo_analysis/data/photo_analysis_api.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../photo_analysis/photo_analysis_test.dart' show fakeJpeg, json;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show FakePhotos;
import 'bill_photo_records_test.dart' show expense, spray;
import 'bill_read_test.dart';

/// A phone tall enough to show every field of the forms at once.
const tall = Size(393, 1700);

List<Override> billOverrides(FakeBillServer server, FakePhotos photos) => [
  billReadApiProvider.overrideWithValue(server.api),
  billPhotosProvider.overrideWithValue(photos),
  photoPreparerProvider.overrideWithValue((_) async => fakeJpeg),
];

Future<AppDatabase> openForm(
  WidgetTester tester,
  String location, {
  FakeBillServer? server,
  FakePhotos? photos,
  SyncStatus? syncStatus,
}) async {
  final db = await pumpApp(
    tester,
    locale: const Locale('en'),
    initialLocation: location,
    seed: seedPlot,
    size: tall,
    syncStatus: syncStatus,
    overrides: billOverrides(
      server ?? FakeBillServer((_) async => json(billJson(), 200)),
      photos ?? FakePhotos(),
    ),
  );
  await settle(tester);
  return db;
}

Future<void> attach(WidgetTester tester, {bool gallery = false}) async {
  await tester.tap(
    find.byKey(Key(gallery ? 'bill-photo-gallery' : 'bill-photo-camera')),
  );
  await settle(tester);
}

Future<void> fillFromBill(WidgetTester tester, {String? pick}) async {
  await tester.tap(find.byKey(const Key('bill-fill')));
  await settle(tester);
  if (pick != null) {
    await tester.tap(find.byKey(Key(pick)));
    await settle(tester);
  }
}

String field(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<Map<String, Object?>> lastPayload(AppDatabase db, String entity) async {
  final rows = await (db.select(
    db.outboxEntries,
  )..where((t) => t.entity.equals(entity))).get();
  return jsonDecode(rows.last.payload) as Map<String, Object?>;
}

void main() {
  const sprayForm = '/plots/p1/sprays/new';
  const expenseForm = '/plots/p1/accounts/expense';

  group('spray record', () {
    testWidgets('a bill photo is attached, removed, and kept with the record', (
      tester,
    ) async {
      final photos = FakePhotos();
      final db = await openForm(tester, sprayForm, photos: photos);
      expect(find.text('Bill photo'), findsOneWidget);
      expect(find.byKey(const Key('bill-fill')), findsNothing);

      await attach(tester);
      expect(find.byKey(const Key('bill-photo-thumb')), findsOneWidget);
      expect(find.byKey(const Key('bill-fill')), findsOneWidget);
      expect(find.byKey(const Key('bill-note-offline')), findsNothing);
      await tester.tap(find.byKey(const Key('bill-photo-remove')));
      await settle(tester);
      expect(find.byKey(const Key('bill-photo-thumb')), findsNothing);

      await attach(tester, gallery: true);
      await tester.enterText(find.byKey(const Key('spray-product')), 'Imida');
      await tester.tap(find.text('Save'));
      await settle(tester);

      final row = await db.select(db.sprayRecords).getSingle();
      expect(row.billPhotoPath, '/docs/scouting_photos/${row.id}.jpg');
      expect(photos.kept, {'/tmp/picked.jpg': row.billPhotoPath});
      final payload = await lastPayload(db, SprayRepository.entity);
      expect(payload.containsKey('bill_photo_key'), isFalse);
      expect(jsonEncode(payload), isNot(contains('/docs/')));
      await unmountApp(tester);
    });

    testWidgets('a photo that cannot be kept saves nothing', (tester) async {
      final db = await openForm(
        tester,
        sprayForm,
        photos: FakePhotos(keepFails: true),
      );
      await attach(tester);
      await tester.enterText(find.byKey(const Key('spray-product')), 'Imida');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(await db.select(db.sprayRecords).get(), isEmpty);
      expect(find.text('Please take the photo again.'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('fill from bill fills only empty fields and says which', (
      tester,
    ) async {
      final server = FakeBillServer((_) async => json(billJson(), 200));
      final db = await openForm(tester, sprayForm, server: server);
      await tester.enterText(
        find.byKey(const Key('spray-product')),
        'Confidor',
      );
      await attach(tester);
      await fillFromBill(tester);
      expect(find.byKey(const Key('bill-pick-sheet')), findsOneWidget);
      expect(find.text('Imida 17.8 SL'), findsOneWidget);
      expect(find.text('₹650'), findsOneWidget);
      expect(find.byKey(const Key('bill-pick-total')), findsNothing);
      await tester.tap(find.byKey(const Key('bill-pick-0')));
      await settle(tester);

      expect(field(tester, 'spray-product'), 'Confidor'); // typed: kept
      // The filled active ingredient selects its entry in the picker (Q137).
      expect(find.byKey(const Key('spray-active')), findsNothing);
      expect(find.text('Insecticide'), findsOneWidget);
      expect(find.text('Imidacloprid 17.80% SL'), findsOneWidget);
      expect(field(tester, 'spray-dose'), '500 ml');
      expect(field(tester, 'spray-cost'), '650');
      expect(find.text('10 Oct 2026'), findsOneWidget);
      expect(
        find.text(
          'Filled from the bill: active ingredient, quantity, cost, date. '
          'Please check once.',
        ),
        findsOneWidget,
      );
      expect(server.requests.single.url.path, '/v1/bills/read');

      // A second pick changes nothing that is now filled.
      await fillFromBill(tester, pick: 'bill-pick-1');
      expect(field(tester, 'spray-dose'), '500 ml');
      expect(find.byKey(const Key('bill-note-nothingFilled')), findsOneWidget);

      await tester.tap(find.text('Save'));
      await settle(tester);
      final payload = await lastPayload(db, SprayRepository.entity);
      expect(payload['product_name'], 'Confidor');
      expect(payload['sprayed_on'], '2026-10-10');
      expect(payload['cost_paise'], 65000);
      expect(payload['active_ingredient'], 'Imidacloprid');
      await unmountApp(tester);
    });

    testWidgets('a bill ingredient outside our list shows under Other', (
      tester,
    ) async {
      final server = FakeBillServer(
        (_) async => json(
          billJson(
            items: const [
              {
                'name': 'Aliette',
                'active_ingredient': 'fosetyl-aluminium',
                'quantity': 1,
                'unit': 'kg',
                'amount_rs': 900,
              },
            ],
          ),
          200,
        ),
      );
      final db = await openForm(tester, sprayForm, server: server);
      await attach(tester);
      await fillFromBill(tester, pick: 'bill-pick-0');
      expect(find.text('Other'), findsOneWidget);
      expect(field(tester, 'spray-active'), 'fosetyl-aluminium');
      await tester.tap(find.text('Save'));
      await settle(tester);
      final payload = await lastPayload(db, SprayRepository.entity);
      expect(payload['active_ingredient'], 'fosetyl-aluminium');
      await unmountApp(tester);
    });

    testWidgets('an unsure bill says so calmly', (tester) async {
      final server = FakeBillServer(
        (_) async => json(billJson(unsure: true, items: const []), 200),
      );
      await openForm(tester, sprayForm, server: server);
      await attach(tester);
      await fillFromBill(tester);
      expect(find.byKey(const Key('bill-pick-sheet')), findsNothing);
      expect(
        find.text(
          'Could not read the bill clearly; fill in the details by hand.',
        ),
        findsOneWidget,
      );
      expect(field(tester, 'spray-product'), isEmpty);

      // Unsure with lines: the sheet shows the same line, and the form keeps it.
      server.answer = (_) async => json(billJson(unsure: true), 200);
      await fillFromBill(tester, pick: 'bill-pick-0');
      expect(find.byKey(const Key('bill-note-unsure')), findsOneWidget);
      expect(find.byKey(const Key('bill-note-filled')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the limit is a calm line, nothing filled', (tester) async {
      final server = FakeBillServer(
        (_) async =>
            json(billLimitJson('daily', resets: '2026-10-14T00:00:00Z'), 429),
      );
      await openForm(tester, sprayForm, server: server);
      await attach(tester);
      await fillFromBill(tester);
      expect(
        find.text(
          "Today's 5 bill readings are used; you can read again "
          'tomorrow.',
        ),
        findsOneWidget,
      );
      expect(field(tester, 'spray-product'), isEmpty);
      await unmountApp(tester);
    });

    testWidgets('offline: no reading offered, the photo is still saved', (
      tester,
    ) async {
      final server = FakeBillServer((_) async => json(billJson(), 200));
      final db = await openForm(
        tester,
        sprayForm,
        server: server,
        syncStatus: const SyncStatus(connectivity: Connectivity.offline),
      );
      await attach(tester);
      expect(find.byKey(const Key('bill-fill')), findsNothing);
      expect(
        find.text(
          'Reading the bill needs internet. The photo is saved with this '
          'record on the phone.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('will be sent'), findsNothing);
      await tester.enterText(find.byKey(const Key('spray-product')), 'Imida');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(
        (await db.select(db.sprayRecords).getSingle()).billPhotoPath,
        isNotNull,
      );
      expect(server.requests, isEmpty);
      await unmountApp(tester);
    });

    testWidgets('no network during the call: the same calm line', (
      tester,
    ) async {
      final server = FakeBillServer(
        (_) async => throw const SocketException('no route'),
      );
      await openForm(tester, sprayForm, server: server);
      await attach(tester);
      await fillFromBill(tester);
      expect(find.byKey(const Key('bill-note-offline')), findsOneWidget);
      expect(find.byKey(const Key('bill-photo-thumb')), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('add expense', () {
    testWidgets('the bill total fills amount, date and note; category stays', (
      tester,
    ) async {
      final photos = FakePhotos();
      final db = await openForm(tester, expenseForm, photos: photos);
      await attach(tester);
      await fillFromBill(tester);
      expect(find.text('Bill total'), findsOneWidget);
      expect(find.text('₹2,150'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bill-pick-total')));
      await settle(tester);
      expect(field(tester, 'expense-amount'), '2150');
      expect(field(tester, 'expense-note'), 'कृषी सेवा केंद्र bill #482');
      expect(find.text('10 Oct 2026'), findsOneWidget);
      expect(find.byKey(const Key('bill-note-filled')), findsOneWidget);
      // No category is guessed from a product bill: the grower picks it.
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .where((c) => c.selected),
        isEmpty,
      );

      await tester.tap(find.text('Other'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await settle(tester);
      await settle(tester);
      final row = await db.select(db.expenses).getSingle();
      expect(row.amountPaise, 215000);
      expect(row.spentOn, DateTime(2026, 10, 10));
      expect(row.billPhotoPath, '/docs/scouting_photos/${row.id}.jpg');
      final payload = await lastPayload(db, AccountsRepository.expenseEntity);
      expect(payload['spent_on'], '2026-10-10');
      expect(payload['note'], 'कृषी सेवा केंद्र bill #482');
      await unmountApp(tester);
    });

    testWidgets('a picked line fills its amount; typed amount and date stay', (
      tester,
    ) async {
      await openForm(tester, expenseForm);
      await tester.enterText(find.byKey(const Key('expense-amount')), '99');
      await attach(tester);
      await fillFromBill(tester, pick: 'bill-pick-1');
      expect(field(tester, 'expense-amount'), '99');
      expect(
        field(tester, 'expense-note'),
        'Ridomil Gold · कृषी सेवा केंद्र bill #482',
      );
      expect(
        find.text('Filled from the bill: note, date. Please check once.'),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('unsure, limit and offline on the expense form', (
      tester,
    ) async {
      final server = FakeBillServer(
        (_) async =>
            json(billJson(unsure: true, items: const [], total: null), 200),
      );
      await openForm(tester, expenseForm, server: server);
      await attach(tester);
      await fillFromBill(tester);
      expect(find.byKey(const Key('bill-note-unsure')), findsOneWidget);
      server.answer = (_) async => json(billLimitJson('total'), 429);
      await fillFromBill(tester);
      expect(find.byKey(const Key('bill-note-limit')), findsOneWidget);
      expect(find.byKey(const Key('bill-note-unsure')), findsNothing);
      await unmountApp(tester);

      await openForm(
        tester,
        expenseForm,
        syncStatus: const SyncStatus(connectivity: Connectivity.offline),
      );
      await attach(tester);
      expect(find.byKey(const Key('bill-fill')), findsNothing);
      expect(find.byKey(const Key('bill-note-offline')), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('lists', () {
    Future<void> seedWithBills(AppDatabase db) async {
      await seedPlot(db);
      await SprayRepository(db).save(spray('s1', bill: '/nope/s1.jpg'));
      await SprayRepository(db).save(spray('s2'));
      await AccountsRepository(db)
          .saveExpense(expense('e1', bill: '/nope/e1.jpg'));
    }

    testWidgets('the spray log shows the bill thumbnail; a tap opens it', (
      tester,
    ) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/sprays',
        seed: seedWithBills,
      );
      await settle(tester);
      expect(find.byKey(const Key('bill-thumb-s1')), findsOneWidget);
      expect(find.byKey(const Key('bill-thumb-s2')), findsNothing);
      await tester.tap(find.byKey(const Key('bill-thumb-s1')));
      await settle(tester);
      expect(find.byKey(const Key('bill-photo-full')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the accounts list shows the expense bill thumbnail', (
      tester,
    ) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/accounts',
        seed: seedWithBills,
      );
      await settle(tester);
      expect(find.byKey(const Key('bill-thumb-e1')), findsOneWidget);
      await unmountApp(tester);
    });
  });
}
