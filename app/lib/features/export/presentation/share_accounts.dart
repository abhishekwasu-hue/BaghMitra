import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/domain/accounts.dart';
import '../../accounts/domain/accounts_summary.dart';
import '../../field_work/domain/field_work.dart';
import '../../inputs/domain/field_records.dart';
import '../../spray/domain/spray_record.dart';
import '../data/pdf_builder.dart';
import '../domain/accounts_csv.dart';
import '../domain/report_pages.dart';
import 'report_page.dart';

/// One block's records read from local storage, with the grower's language applied.
class _Export {
  _Export(this.context, this.ref, this.plotId)
    : t = AppLocalizations.of(context),
      lang = Localizations.localeOf(context).languageCode {
    final plot = ref
        .read(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    plotName = plot?.name ?? plotId;
    expenses = ref.read(expensesProvider(plotId)).value ?? const [];
    incomes = ref.read(incomesProvider(plotId)).value ?? const [];
    sprays = ref.read(spraysProvider(plotId)).value ?? const [];
    inputs = ref.read(inputsProvider(plotId)).value ?? const [];
    labour = ref.read(labourProvider(plotId)).value ?? const [];
    summary = AccountsSummary.of(
      expenses: expenses,
      incomes: incomes,
      sprays: sprays,
      inputs: inputs,
      labour: labour,
      areaAcres: plot?.areaAcres ?? 0,
      treeCount: plot?.treeCount,
    );
    final names = {
      for (final o in [
        ...?ref.read(expenseCategoriesProvider).value,
        ...?ref.read(inputKindsProvider).value?.kinds,
        ...?ref.read(fieldWorkOptionsProvider).value?.tasks,
      ])
        o.slug: o.label(lang),
      'labour': t.labourTitle,
    };
    nameOf = (slug) => names[slug] ?? slug;
    labels = ExportLabels(
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
    );
  }

  final BuildContext context;
  final WidgetRef ref;
  final String plotId;
  final AppLocalizations t;
  final String lang;
  late final String plotName;
  late final List<Expense> expenses;
  late final List<Income> incomes;
  late final List<SprayRecord> sprays;
  late final List<InputRecord> inputs;
  late final List<LabourRecord> labour;
  late final AccountsSummary summary;
  late final String Function(String slug) nameOf;
  late final ExportLabels labels;

  String fileName(String extension) {
    final today = ref.read(clockProvider)();
    final day =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return 'bagmitra-accounts-$plotId-$day.$extension';
  }

  List<LedgerLine> get ledger => buildLedger(
    labels: labels,
    nameOf: nameOf,
    expenses: expenses,
    incomes: incomes,
    sprays: sprays,
    inputs: inputs,
    labour: labour,
  );
}

/// Builds the block's accounts as a CSV in the grower's language and opens the share sheet.
/// Everything comes from local records, so it works offline.
Future<void> shareAccountsCsv(
  BuildContext context,
  WidgetRef ref,
  String plotId,
) async {
  final e = _Export(context, ref, plotId);
  final csv = buildAccountsCsv(
    plotName: e.plotName,
    labels: e.labels,
    nameOf: e.nameOf,
    summary: e.summary,
    expenses: e.expenses,
    incomes: e.incomes,
    sprays: e.sprays,
    inputs: e.inputs,
    labour: e.labour,
  );
  await ref
      .read(fileSharerProvider)
      .share(
        fileName: e.fileName('csv'),
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
      );
}

/// Draws the block's accounts as report pages with Flutter's own text engine (so Marathi is
/// shaped correctly), wraps them in a PDF and opens the share sheet. Works offline.
Future<void> shareAccountsPdf(
  BuildContext context,
  WidgetRef ref,
  String plotId,
) async {
  final e = _Export(context, ref, plotId);
  final view = View.of(context);
  final pages = paginateLedger(
    e.ledger,
    firstPageRows: reportFirstPageRows,
    otherPageRows: reportOtherPageRows,
  );
  final summary = [
    (e.labels.expenses, e.summary.expensePaise),
    (e.labels.income, e.summary.netIncomePaise),
    (e.labels.profit, e.summary.profitPaise),
    (e.labels.dues, e.summary.duesPaise),
  ];
  final pngs = <Uint8List>[
    for (var i = 0; i < pages.length; i++)
      await renderWidgetToPng(
        ReportPage(
          title: '${e.plotName} · ${e.labels.title}',
          lang: e.lang,
          labels: e.labels,
          lines: pages[i],
          pageLabel: '${i + 1} / ${pages.length}',
          summary: i == 0 ? summary : null,
        ),
        view: view,
        size: reportPageSize,
      ),
  ];
  await ref
      .read(fileSharerProvider)
      .share(
        fileName: e.fileName('pdf'),
        bytes: await pdfFromPngPages(pngs),
        mimeType: 'application/pdf',
      );
}
