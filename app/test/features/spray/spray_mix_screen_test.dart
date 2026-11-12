import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bills/bill_forms_test.dart'
    show attach, field, fillFromBill, openForm;
import '../bills/bill_read_test.dart';
import '../photo_analysis/photo_analysis_test.dart' show json;
import '../plots/plots_screen_test.dart' show settle;
import 'spray_mix_test.dart' show captan, imida, kelthane, mixSpray;
import 'spray_screen_test.dart' show seedPlotAndBanList;

// Tank mix on "फवारणी नोंदवा" (OPEN_QUESTIONS Q142).

const _form = '/plots/p1/sprays/new';

Finder inBlock(int id, String key) => find.descendant(
  of: find.byKey(Key('spray-block-$id')),
  matching: find.byKey(Key(key)),
);

Future<void> chooseTypeIn(WidgetTester tester, int id, String label) async {
  await tester.ensureVisible(inBlock(id, 'spray-active-type'));
  await tester.tap(inBlock(id, 'spray-active-type'));
  await settle(tester);
  await tester.tap(find.text(label).last);
  await settle(tester);
}

Future<Map<String, Object?>> queuedSpray(
  WidgetTester tester,
  AppDatabase db,
) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.outboxEntries,
    )..where((t) => t.entity.equals(SprayRepository.entity))).get(),
  );
  return jsonDecode(rows!.single.payload) as Map<String, Object?>;
}

Future<void> seedMix(AppDatabase db) async {
  await seedPlotAndBanList(db);
  await SprayRepository(db).save(mixSpray('m1'));
}

void main() {
  testWidgets('products are added and removed; one product stays', (
    tester,
  ) async {
    await openForm(tester, _form);
    // One product: no heading, no remove control.
    expect(find.text('Product 1'), findsNothing);
    expect(find.byKey(const Key('spray-remove-0')), findsNothing);

    await tester.tap(find.byKey(const Key('spray-add-product')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('spray-add-product')));
    await settle(tester);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 3'), findsOneWidget);
    expect(find.text('For the whole spray'), findsOneWidget);
    // The first product cannot be removed: at least one.
    expect(find.byKey(const Key('spray-remove-0')), findsNothing);
    expect(find.byKey(const Key('spray-remove-2')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('spray-product-1')), 'B');
    await tester.enterText(find.byKey(const Key('spray-product-2')), 'C');
    await tester.tap(find.byKey(const Key('spray-remove-1')));
    await settle(tester);
    // The third product moved up and kept its text.
    expect(field(tester, 'spray-product-1'), 'C');
    expect(find.text('Product 3'), findsNothing);
    await tester.tap(find.byKey(const Key('spray-remove-1')));
    await settle(tester);
    expect(find.text('Product 1'), findsNothing);
    expect(find.byKey(const Key('spray-product-1')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a mix saves as one spray with every product', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: _form,
      seed: seedPlotAndBanList,
      size: const Size(393, 3000),
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('spray-product')), 'Captan');
    await tester.enterText(find.byKey(const Key('spray-phi')), '7');
    await tester.enterText(find.byKey(const Key('spray-cost')), '450');
    await tester.tap(find.byKey(const Key('spray-add-product')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('spray-product-1')), 'Imida');
    await tester.enterText(find.byKey(const Key('spray-dose-1')), '0.3 ml/L');
    await tester.enterText(find.byKey(const Key('spray-phi-1')), '15');
    await tester.enterText(find.byKey(const Key('spray-cost-1')), '650');
    // An extra product left empty is not saved.
    await tester.tap(find.byKey(const Key('spray-add-product')));
    await settle(tester);
    expect(find.text('Total cost ₹1,100'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('spray-water')), '600');
    await tester.enterText(find.byKey(const Key('spray-area')), '4');
    await tester.tap(find.text('Save'));
    await settle(tester);

    final p = await queuedSpray(tester, db);
    expect(p['product_name'], 'Captan');
    expect(p['cost_paise'], 110000);
    expect(p['phi_days'], 15);
    expect(p['water_litres'], 600.0);
    expect(p['products'], [
      {
        'product_name': 'Captan',
        'active_ingredient': null,
        'dose': null,
        'cost_paise': 45000,
        'phi_days': 7,
      },
      {
        'product_name': 'Imida',
        'active_ingredient': null,
        'dose': '0.3 ml/L',
        'cost_paise': 65000,
        'phi_days': 15,
      },
    ]);
    final saved = await tester.runAsync(
      () => SprayRepository(db).watchForPlot('p1').first,
    );
    expect(saved!.single.products, hasLength(2));
    await unmountApp(tester);
  });

  testWidgets(
    'an extra product with only a dose asks for a name or ingredient',
    (tester) async {
      final db = await openForm(tester, _form);
      await tester.enterText(find.byKey(const Key('spray-product')), 'Captan');
      await tester.tap(find.byKey(const Key('spray-add-product')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('spray-dose-1')), '2 g');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(
        find.text('Write the product name or the active ingredient'),
        findsOneWidget,
      );
      final rows = await tester.runAsync(
        () => db.select(db.sprayRecords).get(),
      );
      expect(rows, isEmpty);
      await unmountApp(tester);
    },
  );

  testWidgets('in a mix, a product with an ingredient needs no name', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: _form,
      seed: seedPlotAndBanList,
      size: const Size(393, 2200),
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('spray-product')), 'Captan');
    await tester.tap(find.byKey(const Key('spray-add-product')));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('spray-block-1')),
        matching: find.text('Product name'),
      ),
      findsOneWidget,
    );
    await chooseTypeIn(tester, 1, 'Insecticide');
    await tester.ensureVisible(inBlock(1, 'spray-active-pick'));
    await tester.tap(inBlock(1, 'spray-active-pick'));
    await settle(tester);
    await tester.tap(find.text('Carbofuran 03% CG'));
    await settle(tester);
    // Only the block with the ingredient reads as optional.
    expect(
      find.descendant(
        of: find.byKey(const Key('spray-block-1')),
        matching: find.text('Product name (optional)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('spray-block-0')),
        matching: find.text('Product name'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Save'));
    await settle(tester);

    final p = await queuedSpray(tester, db);
    expect(
      [
        for (final m in (p['products']! as List).cast<Map<String, Object?>>())
          (m['product_name'], m['active_ingredient']),
      ],
      [('Captan', null), ('Carbofuran', 'Carbofuran')],
    );
    // The log names the mix by both, with no blank.
    expect(find.text('Mix: Captan + Carbofuran'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the ban check runs on each product, its note on that one', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: _form,
      seed: seedPlotAndBanList,
      size: const Size(393, 2200),
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('spray-product')), 'Captan');
    await tester.tap(find.byKey(const Key('spray-add-product')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('spray-product-1')),
      'Kelthane',
    );
    await chooseTypeIn(tester, 1, 'Other');
    await tester.enterText(inBlock(1, 'spray-active'), 'Kelthane');
    await settle(tester);
    expect(find.text('Outside the approved list'), findsOneWidget);
    expect(find.byKey(const Key('spray-note-banned-1')), findsOneWidget);
    expect(find.byKey(const Key('spray-note-banned')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('spray-block-1')),
        matching: find.text('Outside the approved list'),
      ),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('bill: several ticked lines fill one product each', (
    tester,
  ) async {
    final server = FakeBillServer((_) async => json(billJson(), 200));
    final db = await openForm(tester, _form, server: server);
    await tester.enterText(find.byKey(const Key('spray-cost')), '700');
    await attach(tester);
    await fillFromBill(tester, picks: ['bill-pick-0', 'bill-pick-1']);
    expect(field(tester, 'spray-product'), 'Imida 17.8 SL');
    expect(field(tester, 'spray-cost'), '700'); // typed: kept
    expect(field(tester, 'spray-product-1'), 'Ridomil Gold');
    expect(field(tester, 'spray-dose-1'), '1 kg');
    expect(field(tester, 'spray-cost-1'), '1500');
    expect(find.text('Total cost ₹2,200'), findsOneWidget);
    expect(
      find.text(
        'Filled from the bill: product name, active ingredient, quantity, '
        'cost, date. Please check once.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    final p = await queuedSpray(tester, db);
    expect(p['cost_paise'], 70000 + 150000);
    expect(p['sprayed_on'], '2026-10-10');
    expect((p['products']! as List).length, 2);
    await unmountApp(tester);
  });

  testWidgets('the log shows the mix; its detail shows each product', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays',
      seed: seedMix,
      size: const Size(393, 1400),
    );
    await settle(tester);
    final label =
        'Mix: ${captan.productName} + ${imida.productName} + '
        '${kelthane.productName}';
    expect(find.text(label), findsOneWidget);
    // Kelthane is banned: the log flags the spray once.
    expect(find.text('Outside the approved list'), findsOneWidget);
    expect(find.textContaining('₹1,300'), findsOneWidget);

    await tester.tap(find.byKey(const Key('spray-open-m1')));
    await settle(tester);
    expect(find.byKey(const Key('spray-detail-title')), findsOneWidget);
    expect(find.text(label), findsOneWidget);
    expect(find.text('Total cost ₹1,300'), findsOneWidget);
    expect(
      find.text('Waiting period of the mix: 15 days (the longest)'),
      findsOneWidget,
    );
    for (final (i, p) in [captan, imida, kelthane].indexed) {
      expect(
        find.descendant(
          of: find.byKey(Key('spray-detail-product-$i')),
          matching: find.text(p.productName),
        ),
        findsWidgets,
      );
    }
    expect(find.text('PHI 7 days'), findsOneWidget);
    expect(find.text('Captan · 2 g per litre'), findsOneWidget);
    expect(find.byKey(const Key('spray-detail-note-2-banned')), findsOneWidget);
    expect(find.byKey(const Key('spray-detail-note-0-banned')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the detail shows an ingredient equal to the name once', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays',
      seed: (db) async {
        await seedPlotAndBanList(db);
        await SprayRepository(db).save(
          SprayRecord.ofProducts(
            id: 'm2',
            plotId: 'p1',
            sprayedOn: DateTime(2026, 10, 2),
            products: const [
              SprayProduct(
                productName: 'Carbofuran',
                activeIngredient: ' carbofuran',
                dose: '2 g',
              ),
              SprayProduct(
                productName: 'Furadan',
                activeIngredient: 'Carbofuran',
              ),
            ],
          ),
        );
      },
      size: const Size(393, 1400),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('spray-open-m2')));
    await settle(tester);
    Finder inProduct(int i, String text) => find.descendant(
      of: find.byKey(Key('spray-detail-product-$i')),
      matching: find.text(text),
    );
    expect(inProduct(0, 'Carbofuran'), findsOneWidget);
    expect(inProduct(0, '2 g'), findsOneWidget);
    expect(find.textContaining('carbofuran ·'), findsNothing);
    expect(find.textContaining('Carbofuran · '), findsNothing);
    // A different name still shows its ingredient.
    expect(inProduct(1, 'Carbofuran'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an old single-product record opens as one product', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays',
      seed: (db) async {
        await seedPlotAndBanList(db);
        await SprayRepository(db).save(
          SprayRecord(
            id: 's1',
            plotId: 'p1',
            sprayedOn: DateTime(2026, 10, 2),
            productName: 'Neem oil',
            costPaise: 30000,
          ),
        );
      },
    );
    await settle(tester);
    expect(find.text('Neem oil'), findsOneWidget);
    expect(find.textContaining('Mix:'), findsNothing);
    await tester.tap(find.byKey(const Key('spray-open-s1')));
    await settle(tester);
    expect(find.byKey(const Key('spray-detail-product-0')), findsOneWidget);
    expect(find.byKey(const Key('spray-detail-product-1')), findsNothing);
    expect(find.byKey(const Key('spray-detail-phi')), findsNothing);
    expect(find.text('₹300'), findsNWidgets(2));
    await unmountApp(tester);
  });
}
