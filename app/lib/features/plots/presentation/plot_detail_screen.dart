import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../weather/presentation/plot_weather_card.dart';
import '../domain/geo.dart';
import 'plot_point.dart';

/// One block at a glance: what the grower entered, the boundary and location, its weather,
/// then one tile per record book of the block (bahar first).
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
    // Pull to refresh: the plot's weather and the latest records from the server.
    Future<void> refresh() async {
      final refresher = ref.read(refresherProvider);
      await Future.wait([
        refresher.plotWeather(plotId, lang),
        refresher.records(),
      ]);
    }

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
        title: Text(plot.name),
        actions: [
          IconButton(
            key: const Key('edit-plot'),
            tooltip: t.editPlot,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editPlot(plot.id)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            PlotLocationRow(
              point: plot.centroidLat != null && plot.centroidLon != null
                  ? LatLon(plot.centroidLat!, plot.centroidLon!)
                  : null,
              onCaptured: (p) => ref
                  .read(plotRepositoryProvider)
                  .save(plot.withCentre(p.lat, p.lon)),
            ),
            if (plot.centroidLat != null && plot.centroidLon != null) ...[
              const SizedBox(height: BmSpace.lg),
              PlotWeatherCard(plotId: plot.id),
            ],
            const SizedBox(height: BmSpace.lg),
            PlotTiles(plotId: plot.id),
          ],
        ),
      ),
    );
  }
}

/// The way into a block's records: Bahar as the one primary tile, then a two-column grid
/// of labelled tiles, one per screen, each opened with one tap.
class PlotTiles extends StatelessWidget {
  const PlotTiles({required this.plotId, super.key});

  final String plotId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tiles = <_TileSpec>[
      (
        key: 'open-sprays',
        icon: const GlyphIcon(BmGlyph.spray, size: 28),
        label: t.sprayLogTitle,
        route: Routes.sprays(plotId),
      ),
      (
        key: 'open-field-log',
        icon: const Icon(Icons.grass_outlined),
        label: t.fieldLogTitle,
        route: Routes.fieldLog(plotId),
      ),
      (
        key: 'open-accounts',
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: t.accountsTitle,
        route: Routes.accounts(plotId),
      ),
      (
        key: 'open-labour',
        icon: const Icon(Icons.groups_outlined),
        label: t.labourTitle,
        route: Routes.labour(plotId),
      ),
      (
        key: 'open-harvest',
        icon: const GlyphIcon(BmGlyph.orange, size: 28),
        label: t.harvestTitle,
        route: Routes.harvest(plotId),
      ),
      (
        key: 'open-scouting',
        icon: const Icon(Icons.search_rounded),
        label: t.scoutingTitle,
        route: Routes.scouting(plotId),
      ),
      (
        key: 'open-insurance',
        icon: const Icon(Icons.verified_user_outlined),
        label: t.insuranceTitle,
        route: Routes.insurance(plotId),
      ),
      (
        key: 'open-lab-tests',
        icon: const Icon(Icons.science_outlined),
        label: t.labTestsTitle,
        route: Routes.labTests(plotId),
      ),
      (
        key: 'open-irrigation-guide',
        icon: const GlyphIcon(BmGlyph.drop, size: 28),
        label: t.irrigationOpen,
        route: Routes.irrigationGuide(plotId),
      ),
      (
        key: 'open-practices',
        icon: const Icon(Icons.eco_outlined),
        label: t.practicesOpen,
        route: Routes.practices,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tile(
          spec: (
            key: 'open-records',
            icon: GlyphIcon(
              BmGlyph.flower,
              size: 28,
              color: context.bm.onAccent,
            ),
            label: t.plotTileBahar,
            route: Routes.plotBahar(plotId),
          ),
          primary: true,
        ),
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.sm),
            // Both tiles of a row take the taller one's height at any text size.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _Tile(spec: tiles[i])),
                  const SizedBox(width: BmSpace.sm),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? _Tile(spec: tiles[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

typedef _TileSpec = ({String key, Widget icon, String label, String route});

class _Tile extends StatelessWidget {
  const _Tile({required this.spec, this.primary = false});

  final _TileSpec spec;

  /// The block's main record book: filled like the app's primary buttons, icon beside the label.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final fg = primary ? c.onAccent : c.ink;
    final label = Text(
      spec.label,
      style: (primary ? BmType.section : BmType.bodyStrong).copyWith(color: fg),
    );
    final icon = SizedBox.square(
      dimension: 28,
      child: IconTheme(
        data: IconThemeData(color: primary ? c.onAccent : c.brand, size: 28),
        child: spec.icon,
      ),
    );
    return Material(
      color: primary ? c.accent : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BmRadius.tile),
        side: primary ? BorderSide.none : BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key(spec.key),
        onTap: () => context.push(spec.route),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BmSpace.tapTarget + 24),
          child: Padding(
            padding: const EdgeInsets.all(BmSpace.sm),
            child: primary
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: BmSpace.sm),
                      Expanded(child: label),
                      Icon(Icons.chevron_right_rounded, color: fg),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(height: BmSpace.xs),
                      label,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
