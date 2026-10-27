import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/irrigation_guide.dart';

/// Read-only irrigation guide (ओलित तक्ता): sourced amounts and intervals per crop, tree age and
/// season. With a block it uses the block's crop and, when the planting year is known, its tree
/// age. Every point names its source; no draft banner (Q30); no fertiliser or chemical content.
class IrrigationGuideScreen extends ConsumerStatefulWidget {
  const IrrigationGuideScreen({this.plotId, super.key});

  final String? plotId;

  @override
  ConsumerState<IrrigationGuideScreen> createState() =>
      _IrrigationGuideScreenState();
}

class _IrrigationGuideScreenState extends ConsumerState<IrrigationGuideScreen> {
  String? _crop;
  String? _band;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(irrigationGuideProvider).value;
    final crops = ref.watch(cropsProvider).value ?? const [];
    final plot = widget.plotId == null
        ? null
        : ref
              .watch(plotsProvider)
              .value
              ?.where((p) => p.id == widget.plotId)
              .firstOrNull;
    final thisYear = ref.watch(clockProvider)().year;

    final appBar = AppBar(
      title: Text(
        t.irrigationGuideTitle,
        style: BmType.section.copyWith(color: c.brand),
      ),
    );
    if (data == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final crop = plot?.crop ?? _crop ?? data.crops.keys.first;
    final guide = data.crops[crop];
    final plotBand = data.bandFor(plot?.plantingYear, thisYear);
    final band = _band ?? plotBand?.key ?? data.ageBands.first.key;

    Widget sourceLines(String source, List<String> keys) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.practicesSource(source), style: BmType.meta),
        for (final k in keys)
          if (data.sources[k] case final s?)
            Text('$k: ${s.title}', style: BmType.meta),
      ],
    );

    Widget row(IrrigationRow r) => Padding(
      key: Key('irrigation-${r.id}'),
      padding: const EdgeInsets.symmetric(vertical: BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.methodLabel(r.method, lang),
            style: BmType.meta.copyWith(color: c.brand),
          ),
          Text(r.label(lang), style: BmType.body),
          const SizedBox(height: BmSpace.xs),
          sourceLines(r.source, r.sourceKeys),
        ],
      ),
    );

    final seasons = [
      for (final s in data.seasons.keys)
        if (guide?.rowsFor(band, s) case final rows? when rows.isNotEmpty)
          (s, rows),
    ];

    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(
            t.irrigationCaveat,
            key: const Key('irrigation-caveat'),
            style: BmType.meta,
          ),
          const SizedBox(height: BmSpace.lg),
          if (plot == null) ...[
            Text(t.irrigationCropLabel, style: BmType.label),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.sm,
              children: [
                for (final k in data.crops.keys)
                  ChoiceChip(
                    key: Key('irrigation-crop-$k'),
                    label: Text(
                      crops
                              .where((o) => o.slug == k)
                              .firstOrNull
                              ?.label(lang) ??
                          k,
                    ),
                    selected: k == crop,
                    onSelected: (_) => setState(() => _crop = k),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.md),
          ],
          Text(t.irrigationAgeLabel, style: BmType.label),
          if (plot != null)
            Text(
              plotBand == null
                  ? t.irrigationNoPlantingYear
                  : t.irrigationPlanted(
                      formatYear(plot.plantingYear!, lang),
                      formatInt(thisYear - plot.plantingYear!, lang),
                    ),
              key: const Key('irrigation-plot-age'),
              style: BmType.meta,
            ),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.sm,
            runSpacing: BmSpace.xs,
            children: [
              for (final b in data.ageBands)
                ChoiceChip(
                  key: Key('irrigation-age-${b.key}'),
                  label: Text(b.label(lang)),
                  selected: b.key == band,
                  onSelected: (_) => setState(() => _band = b.key),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.lg),
          if (seasons.isEmpty)
            Text(
              t.irrigationNoRows,
              key: const Key('irrigation-no-rows'),
              style: BmType.body,
            ),
          for (final (s, rows) in seasons) ...[
            Text(
              data.seasonLabel(s, lang),
              key: Key('irrigation-season-$s'),
              style: BmType.bodyStrong,
            ),
            for (final r in rows) row(r),
            const Divider(),
          ],
          if (guide != null && guide.notes.isNotEmpty) ...[
            const SizedBox(height: BmSpace.sm),
            Text(t.irrigationStagesTitle, style: BmType.bodyStrong),
            for (final n in guide.notes)
              Padding(
                key: Key('irrigation-${n.id}'),
                padding: const EdgeInsets.symmetric(vertical: BmSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.label(lang), style: BmType.body),
                    const SizedBox(height: BmSpace.xs),
                    sourceLines(n.source, n.sourceKeys),
                  ],
                ),
              ),
          ],
          if (guide != null && guide.gaps.isNotEmpty) ...[
            const SizedBox(height: BmSpace.lg),
            Text(t.irrigationGapsTitle, style: BmType.label),
            const SizedBox(height: BmSpace.xs),
            for (final g in guide.gaps)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.xs),
                child: Text(g[lang] ?? g['en'] ?? '', style: BmType.meta),
              ),
          ],
          const SizedBox(height: BmSpace.lg),
          Text(
            t.irrigationSourcesLine,
            key: const Key('irrigation-sources'),
            style: BmType.meta.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
