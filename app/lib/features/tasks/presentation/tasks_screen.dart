import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/farm_task.dart';

/// Every task grouped by when it is due. Tick one to mark it done; swipe to delete.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final tasks = ref.watch(tasksProvider).value ?? const <FarmTask>[];
    final kinds = ref.watch(taskKindsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final repo = ref.read(tasksRepositoryProvider);

    String kindLabel(String slug) =>
        [
          for (final k in kinds)
            if (k.slug == slug) k.label(lang),
        ].firstOrNull ??
        slug;

    final groups = <TaskWhen, String>{
      TaskWhen.overdue: t.tasksOverdue,
      TaskWhen.today: t.tasksToday,
      TaskWhen.upcoming: t.tasksUpcoming,
      TaskWhen.done: t.tasksDone,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(t.tasksTitle),
        actions: [
          IconButton(
            key: const Key('open-calendar'),
            tooltip: t.calendarOpen,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.push(Routes.calendar),
          ),
          IconButton(
            key: const Key('open-market'),
            tooltip: t.marketOpen,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => context.push(Routes.market),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton.icon(
            key: const Key('add-task'),
            onPressed: () => context.push(Routes.addTask),
            icon: const Icon(Icons.add_rounded),
            label: Text(t.addTask),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? EmptyState(glyph: BmGlyph.sunCloud, message: t.tasksEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                BmSpace.md,
                BmSpace.lg,
                96,
              ),
              children: [
                for (final entry in groups.entries)
                  if ([
                        for (final task in tasks)
                          if (taskWhen(task, now) == entry.key) task,
                      ]
                      case final inGroup when inGroup.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: BmSpace.md),
                      child: Text(entry.value, style: BmType.label),
                    ),
                    for (final task in inGroup)
                      Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: c.danger,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: BmSpace.lg),
                          child: Icon(Icons.delete_outline, color: c.onBrand),
                        ),
                        onDismissed: (_) => repo.delete(task.id),
                        child: CheckboxListTile(
                          key: Key('task-${task.id}'),
                          value: task.isDone,
                          onChanged: (v) =>
                              repo.setDone(task, done: v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(task.title, style: BmType.bodyStrong),
                          subtitle: Text(
                            kindLabel(task.kind),
                            style: BmType.meta,
                          ),
                        ),
                      ),
                  ],
              ],
            ),
    );
  }
}
