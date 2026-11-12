import 'dart:convert';

import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:bagmitra/features/accounts/domain/year_comparison.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/export/domain/accounts_csv.dart';
import 'package:bagmitra/features/export_info/domain/export_record.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/features/spray/domain/spray_check.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';
import 'spray_records_test.dart' show spray;

// Tank mix (OPEN_QUESTIONS Q142): several products in one spray are one record.

const captan = SprayProduct(
  productName: 'Captan 50 WP',
  activeIngredient: 'Captan',
  dose: '2 g per litre',
  costPaise: 45000,
  phiDays: 7,
);
const imida = SprayProduct(
  productName: 'Imida 17.8 SL',
  activeIngredient: 'Imidacloprid',
  dose: '0.3 ml per litre',
  costPaise: 65000,
  phiDays: 15,
);
const kelthane = SprayProduct(
  productName: 'Kelthane',
  activeIngredient: 'Kelthane',
  costPaise: 20000,
);

SprayRecord mixSpray(
  String id, {
  List<SprayProduct> products = const [captan, imida, kelthane],
  String? cycle = 'b1',
  DateTime? on,
}) => SprayRecord.ofProducts(
  id: id,
  plotId: 'p1',
  baharCycleId: cycle,
  sprayedOn: on ?? DateTime(2026, 11, 2),
  products: products,
  waterLitres: 600,
  areaAcres: 4,
  operator: 'Ramesh',
  target: 'psylla, canker',
);

final _rules = RestrictionList.fromJson({
  'restrictions': [
    {
      'active_ingredient': 'dicofol',
      'kind': 'banned',
      'notification': 'S.O. 4294(E)',
      'effective_from': '2023-10-03T00:00:00Z',
    },
  ],
  'synonyms': [
    {'name': 'Kelthane', 'active_ingredient': 'dicofol'},
  ],
});

const _crop = CropRules(labelAliases: {'orange'}, groups: {'citrus'});

void main() {
  group('record', () {
    test('a mix is one spray: summed cost, longest PHI, first product', () {
      final s = mixSpray('m1');
      expect(s.isMix, isTrue);
      expect(s.costPaise, 130000);
      expect(s.phiDays, 15);
      expect(s.productName, 'Captan 50 WP');
      expect(s.activeIngredient, 'Captan');
      expect(s.dose, '2 g per litre');
      expect(s.productsLabel, 'Captan 50 WP + Imida 17.8 SL + Kelthane');
      expect(s.activeIngredients, ['Captan', 'Imidacloprid', 'Kelthane']);
      expect(s.products, [captan, imida, kelthane]);
    });

    test('no product with a PHI gives none; one product is the old shape', () {
      expect(
        mixSpray(
          'm1',
          products: const [
            SprayProduct(productName: 'A'),
            SprayProduct(productName: 'B'),
          ],
        ).phiDays,
        isNull,
      );
      final one = mixSpray('m2', products: const [imida]);
      expect(one.isMix, isFalse);
      expect(one.mix, isEmpty);
      expect(one.costPaise, 65000);
      expect(one.toPayload().containsKey('products'), isFalse);
      expect(() => mixSpray('m3', products: const []), throwsArgumentError);
    });

    test('payload lists every product and round-trips', () {
      final p = mixSpray('m1').toPayload();
      expect(p['cost_paise'], 130000);
      expect(p['phi_days'], 15);
      expect(p['product_name'], 'Captan 50 WP');
      expect(p['products'], [
        {
          'product_name': 'Captan 50 WP',
          'active_ingredient': 'Captan',
          'dose': '2 g per litre',
          'cost_paise': 45000,
          'phi_days': 7,
        },
        imida.toPayload(),
        kelthane.toPayload(),
      ]);
      // As it comes back from the server (JSON).
      final back = SprayRecord.fromPayload(
        'm1',
        (jsonDecode(jsonEncode(p)) as Map).cast<String, Object?>(),
      );
      expect(back.products, [captan, imida, kelthane]);
      expect(back.toPayload(), p);
    });

    test('an old single-product payload (products null) reads as before', () {
      final p = {...spray('s1').toPayload(), 'products': null};
      final s = SprayRecord.fromPayload('s1', p);
      expect(s.isMix, isFalse);
      expect(s.products.single.productName, 'Imida 17.8 SL');
      expect(s.products.single.costPaise, 240000);
      expect(s.toPayload(), spray('s1').toPayload());
    });
  });

  group('repository', () {
    test(
      'saves and loads a mix; queues one mutation; applies a remote mix',
      () async {
        final db = memoryDb();
        addTearDown(db.close);
        final repo = SprayRepository(db, clock: TestClock().call);
        await repo.save(mixSpray('m1'));
        final queued = await db.select(db.outboxEntries).get();
        expect(queued, hasLength(1));
        expect(jsonDecode(queued.single.payload), mixSpray('m1').toPayload());
        final loaded = (await repo.watchForPlot('p1').first).single;
        expect(loaded.products, [captan, imida, kelthane]);
        expect(loaded.costPaise, 130000);

        await repo.applyRemote(
          RemoteChange(
            entity: 'spray_record',
            entityId: 'm2',
            data: (jsonDecode(jsonEncode(mixSpray('m2').toPayload())) as Map)
                .cast<String, Object?>(),
            updatedAt: DateTime.utc(2026, 11, 3),
          ),
        );
        expect((await repo.find('m2'))!.products, hasLength(3));
        // A server copy without products (an older record) stores none.
        await repo.applyRemote(
          RemoteChange(
            entity: 'spray_record',
            entityId: 'm2',
            data: {...spray('m2').toPayload(), 'products': null},
            updatedAt: DateTime.utc(2026, 11, 4),
          ),
        );
        final row = await (db.select(
          db.sprayRecords,
        )..where((t) => t.id.equals('m2'))).getSingle();
        expect(row.products, isNull);
      },
    );

    test('the bill photo backup re-sends the whole mix', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = SprayRepository(db, clock: TestClock().call);
      await repo.save(mixSpray('m1'));
      await repo.markBillBackedUp('m1', 'u/bill-m1.jpg');
      final last = (await db.select(db.outboxEntries).get()).last;
      final payload = jsonDecode(last.payload) as Map<String, Object?>;
      expect(payload['bill_photo_key'], 'u/bill-m1.jpg');
      expect(payload['products'], hasLength(3));
    });
  });

  group('totals count a mix once', () {
    test('bahar summary and year comparison', () {
      final s = AccountsSummary.of(
        expenses: const [],
        sprays: [
          mixSpray('m1'),
          spray('s1', cycle: 'b1'),
        ],
        incomes: const [],
        areaAcres: 4,
        treeCount: null,
        baharCycleId: 'b1',
      );
      expect(s.byCategory, {'spray': 130000 + 240000});
      expect(s.expensePaise, 370000);

      final years = compareCycles(
        cycles: const [
          BaharCycle(
            id: 'b1',
            plotId: 'p1',
            bahar: 'ambia',
            seasonYear: 2026,
            status: 'active',
          ),
        ],
        expenses: const [],
        incomes: const [],
        sprays: [mixSpray('m1')],
        areaAcres: 4,
        treeCount: null,
      );
      expect(years.single.summary.byCategory['spray'], 130000);
    });

    test('the accounts ledger has one line for the mix with every name', () {
      final lines = buildLedger(
        labels: const ExportLabels(
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
          typeLabour: 'l',
        ),
        nameOf: (s) => s,
        expenses: const [],
        incomes: const [],
        sprays: [mixSpray('m1')],
      );
      expect(lines, hasLength(1));
      expect(lines.single.details, 'Captan 50 WP + Imida 17.8 SL + Kelthane');
      expect(lines.single.paise, -130000);
    });
  });

  group('checks per product', () {
    test('the ban check names the product it applies to', () {
      final found = checkSprayProducts(
        mixSpray('m1').products,
        sprayedOn: DateTime(2026, 11, 2),
        crop: _crop,
        rules: _rules,
      );
      expect(found[0], isEmpty);
      expect(found[1], isEmpty);
      expect(found[2].single.kind, SprayWarningKind.banned);
      expect(found[2].single.detail, 'S.O. 4294(E)');
    });

    test('the PHI check is on the product whose PHI runs past harvest', () {
      final found = checkSprayProducts(
        mixSpray('m1').products,
        sprayedOn: DateTime(2026, 11, 2),
        crop: _crop,
        rules: RestrictionList.empty(),
        plannedHarvest: DateTime.utc(2026, 11, 12),
      );
      expect(found[0], isEmpty); // 7 days: safe from 9 Nov
      expect(found[1].single.kind, SprayWarningKind.phiConflict);
      expect(found[1].single.safeFrom, DateTime.utc(2026, 11, 17));
    });
  });

  group('export record', () {
    test('strictest PHI, every ingredient, the worst label status', () {
      final rows = exportRecordRows(
        sprays: [mixSpray('m1')],
        baharCycleId: 'b1',
        crop: _crop,
        rules: _rules,
        labelIngredients: ['Captan', 'Imidacloprid'],
      );
      final r = rows.single;
      expect(r.phiEnd, DateTime(2026, 11, 17));
      expect(r.products, [captan, imida, kelthane]);
      expect(r.activeIngredient, 'Captan + Imidacloprid + Kelthane');
      expect(r.status, LabelStatus.banned);
    });

    test('a mix is listed only when every ingredient is on a label row', () {
      final listed = exportRecordRows(
        sprays: [
          mixSpray('m1', products: const [captan, imida]),
        ],
        baharCycleId: null,
        crop: _crop,
        rules: _rules,
        labelIngredients: ['captan', 'imidacloprid'],
      ).single;
      expect(listed.status, LabelStatus.listed);
      final check = exportRecordRows(
        sprays: [
          mixSpray(
            'm1',
            products: const [
              captan,
              SprayProduct(productName: 'Neem oil'),
            ],
          ),
        ],
        baharCycleId: null,
        crop: _crop,
        rules: _rules,
        labelIngredients: ['captan'],
      ).single;
      expect(check.status, LabelStatus.check);
    });

    test('a page holds as many products as it has lines', () {
      final pages = paginate(
        [1, 3, 1, 2, 1],
        first: 4,
        other: 4,
        weight: (n) => n,
      );
      expect(pages, [
        [1, 3],
        [1, 2, 1],
      ]);
      // A row bigger than a page still gets a page of its own.
      expect(paginate([9, 1], first: 4, other: 4, weight: (n) => n), [
        [9],
        [1],
      ]);
    });
  });
}
