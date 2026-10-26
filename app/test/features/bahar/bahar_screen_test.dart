import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'bahar_repository_test.dart' show cycle;

Future<void> seedPlot(AppDatabase db, {double? lat, double? lon}) =>
    PlotRepository(db).save(
      Plot(
        id: 'p1',
        name: 'बाग १',
        crop: 'santra',
        areaSqM: 4 * Plot.sqMPerAcre,
        centroidLat: lat,
        centroidLon: lon,
      ),
    );

Future<void> seedPlotWithCycle(AppDatabase db) async {
  await seedPlot(db);
  await BaharRepository(db).save(cycle('b1'));
}

void main() {
  testWidgets('grower starts a bahar with their own flowering date', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('बाग १'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-records')));
    await settle(tester);
    expect(find.text('No bahar planned yet'), findsOneWidget);

    await tester.tap(find.text('Start a bahar').first);
    await settle(tester);
    await tester.tap(find.text('Mrig bahar'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stage-flowering')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('Mrig bahar'), findsOneWidget);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('bahar_cycle'))).get(),
    );
    final payload = jsonDecode(queued!.single.payload) as Map<String, Object?>;
    expect(payload['bahar'], 'mrig');
    expect(payload['plot_id'], 'p1');
    expect((payload['planned']! as Map).keys, ['flowering']);

    // The planned flowering date also became a reminder on the Tasks list.
    final tasks = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('farm_task'))).get(),
    );
    final task = jsonDecode(tasks!.single.payload) as Map<String, Object?>;
    expect(task['kind'], 'scouting');
    expect(task['plot_id'], 'p1');
    expect(task['title'], contains('Flowering today (Mrig bahar)'));
    await unmountApp(tester);
  });

  testWidgets('lists a planned bahar with its dates', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/bahar',
      seed: seedPlotWithCycle,
    );
    await settle(tester);
    expect(find.text('Ambia bahar'), findsOneWidget);
    expect(find.textContaining('10 Feb 2027'), findsOneWidget);
    await unmountApp(tester);
  });
}
