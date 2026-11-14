import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
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
    final loaded = ref.watch(plotsProvider);
    final plots = loaded.value ?? const <Plot>[];
    final crops = ref.watch(cropsProvider).value ?? const <CropOption>[];
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.myOrchard)),
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : plots.isEmpty
          ? const _EmptyOrchard()
          : RefreshIndicator(
              onRefresh: ref.read(refresherProvider).records,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
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
                  cropLabel: plotCropName(plots[i], crops, lang),
                  lang: lang,
                ),
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
}

/// One block in the list. The whole card opens the block (with ink feedback); deleting
/// lives on the block's edit screen, away from this main tap area.
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
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('plot-card-${plot.id}'),
          borderRadius: BorderRadius.circular(BmRadius.card),
          onTap: () => context.push(Routes.plot(plot.id)),
          child: Padding(
            padding: const EdgeInsets.all(BmSpace.md),
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
                  child: GlyphIcon(
                    plot.hasCitrusFeatures ? BmGlyph.orange : BmGlyph.orchard,
                  ),
                ),
                const SizedBox(width: BmSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.name,
                        style: BmType.section.copyWith(color: c.ink),
                      ),
                      Text(
                        cropLabel,
                        style: BmType.meta.copyWith(color: c.brandStrong),
                      ),
                      Text(
                        facts,
                        style: BmType.meta.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.inkMuted),
              ],
            ),
          ),
        ),
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
