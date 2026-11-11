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
import 'spray_warnings.dart';

/// Records one spray. Warnings appear while typing (offline, from the cached ban list) and
/// never block saving: the record is a fact about what the grower did. An optional bill
/// photo is kept with the record and can fill the empty fields (OPEN_QUESTIONS Q136).
class AddSprayScreen extends ConsumerStatefulWidget {
  const AddSprayScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddSprayScreen> createState() => _AddSprayScreenState();
}

class _AddSprayScreenState extends ConsumerState<AddSprayScreen>
    with BillPhotoForm<AddSprayScreen> {
  final _form = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _active = TextEditingController();
  final _dose = TextEditingController();
  final _water = TextEditingController();
  final _area = TextEditingController();
  final _cost = TextEditingController();
  final _operator = TextEditingController();
  final _phi = TextEditingController();
  final _target = TextEditingController();
  DateTime? _date;
  String? _cycle;

  List<TextEditingController> get _all => [
    _product,
    _active,
    _dose,
    _water,
    _area,
    _cost,
    _operator,
    _phi,
    _target,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  DateTime get _today {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  /// "बिलावरून भरा": the picked bill line fills only what is still empty.
  Future<void> _fillFromBill() async {
    final bill = await readBill();
    if (bill == null || !mounted) return;
    if (bill.items.isEmpty) return showBillUnsure();
    final item = (await showBillPickSheet(context, bill))?.item;
    if (item == null || !mounted) return;
    final today = _today;
    final controllers = {
      BillField.product: _product,
      BillField.active: _active,
      BillField.dose: _dose,
      BillField.cost: _cost,
    };
    final r = sprayFill(
      item: item,
      bill: bill,
      current: {
        for (final MapEntry(:key, :value) in controllers.entries)
          key: value.text.trim(),
      },
      dateIsDefault: _date == null,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 1),
    );
    for (final MapEntry(:key, :value) in r.fill.entries) {
      controllers[key]!.text = value;
    }
    if (r.date != null) _date = r.date;
    showBillFilled(bill, [...r.fill.keys, if (r.date != null) BillField.date]);
  }

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
      SprayRecord(
        id: id,
        plotId: widget.plotId,
        baharCycleId: _cycle,
        sprayedOn: date,
        productName: _product.text.trim(),
        activeIngredient: _opt(_active),
        dose: _opt(_dose),
        waterLitres: double.tryParse(_water.text.trim()),
        areaAcres: double.tryParse(_area.text.trim()),
        costPaise: parseRupeesToPaise(_cost.text) ?? 0,
        operator: _opt(_operator),
        phiDays: int.tryParse(_phi.text.trim()),
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
    final warnings = checkSpray(
      activeIngredient: _active.text,
      sprayedOn: date,
      phiDays: int.tryParse(_phi.text.trim()),
      plannedHarvest: harvest,
      crop: cropRulesFor(ref, plot?.crop),
      rules: rules,
    );
    String? number(String? v) =>
        (v ?? '').trim().isEmpty || (double.tryParse(v!.trim()) ?? -1) > 0
        ? null
        : t.invalidNumber;
    const gap = SizedBox(height: BmSpace.md);
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.addSpray)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            for (final w in warnings) ...[
              Builder(
                builder: (_) {
                  final (title, body) = warningText(t, w, lang);
                  return Column(
                    key: Key('spray-note-${w.kind.name}'),
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
            billField(onFill: _fillFromBill),
            gap,
            TextFormField(
              key: const Key('spray-product'),
              controller: _product,
              decoration: InputDecoration(
                labelText: t.sprayProduct,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _product.text = text,
                ),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.requiredSprayProduct : null,
            ),
            gap,
            TextFormField(
              key: const Key('spray-active'),
              controller: _active,
              decoration: InputDecoration(labelText: t.sprayActive),
            ),
            gap,
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
              key: const Key('spray-dose'),
              controller: _dose,
              decoration: InputDecoration(labelText: t.sprayDose),
            ),
            gap,
            TextFormField(
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
              key: const Key('spray-phi'),
              controller: _phi,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.sprayPhi),
            ),
            gap,
            TextFormField(
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
              key: const Key('spray-cost'),
              controller: _cost,
              keyboardType: decimal,
              decoration: InputDecoration(labelText: t.sprayCost),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
                  ? null
                  : t.invalidNumber,
            ),
            gap,
            TextFormField(
              controller: _operator,
              decoration: InputDecoration(labelText: t.sprayOperator),
            ),
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
