import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/inputs/data/inputs_repository.dart';
import 'package:bagmitra/features/inputs/domain/field_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

Future<void> seedLog(AppDatabase db) async {
  await seedPlot(db);
  final repo = InputsRepository(db);
  await repo.saveInput(
    InputRecord(
      id: 'in1',
      plotId: 'p1',
      appliedOn: DateTime(2026, 10, 10),
      kind: 'fertiliser',
      productName: 'DAP',
      quantity: 50,
      unit: 'kg',
      costPaise: 120000,
    ),
  );
  await repo.saveIrrigation(
    IrrigationRecord(
      id: 'ir1',
      plotId: 'p1',
      irrigatedOn: DateTime(2026, 10, 12),
      durationHours: 3,
    ),
  );
}

void main() {
  testWidgets('field log lists inputs and irrigation, newest first', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/log',
      seed: seedLog,
    );
    await settle(tester);
    expect(find.text('DAP'), findsOneWidget);
    expect(find.text('Irrigation'), findsOneWidget);
    expect(find.text('₹1,200'), findsOneWidget);
    final irrigationY = tester.getTopLeft(find.text('Irrigation')).dy;
    final inputY = tester.getTopLeft(find.text('DAP')).dy;
    expect(irrigationY, lessThan(inputY));
    await unmountApp(tester);
  });

  testWidgets('empty field log explains what to add', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/log',
      seed: seedPlot,
    );
    await settle(tester);
    expect(find.textContaining('No entries yet'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('grower records a fertiliser offline', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/log/input',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('Fertiliser'));
    await tester.enterText(find.byKey(const Key('input-product')), '19:19:19');
    await tester.enterText(find.byKey(const Key('input-quantity')), '25');
    await tester.tap(find.text('bag'));
    await tester.enterText(find.byKey(const Key('input-cost')), '3,200');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('input_record'))).get(),
    );
    final p = jsonDecode(queued!.single.payload) as Map<String, Object?>;
    expect(p['kind'], 'fertiliser');
    expect(p['product_name'], '19:19:19');
    expect(p['quantity'], 25);
    expect(p['unit'], 'bag');
    expect(p['cost_paise'], 320000);
    expect(p['applied_on'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('an input needs a kind and a product name', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/log/input',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('input_record'))).get(),
    );
    expect(queued, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('grower logs irrigation offline', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/log/irrigation',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('irrigation-hours')), '2.5');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('irrigation_record'))).get(),
    );
    final p = jsonDecode(queued!.single.payload) as Map<String, Object?>;
    expect(p['duration_hours'], 2.5);
    expect(p['water_litres'], isNull);
    expect(p['irrigated_on'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('field log in Marathi', (tester) async {
    await pumpApp(tester, initialLocation: '/plots/p1/log', seed: seedLog);
    await settle(tester);
    expect(find.text('खत जोडा'), findsOneWidget);
    expect(find.text('पाणी नोंदवा'), findsOneWidget);
    await unmountApp(tester);
  });
}
