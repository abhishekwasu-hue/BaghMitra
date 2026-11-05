import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../domain/farm_task.dart';

/// Every task grouped by when it is due. Tick one to mark it done; swipe to delete. Finished
/// tasks stay folded behind "Show" (the latest [doneShown] of them), so the list stays
/// short however many seasons it holds; rows are built only as they scroll into view.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  /// How many finished tasks the open "Done" group lists, newest first.
  static const doneShown = 30;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  var _showDone = false;

  @override
  Widget build(BuildContext context) {
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
    // One flat list of headers and tasks, so the list view builds rows lazily.
    final rows = <_Row>[];
    for (final MapEntry(key: group, value: label) in groups.entries) {
      final inGroup = [
        for (final task in tasks)
          if (taskWhen(task, now) == group) task,
      ];
      if (inGroup.isEmpty) continue;
      if (group != TaskWhen.done) {
        rows
          ..add(_Header(label))
          ..addAll(inGroup.map(_TaskRow.new));
        continue;
      }
      rows.add(_Header(label, doneCount: inGroup.length));
      if (!_showDone) continue;
      final latest = [...inGroup]
        ..sort((a, b) => b.doneOn!.compareTo(a.doneOn!));
      rows.addAll(latest.take(TasksScreen.doneShown).map(_TaskRow.new));
      if (latest.length > TasksScreen.doneShown) {
        rows.add(
          _Note(t.tasksDoneLatest(formatInt(TasksScreen.doneShown, lang))),
        );
      }
    }
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
          : RefreshIndicator(
              onRefresh: ref.read(refresherProvider).records,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  BmSpace.lg,
                  BmSpace.md,
                  BmSpace.lg,
                  96,
                ),
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  _Header(:final label, :final doneCount) => Padding(
                    padding: const EdgeInsets.only(top: BmSpace.md),
                    child: Row(
                      children: [
                        Expanded(child: Text(label, style: BmType.label)),
                        if (doneCount != null)
                          TextButton(
                            key: const Key('tasks-done-toggle'),
                            onPressed: () =>
                                setState(() => _showDone = !_showDone),
                            child: Text(
                              _showDone
                                  ? t.tasksDoneHide
                                  : t.tasksDoneShow(formatInt(doneCount, lang)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Note(:final text) => Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xs),
                    child: Text(
                      text,
                      style: BmType.meta.copyWith(color: c.inkMuted),
                    ),
                  ),
                  _TaskRow(:final task) => Dismissible(
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
                      onChanged: (v) => repo.setDone(task, done: v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(task.title, style: BmType.bodyStrong),
                      subtitle: Text(kindLabel(task.kind), style: BmType.meta),
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
                },
              ),
            ),
    );
  }
}

sealed class _Row {
  const _Row();
}

class _Header extends _Row {
  const _Header(this.label, {this.doneCount});

  final String label;

  /// Set on the "Done" header: how many finished tasks it folds.
  final int? doneCount;
}

class _Note extends _Row {
  const _Note(this.text);

  final String text;
}

class _TaskRow extends _Row {
  const _TaskRow(this.task);

  final FarmTask task;
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
