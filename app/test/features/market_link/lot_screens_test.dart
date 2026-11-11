import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:bagmitra/features/scouting/data/scouting_photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/boundary_screen_test.dart' show ScriptedLocation;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show FakePhotos;
import 'lot_form_test.dart' show mlConfig;
import 'market_lot_repository_test.dart' show sampleLot, samplePhoto;

Future<void> seedLots(AppDatabase db) async {
  await seedPlot(db);
  final repo = MarketLotRepository(db);
  await repo.save(sampleLot());
  await repo.save(sampleLot(id: 'l2', status: 'published'));
  await repo.keepServerState(
    'l2',
    status: 'published',
    publishedAt: DateTime.utc(2026, 10, 12),
    orchardCheck: 'inside',
  );
  // Photographed away from the mapped orchard: waits for the admin check (spec §4C).
  await repo.save(sampleLot(id: 'l3'));
  await repo.keepServerState(
    'l3',
    status: 'published',
    publishedAt: DateTime.utc(2026, 10, 12),
    orchardCheck: 'outside',
  );
  for (final id in ['f1', 'f2', 'f3']) {
    await repo.savePhoto(samplePhoto(id, lotId: 'l2'));
  }
}

void main() {
  testWidgets('flag off: no menu entry, no plot tile, no route (decision j)', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/more', seed: seedPlot);
    await settle(tester);
    expect(find.byKey(const Key('more-market-lots')), findsNothing);
    await unmountApp(tester);

    await pumpApp(tester, initialLocation: '/plots/p1', seed: seedPlot);
    await settle(tester);
    expect(find.byKey(const Key('open-market-lot')), findsNothing);
    await unmountApp(tester);

    await pumpApp(tester, initialLocation: '/market-link/lots', seed: seedPlot);
    await settle(tester);
    expect(find.text('माझा विक्रीचा माल'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('flag on: entries in the hub and on the plot', (tester) async {
    await pumpApp(
      tester,
      config: mlConfig,
      initialLocation: '/more',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('more-market-lots')),
      200,
    );
    expect(find.text('माल विक्रीसाठी दाखवा'), findsOneWidget);
    await unmountApp(tester);

    await pumpApp(
      tester,
      config: mlConfig,
      initialLocation: '/plots/p1',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-market-lot')),
      200,
    );
    expect(find.byKey(const Key('open-market-lot')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a lot is drafted offline with camera photos stamped by GPS', (
    tester,
  ) async {
    final photos = FakePhotos();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      config: mlConfig,
      initialLocation: '/market-link/lots/new?plot=p1',
      seed: seedPlot,
      overrides: [lotPhotosProvider.overrideWithValue(photos)],
      // Tall enough that the whole form is built (no lazy scrolling in the test).
      size: const Size(393, 2600),
      location: ScriptedLocation([
        const LocationReading.at(LatLon(21.1, 79.0), accuracyM: 8),
        const LocationReading.problem(LocationProblem.serviceOff),
      ]),
    );
    await settle(tester);
    expect(find.byKey(const Key('ml-disclaimer-note')), findsOneWidget);
    expect(find.byKey(const Key('lot-crop')), findsOneWidget);
    // Nothing chosen yet: saving shows what is missing and saves nothing.
    await tester.tap(find.byKey(const Key('lot-save')));
    await settle(tester);
    expect(find.text('Choose one'), findsWidgets);

    await tester.enterText(find.byKey(const Key('lot-tonnes')), '12.5');
    await tester.enterText(find.byKey(const Key('lot-quality')), 'Big fruit');
    await tester.tap(find.byKey(const Key('lot-basis-per_crate')));
    await tester.enterText(find.byKey(const Key('lot-rate')), '450');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('lot-quality')),
      'call 98220 12345',
    );
    await tester.tap(find.byKey(const Key('lot-save')));
    await settle(tester);
    expect(
      find.text(
        'Write only about the produce here; phone numbers and links are '
        'shared after you accept an offer.',
      ),
      findsWidgets,
    );
    await tester.enterText(find.byKey(const Key('lot-quality')), 'Big fruit');
    await tester.tap(find.byKey(const Key('lot-add-photo')));
    await settle(tester);
    // The second reading has no point: that photo is not kept.
    await tester.tap(find.byKey(const Key('lot-add-photo')));
    await settle(tester);
    expect(
      find.text(
        'Turn on GPS and take the photo again: each photo needs its location.',
      ),
      findsOneWidget,
    );
    expect(photos.sources, [PhotoSource.camera, PhotoSource.camera]);

    // Window still missing.
    await tester.tap(find.byKey(const Key('lot-save')));
    await settle(tester);
    expect(
      await tester.runAsync(() => db.select(db.marketLots).get()),
      isEmpty,
    );
    await unmountApp(tester);
  });

  testWidgets('a complete draft saves the lot, then its photos, for sync', (
    tester,
  ) async {
    final photos = FakePhotos();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      config: mlConfig,
      initialLocation: '/market-link/lots/new',
      seed: (db) async {
        await seedPlot(db);
        await BaharRepository(db).save(
          BaharCycle(
            id: 'b1',
            plotId: 'p1',
            bahar: 'ambia',
            seasonYear: 2026,
            status: 'active',
            planned: {'harvest': DateTime(2026, 12, 10)},
          ),
        );
      },
      overrides: [lotPhotosProvider.overrideWithValue(photos)],
      location: ScriptedLocation([
        const LocationReading.at(LatLon(21.1, 79.0), accuracyM: 8),
      ]),
      size: const Size(393, 2600),
    );
    await settle(tester);
    // The only orchard is chosen already; its crop shows.
    expect(find.byKey(const Key('lot-crop')), findsOneWidget);
    await tester.tap(find.textContaining('2026').first);
    await settle(tester);
    expect(find.text('1 Oct – 16 Oct'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('lot-tonnes')), '१२');
    await tester.tap(find.byKey(const Key('lot-basis-lump_sum')));
    await tester.tap(find.byKey(const Key('lot-size-large')));
    await tester.tap(find.byKey(const Key('lot-grade-grade_a')));
    await tester.enterText(find.byKey(const Key('lot-quality')), 'Good colour');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('lot-add-photo')));
      await settle(tester);
    }
    expect(find.byKey(const Key('lot-publish')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lot-save')));
    await settle(tester);
    final lots = await tester.runAsync(() => db.select(db.marketLots).get());
    expect(lots!.single.quantityT, 12);
    expect(lots.single.baharCycleId, 'b1');
    expect(lots.single.basis, 'lump_sum');
    expect(lots.single.status, 'draft');
    expect(lots.single.quality, 'Large · Grade A · Good colour');
    final queued = await tester.runAsync(
      () => db.select(db.outboxEntries).get(),
    );
    final entities = [for (final e in queued!) e.entity];
    expect(
      entities.indexOf('market_lot'),
      lessThan(entities.indexOf('market_lot_photo')),
    );
    expect(entities.where((e) => e == 'market_lot_photo'), hasLength(3));
    await unmountApp(tester);
  });

  testWidgets('a published lot is read only with one action: stop showing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      config: mlConfig,
      initialLocation: '/market-link/lots/l2',
      seed: seedLots,
    );
    await settle(tester);
    expect(find.text('Shown to traders'), findsOneWidget);
    expect(find.byKey(const Key('lot-close')), findsOneWidget);
    expect(find.byKey(const Key('lot-publish')), findsNothing);
    expect(find.byKey(const Key('lot-add-photo')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('my lots lists drafts and published lots', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      config: mlConfig,
      initialLocation: '/market-link/lots',
      seed: seedLots,
    );
    await settle(tester);
    expect(find.byKey(const Key('lot-l1')), findsOneWidget);
    expect(find.byKey(const Key('lot-l2')), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Shown to traders'), findsOneWidget);
    expect(find.text('Waiting for check'), findsOneWidget);
    expect(find.text('₹3,000 per quintal'), findsNWidgets(3));
    await tester.tap(find.byKey(const Key('lot-l1')));
    await settle(tester);
    expect(find.byKey(const Key('lot-save')), findsOneWidget);
    // The saved text comes back as the ticked chips and the short line.
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('lot-size-large')))
          .selected,
      isTrue,
    );
    expect(find.text('रंग चांगला'), findsOneWidget);
    await unmountApp(tester);
  });
}
