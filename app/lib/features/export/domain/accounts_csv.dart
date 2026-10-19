import '../../../core/formatting.dart';
import '../../accounts/domain/accounts.dart';
import '../../accounts/domain/accounts_summary.dart';
import '../../bahar/domain/bahar_cycle.dart';
import '../../field_work/domain/field_work.dart';
import '../../inputs/domain/field_records.dart';
import '../../spray/domain/spray_record.dart';

/// Column and row names for an export, in the grower's language (built from l10n by the UI).
class ExportLabels {
  const ExportLabels({
    required this.title,
    required this.date,
    required this.type,
    required this.details,
    required this.amount,
    required this.expenses,
    required this.income,
    required this.profit,
    required this.dues,
    required this.typeExpense,
    required this.typeSale,
    required this.typeSpray,
    required this.typeInput,
    required this.typeLabour,
    this.kg = 'kg',
  });

  final String title;
  final String date;
  final String type;
  final String details;
  final String amount;
  final String expenses;
  final String income;
  final String profit;
  final String dues;
  final String typeExpense;
  final String typeSale;
  final String typeSpray;
  final String typeInput;
  final String typeLabour;
  final String kg;
}

/// One block's accounts as a spreadsheet-readable CSV: a summary, then every record as a
/// signed line (costs negative, sales positive), oldest first. Pure and offline.
///
/// The text starts with a byte-order mark so Excel reads Marathi / Hindi as UTF-8. Money is
/// whole paise formatted without floating point; text cells that a spreadsheet would run as a
/// formula (`= + - @`) are prefixed with an apostrophe so grower-typed text cannot execute.
String buildAccountsCsv({
  required String plotName,
  required ExportLabels labels,
  required String Function(String slug) nameOf,
  required AccountsSummary summary,
  required List<Expense> expenses,
  required List<Income> incomes,
  List<SprayRecord> sprays = const [],
  List<InputRecord> inputs = const [],
  List<LabourRecord> labour = const [],
}) {
  String join(Iterable<String?> parts) =>
      parts.where((p) => p != null && p.isNotEmpty).join(' · ');
  String kgText(double kg) =>
      kg == kg.roundToDouble() ? '${kg.round()}' : '$kg';

  final ledger = <(DateTime, String, String, int)>[
    for (final e in expenses)
      (
        e.spentOn,
        labels.typeExpense,
        join([nameOf(e.category), e.note]),
        -e.amountPaise,
      ),
    for (final i in incomes)
      (
        i.soldOn,
        labels.typeSale,
        join([i.buyerName, '${kgText(i.quantityKg)} ${labels.kg}']),
        i.netPaise,
      ),
    for (final s in sprays)
      (s.sprayedOn, labels.typeSpray, s.productName, -s.costPaise),
    for (final i in inputs)
      (
        i.appliedOn,
        labels.typeInput,
        join([i.productName, nameOf(i.kind)]),
        -i.costPaise,
      ),
    for (final l in labour)
      (
        l.workedOn,
        labels.typeLabour,
        join([l.workerName, l.task == null ? null : nameOf(l.task!)]),
        -l.wagePaise,
      ),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  final rows = <List<String>>[
    ['$plotName · ${labels.title}'],
    [],
    [labels.expenses, plainRupees(summary.expensePaise)],
    [labels.income, plainRupees(summary.netIncomePaise)],
    [labels.profit, plainRupees(summary.profitPaise)],
    [labels.dues, plainRupees(summary.duesPaise)],
    [],
    [labels.date, labels.type, labels.details, labels.amount],
    for (final (date, type, details, paise) in ledger)
      [BaharCycle.isoDate(date), type, _defuse(details), plainRupees(paise)],
  ];
  return '\u{feff}${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
}

String _defuse(String text) =>
    text.isNotEmpty && '=+-@\t\r'.contains(text[0]) ? "'$text" : text;

String _cell(String value) => value.contains(RegExp(r'[",\r\n]'))
    ? '"${value.replaceAll('"', '""')}"'
    : value;
