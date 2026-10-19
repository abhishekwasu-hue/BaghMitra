import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/spray/data/restrictions_cache.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'spray_records_test.dart' show SprayTestCopy, spray;

/// A phone that has already cached the ban list (as after one online start).
Future<void> seedPlotAndBanList(AppDatabase db) async {
  await seedPlot(db);
  await db.writeMeta(
    RestrictionsCache.metaKey,
    jsonEncode({
      'restrictions': [
        {
          'active_ingredient': 'dicofol',
          'kind': 'banned',
          'crops': <String>[],
          'crop_groups': <String>[],
          'notification': 'S.O. 4294(E)',
          'effective_from': '2023-10-03T00:00:00Z',
        },
      ],
      'synonyms': [
        {'name': 'Kelthane', 'active_ingredient': 'dicofol'},
      ],
    }),
  );
  await BaharRepository(db).save(
    BaharCycle(
      id: 'b1',
      plotId: 'p1',
      bahar: 'ambia',
      seasonYear: 2026,
      status: 'planned',
      planned: {'harvest': DateTime.utc(2026, 11, 10)},
    ),
  );
}

Future<void> seedWithSpray(AppDatabase db) async {
  await seedPlotAndBanList(db);
  await SprayRepository(db).save(spray('s1'));
  await SprayRepository(db).save(spray('s2').copyWithActive('Kelthane'));
}

void main() {
  testWidgets(
    'banned ingredient warns while typing, offline, and still saves',
    (tester) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/sprays/new',
        seed: seedPlotAndBanList,
      );
      await settle(tester);
      expect(find.text('Banned chemical'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('spray-product')),
        'Kelthane',
      );
      await tester.enterText(find.byKey(const Key('spray-active')), 'Kelthane');
      await settle(tester);
      expect(find.text('Banned chemical'), findsOneWidget);
      expect(find.textContaining('S.O. 4294(E)'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await settle(tester);
      final queued = await tester.runAsync(
        () => (db.select(
          db.outboxEntries,
        )..where((t) => t.entity.equals('spray_record'))).get(),
      );
      final payload =
          jsonDecode(queued!.single.payload) as Map<String, Object?>;
      expect(payload['active_ingredient'], 'Kelthane');
      expect(payload['sprayed_on'], '2026-10-13');
      await unmountApp(tester);
    },
  );

  testWidgets('PHI past the planned harvest warns with the first safe day', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: seedPlotAndBanList,
    );
    await settle(tester);
    await tester.tap(find.textContaining('Ambia'));
    await tester.enterText(find.byKey(const Key('spray-phi')), '40');
    await settle(tester);
    expect(find.text('Harvest too soon'), findsOneWidget);
    expect(find.textContaining('22 Nov 2026'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('spray-phi')), '10');
    await settle(tester);
    expect(find.text('Harvest too soon'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a product name alone is enough to record a spray', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: seedPlotAndBanList,
    );
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('spray-product')), 'Neem oil');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('spray_record'))).get(),
    );
    expect(queued, hasLength(1));
    await unmountApp(tester);
  });

  testWidgets('the log lists sprays and flags the banned one', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays',
      seed: seedWithSpray,
    );
    await settle(tester);
    expect(find.text('Imida 17.8 SL'), findsOneWidget);
    expect(find.text('Banned chemical'), findsOneWidget);
    await unmountApp(tester);
  });
}
