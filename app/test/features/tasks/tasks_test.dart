import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';

// pumpApp's clock is 2026-10-13 06:00 UTC.
FarmTask task(
  String id,
  DateTime due, {
  DateTime? done,
  String kind = 'spray',
}) => FarmTask(
  id: id,
  title: 'Task $id',
  kind: kind,
  dueOn: due,
  doneOn: done,
  source: 'manual',
);

void main() {
  final now = DateTime(2026, 10, 13, 6);

  test('tasks sort into overdue, today, upcoming and done', () {
    expect(taskWhen(task('a', DateTime(2026, 10, 12)), now), TaskWhen.overdue);
    expect(
      taskWhen(task('b', DateTime(2026, 10, 13, 23)), now),
      TaskWhen.today,
    );
    expect(taskWhen(task('c', DateTime(2026, 10, 14)), now), TaskWhen.upcoming);
    expect(
      taskWhen(task('d', DateTime(2026, 10), done: DateTime(2026, 10, 2)), now),
      TaskWhen.done,
    );
  });

  test('a task survives its payload round trip, with and without a plot', () {
    final t = FarmTask(
      id: 't',
      title: 'Prune',
      kind: 'pruning',
      dueOn: DateTime(2026, 11, 2),
      plotId: 'p1',
      baharCycleId: 'b1',
      doneOn: DateTime(2026, 11, 3),
      source: 'mrig (template)',
      note: 'north rows',
    );
    final back = FarmTask.fromPayload('t', t.toPayload());
    expect(back.toPayload(), t.toPayload());
    expect(task('x', DateTime(2026, 11)).toPayload()['plot_id'], isNull);
  });

  test(
    'repository queues farm_task mutations, ticks done and applies remote',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final clock = TestClock(DateTime.utc(2026, 10, 13, 6));
      final repo = TasksRepository(db, clock: clock.call);
      final t = task('t1', DateTime(2026, 10, 15));
      await repo.save(t);
      final queued = await db.select(db.outboxEntries).get();
      expect(queued.single.entity, 'farm_task');
      expect(jsonDecode(queued.single.payload), t.toPayload());

      await repo.setDone(t, done: true);
      final done = (await repo.watchAll().first).single;
      expect(done.doneOn, DateTime(2026, 10, 13));
      await repo.setDone(done, done: false);
      expect((await repo.watchAll().first).single.isDone, isFalse);

      await repo.applyRemote(
        RemoteChange(
          entity: 'farm_task',
          entityId: 't2',
          data: task('t2', DateTime(2026, 10, 14)).toPayload(),
          updatedAt: DateTime.utc(2026, 10, 13),
        ),
      );
      expect((await repo.watchAll().first).map((e) => e.id), ['t2', 't1']);
      await repo.delete('t1');
      expect((await db.select(db.outboxEntries).get()).last.op, 'delete');
      await repo.applyRemote(
        RemoteChange(
          entity: 'farm_task',
          entityId: 't2',
          data: const {},
          updatedAt: DateTime.utc(2026, 10, 14),
          deleted: true,
        ),
      );
      expect(await repo.watchAll().first, isEmpty);
    },
  );

  testWidgets('the tasks screen adds a task, ticks it done and deletes it', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/tasks',
    );
    expect(find.text('Add your first task with the + button.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title')), 'Check drip');
    await tester.tap(find.byKey(const Key('kind-irrigation')));
    await tester.tap(find.byKey(const Key('due-1')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Check drip'), findsOneWidget);
    expect(find.text('Irrigation'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);

    await tester.drag(find.text('Check drip'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Add your first task with the + button.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'home lists real tasks due today and ticks them through the repository',
    (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        seed: (db) async {
          final repo = TasksRepository(
            db,
            clock: () => DateTime.utc(2026, 10, 13, 6),
          );
          await repo.save(
            task('late', DateTime(2026, 10, 11), kind: 'irrigation'),
          );
          await repo.save(task('later', DateTime(2026, 10, 20)));
        },
      );
      expect(find.text('Task late'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Task later'), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      await tester.tap(find.text('Task late'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      final all = await tester.runAsync(
        () => container.read(tasksRepositoryProvider).watchAll().first,
      );
      expect(all!.firstWhere((t) => t.id == 'late').isDone, isTrue);
      await unmountApp(tester);
    },
  );
}
