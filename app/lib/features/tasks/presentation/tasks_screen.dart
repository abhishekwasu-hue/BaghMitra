import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../domain/farm_task.dart';

/// Every task grouped by when it is due. Tick one to mark it done; swipe to delete.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final loaded = ref.watch(tasksProvider);
    final tasks = loaded.value ?? const <FarmTask>[];
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
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : tasks.isEmpty
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
                          secondary: IconButton(
                            key: Key('task-details-${task.id}'),
                            tooltip: t.taskDetails,
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => showTaskDetails(
                              context,
                              task,
                              kindLabel(task.kind),
                            ),
                          ),
                        ),
                      ),
                  ],
              ],
            ),
    );
  }
}

/// One task in full (title, kind, due date, note) with read-aloud and share, in a sheet.
Future<void> showTaskDetails(
  BuildContext context,
  FarmTask task,
  String kindLabel,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => _TaskDetails(task: task, kindLabel: kindLabel),
);

class _TaskDetails extends ConsumerWidget {
  const _TaskDetails({required this.task, required this.kindLabel});

  final FarmTask task;
  final String kindLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final product = ref.watch(appConfigProvider).productName;
    return SafeArea(
      child: Padding(
        key: Key('task-sheet-${task.id}'),
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          0,
          BmSpace.lg,
          BmSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.taskDetails, style: BmType.label),
            const SizedBox(height: BmSpace.xxs),
            Text(task.title, style: BmType.cardTitle.copyWith(color: c.brand)),
            const SizedBox(height: BmSpace.xs),
            Text(kindLabel, style: BmType.body),
            Text(t.taskDueOn(formatDate(task.dueOn, lang)), style: BmType.body),
            if (task.note case final note? when note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: BmSpace.xs),
                child: Text(note, style: BmType.meta),
              ),
            const SizedBox(height: BmSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: ShareSpeakButtons(
                keyPrefix: 'task-${task.id}',
                shareText: taskShareText(t, task, kindLabel, lang, product),
                speakText: taskShareText(t, task, kindLabel, lang, null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What sharing a task hands on: title, kind, due date, the note and (unless read aloud,
/// [productName] null) where it came from. Only what the grower wrote.
String taskShareText(
  AppLocalizations t,
  FarmTask task,
  String kindLabel,
  String lang,
  String? productName,
) => [
  task.title,
  if (kindLabel.isNotEmpty) kindLabel,
  t.taskDueOn(formatDate(task.dueOn, lang)),
  if (task.note case final note? when note.isNotEmpty) note,
  if (productName != null) shareFooter(t, productName),
].join('\n');

/// Today's open tasks as one short text for the family or the labour mukadam.
String todaysTasksShareText(
  AppLocalizations t,
  List<String> titles,
  DateTime today,
  String lang,
  String? productName,
) => [
  t.tasksTodayShare(formatDate(today, lang)),
  for (final title in titles) '• $title',
  if (productName != null) shareFooter(t, productName),
].join('\n');
