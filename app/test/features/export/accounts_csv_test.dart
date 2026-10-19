import 'package:bagmitra/core/formatting.dart';
import 'package:bagmitra/features/accounts/domain/accounts.dart';
import 'package:bagmitra/features/accounts/domain/accounts_summary.dart';
import 'package:bagmitra/features/export/domain/accounts_csv.dart';
import 'package:bagmitra/features/field_work/domain/field_work.dart';
import 'package:bagmitra/features/inputs/domain/field_records.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../accounts/accounts_summary_test.dart' show exp, sale;
import '../field_work/field_work_test.dart' show day;

const labels = ExportLabels(
  title: 'Accounts',
  date: 'Date',
  type: 'Type',
  details: 'Details',
  amount: 'Amount (₹)',
  expenses: 'Expenses',
  income: 'Income',
  profit: 'Profit',
  dues: 'Buyers owe',
  typeExpense: 'Expense',
  typeSale: 'Sale',
  typeSpray: 'Spray',
  typeInput: 'Input',
  typeLabour: 'Labour',
);

String csv({
  List<Expense> expenses = const [],
  List<Income> incomes = const [],
  List<SprayRecord> sprays = const [],
  List<InputRecord> inputs = const [],
  List<LabourRecord> labour = const [],
}) => buildAccountsCsv(
  plotName: 'Bag 1',
  labels: labels,
  nameOf: (slug) => slug,
  summary: AccountsSummary.of(
    expenses: expenses,
    incomes: incomes,
    sprays: sprays,
    inputs: inputs,
    labour: labour,
    areaAcres: 4,
    treeCount: null,
  ),
  expenses: expenses,
  incomes: incomes,
  sprays: sprays,
  inputs: inputs,
  labour: labour,
);

LabourRecord worker(String id, String name) => LabourRecord(
  id: id,
  plotId: 'p1',
  workerName: name,
  workedOn: DateTime(2026, 11, 5),
  task: 'weeding',
  wagePaise: 100,
);

List<String> lines(String s) =>
    s.replaceFirst('\u{feff}', '').trim().split('\r\n');

void main() {
  test('plain rupees are exact: no float, no grouping, no symbol', () {
    expect(plainRupees(0), '0.00');
    expect(plainRupees(5), '0.05');
    expect(plainRupees(150000), '1500.00');
    expect(plainRupees(7950000), '79500.00');
    expect(plainRupees(-1250), '-12.50');
  });

  test('starts with a byte-order mark so Excel reads Marathi text', () {
    expect(csv().startsWith('\u{feff}'), isTrue);
  });

  test('summary then ledger with signed amounts, oldest first', () {
    final out = lines(
      csv(
        expenses: [exp('e1', 'transport', 150000)], // 10 Oct 2026
        incomes: [
          sale('i1', kg: 1000, rate: 100000, deductions: 0),
        ], // 20 Jan 2027
        labour: [day('l1')], // 5 Nov 2026, wage 400
      ),
    );
    expect(out.first, 'Bag 1 · Accounts');
    expect(out, contains('Expenses,1900.00'));
    expect(out, contains('Income,10000.00'));
    expect(out, contains('Profit,8100.00'));
    final header = out.indexOf('Date,Type,Details,Amount (₹)');
    expect(out.sublist(header + 1), [
      '2026-10-10,Expense,transport,-1500.00',
      '2026-11-05,Labour,Sunita · weeding,-400.00',
      '2027-01-20,Sale,Kalmeshwar trader · 1000 kg,10000.00',
    ]);
  });

  test('spray and input costs appear, zero-cost rows too (it is a record)', () {
    final out = lines(
      csv(
        sprays: [
          SprayRecord(
            id: 's1',
            plotId: 'p1',
            sprayedOn: DateTime(2026, 11),
            productName: 'Neem oil',
            costPaise: 25000,
          ),
        ],
        inputs: [
          InputRecord(
            id: 'i1',
            plotId: 'p1',
            appliedOn: DateTime(2026, 11, 2),
            kind: 'fertiliser',
            productName: 'Urea',
          ),
        ],
      ),
    );
    expect(out, contains('2026-11-01,Spray,Neem oil,-250.00'));
    expect(out, contains('2026-11-02,Input,Urea · fertiliser,0.00'));
  });

  test('fields with commas, quotes or line breaks are quoted', () {
    final out = csv(
      expenses: [
        Expense(
          id: 'e1',
          plotId: 'p1',
          spentOn: DateTime(2026, 10, 10),
          category: 'other',
          amountPaise: 100,
          note: 'tape, "red"\nroll',
        ),
      ],
    );
    expect(out, contains('"other · tape, ""red""\nroll"'));
  });

  test('text that a spreadsheet would run as a formula is defused', () {
    final out = lines(
      csv(
        labour: [
          worker('l1', '=HYPERLINK("http://x")'),
          worker('l2', '@SUM(A1)'),
          worker('l3', '-cmd'),
        ],
      ),
    );
    final rows = out.where((l) => l.contains(',Labour,')).toList();
    expect(rows, hasLength(3));
    for (final r in rows) {
      final details = r.split(',Labour,').last;
      expect(details.startsWith("'") || details.startsWith('"\''), isTrue);
    }
  });
}
