import '../../inputs/domain/field_records.dart';
import '../../spray/domain/spray_record.dart';
import 'accounts.dart';

/// Cost and profit for one plot, optionally narrowed to one bahar (spec M2). Pure, so it
/// runs offline on the phone and is unit-tested with fixtures.
class AccountsSummary {
  const AccountsSummary({
    required this.expensePaise,
    required this.byCategory,
    required this.netIncomePaise,
    required this.duesPaise,
    required this.harvestKg,
    required this.costPerAcrePaise,
    required this.costPerTreePaise,
    required this.costPerTonnePaise,
  });

  factory AccountsSummary.of({
    required List<Expense> expenses,
    required List<Income> incomes,
    List<SprayRecord> sprays = const [],
    List<InputRecord> inputs = const [],
    required double areaAcres,
    required int? treeCount,
    String? baharCycleId,
  }) {
    bool inScope(String? cycle) =>
        baharCycleId == null || cycle == baharCycleId;
    final spent = expenses.where((e) => inScope(e.baharCycleId));
    final sold = incomes.where((i) => inScope(i.baharCycleId)).toList();
    final byCategory = <String, int>{};
    for (final e in spent) {
      byCategory.update(
        e.category,
        (v) => v + e.amountPaise,
        ifAbsent: () => e.amountPaise,
      );
    }
    // Spray costs are recorded in the spray log (not as expenses), under "spray".
    for (final sp in sprays.where((s) => inScope(s.baharCycleId))) {
      if (sp.costPaise > 0) {
        byCategory.update(
          'spray',
          (v) => v + sp.costPaise,
          ifAbsent: () => sp.costPaise,
        );
      }
    }
    // Input costs are recorded in the input records, under their kind.
    for (final i in inputs.where((i) => inScope(i.baharCycleId))) {
      if (i.costPaise > 0) {
        byCategory.update(
          i.kind,
          (v) => v + i.costPaise,
          ifAbsent: () => i.costPaise,
        );
      }
    }
    final total = byCategory.values.fold(0, (a, b) => a + b);
    final kg = sold.fold(0.0, (a, i) => a + i.quantityKg);
    int? per(num units) => units > 0 ? (total / units).round() : null;
    return AccountsSummary(
      expensePaise: total,
      byCategory: byCategory,
      netIncomePaise: sold.fold(0, (a, i) => a + i.netPaise),
      duesPaise: sold.fold(0, (a, i) => a + i.duesPaise),
      harvestKg: kg,
      costPerAcrePaise: per(areaAcres),
      costPerTreePaise: per(treeCount ?? 0),
      costPerTonnePaise: per(kg / 1000),
    );
  }

  final int expensePaise;
  final Map<String, int> byCategory;
  final int netIncomePaise;
  final int duesPaise;
  final double harvestKg;
  final int? costPerAcrePaise;
  final int? costPerTreePaise;
  final int? costPerTonnePaise;

  int get profitPaise => netIncomePaise - expensePaise;
}
