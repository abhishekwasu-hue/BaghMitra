import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/sources_disclosure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/bahar_catalog.dart';
import '../data/stage_templates.dart';
import '../domain/bahar_cycle.dart';

/// Starts a bahar for one block. The grower picks the bahar and enters their own dates. Each
/// stage shows the window public sources give (stage templates, Q57: general information with
/// the source and the date it was read); the grower can fill them in and change every date.
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

  Future<void> _pick(String stage, DateTime? suggested) async {
    final today = ref.read(clockProvider)();
    final first = DateTime(today.year - 2);
    final last = DateTime(today.year + 3);
    final initial = _dates[stage] ?? suggested ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) || initial.isAfter(last)
          ? today
          : initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _dates[stage] = picked);
  }

  Future<void> _save() async {
    final repo = ref.read(baharRepositoryProvider);
    final catalog = await ref.read(baharOptionsProvider.future);
    final crop = ref
        .read(plotsProvider)
        .value
        ?.where((p) => p.id == widget.plotId)
        .firstOrNull
        ?.crop;
    final templates = await ref.read(stageTemplatesProvider.future);
    final template = crop == null
        ? null
        : templates[templateKey(crop, _bahar!)];
    final stages = template?.withStages(catalog.stages) ?? catalog.stages;
    final cycle = BaharCycle(
      id: repo.newId(),
      plotId: widget.plotId,
      bahar: _bahar!,
      seasonYear: _season!,
      status: 'planned',
      // Only the stages shown for the chosen bahar (a date typed under another bahar's extra
      // stage is dropped).
      planned: {
        for (final e in _dates.entries)
          if (stages.any((s) => s.key == e.key)) e.key: e.value,
      },
    );
    await repo.save(cycle);
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    await ref
        .read(cycleTasksProvider)
        .sync(
          cycle,
          lang: lang,
          baharLabel: catalog.baharLabel(cycle.bahar, lang),
          stageLabels: {for (final s in stages) s.slug: s.label(lang)},
          crop: crop,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.pop();
  }

  Widget _chip(String label, {required bool selected, VoidCallback? onTap}) {
    return ChoiceChip(
      label: Text(label, style: BmType.bodyStrong),
      selected: selected,
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
    final template = crop == null || _bahar == null
        ? null
        : ref.watch(stageTemplatesProvider).value?[templateKey(crop, _bahar!)];
    final windows = template?.windows(_season!, _dates) ?? const {};
    final checked = template?.checked();
    final stages =
        template?.withStages(catalog?.stages ?? const []) ??
        catalog?.stages ??
        const <LabeledOption>[];
    final label = BmType.formLabel.copyWith(color: c.ink);
    const gap = SizedBox(height: BmSpace.lg);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.startBahar)),
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('compare-bahars'),
              icon: const Icon(Icons.compare_arrows),
              label: Text(t.baharCompareTitle),
              onPressed: () async {
                final picked = await context.push<String>(
                  Routes.compareBahars(widget.plotId),
                );
                if (picked != null) setState(() => _bahar = picked);
              },
            ),
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
          if (template != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('fill-suggested'),
                icon: const Icon(Icons.event_available),
                label: Text(t.baharFillSuggested),
                onPressed: () => setState(() {
                  final filled = template.fillSuggested(_season!, _dates);
                  _dates
                    ..clear()
                    ..addAll(filled);
                }),
              ),
            ),
          for (final stage in stages)
            ListTile(
              key: Key('stage-${stage.key}'),
              contentPadding: EdgeInsets.zero,
              title: Text(stage.label(lang), style: BmType.body),
              subtitle: template == null
                  ? null
                  : _StageHint(
                      window: windows[stage.key],
                      bySoil:
                          stage.key == 'irrigation_restart' &&
                          windows.containsKey(stage.key),
                    ),
              trailing: Text(switch (_dates[stage.key]) {
                final d? => formatDate(d, lang),
                null => t.baharPickDate,
              }, style: BmType.bodyStrong.copyWith(color: c.brandStrong)),
              onTap: () => _pick(stage.key, windows[stage.key]?.from),
            ),
          if (template != null) ...[
            const SizedBox(height: BmSpace.sm),
            Text(t.baharSuggestedHelp, style: BmType.meta),
            // Each stage's sources, once for the screen and folded (owner request).
            SourcesDisclosure(
              key: const Key('stage-sources'),
              notes: [
                t.generalInfoSource(
                  template.sourceNames().join(', '),
                  checked == null ? '–' : formatDate(checked, lang),
                ),
                for (final stage in stages)
                  if (template.sourcesFor(stage.key) case final src
                      when src.isNotEmpty)
                    '${stage.label(lang)}: '
                        '${src.map((s) => s.name).join(', ')}',
              ],
              sources: [
                for (final src in {
                  for (final stage in stages) ...template.sourcesFor(stage.key),
                })
                  SourceRef(
                    src.title,
                    url: src.url,
                    publisher: src.name,
                    checked: switch (src.read) {
                      final d? => formatDate(d, lang),
                      null => null,
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: _bahar == null ? null : _save,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

/// The suggested window of one stage, or a plain "not published". Its sources are listed
/// once, folded, under the stage list.
class _StageHint extends StatelessWidget {
  const _StageHint({required this.window, required this.bySoil});

  final StageWindow? window;
  final bool bySoil;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final w = window;
    if (w == null) return Text(t.baharNoWindow, style: BmType.meta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.baharSuggestedWindow(
            formatDate(w.from, lang),
            formatDate(w.to, lang),
          ),
          style: BmType.meta.copyWith(color: context.bm.ink),
        ),
        if (bySoil) Text(t.baharStressBySoil, style: BmType.meta),
      ],
    );
  }
}
