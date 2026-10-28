import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/data/bahar_catalog.dart';
import '../../bahar/presentation/cycle_chips.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/field_work.dart';

DateTime _today(WidgetRef ref) {
  final now = ref.read(clockProvider)();
  return DateTime(now.year, now.month, now.day);
}

/// The labour register for one block: each worker day with its wage, and what is still owed.
class LabourScreen extends ConsumerWidget {
  const LabourScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final days = ref.watch(labourProvider(plotId)).value ?? const [];
    final tasks = ref.watch(fieldWorkOptionsProvider).value?.tasks;
    final totalDue = days.fold(0, (a, d) => a + d.duePaise);
    String taskLabel(String? slug) => slug == null
        ? ''
        : (tasks ?? const <LabeledOption>[])
                  .where((x) => x.slug == slug)
                  .firstOrNull
                  ?.label(lang) ??
              slug;
    return Scaffold(
      appBar: AppBar(title: Text(t.labourTitle)),
      body: days.isEmpty
          ? EmptyState(glyph: BmGlyph.ledger, message: t.labourEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              children: [
                BmCard(
                  elevated: false,
                  radius: BmRadius.card,
                  padding: const EdgeInsets.all(BmSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(t.labourTotalDue, style: BmType.body),
                      ),
                      Text(
                        t.labourDue(formatPaise(totalDue, lang)),
                        style: BmType.section.copyWith(
                          color: totalDue > 0 ? c.danger : c.brand,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BmSpace.sm),
                for (final d in days)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      [
                        d.workerName,
                        if (d.task != null) taskLabel(d.task),
                      ].join(' · '),
                      style: BmType.body,
                    ),
                    subtitle: Text(
                      [
                        formatDate(d.workedOn, lang),
                        if (d.settled)
                          t.labourSettled
                        else if (d.duePaise > 0)
                          t.labourDue(formatPaise(d.duePaise, lang)),
                      ].join(' · '),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPaise(d.wagePaise, lang),
                          style: BmType.bodyStrong,
                        ),
                        if (!d.settled && d.duePaise > 0)
                          GestureDetector(
                            onTap: () => ref
                                .read(fieldWorkRepositoryProvider)
                                .saveLabour(
                                  LabourRecord(
                                    id: d.id,
                                    plotId: d.plotId,
                                    baharCycleId: d.baharCycleId,
                                    workerName: d.workerName,
                                    workedOn: d.workedOn,
                                    task: d.task,
                                    wagePaise: d.wagePaise,
                                    advancePaise: d.advancePaise,
                                    settledOn: _today(ref),
                                    note: d.note,
                                  ),
                                ),
                            child: Text(
                              t.labourMarkPaid,
                              style: BmType.label.copyWith(color: c.brand),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: () => context.push(Routes.addLabour(plotId)),
            child: Text(t.labourAddDay),
          ),
        ],
      ),
    );
  }
}

/// Records one worker's day: who, what work, wage, advance, and whether it was paid in full.
class AddLabourScreen extends ConsumerStatefulWidget {
  const AddLabourScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends ConsumerState<AddLabourScreen> {
  final _form = GlobalKey<FormState>();
  final _worker = TextEditingController();
  final _wage = TextEditingController();
  final _advance = TextEditingController();
  String? _task;
  String? _cycle;
  var _paidNow = false;

  @override
  void dispose() {
    for (final c in [_worker, _wage, _advance]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(fieldWorkRepositoryProvider);
    final today = _today(ref);
    await repo.saveLabour(
      LabourRecord(
        id: repo.newId(),
        plotId: widget.plotId,
        baharCycleId: _cycle,
        workerName: _worker.text.trim(),
        workedOn: today,
        task: _task,
        wagePaise: parseRupeesToPaise(_wage.text)!,
        advancePaise: parseRupeesToPaise(_advance.text) ?? 0,
        settledOn: _paidNow ? today : null,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.canPop() ? context.pop() : context.go(Routes.labour(widget.plotId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final tasks = ref.watch(fieldWorkOptionsProvider).value?.tasks;
    const gap = SizedBox(height: BmSpace.md);
    const money = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: Text(t.labourAddDay)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('labour-worker'),
              controller: _worker,
              maxLength: 120,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.labourWorker,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _worker.text = text,
                ),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.fieldRequired : null,
            ),
            const SizedBox(height: BmSpace.md),
            Text(t.labourTask, style: BmType.formLabel.copyWith(color: c.ink)),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final k in tasks ?? const <LabeledOption>[])
                  ChoiceChip(
                    label: Text(k.label(lang), style: BmType.bodyStrong),
                    selected: _task == k.slug,
                    onSelected: (on) =>
                        setState(() => _task = on ? k.slug : null),
                  ),
              ],
            ),
            gap,
            TextFormField(
              key: const Key('labour-wage'),
              controller: _wage,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.labourWage),
              validator: (v) => (parseRupeesToPaise(v ?? '') ?? 0) > 0
                  ? null
                  : t.invalidNumber,
            ),
            gap,
            TextFormField(
              key: const Key('labour-advance'),
              controller: _advance,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.labourAdvance),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
                  ? null
                  : t.invalidNumber,
            ),
            SwitchListTile(
              key: const Key('labour-paid-now'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.labourPaidNow, style: BmType.body),
              value: _paidNow,
              onChanged: (v) => setState(() => _paidNow = v),
            ),
            CycleChips(
              plotId: widget.plotId,
              selected: _cycle,
              onChanged: (v) => setState(() => _cycle = v),
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

final _kgOnly = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

/// Records one harvest lot. Only the weight is required; grade and size can follow.
class AddHarvestScreen extends ConsumerStatefulWidget {
  const AddHarvestScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddHarvestScreen> createState() => _AddHarvestScreenState();
}

class _AddHarvestScreenState extends ConsumerState<AddHarvestScreen> {
  final _form = GlobalKey<FormState>();
  final _kg = TextEditingController();
  String? _grade;
  String? _size;
  String? _cycle;

  @override
  void dispose() {
    _kg.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(fieldWorkRepositoryProvider);
    await repo.saveHarvest(
      HarvestRecord(
        id: repo.newId(),
        plotId: widget.plotId,
        baharCycleId: _cycle,
        harvestedOn: _today(ref),
        grade: _grade,
        sizeClass: _size,
        quantityKg: double.parse(_kg.text.trim()),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.canPop()
        ? context.pop()
        : context.go(Routes.harvest(widget.plotId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final opts = ref.watch(fieldWorkOptionsProvider).value;
    final label = BmType.formLabel.copyWith(color: c.ink);
    Widget choice(
      String title,
      List<LabeledOption> items,
      String? value,
      ValueChanged<String?> set,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BmSpace.md),
        Text(title, style: label),
        const SizedBox(height: BmSpace.xs),
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            for (final o in items)
              ChoiceChip(
                label: Text(o.label(lang), style: BmType.bodyStrong),
                selected: value == o.slug,
                onSelected: (on) => setState(() => set(on ? o.slug : null)),
              ),
          ],
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.harvestAdd)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('harvest-kg'),
              controller: _kg,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_kgOnly],
              decoration: InputDecoration(labelText: t.harvestKg),
              validator: (v) => (double.tryParse(v?.trim() ?? '') ?? 0) > 0
                  ? null
                  : t.invalidNumber,
            ),
            choice(
              t.harvestGrade,
              opts?.grades ?? const [],
              _grade,
              (v) => _grade = v,
            ),
            choice(
              t.harvestSize,
              opts?.sizeClasses ?? const [],
              _size,
              (v) => _size = v,
            ),
            CycleChips(
              plotId: widget.plotId,
              selected: _cycle,
              onChanged: (v) => setState(() => _cycle = v),
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
