import 'dart:convert';

import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:bagmitra/features/export/domain/accounts_csv.dart';
import 'package:bagmitra/features/field_work/domain/field_work.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bills/bill_forms_test.dart'
    show attach, field, fillFromBill, openForm;
import '../plots/plots_screen_test.dart' show settle;
import 'spray_mix_screen_test.dart' show queuedSpray;
import 'spray_mix_test.dart' show captan, imida, mixSpray;
import 'spray_records_test.dart' show spray;
import 'spray_screen_test.dart' show seedPlotAndBanList;

// Spraying labour, "फवारणी मजुरी" (OPEN_QUESTIONS Q143): once per spray, counted under
// "labour", never in the products' cost.

SprayRecord withLabour(String id, int labour, {String cycle = 'b1'}) =>
    SprayRecord.ofProducts(
      id: id,
      plotId: 'p1',
      baharCycleId: cycle,
      sprayedOn: DateTime(2026, 11, 2),
      products: const [captan, imida],
      labourPaise: labour,
    );

const _labels = ExportLabels(
  title: 't',
  date: 'd',
  type: 'ty',
  details: 'de',
  amount: 'a',
  expenses: 'ex',
  income: 'in',
  profit: 'p',
  dues: 'du',
  typeExpense: 'e',
  typeSale: 's',
  typeSpray: 'Spray',
  typeInput: 'i',
  typeLabour: 'Labour',
);

void main() {
  group('record', () {
    test('labour stays apart from the products cost; payload round-trips', () {
      final s = withLabour('m1', 50000);
      expect(s.costPaise, 110000);
      expect(s.labourPaise, 50000);
      expect(s.totalPaise, 160000);
      final p = s.toPayload();
      expect(p['labour_paise'], 50000);
      expect(p['cost_paise'], 110000);
      final back = SprayRecord.fromPayload(
        'm1',
        (jsonDecode(jsonEncode(p)) as Map).cast<String, Object?>(),
      );
      expect(back.labourPaise, 50000);
      expect(back.toPayload(), p);
    });

    test('no labour: the payload has no key (as before Q143)', () {
      expect(spray('s1').toPayload().containsKey('labour_paise'), isFalse);
      expect(mixSpray('m1').labourPaise, isNull);
      expect(mixSpray('m1').totalPaise, mixSpray('m1').costPaise);
    });
  });

  test(
    'repository saves, loads, applies remote and keeps it on backup',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = SprayRepository(db, clock: TestClock().call);
      await repo.save(withLabour('m1', 50000));
      expect((await repo.find('m1'))!.labourPaise, 50000);
      await repo.markBillBackedUp('m1', 'u/bill-m1.jpg');
      final last = (await db.select(db.outboxEntries).get()).last;
      expect(
        (jsonDecode(last.payload) as Map<String, Object?>)['labour_paise'],
        50000,
      );
      await repo.applyRemote(
        RemoteChange(
          entity: 'spray_record',
          entityId: 's2',
          data: {...spray('s2').toPayload(), 'labour_paise': 20000},
          updatedAt: DateTime.utc(2026, 11, 3),
        ),
      );
      expect((await repo.find('s2'))!.labourPaise, 20000);
      await repo.applyRemote(
        RemoteChange(
          entity: 'spray_record',
          entityId: 's2',
          data: {...spray('s2').toPayload(), 'labour_paise': null},
          updatedAt: DateTime.utc(2026, 11, 4),
        ),
      );
      expect((await repo.find('s2'))!.labourPaise, isNull);
    },
  );

  group('totals', () {
    test('products under spray, labour under labour, each once', () {
      final s = AccountsSummary.of(
        expenses: const [],
        incomes: const [],
        sprays: [
          withLabour('m1', 50000),
          spray('s1', cycle: 'b1'),
        ],
        labour: [
          LabourRecord(
            id: 'l1',
            plotId: 'p1',
            baharCycleId: 'b1',
            workerName: 'Ramesh',
            workedOn: DateTime(2026, 11, 2),
            wagePaise: 40000,
          ),
        ],
        areaAcres: 4,
        treeCount: null,
        baharCycleId: 'b1',
      );
      expect(s.byCategory, {'spray': 110000 + 240000, 'labour': 50000 + 40000});
      expect(s.expensePaise, 110000 + 240000 + 50000 + 40000);
    });

    test('the ledger has a spray line and a labour line', () {
      final lines = buildLedger(
        labels: _labels,
        nameOf: (s) => s == 'spraying' ? 'Spraying' : s,
        expenses: const [],
        incomes: const [],
        sprays: [withLabour('m1', 50000), spray('s1')],
      );
      expect(
        [for (final l in lines) (l.type, l.details, l.paise)],
        unorderedEquals([
          ('Spray', 'Captan 50 WP + Imida 17.8 SL', -110000),
          ('Labour', 'Spraying · Captan 50 WP + Imida 17.8 SL', -50000),
          ('Spray', 'Imida 17.8 SL', -240000),
        ]),
      );
    });
  });

  group('form', () {
    testWidgets('labour saves once per spray and shows the split', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/sprays/new',
        seed: seedPlotAndBanList,
        size: const Size(393, 2600),
      );
      await settle(tester);
      expect(find.text('Spraying labour (₹, optional)'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('spray-product')), 'Captan');
      await tester.enterText(find.byKey(const Key('spray-cost')), '450');
      await tester.tap(find.byKey(const Key('spray-add-product')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('spray-product-1')), 'Imida');
      await tester.enterText(find.byKey(const Key('spray-cost-1')), '650');
      await settle(tester);
      expect(find.text('Total cost ₹1,100'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('spray-labour')), '500');
      await settle(tester);
      expect(
        find.text('Total cost = products ₹1,100 + labour ₹500'),
        findsOneWidget,
      );
      expect(find.text('Total cost ₹1,100'), findsNothing);
      await tester.tap(find.text('Save'));
      await settle(tester);
      final p = await queuedSpray(tester, db);
      expect(p['cost_paise'], 110000);
      expect(p['labour_paise'], 50000);
      await unmountApp(tester);
    });

    testWidgets('a wrong labour amount is asked again', (tester) async {
      final db = await openForm(tester, '/plots/p1/sprays/new');
      await tester.enterText(find.byKey(const Key('spray-product')), 'Captan');
      await tester.enterText(find.byKey(const Key('spray-labour')), '5.555');
      await tester.tap(find.text('Save'));
      await settle(tester);
      final rows = await tester.runAsync(
        () => db.select(db.sprayRecords).get(),
      );
      expect(rows, isEmpty);
      await unmountApp(tester);
    });

    testWidgets('bill fill never fills the labour', (tester) async {
      await openForm(tester, '/plots/p1/sprays/new');
      await attach(tester);
      await fillFromBill(tester, picks: ['bill-pick-0', 'bill-pick-1']);
      expect(field(tester, 'spray-cost'), '650');
      await tester.scrollUntilVisible(
        find.byKey(const Key('spray-labour')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(field(tester, 'spray-labour'), isEmpty);
      await unmountApp(tester);
    });
  });
}
