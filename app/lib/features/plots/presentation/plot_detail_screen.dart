import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../weather/presentation/plot_weather_card.dart';
import '../domain/geo.dart';

/// One block at a glance: what the grower entered, the boundary, and the way into its bahars,
/// sprays, field log and accounts.
class PlotDetailScreen extends ConsumerWidget {
  const PlotDetailScreen({required this.plotId, super.key});

  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    final crops = ref.watch(cropsProvider).value ?? const [];
    if (plot == null) return const Scaffold(body: SizedBox.shrink());
    final cropLabel =
        [
          for (final k in crops)
            if (k.slug == plot.crop) k.label(lang),
        ].firstOrNull ??
        plot.crop;
    final corners = cornersFromGeoJson(plot.boundary);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: BmType.meta.copyWith(color: c.inkMuted)),
          ),
          Expanded(flex: 3, child: Text(value, style: BmType.bodyStrong)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(plot.name, style: BmType.section.copyWith(color: c.brand)),
        actions: [
          IconButton(
            key: const Key('edit-plot'),
            tooltip: t.editPlot,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editPlot(plot.id)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          row(t.plotCrop, cropLabel),
          if (plot.variety != null) row(t.plotVariety, plot.variety!),
          row(t.plotAreaAcres, formatDecimal(plot.areaAcres, lang)),
          if (plot.treeCount != null)
            row(t.plotTreeCount, formatInt(plot.treeCount!, lang)),
          if (plot.plantingYear != null)
            row(t.plotPlantingYear, formatYear(plot.plantingYear!, lang)),
          row(
            t.boundaryWalk,
            corners == null
                ? t.plotBoundaryNone
                : t.boundaryMarked(corners.length),
          ),
          if (plot.centroidLat != null && plot.centroidLon != null)
            row(
              t.plotCentre,
              '${plot.centroidLat!.toStringAsFixed(5)}, '
              '${plot.centroidLon!.toStringAsFixed(5)}',
            ),
          if (plot.centroidLat != null && plot.centroidLon != null) ...[
            const SizedBox(height: BmSpace.lg),
            PlotWeatherCard(plotId: plot.id),
          ],
          const SizedBox(height: BmSpace.lg),
          FilledButton(
            key: const Key('open-records'),
            onPressed: () => context.push(Routes.plotBahar(plot.id)),
            child: Text(t.plotOpenRecords),
          ),
          const SizedBox(height: BmSpace.sm),
          OutlinedButton(
            onPressed: () => context.push(Routes.editPlot(plot.id)),
            child: Text(t.editPlot),
          ),
        ],
      ),
    );
  }
}
