import 'package:bagmitra/features/accounts/domain/year_comparison.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../field_work/field_work_test.dart' show day;
import 'accounts_summary_test.dart' show exp, sale;

BaharCycle cycle(String id, String bahar, int year) => BaharCycle(
  id: id,
  plotId: 'p1',
  bahar: bahar,
  seasonYear: year,
  status: 'completed',
);

void main() {
  final cycles = [
    cycle('a25', 'ambia', 2025),
    cycle('a26', 'ambia', 2026),
    cycle('m26', 'mrig', 2026),
  ];

  List<CycleResult> compare() => compareCycles(
    cycles: cycles,
    expenses: [
      exp('e1', 'transport', 100000, cycle: 'a25'),
      exp('e2', 'transport', 150000, cycle: 'a26'),
      exp('e3', 'transport', 70000, cycle: 'm26'),
      exp('e4', 'transport', 999, cycle: 'other'),
    ],
    incomes: [
      sale('i1', cycle: 'a25', kg: 1000, rate: 100000, deductions: 0),
      sale('i2', cycle: 'a26', kg: 1000, rate: 300000, deductions: 0),
    ],
    labour: [day('l1', wage: 50000, cycle: 'a26')],
    areaAcres: 4,
    treeCount: null,
  );

  test('every bahar cycle gets its own cost, income and profit', () {
    final r = compare();
    final a26 = r.firstWhere((x) => x.cycle.id == 'a26');
    // costs: transport 1,500 + wages 500 = 2,000; sold 10 quintal x 3,000.
    expect(a26.summary.expensePaise, 200000);
    expect(a26.summary.netIncomePaise, 3000000);
    expect(a26.summary.profitPaise, 2800000);
    expect(
      r.firstWhere((x) => x.cycle.id == 'm26').summary.expensePaise,
      70000,
    );
  });

  test('newest season first, then by bahar', () {
    expect(compare().map((x) => x.cycle.id), ['a26', 'm26', 'a25']);
  });

  test('a cycle is compared with the same bahar in the previous season', () {
    final r = compare();
    final a26 = r.firstWhere((x) => x.cycle.id == 'a26');
    expect(a26.previous?.cycle.id, 'a25');
    // a25: cost 1,000, income 10,000 -> profit 9,000; a26 profit is 28,000.
    expect(a26.expenseChangePaise, 100000);
    expect(a26.profitChangePaise, 1900000);
    expect(r.firstWhere((x) => x.cycle.id == 'a25').previous, isNull);
    expect(r.firstWhere((x) => x.cycle.id == 'a25').profitChangePaise, isNull);
    // mrig has no earlier season, so nothing to compare with.
    expect(r.firstWhere((x) => x.cycle.id == 'm26').previous, isNull);
  });

  test(
    'compares with the latest earlier season even if a year was skipped',
    () {
      final r = compareCycles(
        cycles: [cycle('a24', 'ambia', 2024), cycle('a26', 'ambia', 2026)],
        expenses: [exp('e1', 'transport', 50000, cycle: 'a24')],
        incomes: const [],
        areaAcres: 1,
        treeCount: null,
      );
      expect(r.first.previous?.cycle.id, 'a24');
      expect(r.first.expenseChangePaise, -50000);
    },
  );

  test('no cycles means nothing to compare', () {
    expect(
      compareCycles(
        cycles: const [],
        expenses: const [],
        incomes: const [],
        areaAcres: 1,
        treeCount: null,
      ),
      isEmpty,
    );
  });
}
