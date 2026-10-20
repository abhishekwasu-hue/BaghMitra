import '../../tasks/domain/farm_task.dart';

/// One phone notification: a task that is due, shown in the morning of its due date.
class Reminder {
  const Reminder({required this.id, required this.at, required this.title});

  /// Stable 31-bit id from the task id, so re-planning replaces rather than duplicates.
  final int id;
  final DateTime at;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.at == at &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, at, title);
}

/// Replaces every pending reminder with [reminders]. Implementations are idempotent.
abstract interface class ReminderScheduler {
  Future<void> replaceAll(String heading, List<Reminder> reminders);
}

/// Used in tests and where notifications are unavailable.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> replaceAll(String heading, List<Reminder> reminders) async {}
}

/// Open tasks whose reminder time ([hour] on the due date) is still ahead of [now], soonest
/// first, at most [limit] (phones keep a bounded alarm list).
List<Reminder> planReminders(
  List<FarmTask> tasks,
  DateTime now, {
  int hour = 7,
  int limit = 60,
}) {
  final out = <Reminder>[];
  for (final t in tasks) {
    if (t.isDone) continue;
    final at = DateTime(t.dueOn.year, t.dueOn.month, t.dueOn.day, hour);
    if (!at.isAfter(now)) continue;
    out.add(Reminder(id: reminderId(t.id), at: at, title: t.title));
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > limit ? out.sublist(0, limit) : out;
}

/// FNV-1a over the id, kept to 31 bits (Android notification ids are ints).
int reminderId(String taskId) {
  var h = 0x811c9dc5;
  for (final c in taskId.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}
