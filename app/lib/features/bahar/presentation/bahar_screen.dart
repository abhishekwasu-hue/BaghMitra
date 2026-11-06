import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/bahar_catalog.dart';
import '../domain/bahar_cycle.dart';

/// Bahar cycles of one orchard block, newest season first. Fully offline (reads Drift).
class BaharScreen extends ConsumerWidget {
  const BaharScreen({required this.plotId, super.key});

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
    final loaded = ref.watch(baharCyclesProvider(plotId));
    final cycles = loaded.value ?? const [];
    final catalog = ref.watch(baharOptionsProvider).value;
    void start() => context.push(Routes.startBahar(plotId));
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(plot?.name ?? ''),
        actions: [
          // One labelled menu instead of icon-only buttons: every record book of the block,
          // each with its icon and its name.
          PopupMenuButton<String>(
            key: const Key('bahar-records-menu'),
            tooltip: t.baharRecordsMenu,
            onSelected: context.push,
            itemBuilder: (_) => [
              for (final (route, icon, label) in [
                (
                  Routes.sprays(plotId),
                  const GlyphIcon(BmGlyph.spray),
                  t.sprayLogTitle,
                ),
                (
                  Routes.fieldLog(plotId),
                  const Icon(Icons.grass_outlined),
                  t.fieldLogTitle,
                ),
                (
                  Routes.accounts(plotId),
                  const Icon(Icons.account_balance_wallet_outlined),
                  t.accountsTitle,
                ),
                (
                  Routes.labour(plotId),
                  const Icon(Icons.groups_outlined),
                  t.labourTitle,
                ),
                (
                  Routes.harvest(plotId),
                  const GlyphIcon(BmGlyph.orange),
                  t.harvestTitle,
                ),
                (
                  Routes.scouting(plotId),
                  const Icon(Icons.search_rounded),
                  t.scoutingTitle,
                ),
              ])
                PopupMenuItem(
                  value: route,
                  child: Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(color: c.brand),
                        child: SizedBox.square(dimension: 24, child: icon),
                      ),
                      const SizedBox(width: BmSpace.sm),
                      Flexible(child: Text(label, style: BmType.body)),
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BmSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_rounded, color: c.brand),
                  const SizedBox(width: BmSpace.xxs),
                  Text(
                    t.baharRecordsMenu,
                    style: BmType.bodyStrong.copyWith(color: c.brand),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: c.brand),
                ],
              ),
            ),
          ),
        ],
      ),
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : cycles.isEmpty || catalog == null
          ? _Empty(onStart: start)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                BmSpace.xs,
                BmSpace.lg,
                120,
              ),
              itemCount: cycles.length,
              separatorBuilder: (_, _) => const SizedBox(height: BmSpace.sm),
              itemBuilder: (_, i) =>
                  _CycleCard(cycle: cycles[i], catalog: catalog, lang: lang),
            ),
      bottomNavigationBar: cycles.isEmpty
          ? null
          : BottomActions(
              children: [
                FilledButton.icon(
                  onPressed: start,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(t.startBahar),
                ),
              ],
            ),
    );
  }
}

String statusLabel(AppLocalizations t, String status) => switch (status) {
  'active' => t.baharStatusActive,
  'completed' => t.baharStatusCompleted,
  'abandoned' => t.baharStatusAbandoned,
  _ => t.baharStatusPlanned,
};

class _CycleCard extends StatelessWidget {
  const _CycleCard({
    required this.cycle,
    required this.catalog,
    required this.lang,
  });

  final BaharCycle cycle;
  final BaharCatalogData catalog;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return BmCard(
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox.square(
                dimension: 28,
                child: GlyphIcon(BmGlyph.flower),
              ),
              const SizedBox(width: BmSpace.xs),
              Expanded(
                child: Text(
                  catalog.baharLabel(cycle.bahar, lang),
                  style: BmType.section.copyWith(color: c.ink),
                ),
              ),
              Text(
                '${t.baharSeason} ${formatYear(cycle.seasonYear, lang)} · '
                '${statusLabel(t, cycle.status)}',
                style: BmType.meta.copyWith(color: c.brandStrong),
              ),
            ],
          ),
          for (final stage in catalog.stages)
            if (cycle.planned[stage.key] case final date?)
              Padding(
                padding: const EdgeInsets.only(top: BmSpace.xs),
                child: Text(
                  '${stage.label(lang)}: ${formatDate(date, lang)}',
                  style: BmType.body.copyWith(color: c.inkMuted),
                ),
              ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return EmptyState(
      glyph: BmGlyph.flower,
      title: t.baharEmptyTitle,
      message: t.baharEmptyBody,
      action: FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.startBahar),
      ),
    );
  }
}
