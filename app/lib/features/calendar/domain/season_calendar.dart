import '../../bahar/domain/bahar_cycle.dart';
import '../../tasks/domain/farm_task.dart';

enum CalendarEntryKind { stage, task }

/// One dated item on the season calendar: a bahar stage the grower dated (planned, or actual
/// once it happened) or a task. Only the grower's own dates; no timing advice.
class CalendarEntry {
  const CalendarEntry({
    required this.date,
    required this.kind,
    required this.done,
    this.plotId,
    this.bahar,
    this.stage,
    this.title,
  });

  final DateTime date;
  final CalendarEntryKind kind;

  /// Stage: the actual date is recorded. Task: ticked off.
  final bool done;
  final String? plotId;
  final String? bahar;
  final String? stage;

  /// Task title (stages are labelled from the bahar catalog).
  final String? title;
}

/// [months] calendar months starting with the month of [from], each with its entries sorted by
/// date. Empty months are kept so the grower sees the whole season. Tasks made from a bahar's
/// dates are left out: the stage itself is already on the calendar that day.
List<(DateTime, List<CalendarEntry>)> buildSeasonCalendar({
  required List<BaharCycle> cycles,
  required List<FarmTask> tasks,
  required DateTime from,
  int months = 12,
}) {
  final start = DateTime(from.year, from.month);
  final entries = <CalendarEntry>[
    for (final c in cycles)
      for (final stage in {...c.planned.keys, ...c.actual.keys})
        CalendarEntry(
          date: c.actual[stage] ?? c.planned[stage]!,
          kind: CalendarEntryKind.stage,
          done: c.actual.containsKey(stage),
          plotId: c.plotId,
          bahar: c.bahar,
          stage: stage,
        ),
    for (final t in tasks)
      if (t.baharCycleId == null)
        CalendarEntry(
          date: t.dueOn,
          kind: CalendarEntryKind.task,
          done: t.isDone,
          plotId: t.plotId,
          title: t.title,
        ),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return [
    for (var i = 0; i < months; i++)
      if (DateTime(start.year, start.month + i) case final month)
        (
          month,
          [
            for (final e in entries)
              if (e.date.year == month.year && e.date.month == month.month) e,
          ],
        ),
  ];
}
