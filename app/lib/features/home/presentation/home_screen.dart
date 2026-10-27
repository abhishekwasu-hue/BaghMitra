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
import '../../../design_system/sync_banner.dart';
import '../../../design_system/task_tile.dart';
import '../../../design_system/weather_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/sync_engine.dart';
import '../../../theme/app_theme.dart';
import '../../tasks/domain/farm_task.dart';
import '../domain/home_snapshot.dart';

/// "Today's orchard": weather, bahar stage, risk alert, tasks, market price, camera.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final snapshot = ref.watch(homeSnapshotProvider(lang));
    final config = ref.watch(appConfigProvider);
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: switch (snapshot) {
        AsyncData(:final value) => _HomeBody(snapshot: value, lang: lang),
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
        onSelect: (i) {
          if (i == 1) context.push(Routes.plots);
        },
        cameraLabel: t.takePhoto,
        // Camera capture lands in M3; in dev builds the button opens the component gallery.
        onCamera: () {
          if (config.devGallery) context.push(Routes.gallery);
        },
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
    final sync = ref.watch(syncStatusProvider).value;
    final s = snapshot.stage;
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
    // A test build with no backend never syncs, so say where the data lives instead.
    final banner = config.demoMode && config.isTestBuild
        ? SyncBanner(kind: SyncBannerKind.offline, message: t.localModeBanner)
        : _syncBanner(t, sync);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              WeatherHeader(
                greeting: t.greetingHello,
                name: t.greetingName(snapshot.farmerName),
                initial: snapshot.initial,
                temperature: t.temperature(w.tempC),
                place: w.place,
                condition: w.condition,
                maxTemperature: t.maxTemperature(w.maxC),
                soilPill: t.soilMoisture(w.soilMoisturePct),
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
                  StageCard(
                    tag: s.tag,
                    stageName: s.currentName,
                    dayCount: formatInt(s.day, lang),
                    dayUnit: t.stageDays,
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
                    nextLine: t.nextStage(
                      s.nextName,
                      s.nextInDays,
                      formatMonth(s.harvestMonth, lang),
                    ),
                  ),
                  const SizedBox(height: BmSpace.sm),
                  if (banner != null) ...[
                    banner,
                    const SizedBox(height: BmSpace.sm),
                  ],
                  if (snapshot.alert case final alert?)
                    AlertBanner(title: alert.title, body: alert.body),
                  const SizedBox(height: BmSpace.xs),
                  SectionHeader(
                    title: t.todaysTasks,
                    action: t.seeAll,
                    onAction: () => context.push(Routes.tasks),
                  ),
                  if (realTasks.isNotEmpty) ...[
                    if (dueToday.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(t.noTasksToday, style: BmType.meta),
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
                  ] else
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
                    ],
                  SectionHeader(
                    title: t.marketTitle(m.market),
                    action: t.sevenDayTrend,
                    onAction: () {},
                  ),
                  PriceHeroCard(
                    price: formatRupees(m.pricePerQuintal, lang),
                    caption: '${t.perQuintal} · ${m.grade}',
                    change: formatPercent(m.weeklyChangePct.abs(), lang),
                    changeCaption: t.vsLastWeek,
                    rising: m.weeklyChangePct >= 0,
                  ),
                  if (config.sarkariSandeshEnabled) ...[
                    const SizedBox(height: BmSpace.md),
                    SectionHeader(
                      title: t.feedTitle,
                      action: t.seeAll,
                      onAction: () => context.push(Routes.feed),
                    ),
                    BmCard(
                      elevated: false,
                      padding: EdgeInsets.zero,
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          key: const Key('open-feed'),
                          leading: Icon(
                            Icons.account_balance_outlined,
                            color: context.bm.brand,
                          ),
                          title: Text(t.feedTitle, style: BmType.bodyStrong),
                          subtitle: Text(t.feedOpenHint, style: BmType.meta),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(Routes.feed),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget? _syncBanner(AppLocalizations t, SyncStatus? s) {
    if (s == null) return null;
    if (s.connectivity == Connectivity.offline) {
      return SyncBanner(kind: SyncBannerKind.offline, message: t.offlineBanner);
    }
    if (s.rejected > 0) {
      return SyncBanner(kind: SyncBannerKind.failed, message: t.syncFailed);
    }
    if (s.pending > 0) {
      return SyncBanner(
        kind: SyncBannerKind.pending,
        message: t.pendingSync(s.pending),
      );
    }
    return null;
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
      child: Text(
        label,
        style: BmType.label.copyWith(color: c.onBrand, fontSize: 11),
      ),
    );
  }
}
