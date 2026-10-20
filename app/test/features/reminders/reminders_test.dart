import 'package:bagmitra/features/reminders/domain/reminders.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:flutter_test/flutter_test.dart';

FarmTask _t(String id, DateTime due, {DateTime? done}) => FarmTask(
  id: id,
  title: 'Task $id',
  kind: 'other',
  dueOn: due,
  doneOn: done,
);

void main() {
  final now = DateTime(2026, 10, 20, 9);

  test('plans open future tasks at 7am on the due date, soonest first', () {
    final r = planReminders([
      _t('b', DateTime(2026, 10, 25)),
      _t('a', DateTime(2026, 10, 22)),
    ], now);
    expect(r.map((e) => e.title), ['Task a', 'Task b']);
    expect(r.first.at, DateTime(2026, 10, 22, 7));
  });

  test('skips done tasks and reminders already in the past', () {
    final r = planReminders([
      _t('done', DateTime(2026, 10, 22), done: DateTime(2026, 10, 21)),
      _t('today', DateTime(2026, 10, 20)),
      _t('late', DateTime(2026, 9, 30)),
      _t('tomorrow', DateTime(2026, 10, 21)),
    ], now);
    expect(r.map((e) => e.title), ['Task tomorrow']);
  });

  test('caps the list and keeps ids stable and non-negative', () {
    final tasks = [
      for (var i = 0; i < 100; i++) _t('t$i', DateTime(2027, 1, 1 + i % 28)),
    ];
    expect(planReminders(tasks, now), hasLength(60));
    expect(reminderId('abc'), reminderId('abc'));
    expect(reminderId('abc'), isNonNegative);
    expect(reminderId('abc'), isNot(reminderId('abd')));
  });
}
