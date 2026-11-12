import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bills/domain/bill_reading.dart';
import '../../bills/presentation/bill_photo_field.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/spray_check.dart';
import '../domain/spray_record.dart';
import 'spray_ingredient_picker.dart';
import 'spray_warnings.dart';

/// The key of a product block's field: the first block keeps the plain key ("spray-product"),
/// block i > 0 gets "spray-product-i".
String sprayFieldKey(String base, int block) =>
    block == 0 ? base : '$base-$block';

/// One product block of the form: what went into the tank (Q142).
class _ProductFields {
  _ProductFields(this.id, VoidCallback onChange) {
    for (final c in all) {
      c.addListener(onChange);
    }
  }

  /// Stable across removals, so a block keeps its picker state.
  final int id;
  final product = TextEditingController();
  final active = TextEditingController();
  final dose = TextEditingController();
  final phi = TextEditingController();
  final cost = TextEditingController();

  List<TextEditingController> get all => [product, active, dose, phi, cost];

  bool get isBlank => all.every((c) => c.text.trim().isEmpty);

  Map<BillField, TextEditingController> get billFields => {
    BillField.product: product,
    BillField.active: active,
    BillField.dose: dose,
    BillField.cost: cost,
  };

  void dispose() {
    for (final c in all) {
      c.dispose();
    }
  }
}

/// Records one spray. Several products mixed in one tank are one spray (Q142): each product
/// has its name, ingredient, dose, PHI and cost; date, bahar, water, area, target, sprayer,
/// spraying labour (Q143) and the bill photo are the spray's. Warnings appear while typing (offline, from the cached
/// ban list) on the product they are about and never block saving: the record is a fact
/// about what the grower did. An optional bill photo is kept with the record and can fill
/// the empty fields (OPEN_QUESTIONS Q136).
class AddSprayScreen extends ConsumerStatefulWidget {
  const AddSprayScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddSprayScreen> createState() => _AddSprayScreenState();
}

class _AddSprayScreenState extends ConsumerState<AddSprayScreen>
    with BillPhotoForm<AddSprayScreen> {
  final _form = GlobalKey<FormState>();
  late final List<_ProductFields> _products = [_ProductFields(0, _refresh)];
  var _nextId = 1;
  final _water = TextEditingController();
  final _area = TextEditingController();
  final _operator = TextEditingController();
  final _labour = TextEditingController();
  final _target = TextEditingController();
  DateTime? _date;
  String? _cycle;

  List<TextEditingController> get _shared => [
    _water,
    _area,
    _operator,
    _labour,
    _target,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _shared) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final c in _shared) {
      c.dispose();
    }
    for (final p in _products) {
      p.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  _ProductFields _addProduct() {
    final p = _ProductFields(_nextId++, _refresh);
    setState(() => _products.add(p));
    return p;
  }

  void _removeProduct(_ProductFields p) {
    setState(() => _products.remove(p));
    // Its fields leave the tree in this frame; free the controllers after it.
    WidgetsBinding.instance.addPostFrameCallback((_) => p.dispose());
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  DateTime get _today {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  /// "बिलावरून भरा": every ticked bill line fills one product block, only what is still
  /// empty; lines beyond the blocks add blocks.
  Future<void> _fillFromBill() async {
    final bill = await readBill();
    if (bill == null || !mounted) return;
    if (bill.items.isEmpty) return showBillUnsure();
    final items = await showBillPickManySheet(context, bill);
    if (items == null || items.isEmpty || !mounted) return;
    final today = _today;
    final r = sprayFillMany(
      items: items,
      bill: bill,
      blocks: [
        for (final p in _products)
          {
            for (final MapEntry(:key, :value) in p.billFields.entries)
              key: value.text.trim(),
          },
      ],
      dateIsDefault: _date == null,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 1),
    );
    final filled = <BillField>{};
    for (final (i, fill) in r.fills.indexed) {
      final block = i < _products.length ? _products[i] : _addProduct();
      for (final MapEntry(:key, :value) in fill.entries) {
        block.billFields[key]!.text = value;
      }
      filled.addAll(fill.keys);
    }
    if (r.date != null) _date = r.date;
    showBillFilled(bill, [
      for (final f in sprayProductFields)
        if (filled.contains(f)) f,
      if (r.date != null) BillField.date,
    ]);
  }

  List<SprayProduct> get _filledProducts => [
    for (final (i, p) in _products.indexed)
      // An extra block left empty is not a product.
      if (i == 0 || !p.isBlank)
        SprayProduct(
          productName: p.product.text.trim(),
          activeIngredient: _opt(p.active),
          dose: _opt(p.dose),
          costPaise: parseRupeesToPaise(p.cost.text) ?? 0,
          phiDays: int.tryParse(p.phi.text.trim()),
        ),
  ];

  Future<void> _save(DateTime date) async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(sprayRepositoryProvider);
    final id = repo.newId();
    final String? bill;
    try {
      bill = await keepBill(id);
    } on Object {
      return; // told in keepBill; nothing is saved
    }
    await repo.save(
      SprayRecord.ofProducts(
        id: id,
        plotId: widget.plotId,
        baharCycleId: _cycle,
        sprayedOn: date,
        products: _filledProducts,
        waterLitres: double.tryParse(_water.text.trim()),
        areaAcres: double.tryParse(_area.text.trim()),
        operator: _opt(_operator),
        labourPaise: parseRupeesToPaise(_labour.text),
        target: _opt(_target),
        billPhotoPath: bill,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.canPop() ? context.pop() : context.go(Routes.sprays(widget.plotId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.watch(clockProvider)();
    final date = _date ?? DateTime(today.year, today.month, today.day);
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == widget.plotId)
        .firstOrNull;
    final cycles =
        ref.watch(baharCyclesProvider(widget.plotId)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    final rules =
        ref.watch(restrictionsProvider).value ?? RestrictionList.empty();
    final harvest = cycles
        .where((cy) => cy.id == _cycle)
        .firstOrNull
        ?.planned['harvest'];
    final crop = cropRulesFor(ref, plot?.crop);
    String? number(String? v) =>
        (v ?? '').trim().isEmpty || (double.tryParse(v!.trim()) ?? -1) > 0
        ? null
        : t.invalidNumber;
    const gap = SizedBox(height: BmSpace.md);
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final mixed = _products.length > 1;
    final labourPaise = parseRupeesToPaise(_labour.text) ?? 0;
    final totalPaise = _products.fold<int>(
      0,
      (sum, p) => sum + (parseRupeesToPaise(p.cost.text) ?? 0),
    );

    Widget productBlock(int i, _ProductFields p) {
      final warnings = checkSpray(
        activeIngredient: p.active.text,
        sprayedOn: date,
        phiDays: int.tryParse(p.phi.text.trim()),
        plannedHarvest: harvest,
        crop: crop,
        rules: rules,
      );
      final n = formatInt(i + 1, lang);
      final fields = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mixed) ...[
            ConstrainedBox(
              // As tall as the remove control, so every block's heading lines up.
              constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.sprayProductHeading(n),
                      style: BmType.section.copyWith(color: c.brandStrong),
                    ),
                  ),
                  if (i > 0)
                    IconButton(
                      key: Key('spray-remove-$i'),
                      tooltip: t.sprayRemoveProduct(n),
                      onPressed: () => _removeProduct(p),
                      icon: Icon(Icons.close_rounded, color: c.inkMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: BmSpace.sm),
          ],
          for (final w in warnings) ...[
            Builder(
              builder: (_) {
                final (title, body) = warningText(t, w, lang);
                return Column(
                  key: Key(sprayFieldKey('spray-note-${w.kind.name}', i)),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BmType.label.copyWith(color: c.inkMuted),
                    ),
                    InfoNote(body),
                  ],
                );
              },
            ),
            const SizedBox(height: BmSpace.sm),
          ],
          TextFormField(
            key: Key(sprayFieldKey('spray-product', i)),
            controller: p.product,
            decoration: InputDecoration(
              labelText: t.sprayProduct,
              suffixIcon: VoiceMicButton(
                onResult: (text, {required isFinal}) => p.product.text = text,
              ),
            ),
            validator: (v) => (v ?? '').trim().isEmpty && (i == 0 || !p.isBlank)
                ? t.requiredSprayProduct
                : null,
          ),
          gap,
          SprayIngredientPicker(controller: p.active),
          gap,
          TextFormField(
            key: Key(sprayFieldKey('spray-dose', i)),
            controller: p.dose,
            decoration: InputDecoration(labelText: t.sprayDose),
          ),
          gap,
          TextFormField(
            key: Key(sprayFieldKey('spray-phi', i)),
            controller: p.phi,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: t.sprayPhi),
          ),
          gap,
          TextFormField(
            key: Key(sprayFieldKey('spray-cost', i)),
            controller: p.cost,
            keyboardType: decimal,
            decoration: InputDecoration(labelText: t.sprayCost),
            validator: (v) =>
                (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
                ? null
                : t.invalidNumber,
          ),
        ],
      );
      // Keyed by the block's id (not its place), so removing one keeps the others' state;
      // the same widget type with or without the frame, so adding one keeps it too.
      return Container(
        key: ValueKey('spray-block-${p.id}'),
        margin: const EdgeInsets.only(bottom: BmSpace.md),
        padding: mixed
            ? const EdgeInsets.fromLTRB(
                BmSpace.md,
                BmSpace.xs,
                BmSpace.md,
                BmSpace.md,
              )
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          border: mixed ? Border.all(color: c.line) : null,
          borderRadius: BorderRadius.circular(BmRadius.card),
        ),
        child: fields,
      );
    }

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.addSpray)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            billField(onFill: _fillFromBill),
            gap,
            for (final (i, p) in _products.indexed) productBlock(i, p),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                key: const Key('spray-add-product'),
                onPressed: _addProduct,
                child: Text(t.sprayAddProduct),
              ),
            ),
            // With labour, the split under the labour field says it all.
            if (mixed && totalPaise > 0 && labourPaise == 0) ...[
              const SizedBox(height: BmSpace.sm),
              Text(
                t.sprayMixTotal(formatPaise(totalPaise, lang)),
                key: const Key('spray-mix-total'),
                style: BmType.bodyStrong.copyWith(color: c.ink),
              ),
            ],
            gap,
            if (mixed) ...[
              Text(
                t.spraySharedHeading,
                style: BmType.section.copyWith(color: c.brandStrong),
              ),
              const SizedBox(height: BmSpace.xs),
            ],
            ListTile(
              key: const Key('spray-date'),
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
              Text(
                t.sprayWhichBahar,
                style: BmType.formLabel.copyWith(color: c.ink),
              ),
              const SizedBox(height: BmSpace.xs),
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
              gap,
            ],
            TextFormField(
              key: const Key('spray-water'),
              controller: _water,
              keyboardType: decimal,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(labelText: t.sprayWater),
              validator: number,
            ),
            gap,
            TextFormField(
              key: const Key('spray-area'),
              controller: _area,
              keyboardType: decimal,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(labelText: t.sprayArea),
              validator: number,
            ),
            gap,
            TextFormField(
              key: const Key('spray-target'),
              controller: _target,
              decoration: InputDecoration(
                labelText: t.sprayTarget,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _target.text = text,
                ),
              ),
            ),
            gap,
            TextFormField(
              key: const Key('spray-operator'),
              controller: _operator,
              decoration: InputDecoration(labelText: t.sprayOperator),
            ),
            gap,
            // Once per spray (Q143); counted under "labour" in the accounts. Bill fill never
            // writes it.
            TextFormField(
              key: const Key('spray-labour'),
              controller: _labour,
              keyboardType: decimal,
              decoration: InputDecoration(
                labelText: t.sprayLabour,
                helperText: t.sprayLabourHelp,
                helperMaxLines: 3,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
                  ? null
                  : t.invalidNumber,
            ),
            if (labourPaise > 0) ...[
              const SizedBox(height: BmSpace.sm),
              Text(
                t.sprayCostSplit(
                  formatPaise(totalPaise, lang),
                  formatPaise(labourPaise, lang),
                ),
                key: const Key('spray-cost-split'),
                style: BmType.bodyStrong.copyWith(color: c.ink),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(onPressed: () => _save(date), child: Text(t.save)),
        ],
      ),
    );
  }
}
