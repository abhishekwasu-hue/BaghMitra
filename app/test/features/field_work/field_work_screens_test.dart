import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/field_work/data/field_work_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'field_work_test.dart' show day, lot;

Future<void> seedWork(AppDatabase db) async {
  await seedPlot(db);
  final repo = FieldWorkRepository(db);
  await repo.saveLabour(day('l1')); // wage 400, advance 100 -> 300 due
  await repo.saveLabour(
    day('l2', wage: 50000, advance: 0, settledOn: DateTime(2026, 11, 7)),
  );
  await repo.saveHarvest(lot('h1'));
  await repo.saveHarvest(lot('h2', grade: null, kg: 100));
}

Future<List<Map<String, Object?>>> queued(
  WidgetTester tester,
  AppDatabase db,
  String entity,
) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.outboxEntries,
    )..where((t) => t.entity.equals(entity))).get(),
  );
  return [for (final r in rows!) jsonDecode(r.payload) as Map<String, Object?>];
}

void main() {
  testWidgets('labour register shows workers, wages and what is still due', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/labour',
      seed: seedWork,
    );
    await settle(tester);
    expect(find.textContaining('Sunita'), findsNWidgets(2));
    expect(find.text('₹500'), findsOneWidget); // settled day's wage
    expect(find.text('Due ₹300'), findsOneWidget); // total owed
    expect(find.textContaining('Due ₹300'), findsNWidgets(2)); // + the open day
    expect(find.textContaining('Settled'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('settling a day records the settlement offline', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/labour',
      seed: seedWork,
    );
    await settle(tester);
    await tester.tap(find.text('Mark paid'));
    await settle(tester);
    final rows = await queued(tester, db, 'labour_record');
    expect(rows.last['settled_on'], '2026-10-13');
    expect(find.textContaining('Due ₹300'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('grower records a worker day offline', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/labour/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('labour-worker')), 'Ramesh');
    await tester.tap(find.text('Weeding'));
    await tester.enterText(find.byKey(const Key('labour-wage')), '450');
    await tester.enterText(find.byKey(const Key('labour-advance')), '100');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final p = (await queued(tester, db, 'labour_record')).single;
    expect(p['worker_name'], 'Ramesh');
    expect(p['task'], 'weeding');
    expect(p['wage_paise'], 45000);
    expect(p['advance_paise'], 10000);
    expect(p['settled_on'], isNull);
    expect(p['worked_on'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('paying in full today settles the new day', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/labour/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('labour-worker')), 'Ramesh');
    await tester.enterText(find.byKey(const Key('labour-wage')), '450');
    await tester.tap(find.byKey(const Key('labour-paid-now')));
    await tester.tap(find.text('Save'));
    await settle(tester);
    final p = (await queued(tester, db, 'labour_record')).single;
    expect(p['settled_on'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('a worker day needs a name and a wage', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/labour/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(await queued(tester, db, 'labour_record'), isEmpty);
    await unmountApp(tester);
  });

  testWidgets('harvest log lists lots and the total weight', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/harvest',
      seed: seedWork,
    );
    await settle(tester);
    expect(find.text('Total 1,350.5 kg'), findsOneWidget);
    expect(find.textContaining('Grade A'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('grower records a harvest lot offline', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/harvest/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('harvest-kg')), '820.5');
    await tester.tap(find.text('Grade A'));
    await tester.tap(find.text('Large'));
    await tester.tap(find.text('Save'));
    await settle(tester);
    final p = (await queued(tester, db, 'harvest_record')).single;
    expect(p['quantity_kg'], 820.5);
    expect(p['grade'], 'grade_a');
    expect(p['size_class'], 'large');
    expect(p['harvested_on'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('a harvest lot needs a weight', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/harvest/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(await queued(tester, db, 'harvest_record'), isEmpty);
    await unmountApp(tester);
  });

  testWidgets('labour register in Marathi', (tester) async {
    await pumpApp(tester, initialLocation: '/plots/p1/labour', seed: seedWork);
    await settle(tester);
    expect(find.text('मजूर दिवस जोडा'), findsOneWidget);
    expect(find.text('पूर्ण दिले'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the bahar screen menu opens labour and harvest', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/bahar',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Harvest'));
    await settle(tester);
    expect(find.text('Add harvest'), findsOneWidget);
    await unmountApp(tester);
  });
}
