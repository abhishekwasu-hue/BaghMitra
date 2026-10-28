import 'package:flutter/material.dart';
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
import '../data/crop_catalog.dart';
import '../domain/plot.dart';

/// "My orchard": every block the grower manages. Works fully offline (reads Drift).
class PlotsScreen extends ConsumerWidget {
  const PlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final plots = ref.watch(plotsProvider).value ?? const <Plot>[];
    final crops = ref.watch(cropsProvider).value ?? const <CropOption>[];
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.myOrchard)),
      body: plots.isEmpty
          ? const _EmptyOrchard()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                BmSpace.xs,
                BmSpace.lg,
                120,
              ),
              itemCount: plots.length,
              separatorBuilder: (_, _) => const SizedBox(height: BmSpace.sm),
              itemBuilder: (context, i) => _PlotCard(
                plot: plots[i],
                cropLabel: _cropLabel(crops, plots[i].crop, lang),
                lang: lang,
              ),
            ),
      bottomNavigationBar: plots.isEmpty
          ? null
          : BottomActions(
              children: [
                FilledButton.icon(
                  onPressed: () => context.push(Routes.addPlot),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(t.addPlot),
                ),
              ],
            ),
    );
  }

  static String _cropLabel(List<CropOption> crops, String slug, String lang) =>
      crops.where((c) => c.slug == slug).firstOrNull?.label(lang) ?? slug;
}

class _PlotCard extends ConsumerWidget {
  const _PlotCard({
    required this.plot,
    required this.cropLabel,
    required this.lang,
  });

  final Plot plot;
  final String cropLabel;
  final String lang;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deletePlot),
        content: Text(t.deletePlotConfirm(plot.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(plotRepositoryProvider).delete(plot.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final facts = [
      t.plotAcres(formatDecimal(plot.areaAcres, lang)),
      if (plot.treeCount != null) t.plotTrees(plot.treeCount!),
    ].join(' · ');
    final card = BmCard(
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.fromLTRB(
        BmSpace.md,
        BmSpace.md,
        BmSpace.xs,
        BmSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.nowTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const GlyphIcon(BmGlyph.orange),
          ),
          const SizedBox(width: BmSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plot.name, style: BmType.section.copyWith(color: c.ink)),
                Text(
                  cropLabel,
                  style: BmType.meta.copyWith(color: c.brandStrong),
                ),
                Text(facts, style: BmType.meta.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: t.deletePlot,
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(Icons.delete_outline_rounded, color: c.inkMuted),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.plot(plot.id)),
        child: card,
      ),
    );
  }
}

class _EmptyOrchard extends StatelessWidget {
  const _EmptyOrchard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return EmptyState(
      glyph: BmGlyph.orange,
      title: t.plotsEmptyTitle,
      message: t.plotsEmptyBody,
      action: FilledButton.icon(
        onPressed: () => context.push(Routes.addPlot),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.addPlot),
      ),
    );
  }
}
