import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../export/presentation/share_accounts.dart';
import '../domain/accounts_summary.dart';
import 'fair_price_note.dart';

/// "Accounts" for one block: cost, income, profit and buyer dues, overall or per bahar.
/// Computed on the phone from local records, so it works offline.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String? _cycle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final id = widget.plotId;
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == id)
        .firstOrNull;
    final cycles = ref.watch(baharCyclesProvider(id)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    final expenses = ref.watch(expensesProvider(id)).value ?? const [];
    final incomes = ref.watch(incomesProvider(id)).value ?? const [];
    final cats = ref.watch(expenseCategoriesProvider).value ?? const [];
    final sprays = ref.watch(spraysProvider(id)).value ?? const [];
    final inputs = ref.watch(inputsProvider(id)).value ?? const [];
    final labour = ref.watch(labourProvider(id)).value ?? const [];
    final kinds = ref.watch(inputKindsProvider).value;
    final s = AccountsSummary.of(
      expenses: expenses,
      incomes: incomes,
      sprays: sprays,
      inputs: inputs,
      labour: labour,
      areaAcres: plot?.areaAcres ?? 0,
      treeCount: plot?.treeCount,
      baharCycleId: _cycle,
    );
    String money(int? p) => p == null ? '—' : formatPaise(p, lang);
    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: BmType.body)),
          Text(value, style: BmType.section.copyWith(color: color ?? c.ink)),
        ],
      ),
    );
    // Older or synced rows may use a category that moved to input kinds or to the
    // labour register.
    String categoryLabel(String slug) => slug == 'labour'
        ? t.labourTitle
        : [
                ...cats,
                ...?kinds?.kinds,
              ].where((x) => x.slug == slug).firstOrNull?.label(lang) ??
              slug;
    final inScope = [
      for (final e in expenses)
        if (_cycle == null || e.baharCycleId == _cycle)
          (
            e.spentOn,
            categoryLabel(e.category),
            '−${money(e.amountPaise)}',
            null,
          ),
      for (final i in incomes)
        if (_cycle == null || i.baharCycleId == _cycle)
          (
            i.soldOn,
            t.saleBy(i.buyerName, formatDecimal(i.quantityKg, lang)),
            '+${money(i.netPaise)}',
            i,
          ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.accountsTitle} · ${plot?.name ?? ''}'),
        actions: [
          IconButton(
            tooltip: t.exportSharePdf,
            onPressed: () => shareAccountsPdf(context, ref, id),
            icon: Icon(Icons.picture_as_pdf_outlined, color: c.brand),
          ),
          IconButton(
            tooltip: t.exportShare,
            onPressed: () => shareAccountsCsv(context, ref, id),
            icon: Icon(Icons.ios_share, color: c.brand),
          ),
          IconButton(
            tooltip: t.compareTitle,
            onPressed: () => context.push(Routes.compare(id)),
            icon: Icon(Icons.compare_arrows, color: c.brand),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(BmSpace.lg, 0, BmSpace.lg, 120),
        children: [
          Wrap(
            spacing: BmSpace.xs,
            children: [
              ChoiceChip(
                label: Text(t.allBahars),
                selected: _cycle == null,
                onSelected: (_) => setState(() => _cycle = null),
              ),
              for (final cy in cycles)
                ChoiceChip(
                  label: Text(
                    '${bahars?.baharLabel(cy.bahar, lang) ?? cy.bahar} '
                    '${formatYear(cy.seasonYear, lang)}',
                  ),
                  selected: _cycle == cy.id,
                  onSelected: (_) => setState(() => _cycle = cy.id),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.sm),
          BmCard(
            elevated: false,
            radius: BmRadius.card,
            padding: const EdgeInsets.all(BmSpace.md),
            child: Column(
              children: [
                row(t.accountsExpenses, money(s.expensePaise)),
                row(t.accountsIncome, money(s.netIncomePaise)),
                row(
                  t.accountsProfit,
                  money(s.profitPaise),
                  color: s.profitPaise < 0 ? c.danger : c.brand,
                ),
                row(t.accountsDues, money(s.duesPaise)),
                Divider(color: c.line),
                row(t.costPerAcre, money(s.costPerAcrePaise)),
                row(t.costPerTree, money(s.costPerTreePaise)),
                row(t.costPerTonne, money(s.costPerTonnePaise)),
              ],
            ),
          ),
          const SizedBox(height: BmSpace.sm),
          if (inScope.isEmpty) EmptyNote(t.accountsEmpty),
          for (final (date, label, amount, sale) in inScope)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label, style: BmType.body),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatDate(date, lang)),
                  if (sale != null && plot != null)
                    FairPriceNote(
                      crop: plot.crop,
                      soldOn: sale.soldOn,
                      ratePaisePerQuintal: sale.ratePaisePerQuintal,
                    ),
                ],
              ),
              trailing: Text(amount, style: BmType.bodyStrong),
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton(
            onPressed: () => context.push(Routes.addExpense(id)),
            child: Text(t.addExpense),
          ),
          FilledButton(
            onPressed: () => context.push(Routes.addSale(id)),
            child: Text(t.addSale),
          ),
        ],
      ),
    );
  }
}
