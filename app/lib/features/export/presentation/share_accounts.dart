import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/domain/accounts_summary.dart';
import '../domain/accounts_csv.dart';

/// Builds the block's accounts as a CSV in the grower's language and opens the share sheet.
/// Everything comes from local records, so it works offline.
Future<void> shareAccountsCsv(
  BuildContext context,
  WidgetRef ref,
  String plotId,
) async {
  final t = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final plot = ref
      .read(plotsProvider)
      .value
      ?.where((p) => p.id == plotId)
      .firstOrNull;
  final expenses = ref.read(expensesProvider(plotId)).value ?? const [];
  final incomes = ref.read(incomesProvider(plotId)).value ?? const [];
  final sprays = ref.read(spraysProvider(plotId)).value ?? const [];
  final inputs = ref.read(inputsProvider(plotId)).value ?? const [];
  final labour = ref.read(labourProvider(plotId)).value ?? const [];
  final names = {
    for (final o in [
      ...?ref.read(expenseCategoriesProvider).value,
      ...?ref.read(inputKindsProvider).value?.kinds,
      ...?ref.read(fieldWorkOptionsProvider).value?.tasks,
    ])
      o.slug: o.label(lang),
    'labour': t.labourTitle,
  };
  final csv = buildAccountsCsv(
    plotName: plot?.name ?? plotId,
    labels: ExportLabels(
      title: t.accountsTitle,
      date: t.exportDate,
      type: t.exportType,
      details: t.exportDetails,
      amount: t.amountRupees,
      expenses: t.accountsExpenses,
      income: t.accountsIncome,
      profit: t.accountsProfit,
      dues: t.accountsDues,
      typeExpense: t.exportTypeExpense,
      typeSale: t.exportTypeSale,
      typeSpray: t.exportTypeSpray,
      typeInput: t.exportTypeInput,
      typeLabour: t.exportTypeLabour,
      kg: t.exportKg,
    ),
    nameOf: (slug) => names[slug] ?? slug,
    summary: AccountsSummary.of(
      expenses: expenses,
      incomes: incomes,
      sprays: sprays,
      inputs: inputs,
      labour: labour,
      areaAcres: plot?.areaAcres ?? 0,
      treeCount: plot?.treeCount,
    ),
    expenses: expenses,
    incomes: incomes,
    sprays: sprays,
    inputs: inputs,
    labour: labour,
  );
  final today = ref.read(clockProvider)();
  final day =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
  await ref
      .read(fileSharerProvider)
      .share(
        fileName: 'bagmitra-accounts-$plotId-$day.csv',
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
      );
}
