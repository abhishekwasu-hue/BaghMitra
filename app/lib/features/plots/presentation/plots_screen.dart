import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
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
    final c = context.bm;
    final plots = ref.watch(plotsProvider).value ?? const <Plot>[];
    final crops = ref.watch(cropsProvider).value ?? const <CropOption>[];
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(t.myOrchard, style: BmType.title.copyWith(color: c.brand)),
      ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: plots.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: BmSpace.lg),
              child: FilledButton.icon(
                onPressed: () => context.push(Routes.addPlot),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.addPlot),
              ),
            ),
    );
  }

  static String _cropLabel(List<CropOption> crops, String slug, String lang) =>
      crops.where((c) => c.slug == slug).firstOrNull?.label(lang) ?? slug;
}

class _PlotCard extends StatelessWidget {
  const _PlotCard({
    required this.plot,
    required this.cropLabel,
    required this.lang,
  });

  final Plot plot;
  final String cropLabel;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final facts = [
      t.plotAcres(formatDecimal(plot.areaAcres, lang)),
      if (plot.treeCount != null) t.plotTrees(plot.treeCount!),
    ].join(' · ');
    return BmCard(
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
        ],
      ),
    );
  }
}

class _EmptyOrchard extends StatelessWidget {
  const _EmptyOrchard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BmSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [c.nowTint, c.doneTint]),
              ),
              child: const GlyphIcon(BmGlyph.orange),
            ),
            const SizedBox(height: BmSpace.xl),
            Text(
              t.plotsEmptyTitle,
              textAlign: TextAlign.center,
              style: BmType.cardTitle.copyWith(color: c.brand),
            ),
            const SizedBox(height: BmSpace.xs),
            Text(
              t.plotsEmptyBody,
              textAlign: TextAlign.center,
              style: BmType.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: BmSpace.xl),
            FilledButton.icon(
              onPressed: () => context.push(Routes.addPlot),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.addPlot),
            ),
          ],
        ),
      ),
    );
  }
}
