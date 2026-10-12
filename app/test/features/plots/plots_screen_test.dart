import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/crop_catalog.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<void> seedTwo(AppDatabase db) async {
  final repo = PlotRepository(db);
  await repo.save(
    const Plot(
      id: 'p1',
      name: 'बाग १',
      crop: 'santra',
      areaSqM: 4 * Plot.sqMPerAcre,
      treeCount: 440,
    ),
  );
  await repo.save(
    const Plot(
      id: 'p2',
      name: 'बाग २',
      crop: 'mosambi',
      areaSqM: 2.5 * Plot.sqMPerAcre,
    ),
  );
}

/// Lets Drift stream queries (real async) deliver, then settles frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('crop labels fall back to English, then slug', () {
    const crop = CropOption('santra', {'en': 'Mandarin', 'mr': 'संत्रा'});
    expect(crop.label('mr'), 'संत्रा');
    expect(crop.label('ta'), 'Mandarin');
    expect(const CropOption('x', {}).label('mr'), 'x');
  });

  testWidgets('empty orchard invites adding the first block', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots',
    );
    await settle(tester);
    expect(find.text('No orchard blocks yet'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('lists plots with localized crop, acres and trees', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/plots', seed: seedTwo);
    await settle(tester);
    expect(find.text('बाग १'), findsOneWidget);
    expect(find.text('संत्रा'), findsOneWidget);
    expect(find.text('४ एकर · ४४० झाडं'), findsOneWidget);
    expect(find.text('२.५ एकर'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('add plot: validates, saves offline, returns to list', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots',
    );
    await settle(tester);
    await tester.tap(find.text('Add orchard block'));
    await settle(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Enter a valid number'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('plot-name')), 'Bag 3');
    await tester.tap(find.text('Sweet orange (mosambi)'));
    await tester.enterText(find.byKey(const Key('plot-acres')), '1.5');
    await tester.enterText(find.byKey(const Key('plot-trees')), '150');
    await tester.enterText(find.byKey(const Key('plot-variety')), 'Nucellar');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('Bag 3'), findsOneWidget);
    expect(find.text('1.5 acres · 150 trees'), findsOneWidget);
    final queued = await tester.runAsync(
      () => db.select(db.outboxEntries).get(),
    );
    expect(queued!.single.entity, 'plot');
    expect(queued.single.payload, contains('"crop":"mosambi"'));
    expect(queued.single.payload, contains('"variety":"Nucellar"'));
    await unmountApp(tester);
  });

  testWidgets('delete asks for confirmation then removes the plot', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots',
      seed: seedTwo,
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Delete block').first);
    await settle(tester);
    expect(
      find.textContaining('also removes it from your other devices'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('बाग १'), findsNothing);
    expect(find.text('बाग २'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('orchard tab on home opens My orchard', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));
    await tester.tap(find.text('Orchard'));
    await settle(tester);
    expect(find.text('My orchard'), findsOneWidget);
    await unmountApp(tester);
  });
}
