import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/year_comparison.dart';

/// Season-by-season results for one block: each bahar cycle's cost, income and profit, with
/// the change against the same bahar a season earlier. Computed on the phone from local records.
class CompareScreen extends ConsumerWidget {
  const CompareScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    final bahars = ref.watch(baharOptionsProvider).value;
    final results = compareCycles(
      cycles: ref.watch(baharCyclesProvider(plotId)).value ?? const [],
      expenses: ref.watch(expensesProvider(plotId)).value ?? const [],
      incomes: ref.watch(incomesProvider(plotId)).value ?? const [],
      sprays: ref.watch(spraysProvider(plotId)).value ?? const [],
      inputs: ref.watch(inputsProvider(plotId)).value ?? const [],
      labour: ref.watch(labourProvider(plotId)).value ?? const [],
      areaAcres: plot?.areaAcres ?? 0,
      treeCount: plot?.treeCount,
    );
    String name(String bahar, int year) =>
        '${bahars?.baharLabel(bahar, lang) ?? bahar} ${formatYear(year, lang)}';
    String change(int paise) => paise == 0
        ? t.compareSame
        : paise > 0
        ? t.compareMore(formatPaise(paise, lang))
        : t.compareLess(formatPaise(-paise, lang));

    Widget row(
      String label,
      int paise, {
      int? changePaise,
      CycleResult? vs,
      bool upIsGood = true,
    }) {
      final good = changePaise == null || changePaise == 0
          ? null
          : (changePaise > 0) == upIsGood;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BmSpace.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: BmType.body)),
                Text(formatPaise(paise, lang), style: BmType.section),
              ],
            ),
            if (vs != null && changePaise != null)
              Text(
                t.compareVs(
                  name(vs.cycle.bahar, vs.cycle.seasonYear),
                  change(changePaise),
                ),
                style: BmType.label.copyWith(
                  color: good == null
                      ? c.inkMuted
                      : good
                      ? c.brand
                      : c.danger,
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${t.compareTitle} · ${plot?.name ?? ''}')),
      body: results.isEmpty
          ? EmptyState(glyph: BmGlyph.ledger, message: t.compareEmpty)
          : ListView(
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                for (final r in results) ...[
                  BmCard(
                    elevated: false,
                    radius: BmRadius.card,
                    padding: const EdgeInsets.all(BmSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name(r.cycle.bahar, r.cycle.seasonYear),
                          style: BmType.section.copyWith(color: c.brand),
                        ),
                        const SizedBox(height: BmSpace.xs),
                        row(
                          t.accountsExpenses,
                          r.summary.expensePaise,
                          changePaise: r.expenseChangePaise,
                          vs: r.previous,
                          upIsGood: false,
                        ),
                        row(t.accountsIncome, r.summary.netIncomePaise),
                        row(
                          t.accountsProfit,
                          r.summary.profitPaise,
                          changePaise: r.profitChangePaise,
                          vs: r.previous,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BmSpace.sm),
                ],
              ],
            ),
    );
  }
}
