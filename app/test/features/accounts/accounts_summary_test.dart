import 'package:bagmitra/features/accounts/domain/accounts.dart';
import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Expense exp(String id, String category, int paise, {String? cycle}) => Expense(
  id: id,
  plotId: 'p1',
  baharCycleId: cycle,
  spentOn: DateTime(2026, 10, 10),
  category: category,
  amountPaise: paise,
);

Income sale(
  String id, {
  double kg = 2500,
  int rate = 320000,
  int deductions = 50000,
  String status = 'partial',
  int paid = 5000000,
  String? cycle,
}) => Income(
  id: id,
  plotId: 'p1',
  baharCycleId: cycle,
  soldOn: DateTime(2027, 1, 20),
  buyerName: 'Kalmeshwar trader',
  quantityKg: kg,
  ratePaisePerQuintal: rate,
  deductionsPaise: deductions,
  paymentStatus: status,
  paidPaise: paid,
);

void main() {
  test('sale amounts: quintal rate, deductions and dues are exact paise', () {
    final s = sale('i1');
    // 2500 kg = 25 quintal x ₹3,200 = ₹80,000; minus ₹500 deductions.
    expect(s.grossPaise, 8000000);
    expect(s.netPaise, 7950000);
    expect(s.duesPaise, 2950000);
    expect(sale('i2', status: 'paid', paid: 0).duesPaise, 0);
    expect(sale('i3', kg: 0.5, rate: 333).grossPaise, 2); // rounds half up
    expect(sale('i4', paid: 99999999).duesPaise, 0); // overpaid never negative
  });

  test('bahar summary: totals, per acre, per tree, per tonne, profit', () {
    final summary = AccountsSummary.of(
      expenses: [
        exp('e1', 'labour', 1500000, cycle: 'b1'),
        exp('e2', 'fertiliser', 2500000, cycle: 'b1'),
        exp('e3', 'labour', 500000, cycle: 'b1'),
        exp('e4', 'labour', 999900, cycle: 'b2'),
      ],
      incomes: [
        sale('i1', cycle: 'b1'),
        sale('i5', cycle: 'b2'),
      ],
      areaAcres: 4,
      treeCount: 400,
      baharCycleId: 'b1',
    );
    expect(summary.expensePaise, 4500000);
    expect(summary.byCategory, {'labour': 2000000, 'fertiliser': 2500000});
    expect(summary.netIncomePaise, 7950000);
    expect(summary.profitPaise, 3450000);
    expect(summary.costPerAcrePaise, 1125000);
    expect(summary.costPerTreePaise, 11250);
    expect(summary.costPerTonnePaise, 1800000); // 2.5 t
    expect(summary.duesPaise, 2950000);
    expect(summary.harvestKg, 2500);
  });

  test('per-unit figures are null when the unit is unknown or zero', () {
    final summary = AccountsSummary.of(
      expenses: [exp('e1', 'labour', 100)],
      incomes: const [],
      areaAcres: 0,
      treeCount: null,
    );
    expect(summary.costPerAcrePaise, isNull);
    expect(summary.costPerTreePaise, isNull);
    expect(summary.costPerTonnePaise, isNull);
    expect(summary.profitPaise, -100);
  });

  test('payloads match the API contract', () {
    final e = exp('e1', 'labour', 150000, cycle: 'b1');
    expect(e.toPayload(), {
      'plot_id': 'p1',
      'bahar_cycle_id': 'b1',
      'spent_on': '2026-10-10',
      'category': 'labour',
      'amount_paise': 150000,
      'note': null,
    });
    expect(Expense.fromPayload('e1', e.toPayload()).toPayload(), e.toPayload());
    final s = sale('i1');
    expect(s.toPayload()['rate_paise_per_quintal'], 320000);
    expect(s.toPayload()['sold_on'], '2027-01-20');
    expect(Income.fromPayload('i1', s.toPayload()).toPayload(), s.toPayload());
  });
}
