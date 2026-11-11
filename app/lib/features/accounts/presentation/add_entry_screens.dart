import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bills/domain/bill_reading.dart';
import '../../bills/presentation/bill_photo_field.dart';
import '../../voice/domain/voice_note.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/accounts.dart';
import 'fair_price_note.dart';

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

/// Records one expense for a block, optionally against one of its bahars, with an optional
/// bill photo kept with it that can fill the empty fields (OPEN_QUESTIONS Q136).
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with BillPhotoForm<AddExpenseScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  String? _cycle;

  /// Null: today (the default until the grower or a bill picks one).
  DateTime? _date;

  DateTime get _today {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  /// "बिलावरून भरा": the bill total or a picked line fills only what is still empty. The
  /// category is left to the grower: the bill's lines name products, not these categories.
  Future<void> _fillFromBill() async {
    final t = AppLocalizations.of(context);
    final bill = await readBill();
    if (bill == null || !mounted) return;
    if (bill.items.isEmpty && bill.totalRs == null) return showBillUnsure();
    final pick = await showBillPickSheet(context, bill, withTotal: true);
    if (pick == null || !mounted) return;
    final today = _today;
    final r = expenseFill(
      item: pick.item,
      bill: bill,
      billLabel: billLabel(t, bill),
      current: {
        BillField.amount: _amount.text.trim(),
        BillField.note: _note.text.trim(),
      },
      dateIsDefault: _date == null,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 1),
    );
    if (r.fill[BillField.amount] case final v?) _amount.text = v;
    if (r.fill[BillField.note] case final v?) _note.text = v;
    if (r.date != null) _date = r.date;
    showBillFilled(bill, [...r.fill.keys, if (r.date != null) BillField.date]);
  }

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
    final id = repo.newId();
    final String? bill;
    try {
      bill = await keepBill(id);
    } on Object {
      return; // told in keepBill; nothing is saved
    }
    await repo.saveExpense(
      Expense(
        id: id,
        plotId: widget.plotId,
        baharCycleId: _cycle,
        spentOn: _date ?? _today,
        category: _category!,
        amountPaise: parseRupeesToPaise(_amount.text)!,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        billPhotoPath: bill,
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
    final label = BmType.formLabel.copyWith(color: c.ink);
    final today = ref.watch(clockProvider)();
    final date = _date ?? DateTime(today.year, today.month, today.day);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.addExpense)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            // Costs that have their own record (owner 2026-11-08: "spray, labour ... are
            // missing"): one tap opens that form; the accounts count them already.
            Text(
              t.expenseElsewhere,
              key: const Key('expense-elsewhere'),
              style: BmType.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final (key, icon, text, route) in [
                  (
                    'spray',
                    Icons.water_drop_outlined,
                    t.expenseGoSpray,
                    Routes.addSpray(widget.plotId),
                  ),
                  (
                    'labour',
                    Icons.groups_outlined,
                    t.expenseGoLabour,
                    Routes.addLabour(widget.plotId),
                  ),
                  (
                    'inputs',
                    Icons.grass_outlined,
                    t.expenseGoInputs,
                    Routes.addInput(widget.plotId),
                  ),
                ])
                  ActionChip(
                    key: Key('expense-go-$key'),
                    avatar: Icon(icon, color: c.brand),
                    label: Text(text, style: BmType.bodyStrong),
                    onPressed: () => context.push(route),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.lg),
            billField(onFill: _fillFromBill),
            const SizedBox(height: BmSpace.lg),
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
            ListTile(
              key: const Key('expense-date'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.sprayDate, style: BmType.body),
              trailing: Text(
                formatDate(date, lang),
                style: BmType.bodyStrong.copyWith(color: c.brandStrong),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(today.year - 2),
                  lastDate: DateTime(today.year + 1),
                );
                if (picked != null) setState(() => _date = picked);
              },
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
                counterText: '',
                labelText: t.noteOptional,
                suffixIcon: VoiceMicButton(onResult: _heard),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: _category == null ? null : _save,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

/// Records one sale: buyer, kg, rate per quintal, deductions and what was received.
/// Payment status follows from the amounts, so the grower never has to pick it.
class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({
    required this.plotId,
    super.key,
    this.buyer,
    this.kg,
    this.rate,
  });
  final String plotId;

  /// Filled from a market-link introduction (L5 copy to own Accounts); all editable.
  final String? buyer;
  final String? kg;

  /// Rupees per quintal.
  final String? rate;

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final _form = GlobalKey<FormState>();
  late final _buyer = TextEditingController(text: widget.buyer);
  late final _kg = TextEditingController(text: widget.kg);
  late final _rate = TextEditingController(text: widget.rate);
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
    const gap = SizedBox(height: BmSpace.md);
    const money = TextInputType.numberWithOptions(decimal: true);
    final crop = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == widget.plotId)
        .firstOrNull
        ?.crop;
    final rate = parseRupeesToPaise(_rate.text) ?? 0;
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.addSale)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('sale-buyer'),
              controller: _buyer,
              decoration: InputDecoration(
                labelText: t.saleBuyer,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _buyer.text = text,
                ),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.requiredBuyer : null,
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
              onChanged: (_) => setState(() {}),
            ),
            if (crop != null && rate > 0)
              FairPriceNote(
                crop: crop,
                soldOn: DateTime(now.year, now.month, now.day),
                ratePaisePerQuintal: rate,
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
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [FilledButton(onPressed: _save, child: Text(t.save))],
      ),
    );
  }
}
