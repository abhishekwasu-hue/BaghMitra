import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/alert_banner.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/price_card.dart';
import '../../../design_system/stage_timeline.dart';
import '../../../design_system/task_tile.dart';
import '../../../design_system/weather_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/sync_status_banner.dart';
import '../../../theme/app_theme.dart';
import '../../plots/domain/plot.dart';
import '../../profile/presentation/name_script_prompt.dart';
import '../../tasks/domain/farm_task.dart';
import '../../tasks/presentation/tasks_screen.dart' show todaysTasksShareText;
import '../../voice/presentation/share_speak_buttons.dart';
import '../../weather/presentation/alert_switch.dart';
import '../domain/home_snapshot.dart';

/// "Today's orchard": weather, bahar stage, risk alert, tasks, market price, camera.
/// Demo mode shows the bundled sample; every other build only the grower's own data.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final snapshot = ref.watch(homeSnapshotProvider(lang));
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: switch (snapshot) {
        AsyncValue(hasValue: true, :final value?) => _HomeBody(
          snapshot: value,
          lang: lang,
        ),
        AsyncError() => Center(child: Text(t.syncFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Opens [route] for the grower's block: straight away with one block, after a short
/// "choose a block" sheet with several. With no block yet, a short sheet first says why a
/// block is needed for [action] (its name as the grower tapped it); once the block is added
/// from there, [route] opens for it at once (the add-block form returns the new block's id).
Future<void> openForPlot(
  BuildContext context,
  List<Plot> plots,
  String Function(String plotId) route, {
  required String action,
}) async {
  if (plots.isEmpty) {
    final add = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => _NoPlotSheet(action: action),
    );
    if (add != true || !context.mounted) return;
    final id = await context.push<String>(Routes.addPlot);
    if (id != null && context.mounted) await context.push(route(id));
    return;
  }
  if (plots.length == 1) {
    await context.push(route(plots.single.id));
    return;
  }
  final t = AppLocalizations.of(context);
  final id = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BmSpace.lg),
            child: Text(t.choosePlot, style: BmType.section),
          ),
          for (final p in plots)
            ListTile(
              key: Key('pick-plot-${p.id}'),
              leading: const GlyphIcon(BmGlyph.orchard),
              title: Text(p.name, style: BmType.bodyStrong),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(sheet).pop(p.id),
            ),
        ],
      ),
    ),
  );
  if (id != null && context.mounted) await context.push(route(id));
}

/// "Add your block first": names the action the grower tapped, says why, and offers the
/// add-block form (or cancel).
class _NoPlotSheet extends StatelessWidget {
  const _NoPlotSheet({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return SafeArea(
      child: Padding(
        key: const Key('no-plot-sheet'),
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          0,
          BmSpace.lg,
          BmSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const GlyphIcon(BmGlyph.orchard),
                const SizedBox(width: BmSpace.xs),
                Expanded(
                  child: Text(
                    action,
                    style: BmType.label.copyWith(color: c.brand),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BmSpace.xs),
            Text(t.noPlotTitle, style: BmType.section),
            const SizedBox(height: BmSpace.xs),
            Text(t.noPlotBody, style: BmType.body.copyWith(color: c.inkMuted)),
            const SizedBox(height: BmSpace.lg),
            FilledButton.icon(
              key: const Key('no-plot-add'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.addPlot),
            ),
            const SizedBox(height: BmSpace.xs),
            TextButton(
              key: const Key('no-plot-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.snapshot, required this.lang});

  final HomeSnapshot snapshot;
  final String lang;

  static BmGlyph _stageGlyph(StageKind k) => switch (k) {
    StageKind.stress => BmGlyph.drop,
    StageKind.flowering => BmGlyph.flower,
    StageKind.fruitSet || StageKind.fruitGrowth => BmGlyph.fruitSet,
    StageKind.harvest => BmGlyph.orange,
  };

  static BmGlyph _kindGlyph(String kind) => switch (kind) {
    'irrigation' => BmGlyph.drop,
    'spray' => BmGlyph.spray,
    'scouting' => BmGlyph.camera,
    'harvest' => BmGlyph.orange,
    _ => BmGlyph.orchard,
  };

  static BmGlyph _taskGlyph(TaskKind k) => switch (k) {
    TaskKind.irrigation => BmGlyph.drop,
    TaskKind.spray => BmGlyph.spray,
    TaskKind.scouting => BmGlyph.camera,
    TaskKind.other => BmGlyph.orchard,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final ticks = ref.watch(taskTicksProvider);
    final w = snapshot.weather;
    final m = snapshot.market;
    final config = ref.watch(appConfigProvider);
    final now = ref.watch(clockProvider)();
    final realTasks = ref.watch(tasksProvider).value ?? const <FarmTask>[];
    final plots = ref.watch(plotsProvider).value ?? const <Plot>[];
    // Open tasks due today or earlier, and the ones ticked off today.
    final dueToday = [
      for (final task in realTasks)
        if (task.isDone
            ? dateOnly(task.doneOn!) == dateOnly(now)
            : !dateOnly(task.dueOn).isAfter(dateOnly(now)))
          task,
    ];
    // The sample task list is shown only in demo mode, and only until a real task exists.
    final sampleTasks = snapshot.isDemo && realTasks.isEmpty;
    // What "share today's tasks" hands on: the open ones.
    final openTitles = sampleTasks
        ? [
            for (final task in snapshot.tasks)
              if (!(ticks[task.id] ?? task.done)) task.title,
          ]
        : [
            for (final task in dueToday)
              if (!task.isDone) task.title,
          ];
    // The shared sync strip: signed out, offline, server unavailable, entries to check,
    // entries waiting; a test build with no backend says where the data lives instead.
    final banner = buildSyncStatusBanner(context, ref);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              WeatherHeader(
                greeting: t.greetingHello,
                name: snapshot.farmerName.isEmpty
                    ? ''
                    : t.greetingName(snapshot.farmerName),
                initial: snapshot.initial,
                temperature: w == null ? null : t.temperature(w.tempC),
                details: [
                  if (w != null) ...[
                    w.place,
                    ?w.condition,
                    if (w.maxC case final max?) t.maxTemperature(max),
                    if (w.minC case final min?) t.minTemperature(min),
                  ],
                ],
                soilPill: switch (w?.soilMoisturePct) {
                  final int pct => t.soilMoisture(pct),
                  null => null,
                },
                weatherNote: switch (snapshot.weatherNote) {
                  WeatherNote.needsLocation => t.homeWeatherNeedsLocation,
                  WeatherNote.notYetLoaded => t.weatherNone,
                  null => null,
                },
                onAvatarTap: () => context.push(Routes.profile),
                avatarLabel: t.profileTitle,
              ),
              if (snapshot.isDemo)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 6,
                  left: 0,
                  right: 0,
                  child: Center(child: _DemoChip(label: t.demoDataNotice)),
                ),
              if (config.isTestBuild)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 6,
                  right: BmSpace.md,
                  child: GestureDetector(
                    key: const Key('test-badge'),
                    onTap: () => context.push(Routes.settings),
                    child: _DemoChip(label: t.testBuildBadge(config.testBuild)),
                  ),
                ),
            ],
          ),
          // The stage card overlaps the header (painted later, so on top). Everything below
          // shifts with it; the 62 px this frees at the very end is harmless scroll slack.
          Transform.translate(
            offset: const Offset(0, -62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BmSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A name saved in Latin letters, in Marathi / Hindi: write it once in
                  // the script (owner request; no machine transliteration).
                  if (!snapshot.isDemo) const NameScriptPrompt(),
                  _stageBlock(context, t),
                  const SizedBox(height: BmSpace.sm),
                  if (banner != null) ...[
                    banner,
                    const SizedBox(height: BmSpace.sm),
                  ],
                  ..._alerts(t, ref, config.productName),
                  const SizedBox(height: BmSpace.xs),
                  // The core tasks one tap away, and "more" for every other screen (H1).
                  SectionHeader(
                    title: t.homeQuickTitle,
                    action: t.moreMenu,
                    onAction: () => context.push(Routes.more),
                  ),
                  _QuickActions(plots: plots),
                  const SizedBox(height: BmSpace.sm),
                  SectionHeader(
                    title: t.todaysTasks,
                    action: t.seeAll,
                    onAction: () => context.push(Routes.tasks),
                  ),
                  if (openTitles.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ShareSpeakButtons(
                        keyPrefix: 'home-tasks',
                        shareText: todaysTasksShareText(
                          t,
                          openTitles,
                          now,
                          lang,
                          config.productName,
                        ),
                        speakText: todaysTasksShareText(
                          t,
                          openTitles,
                          now,
                          lang,
                          null,
                        ),
                      ),
                    ),
                  if (sampleTasks)
                    for (final task in snapshot.tasks) ...[
                      TaskTile(
                        title: task.title,
                        subtitle: task.subtitle,
                        glyph: _taskGlyph(task.kind),
                        done: ticks[task.id] ?? task.done,
                        checkLabel: t.markTaskDone,
                        onToggle: (v) => ref
                            .read(taskTicksProvider.notifier)
                            .set(task.id, v),
                      ),
                      const SizedBox(height: 10),
                    ]
                  else ...[
                    if (dueToday.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(t.noTasksToday, style: BmType.meta),
                            ),
                            TextButton.icon(
                              key: const Key('home-add-task'),
                              onPressed: () => context.push(Routes.addTask),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(t.addTask),
                            ),
                          ],
                        ),
                      ),
                    for (final task in dueToday) ...[
                      TaskTile(
                        title: task.title,
                        subtitle: taskWhen(task, now) == TaskWhen.overdue
                            ? t.taskOverdue
                            : '',
                        glyph: _kindGlyph(task.kind),
                        done: task.isDone,
                        checkLabel: t.markTaskDone,
                        onToggle: (v) => ref
                            .read(tasksRepositoryProvider)
                            .setDone(task, done: v),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  SectionHeader(
                    title: m == null
                        ? t.marketPricesTitle
                        : t.marketTitle(m.market),
                    action: t.seeAll,
                    onAction: () => context.push(Routes.market),
                  ),
                  if (m != null)
                    GestureDetector(
                      key: const Key('home-price'),
                      onTap: () => context.push(Routes.market),
                      child: PriceHeroCard(
                        price: formatRupees(m.pricePerQuintal, lang),
                        caption: [
                          t.perQuintal,
                          ?m.grade,
                          if (m.day case final day?) formatDate(day, lang),
                        ].join(' · '),
                        change: switch (m.weeklyChangePct) {
                          final int pct => formatPercent(pct.abs(), lang),
                          null => null,
                        },
                        changeCaption: t.vsLastWeek,
                        changeLabel: switch (m.weeklyChangePct) {
                          final int pct when pct < 0 => t.priceChangeDown(
                            formatPercent(pct.abs(), lang),
                          ),
                          final int pct => t.priceChangeUp(
                            formatPercent(pct, lang),
                          ),
                          null => null,
                        },
                        rising: (m.weeklyChangePct ?? 0) >= 0,
                      ),
                    )
                  else
                    _linkCard(
                      context,
                      key: const Key('home-market-empty'),
                      icon: Icons.storefront_outlined,
                      title: t.homeOpenMarket,
                      subtitle: t.marketEmpty,
                      onTap: () => context.push(Routes.market),
                    ),
                  if (config.sarkariSandeshEnabled) ...[
                    const SizedBox(height: BmSpace.md),
                    SectionHeader(
                      title: t.feedTitle,
                      action: t.seeAll,
                      onAction: () => context.push(Routes.feed),
                    ),
                    _linkCard(
                      context,
                      key: const Key('open-feed'),
                      icon: Icons.account_balance_outlined,
                      title: t.feedTitle,
                      subtitle: t.feedOpenHint,
                      onTap: () => context.push(Routes.feed),
                    ),
                  ],
                  // Market link (flag only, spec v1.5 §2.1): the five role cards.
                  if (config.marketLink) ...[
                    const SizedBox(height: BmSpace.md),
                    _linkCard(
                      context,
                      key: const Key('open-roles'),
                      icon: Icons.handshake_outlined,
                      title: t.mlHomeLinkTitle,
                      subtitle: t.mlHomeLinkHint,
                      onTap: () => context.push(Routes.roles),
                    ),
                    // One tap to the grower's lots and the checked traders (owner
                    // 2026-11-08: both were hard to find under All features).
                    const SizedBox(height: BmSpace.xs),
                    Row(
                      children: [
                        for (final (i, (key, icon, label, route)) in [
                          (
                            'home-ml-lots',
                            Icons.sell_outlined,
                            t.mlOpen,
                            Routes.marketLots,
                          ),
                          (
                            'home-ml-people',
                            Icons.groups_outlined,
                            t.mlPeopleTitle,
                            Routes.marketLinkPeople,
                          ),
                        ].indexed) ...[
                          if (i > 0) const SizedBox(width: BmSpace.xs),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: Key(key),
                              onPressed: () => context.push(route),
                              icon: Icon(icon),
                              label: Text(label, textAlign: TextAlign.center),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: BmSpace.md),
                  _linkCard(
                    context,
                    key: const Key('open-schemes'),
                    icon: Icons.fact_check_outlined,
                    title: t.schemesTitle,
                    subtitle: t.schemesHomeHint,
                    onTap: () => context.push(Routes.schemes),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The bahar block: the stage card; else "start a bahar" for the block; else, for a
  /// grower with no block yet, the first step: add the first orchard block (H2).
  Widget _stageBlock(BuildContext context, AppLocalizations t) {
    final plotId = snapshot.plotId;
    if (!snapshot.hasPlot) {
      return _ActionCard(
        key: const Key('home-add-first-plot'),
        glyph: BmGlyph.orchard,
        title: t.plotsEmptyTitle,
        body: t.plotsEmptyBody,
        action: t.addPlot,
        onPressed: () => context.push(Routes.addPlot),
      );
    }
    final s = snapshot.stage;
    if (s == null) {
      return _ActionCard(
        key: const Key('home-start-bahar'),
        glyph: BmGlyph.flower,
        title: t.baharEmptyTitle,
        body: t.baharEmptyBody,
        action: t.startBahar,
        onPressed: plotId == null
            ? null
            : () => context.push(Routes.startBahar(plotId)),
      );
    }
    final next = [
      if ((s.nextName, s.nextInDays) case (final name?, final days?))
        t.homeNextStage(name, days),
      if (s.harvestMonth case final month?)
        t.homeHarvestMonth(formatMonth(month, lang)),
    ];
    final card = StageCard(
      tag: s.tag,
      stageName: s.currentName,
      dayCount: s.day == null ? '' : formatInt(s.day!, lang),
      dayUnit: s.day == null ? '' : t.stageDays,
      progress: s.progress,
      nodes: [
        for (final (i, ms) in s.milestones.indexed)
          StageNodeData(
            label: ms.label,
            glyph: _stageGlyph(ms.kind),
            position: ms.position,
            state: i < s.currentIndex
                ? StageState.done
                : i == s.currentIndex
                ? StageState.now
                : StageState.upcoming,
          ),
      ],
      nextLine: next.isEmpty ? t.homeStageAddDates : next.join(' · '),
    );
    if (plotId == null) return card;
    return GestureDetector(
      key: const Key('home-stage'),
      onTap: () => context.push(Routes.plotBahar(plotId)),
      child: card,
    );
  }

  /// The first alert of a type switched on, as the big card; each type the grower
  /// switched off with the ⚠ button as one muted line to switch it on again (Q133).
  List<Widget> _alerts(AppLocalizations t, WidgetRef ref, String productName) {
    final off = ref.watch(alertsOffProvider).value ?? const <String>{};
    bool isOff(RiskAlert a) => a.ruleKey != null && off.contains(a.ruleKey);
    final shown = snapshot.alerts.where((a) => !isOff(a)).firstOrNull;
    final offKeys = {
      for (final a in snapshot.alerts)
        if (isOff(a)) a.ruleKey!,
    };
    return [
      if (shown != null) _alert(t, ref, shown, productName),
      for (final key in offKeys)
        SwitchedOffAlert(ruleKey: key, keyPrefix: 'home-alert'),
    ];
  }

  Widget _alert(
    AppLocalizations t,
    WidgetRef ref,
    RiskAlert alert,
    String productName,
  ) {
    final body =
        alert.body ??
        [
          if (alert.firstDay case final day?) formatDate(day, lang),
          if (alert.source case final source?) t.weatherSource(source),
        ].join(' · ');
    final ruleKey = alert.ruleKey;
    return AlertBanner(
      title: alert.title,
      body: body,
      onToggle: ruleKey == null
          ? null
          : () => switchAlert(ref, ruleKey, on: false),
      toggleLabel: t.alertSwitchOff,
      toggleKey: ruleKey == null ? null : Key('home-alert-toggle-$ruleKey'),
      actions: ShareSpeakButtons(
        keyPrefix: 'home-alert',
        shareText: [alert.title, body, shareFooter(t, productName)].join('\n'),
        speakText: '${alert.title}\n$body',
      ),
    );
  }

  static Widget _linkCard(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => BmCard(
    elevated: false,
    padding: EdgeInsets.zero,
    child: Material(
      type: MaterialType.transparency,
      child: ListTile(
        key: key,
        leading: Icon(icon, color: context.bm.brand),
        title: Text(title, style: BmType.bodyStrong),
        subtitle: Text(subtitle, style: BmType.meta),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}

/// Home quick actions (audit H1): add a spray, add an expense, a scouting photo, market
/// prices. The record actions open for the grower's block (see [openForPlot]).
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.plots});

  final List<Plot> plots;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tiles = [
      _QuickTile(
        key: const Key('quick-spray'),
        icon: const GlyphIcon(BmGlyph.spray),
        label: t.addSpray,
        onTap: () =>
            openForPlot(context, plots, Routes.addSpray, action: t.addSpray),
      ),
      _QuickTile(
        key: const Key('quick-expense'),
        icon: const GlyphIcon(BmGlyph.ledger),
        label: t.addExpense,
        onTap: () => openForPlot(
          context,
          plots,
          Routes.addExpense,
          action: t.addExpense,
        ),
      ),
      _QuickTile(
        key: const Key('quick-photo'),
        icon: const GlyphIcon(BmGlyph.camera),
        label: t.takePhoto,
        onTap: () => openForPlot(
          context,
          plots,
          Routes.addScouting,
          action: t.takePhoto,
        ),
      ),
      _QuickTile(
        key: const Key('quick-market'),
        icon: Icon(Icons.storefront_outlined, color: context.bm.brand),
        label: t.marketPricesTitle,
        onTap: () => context.push(Routes.market),
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const SizedBox(width: BmSpace.xs),
            Expanded(child: tile),
          ],
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BmRadius.tile),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(BmRadius.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BmSpace.xxs,
            vertical: BmSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(BmSpace.xs + 2),
                decoration: BoxDecoration(
                  color: c.doneTint,
                  shape: BoxShape.circle,
                ),
                child: icon,
              ),
              const SizedBox(height: BmSpace.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: BmType.label.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card with one clear next step (add the first block, start a bahar).
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.glyph,
    required this.title,
    required this.body,
    required this.action,
    required this.onPressed,
  });

  final BmGlyph glyph;
  final String title;
  final String body;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return BmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(dimension: 40, child: GlyphIcon(glyph)),
              const SizedBox(width: BmSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: BmType.cardTitle.copyWith(color: c.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: BmSpace.xs),
          Text(body, style: BmType.body.copyWith(color: c.inkMuted)),
          const SizedBox(height: BmSpace.md),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BmSpace.xs, vertical: 2),
      decoration: BoxDecoration(
        color: c.onBrand.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(BmRadius.pill),
      ),
      child: Text(label, style: BmType.label.copyWith(color: c.onBrand)),
    );
  }
}
