import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../voice/domain/voice_note.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/accounts.dart';

String? _rupeesRequired(AppLocalizations t, String? v) =>
    (parseRupeesToPaise(v ?? '') ?? 0) > 0 ? null : t.invalidNumber;

String? _rupeesOptional(AppLocalizations t, String? v) =>
    (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
    ? null
    : t.invalidNumber;

Future<void> _savedAndBack(BuildContext context, String plotId) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
  );
  // Opened directly (e.g. from a notification) there is nothing to pop.
  context.canPop() ? context.pop() : context.go(Routes.accounts(plotId));
}

/// Records one expense for a block, optionally against one of its bahars.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  String? _cycle;

  /// A spoken note fills the note field; a number in it becomes the amount when that is empty.
  /// Nothing is saved until the grower taps Save.
  void _heard(String text, {required bool isFinal}) {
    final voice = parseVoiceNote(text);
    _note.text = voice.text;
    final paise = voice.amountPaise;
    if (isFinal && paise != null && _amount.text.trim().isEmpty) {
      _amount.text = amountFieldText(paise);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _category == null) return;
    final repo = ref.read(accountsRepositoryProvider);
    final today = ref.read(clockProvider)();
    await repo.saveExpense(
      Expense(
        id: repo.newId(),
        plotId: widget.plotId,
        baharCycleId: _cycle,
        spentOn: DateTime(today.year, today.month, today.day),
        category: _category!,
        amountPaise: parseRupeesToPaise(_amount.text)!,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
    if (mounted) await _savedAndBack(context, widget.plotId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final cats = ref.watch(expenseCategoriesProvider).value ?? const [];
    final cycles =
        ref.watch(baharCyclesProvider(widget.plotId)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    final label = BmType.label.copyWith(color: c.inkMuted, fontSize: 14);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(
          t.addExpense,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            Text(t.expenseCategory, style: label),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final cat in cats)
                  ChoiceChip(
                    label: Text(cat.label(lang), style: BmType.bodyStrong),
                    selected: _category == cat.slug,
                    selectedColor: c.nowTint,
                    onSelected: (_) => setState(() => _category = cat.slug),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.md),
            TextFormField(
              key: const Key('expense-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: t.amountRupees),
              validator: (v) => _rupeesRequired(t, v),
            ),
            if (cycles.isNotEmpty) ...[
              const SizedBox(height: BmSpace.md),
              Wrap(
                spacing: BmSpace.xs,
                children: [
                  for (final cy in cycles)
                    ChoiceChip(
                      label: Text(
                        '${bahars?.baharLabel(cy.bahar, lang) ?? cy.bahar} '
                        '${formatYear(cy.seasonYear, lang)}',
                      ),
                      selected: _cycle == cy.id,
                      onSelected: (on) =>
                          setState(() => _cycle = on ? cy.id : null),
                    ),
                ],
              ),
            ],
            const SizedBox(height: BmSpace.md),
            TextFormField(
              key: const Key('expense-note'),
              controller: _note,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: t.noteOptional,
                suffixIcon: VoiceMicButton(onResult: _heard),
              ),
            ),
            const SizedBox(height: BmSpace.lg),
            FilledButton(
              onPressed: _category == null ? null : _save,
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Records one sale: buyer, kg, rate per quintal, deductions and what was received.
/// Payment status follows from the amounts, so the grower never has to pick it.
class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final _form = GlobalKey<FormState>();
  final _buyer = TextEditingController();
  final _kg = TextEditingController();
  final _rate = TextEditingController();
  final _deductions = TextEditingController();
  final _paid = TextEditingController();

  @override
  void dispose() {
    for (final c in [_buyer, _kg, _rate, _deductions, _paid]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(accountsRepositoryProvider);
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final paid = parseRupeesToPaise(_paid.text) ?? 0;
    final draft = Income(
      id: repo.newId(),
      plotId: widget.plotId,
      soldOn: today,
      buyerName: _buyer.text.trim(),
      quantityKg: double.parse(_kg.text.trim()),
      ratePaisePerQuintal: parseRupeesToPaise(_rate.text)!,
      deductionsPaise: parseRupeesToPaise(_deductions.text) ?? 0,
      paymentStatus: 'pending',
      paidPaise: paid,
    );
    final status = paid == 0
        ? 'pending'
        : paid >= draft.netPaise
        ? 'paid'
        : 'partial';
    await repo.saveIncome(
      Income(
        id: draft.id,
        plotId: draft.plotId,
        soldOn: today,
        buyerName: draft.buyerName,
        quantityKg: draft.quantityKg,
        ratePaisePerQuintal: draft.ratePaisePerQuintal,
        deductionsPaise: draft.deductionsPaise,
        paymentStatus: status,
        paidPaise: paid,
        paidOn: paid > 0 ? today : null,
      ),
    );
    if (mounted) await _savedAndBack(context, widget.plotId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    const gap = SizedBox(height: BmSpace.md);
    const money = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(t.addSale, style: BmType.section.copyWith(color: c.brand)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('sale-buyer'),
              controller: _buyer,
              decoration: InputDecoration(labelText: t.saleBuyer),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.fieldRequired : null,
            ),
            gap,
            TextFormField(
              key: const Key('sale-kg'),
              controller: _kg,
              keyboardType: money,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(labelText: t.saleKg),
              validator: (v) => (double.tryParse(v?.trim() ?? '') ?? 0) > 0
                  ? null
                  : t.invalidNumber,
            ),
            gap,
            TextFormField(
              key: const Key('sale-rate'),
              controller: _rate,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.saleRate),
              validator: (v) => _rupeesRequired(t, v),
            ),
            gap,
            TextFormField(
              controller: _deductions,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.saleDeductions),
              validator: (v) => _rupeesOptional(t, v),
            ),
            gap,
            TextFormField(
              key: const Key('sale-paid'),
              controller: _paid,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.salePaid),
              validator: (v) => _rupeesOptional(t, v),
            ),
            const SizedBox(height: BmSpace.lg),
            FilledButton(onPressed: _save, child: Text(t.save)),
          ],
        ),
      ),
    );
  }
}
