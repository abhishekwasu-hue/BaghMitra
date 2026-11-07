import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:bagmitra/features/bahar/data/stage_templates.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/market_link/domain/lot_form_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'market_lot_repository_test.dart' show sampleLot;

const mlConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
  marketLink: true,
);

Future<void> seedLots(AppDatabase db) async {
  await seedPlot(db);
  final repo = MarketLotRepository(db);
  await repo.save(sampleLot());
  await repo.save(sampleLot(id: 'l2'));
  await repo.keepServerState(
    'l2',
    status: 'published',
    publishedAt: DateTime.utc(2026, 10, 12),
    orchardCheck: 'inside',
  );
}

void main() {
  test('lot text with a phone number or a link is caught (spec 4B)', () {
    for (final text in [
      'call 9822012345',
      'फोन ९८२२० १२३४५',
      '+91 98220-12345',
      '9 8 2 2 0 1 2 3 4 5',
      'see www.example.com',
      'https://x.example/lot',
      'wa.me/919822012345',
      'mail a@b.in',
      'photos on mybag.in',
    ]) {
      expect(hasContactDetails(text), isTrue, reason: text);
    }
    for (final text in [
      'मोठा आकार, ७०-८० मिमी, रंग चांगला',
      '12.5 tonnes, 2026-12-01 to 2026-12-20',
      'A grade',
    ]) {
      expect(hasContactDetails(text), isFalse, reason: text);
    }
  });

  test('the harvest window comes from the bahar stage template', () {
    const template = StageTemplate(
      crop: 'santra',
      bahar: 'ambia',
      version: 1,
      stages: [
        TemplateStage(
          key: 'flowering',
          labels: {},
          anchor: TemplateStage.seasonStart,
          min: 30,
          max: 40,
          sourceIds: [],
        ),
        TemplateStage(
          key: 'harvest',
          labels: {},
          anchor: 'flowering',
          min: 240,
          max: 270,
          sourceIds: [],
        ),
      ],
      sources: {},
    );
    final cycle = BaharCycle(
      id: 'b1',
      plotId: 'p1',
      bahar: 'ambia',
      seasonYear: 2026,
      status: 'active',
      actual: {'flowering': DateTime(2026, 2, 10)},
    );
    final w = harvestWindowFor(cycle, template)!;
    expect(w.from, DateTime(2026, 10, 8));
    expect(w.to, DateTime(2026, 11, 7));
    final entered = BaharCycle(
      id: 'b2',
      plotId: 'p1',
      bahar: 'mrig',
      seasonYear: 2026,
      status: 'active',
      planned: {'harvest': DateTime(2027, 1, 5)},
    );
    expect(harvestWindowFor(entered, null)!.to, DateTime(2027, 1, 5));
    expect(
      harvestWindowFor(
        const BaharCycle(
          id: 'b3',
          plotId: 'p1',
          bahar: 'x',
          seasonYear: 2026,
          status: 'planned',
        ),
        null,
      ),
      isNull,
    );
  });

  testWidgets('flag off: no lot form route (decision j)', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/market-link/lots/new?plot=p1',
      seed: seedPlot,
    );
    await settle(tester);
    expect(find.byKey(const Key('lot-tonnes')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets(
    'the form shows what is missing and refuses contacts in lot text',
    (tester) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        config: mlConfig,
        initialLocation: '/market-link/lots/new?plot=p1',
        seed: seedPlot,
        // Tall enough that the whole form is built (no lazy scrolling in the test).
        size: const Size(393, 2600),
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
      // Window still missing.
      await tester.tap(find.byKey(const Key('lot-save')));
      await settle(tester);
      expect(
        await tester.runAsync(() => db.select(db.marketLots).get()),
        isEmpty,
      );
      await unmountApp(tester);
    },
  );

  testWidgets('a complete draft is saved for sync, chips into the lot text', (
    tester,
  ) async {
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
      size: const Size(393, 2600),
    );
    await settle(tester);
    // The only orchard is chosen already; its crop shows.
    expect(find.byKey(const Key('lot-crop')), findsOneWidget);
    await tester.tap(find.textContaining('2026').first);
    await settle(tester);
    expect(find.byKey(const Key('lot-window-bahar')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('lot-tonnes')), '१२');
    await tester.tap(find.byKey(const Key('lot-basis-lump_sum')));
    await tester.tap(find.byKey(const Key('lot-size-large')));
    await tester.tap(find.byKey(const Key('lot-grade-grade_a')));
    await tester.enterText(find.byKey(const Key('lot-quality')), 'Good colour');
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
    expect(
      [
        for (final e in queued!)
          if (e.entity.startsWith('market_lot')) e.entity,
      ],
      ['market_lot'],
    );
    await unmountApp(tester);
  });

  testWidgets(
    'a saved draft reopens with its chips; a published lot is read only',
    (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        config: mlConfig,
        initialLocation: '/market-link/lots/l1',
        seed: seedLots,
      );
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

      await pumpApp(
        tester,
        locale: const Locale('en'),
        config: mlConfig,
        initialLocation: '/market-link/lots/l2',
        seed: seedLots,
      );
      await settle(tester);
      expect(find.text('Shown to traders'), findsOneWidget);
      expect(find.byKey(const Key('lot-save')), findsNothing);
      await unmountApp(tester);
    },
  );
}
