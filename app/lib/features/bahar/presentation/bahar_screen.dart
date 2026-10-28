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
    final cycles = ref.watch(baharCyclesProvider(plotId)).value ?? const [];
    final catalog = ref.watch(baharOptionsProvider).value;
    void start() => context.push(Routes.startBahar(plotId));
    return Scaffold(
      appBar: AppBar(
        title: Text(plot?.name ?? ''),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).sprayLogTitle,
            onPressed: () => context.push(Routes.sprays(plotId)),
            icon: Icon(Icons.water_drop_outlined, color: c.brand),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).fieldLogTitle,
            onPressed: () => context.push(Routes.fieldLog(plotId)),
            icon: Icon(Icons.grass_outlined, color: c.brand),
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context).moreMenu,
            icon: Icon(Icons.more_vert, color: c.brand),
            onSelected: context.push,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: Routes.labour(plotId),
                child: Text(AppLocalizations.of(context).labourTitle),
              ),
              PopupMenuItem(
                value: Routes.harvest(plotId),
                child: Text(AppLocalizations.of(context).harvestTitle),
              ),
              PopupMenuItem(
                value: Routes.scouting(plotId),
                child: Text(AppLocalizations.of(context).scoutingTitle),
              ),
            ],
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).accountsTitle,
            onPressed: () => context.push(Routes.accounts(plotId)),
            icon: Icon(Icons.account_balance_wallet_outlined, color: c.brand),
          ),
        ],
      ),
      body: cycles.isEmpty || catalog == null
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
