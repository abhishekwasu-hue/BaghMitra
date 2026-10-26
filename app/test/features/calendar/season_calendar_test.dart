import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/calendar/domain/season_calendar.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlotWithCycle;
import '../plots/plots_screen_test.dart' show settle;

FarmTask _task(String id, DateTime due, {String? cycleId}) => FarmTask(
  id: id,
  title: 'Task $id',
  kind: 'other',
  dueOn: due,
  baharCycleId: cycleId,
);

void main() {
  final from = DateTime(2026, 10, 20);
  final cycle = BaharCycle(
    id: 'c1',
    plotId: 'p1',
    bahar: 'mrig',
    seasonYear: 2026,
    status: 'active',
    planned: {
      'flowering': DateTime(2026, 11, 5),
      'harvest': DateTime(2027, 2, 10),
    },
    actual: {'flowering': DateTime(2026, 11, 2)},
  );

  test('twelve months from the current one, stages and tasks by date', () {
    final months = buildSeasonCalendar(
      cycles: [cycle],
      tasks: [
        _task('a', DateTime(2026, 11, 20)),
        _task('stage-reminder', DateTime(2026, 11, 5), cycleId: 'c1'),
        _task('too-late', DateTime(2027, 10, 2)),
      ],
      from: from,
    );
    expect(months, hasLength(12));
    expect(months.first.$1, DateTime(2026, 10));
    expect(months.last.$1, DateTime(2027, 9));
    expect(months.first.$2, isEmpty);

    final nov = months[1].$2;
    expect(nov, hasLength(2), reason: 'stage reminder task is not repeated');
    expect(nov.first.stage, 'flowering');
    expect(nov.first.date, DateTime(2026, 11, 2), reason: 'actual wins');
    expect(nov.first.done, isTrue);
    expect(nov.last.title, 'Task a');

    final feb = months[4].$2.single;
    expect((feb.stage, feb.done), ('harvest', false));
  });

  testWidgets('tasks screen opens the calendar with the bahar stage', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/tasks',
      seed: (db) async {
        await seedPlotWithCycle(db);
        await TasksRepository(db)
            .save(_task('a0000000-0000-4000-8000-000000000001', from));
      },
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-calendar')));
    await settle(tester);
    expect(find.text('Season calendar'), findsOneWidget);
    expect(find.text('Flowering · Ambia bahar'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('बाग १'), 200);
    expect(find.textContaining('planned'), findsOneWidget);
    await unmountApp(tester);
  });
}
