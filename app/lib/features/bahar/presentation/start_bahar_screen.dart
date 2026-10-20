import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/bahar_catalog.dart';
import '../domain/bahar_cycle.dart';

/// Starts a bahar for one block. The grower picks the bahar and enters their own dates;
/// no dates are suggested until a verified stage template is published (Q10).
class StartBaharScreen extends ConsumerStatefulWidget {
  const StartBaharScreen({required this.plotId, super.key});

  final String plotId;

  @override
  ConsumerState<StartBaharScreen> createState() => _StartBaharScreenState();
}

class _StartBaharScreenState extends ConsumerState<StartBaharScreen> {
  String? _bahar;
  int? _season;
  final Map<String, DateTime> _dates = {};

  Future<void> _pick(String stage) async {
    final today = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dates[stage] ?? today,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 3),
    );
    if (picked != null) setState(() => _dates[stage] = picked);
  }

  Future<void> _save() async {
    final repo = ref.read(baharRepositoryProvider);
    final cycle = BaharCycle(
      id: repo.newId(),
      plotId: widget.plotId,
      bahar: _bahar!,
      seasonYear: _season!,
      status: 'planned',
      planned: Map.of(_dates),
    );
    await repo.save(cycle);
    final catalog = await ref.read(baharOptionsProvider.future);
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    await ref
        .read(cycleTasksProvider)
        .sync(
          cycle,
          lang: lang,
          baharLabel: catalog.baharLabel(cycle.bahar, lang),
          stageLabels: {for (final s in catalog.stages) s.slug: s.label(lang)},
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.pop();
  }

  Widget _chip(String label, {required bool selected, VoidCallback? onTap}) {
    final c = context.bm;
    return ChoiceChip(
      label: Text(label, style: BmType.bodyStrong),
      selected: selected,
      selectedColor: c.nowTint,
      side: BorderSide(color: selected ? c.accent : c.line),
      onSelected: (_) => onTap?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final year = ref.watch(clockProvider)().year;
    final catalog = ref.watch(baharOptionsProvider).value;
    final crop = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == widget.plotId)
        .firstOrNull
        ?.crop;
    final bahars = crop == null || catalog == null
        ? const <LabeledOption>[]
        : catalog.forCrop(crop);
    _season ??= year;
    final label = BmType.label.copyWith(color: c.inkMuted, fontSize: 14);
    const gap = SizedBox(height: BmSpace.lg);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(
          t.startBahar,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(t.baharWhich, style: label),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              for (final b in bahars)
                _chip(
                  b.label(lang),
                  selected: _bahar == b.slug,
                  onTap: () => setState(() => _bahar = b.slug),
                ),
            ],
          ),
          gap,
          Text(t.baharSeason, style: label),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.xs,
            children: [
              for (final y in [year, year + 1])
                _chip(
                  formatYear(y, lang),
                  selected: _season == y,
                  onTap: () => setState(() => _season = y),
                ),
            ],
          ),
          gap,
          Text(t.baharDates, style: label),
          for (final stage in catalog?.stages ?? const <LabeledOption>[])
            ListTile(
              key: Key('stage-${stage.key}'),
              contentPadding: EdgeInsets.zero,
              title: Text(stage.label(lang), style: BmType.body),
              trailing: Text(switch (_dates[stage.key]) {
                final d? => formatDate(d, lang),
                null => t.baharPickDate,
              }, style: BmType.bodyStrong.copyWith(color: c.brandStrong)),
              onTap: () => _pick(stage.key),
            ),
          const SizedBox(height: BmSpace.xl),
          FilledButton(
            onPressed: _bahar == null ? null : _save,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}
