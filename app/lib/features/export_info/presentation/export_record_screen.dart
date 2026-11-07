import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/domain/bahar_cycle.dart';
import '../../export/data/pdf_builder.dart';
import '../../export/presentation/report_page.dart';
import '../../spray/domain/spray_check.dart';
import '../../spray/presentation/spray_warnings.dart';
import '../domain/export_record.dart';
import 'export_record_page.dart';

/// Export record for a chosen plot and bahar (spec v1.5 §4A): the grower's own sprays with
/// the label check and PHI end dates the app already holds, as a PDF to hand to an exporter.
/// Information only; no compliance claim. Works offline.
class ExportRecordScreen extends ConsumerStatefulWidget {
  const ExportRecordScreen({super.key});

  @override
  ConsumerState<ExportRecordScreen> createState() => _ExportRecordScreenState();
}

class _ExportRecordScreenState extends ConsumerState<ExportRecordScreen> {
  String? _plotId;

  /// null: every spray of the plot.
  String? _cycleId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plots = ref.watch(plotsProvider).value ?? const [];
    final plot =
        plots.where((p) => p.id == _plotId).firstOrNull ?? plots.firstOrNull;
    if (plot == null) {
      return Scaffold(
        appBar: AppBar(title: AppBarTitle(t.exportRecordTitle)),
        body: EmptyState(glyph: BmGlyph.spray, message: t.exportRecordNoPlot),
      );
    }
    final cycles = ref.watch(baharCyclesProvider(plot.id)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    final crop = plot.crop;
    final rows = exportRecordRows(
      sprays: ref.watch(spraysProvider(plot.id)).value ?? const [],
      baharCycleId: _cycleId,
      crop: cropRulesFor(ref, crop),
      rules: ref.watch(restrictionsProvider).value ?? RestrictionList.empty(),
      labelIngredients: ref
          .watch(labelClaimsProvider(crop))
          .value
          ?.claims
          .map((cl) => cl.activeIngredient),
    );
    String cycleLabel(BaharCycle cy) =>
        '${bahars?.baharLabel(cy.bahar, lang) ?? cy.bahar} '
        '${formatYear(cy.seasonYear, lang)}';
    final cycle = cycles.where((cy) => cy.id == _cycleId).firstOrNull;
    final lastPhi = [for (final r in rows) ?r.phiEnd]
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    Future<void> share() async {
      setState(() => _busy = true);
      final view = View.of(context);
      final cropName = ref
          .read(cropsProvider)
          .value
          ?.where((k) => k.slug == crop)
          .firstOrNull
          ?.label(lang);
      final pages = exportRecordPages(
        t: t,
        lang: lang,
        heading: [
          (t.exportRecordPlot, [plot.name, ?cropName].join(' · ')),
          (
            t.exportRecordBahar,
            cycle == null ? t.exportRecordAllBahars : cycleLabel(cycle),
          ),
        ],
        rows: rows,
        made: ref.read(clockProvider)(),
      );
      final pngs = [
        for (final p in pages)
          await renderWidgetToPng(
            ExportRecordPage(p),
            view: view,
            size: reportPageSize,
          ),
      ];
      final day = BaharCycle.isoDate(ref.read(clockProvider)());
      await ref
          .read(fileSharerProvider)
          .share(
            fileName: 'bagmitra-export-record-${plot.id}-$day.pdf',
            bytes: await pdfFromPngPages(pngs),
            mimeType: 'application/pdf',
          );
      if (mounted) setState(() => _busy = false);
    }

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.exportRecordTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          0,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          InfoNote(t.exportRecordFooter),
          const SizedBox(height: BmSpace.md),
          Text(t.exportRecordPlot, style: BmType.label),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              for (final p in plots)
                ChoiceChip(
                  key: Key('record-plot-${p.id}'),
                  label: Text(p.name),
                  selected: p.id == plot.id,
                  onSelected: (_) => setState(() {
                    _plotId = p.id;
                    _cycleId = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.md),
          Text(t.exportRecordBahar, style: BmType.label),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              ChoiceChip(
                key: const Key('record-bahar-all'),
                label: Text(t.exportRecordAllBahars),
                selected: _cycleId == null,
                onSelected: (_) => setState(() => _cycleId = null),
              ),
              for (final cy in cycles)
                ChoiceChip(
                  key: Key('record-bahar-${cy.id}'),
                  label: Text(cycleLabel(cy)),
                  selected: _cycleId == cy.id,
                  onSelected: (_) => setState(() => _cycleId = cy.id),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.md),
          BmCard(
            key: const Key('record-summary'),
            elevated: false,
            radius: BmRadius.card,
            padding: const EdgeInsets.all(BmSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.exportRecordCount(formatInt(rows.length, lang)),
                  style: BmType.section.copyWith(color: c.ink),
                ),
                if (lastPhi != null)
                  Text(
                    t.exportRecordLastPhi(formatDate(lastPhi, lang)),
                    style: BmType.body,
                  ),
                for (final s in LabelStatus.values)
                  if (rows.where((r) => r.status == s).length case final n
                      when n > 0)
                    Text(
                      '${formatInt(n, lang)} · ${labelStatusText(t, s)}',
                      style: BmType.meta.copyWith(
                        color: switch (s) {
                          LabelStatus.listed => c.brand,
                          LabelStatus.check => c.inkMuted,
                          _ => c.danger,
                        },
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton.icon(
            key: const Key('record-share'),
            onPressed: _busy ? null : share,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(t.exportRecordShare),
          ),
        ],
      ),
    );
  }
}
