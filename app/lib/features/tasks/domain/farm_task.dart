import '../../bahar/domain/bahar_cycle.dart';

/// A job with a due date: made by the grower, or generated from a template (then [source] says
/// which). Without a [plotId] it belongs to the whole orchard. Done is just a date.
class FarmTask {
  const FarmTask({
    required this.id,
    required this.title,
    required this.kind,
    required this.dueOn,
    this.plotId,
    this.baharCycleId,
    this.doneOn,
    this.source,
    this.note,
  });

  final String id;
  final String title;

  /// Slug from `assets/config/task_kinds.json`.
  final String kind;
  final DateTime dueOn;
  final String? plotId;
  final String? baharCycleId;
  final DateTime? doneOn;
  final String? source;
  final String? note;

  bool get isDone => doneOn != null;

  FarmTask withDone(DateTime? on) => FarmTask(
    id: id,
    title: title,
    kind: kind,
    dueOn: dueOn,
    plotId: plotId,
    baharCycleId: baharCycleId,
    doneOn: on,
    source: source,
    note: note,
  );

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'title': title,
    'kind': kind,
    'due_on': BaharCycle.isoDate(dueOn),
    'done_on': doneOn == null ? null : BaharCycle.isoDate(doneOn!),
    'source': source,
    'note': note,
  };

  static FarmTask fromPayload(String id, Map<String, Object?> p) => FarmTask(
    id: id,
    plotId: p['plot_id'] as String?,
    baharCycleId: p['bahar_cycle_id'] as String?,
    title: p['title']! as String,
    kind: p['kind']! as String,
    dueOn: DateTime.parse(p['due_on']! as String),
    doneOn: p['done_on'] == null
        ? null
        : DateTime.parse(p['done_on']! as String),
    source: p['source'] as String?,
    note: p['note'] as String?,
  );
}

/// Where a task sits relative to today, for grouping the list.
enum TaskWhen { overdue, today, upcoming, done }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

TaskWhen taskWhen(FarmTask t, DateTime now) {
  if (t.isDone) return TaskWhen.done;
  final today = dateOnly(now);
  final due = dateOnly(t.dueOn);
  if (due.isBefore(today)) return TaskWhen.overdue;
  return due == today ? TaskWhen.today : TaskWhen.upcoming;
}
