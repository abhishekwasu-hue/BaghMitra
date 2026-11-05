import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/alert_banner.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/navigation.dart';
import '../../../design_system/price_card.dart';
import '../../../design_system/stage_timeline.dart';
import '../../../design_system/task_tile.dart';
import '../../../design_system/weather_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/sync_status_banner.dart';
import '../../../theme/app_theme.dart';
import '../../plots/domain/plot.dart';
import '../../tasks/domain/farm_task.dart';
import '../../tasks/presentation/tasks_screen.dart' show todaysTasksShareText;
import '../../voice/presentation/share_speak_buttons.dart';
import '../domain/home_snapshot.dart';

/// "Today's orchard": weather, bahar stage, risk alert, tasks, market price, camera.
/// Demo mode shows the bundled sample; every other build only the grower's own data.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final snapshot = ref.watch(homeSnapshotProvider(lang));
    final config = ref.watch(appConfigProvider);
    final plots = ref.watch(plotsProvider).value ?? const <Plot>[];
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
      bottomNavigationBar: BmBottomBar(
        items: [
          BmNavItem(BmGlyph.home, t.navHome),
          BmNavItem(BmGlyph.orchard, t.navOrchard),
          BmNavItem(BmGlyph.ledger, t.navAccounts),
          BmNavItem(BmGlyph.mic, t.navAsk),
        ],
        selected: 0,
        onSelect: (i) => switch (i) {
          1 => context.push(Routes.plots),
          2 => openForPlot(context, plots, Routes.accounts),
          // "Ask": the practices guide, grouped by problem, with its links to the
          // look-alike symptoms and the labs (the app has no question flow).
          3 => context.push(Routes.practices),
          _ => null,
        },
        cameraLabel: t.takePhoto,
        // A scouting record with a photo, for the grower's block.
        onCamera: () => openForPlot(context, plots, Routes.addScouting),
        onCameraLongPress: config.devGallery
            ? () => context.push(Routes.gallery)
            : null,
      ),
    );
  }
}

/// Opens [route] for the grower's block: straight away with one block, after a short
/// "choose a block" sheet with several, and the add-block form when there is none yet.
Future<void> openForPlot(
  BuildContext context,
  List<Plot> plots,
  String Function(String plotId) route,
) async {
  if (plots.isEmpty) {
    await context.push(Routes.addPlot);
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
                  _stageBlock(context, t),
                  const SizedBox(height: BmSpace.sm),
                  if (banner != null) ...[
                    banner,
                    const SizedBox(height: BmSpace.sm),
                  ],
                  if (snapshot.alert case final alert?)
                    _alert(t, alert, config.productName),
                  const SizedBox(height: BmSpace.xs),
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

  Widget _alert(AppLocalizations t, RiskAlert alert, String productName) {
    final body =
        alert.body ??
        [
          if (alert.firstDay case final day?) formatDate(day, lang),
          if (alert.source case final source?) t.weatherSource(source),
        ].join(' · ');
    return AlertBanner(
      title: alert.title,
      body: body,
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
