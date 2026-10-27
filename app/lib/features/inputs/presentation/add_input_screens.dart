import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/data/bahar_catalog.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/field_records.dart';

Future<void> _savedAndBack(BuildContext context, String plotId) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
  );
  // Opened directly (e.g. from a notification) there is nothing to pop.
  context.canPop() ? context.pop() : context.go(Routes.fieldLog(plotId));
}

String? _decimalOptional(AppLocalizations t, String? v) =>
    (v ?? '').trim().isEmpty || (double.tryParse(v!.trim()) ?? -1) > 0
    ? null
    : t.invalidNumber;

double? _decimal(String v) => double.tryParse(v.trim());

final _decimalOnly = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

/// Records one fertiliser / manure / micronutrient application for a block.
class AddInputScreen extends ConsumerStatefulWidget {
  const AddInputScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddInputScreen> createState() => _AddInputScreenState();
}

class _AddInputScreenState extends ConsumerState<AddInputScreen> {
  final _form = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  String? _kind;
  String? _unit;
  String? _cycle;

  @override
  void dispose() {
    for (final c in [_product, _quantity, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _kind == null) return;
    final repo = ref.read(inputsRepositoryProvider);
    final now = ref.read(clockProvider)();
    final qty = _decimal(_quantity.text);
    await repo.saveInput(
      InputRecord(
        id: repo.newId(),
        plotId: widget.plotId,
        baharCycleId: _cycle,
        appliedOn: DateTime(now.year, now.month, now.day),
        kind: _kind!,
        productName: _product.text.trim(),
        quantity: qty,
        unit: qty == null ? null : _unit,
        costPaise: parseRupeesToPaise(_cost.text) ?? 0,
      ),
    );
    if (mounted) await _savedAndBack(context, widget.plotId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(inputKindsProvider).value;
    final cycles =
        ref.watch(baharCyclesProvider(widget.plotId)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    final label = BmType.label.copyWith(color: c.inkMuted, fontSize: 14);
    const gap = SizedBox(height: BmSpace.md);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(t.addInput, style: BmType.section.copyWith(color: c.brand)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            Text(t.inputKind, style: label),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final k in data?.kinds ?? const <LabeledOption>[])
                  ChoiceChip(
                    label: Text(k.label(lang), style: BmType.bodyStrong),
                    selected: _kind == k.slug,
                    selectedColor: c.nowTint,
                    onSelected: (_) => setState(() => _kind = k.slug),
                  ),
              ],
            ),
            gap,
            TextFormField(
              key: const Key('input-product'),
              controller: _product,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: t.inputProduct,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _product.text = text,
                ),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.fieldRequired : null,
            ),
            TextFormField(
              key: const Key('input-quantity'),
              controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_decimalOnly],
              decoration: InputDecoration(labelText: t.inputQuantity),
              validator: (v) => _decimalOptional(t, v),
            ),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              children: [
                for (final u in data?.units ?? const <LabeledOption>[])
                  ChoiceChip(
                    label: Text(u.label(lang)),
                    selected: _unit == u.slug,
                    onSelected: (on) =>
                        setState(() => _unit = on ? u.slug : null),
                  ),
              ],
            ),
            gap,
            TextFormField(
              key: const Key('input-cost'),
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: t.inputCost),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
                  ? null
                  : t.invalidNumber,
            ),
            if (cycles.isNotEmpty) ...[
              gap,
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: FilledButton(
            onPressed: _kind == null ? null : _save,
            child: Text(t.save),
          ),
        ),
      ),
    );
  }
}

/// Logs one irrigation event. Hours and litres are optional: a grower can just note the day.
class AddIrrigationScreen extends ConsumerStatefulWidget {
  const AddIrrigationScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddIrrigationScreen> createState() =>
      _AddIrrigationScreenState();
}

class _AddIrrigationScreenState extends ConsumerState<AddIrrigationScreen> {
  final _form = GlobalKey<FormState>();
  final _hours = TextEditingController();
  final _litres = TextEditingController();

  @override
  void dispose() {
    _hours.dispose();
    _litres.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(inputsRepositoryProvider);
    final now = ref.read(clockProvider)();
    await repo.saveIrrigation(
      IrrigationRecord(
        id: repo.newId(),
        plotId: widget.plotId,
        irrigatedOn: DateTime(now.year, now.month, now.day),
        durationHours: _decimal(_hours.text),
        waterLitres: _decimal(_litres.text),
      ),
    );
    if (mounted) await _savedAndBack(context, widget.plotId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(
          t.logIrrigation,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('irrigation-hours'),
              controller: _hours,
              keyboardType: decimal,
              inputFormatters: [_decimalOnly],
              decoration: InputDecoration(labelText: t.irrigationHours),
              validator: (v) => _decimalOptional(t, v),
            ),
            const SizedBox(height: BmSpace.md),
            TextFormField(
              key: const Key('irrigation-litres'),
              controller: _litres,
              keyboardType: decimal,
              inputFormatters: [_decimalOnly],
              decoration: InputDecoration(labelText: t.irrigationLitres),
              validator: (v) => _decimalOptional(t, v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: FilledButton(onPressed: _save, child: Text(t.save)),
        ),
      ),
    );
  }
}
