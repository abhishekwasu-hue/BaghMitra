import '../../bahar/domain/bahar_cycle.dart';
import '../../field_work/domain/field_work.dart';
import '../../inputs/domain/field_records.dart';
import '../../spray/domain/spray_record.dart';
import 'accounts.dart';
import 'accounts_summary.dart';

/// One bahar cycle's results, and how they moved against the same bahar in an earlier season.
class CycleResult {
  const CycleResult({
    required this.cycle,
    required this.summary,
    required this.previous,
  });

  final BaharCycle cycle;
  final AccountsSummary summary;

  /// The same bahar in the latest earlier season on this block, if it has records.
  final CycleResult? previous;

  int? get expenseChangePaise => previous == null
      ? null
      : summary.expensePaise - previous!.summary.expensePaise;

  int? get profitChangePaise => previous == null
      ? null
      : summary.profitPaise - previous!.summary.profitPaise;
}

/// Year-on-year view for one plot (spec M2): each bahar cycle's cost and profit next to the
/// same bahar a season earlier. Pure, so it runs offline and is unit-tested with fixtures.
List<CycleResult> compareCycles({
  required List<BaharCycle> cycles,
  required List<Expense> expenses,
  required List<Income> incomes,
  List<SprayRecord> sprays = const [],
  List<InputRecord> inputs = const [],
  List<LabourRecord> labour = const [],
  required double areaAcres,
  required int? treeCount,
}) {
  final ordered = [...cycles]
    ..sort((a, b) {
      final byYear = b.seasonYear.compareTo(a.seasonYear);
      return byYear != 0 ? byYear : a.bahar.compareTo(b.bahar);
    });
  final summaries = {
    for (final c in ordered)
      c.id: AccountsSummary.of(
        expenses: expenses,
        incomes: incomes,
        sprays: sprays,
        inputs: inputs,
        labour: labour,
        areaAcres: areaAcres,
        treeCount: treeCount,
        baharCycleId: c.id,
      ),
  };
  final results = <String, CycleResult>{};
  // Oldest first, so a cycle can point at the result of the one before it.
  for (final c in ordered.reversed) {
    final earlier = ordered
        .where((o) => o.bahar == c.bahar && o.seasonYear < c.seasonYear)
        .map((o) => results[o.id])
        .nonNulls
        .firstOrNull;
    results[c.id] = CycleResult(
      cycle: c,
      summary: summaries[c.id]!,
      previous: earlier,
    );
  }
  return [for (final c in ordered) results[c.id]!];
}
