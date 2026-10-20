import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/tasks/data/cycle_tasks_service.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/tasks/domain/cycle_tasks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart' show FileAssetBundle;
import '../../helpers/test_db.dart';

const templates = [
  TaskTemplate(
    stage: 'flowering',
    kind: 'scouting',
    titles: {'en': '{stage} today ({bahar})', 'mr': 'आज {stage} ({bahar})'},
  ),
  TaskTemplate(
    stage: 'harvest',
    kind: 'harvest',
    titles: {'en': 'Pick {stage}'},
  ),
];

BaharCycle cycle({Map<String, DateTime>? actual}) => BaharCycle(
  id: 'a0000000-0000-4000-8000-0000000000c1',
  plotId: 'p1',
  bahar: 'mrig',
  seasonYear: 2026,
  status: 'planned',
  planned: {
    'flowering': DateTime(2026, 6, 25),
    'harvest': DateTime(2027, 2, 10),
    'fruit_set': DateTime(2026, 8),
  },
  actual: actual ?? const {},
);

void main() {
  test(
    'one task per planned stage that has a template, due on the planned date',
    () {
      final tasks = tasksForCycle(
        cycle(),
        templates: templates,
        source: 'BagMitra stage reminder',
        lang: 'en',
        baharLabel: 'Mrig bahar',
        stageLabels: const {'flowering': 'Flowering', 'harvest': 'Harvest'},
      );
      expect(tasks.map((t) => t.dueOn), [
        DateTime(2026, 6, 25),
        DateTime(2027, 2, 10),
      ]);
      expect(tasks.first.title, 'Flowering today (Mrig bahar)');
      expect(tasks.first.plotId, 'p1');
      expect(tasks.first.baharCycleId, cycle().id);
      expect(tasks.last.kind, 'harvest');
      // fruit_set has a date but no template: no task.
      expect(tasks, hasLength(2));
    },
  );

  test('stages that already happened are skipped; unknown languages fall back to English', () {
    final tasks = tasksForCycle(
      cycle(actual: {'flowering': DateTime(2026, 6, 28)}),
      templates: templates,
      source: 's',
      lang: 'hi',
      baharLabel: 'B',
      stageLabels: const {'harvest': 'Harvest'},
    );
    expect(tasks.single.title, 'Pick Harvest');
  });

  test('the same stage always gets the same valid UUID', () {
    final a = cycleTaskId('c1', 'flowering');
    expect(a, cycleTaskId('c1', 'flowering'));
    expect(a, isNot(cycleTaskId('c1', 'harvest')));
    expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(a), isTrue);
  });

  test(
    'syncing twice does not duplicate, and a ticked task is left alone',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = TasksRepository(db, clock: TestClock().call);
      final service = CycleTasksService(repo, bundle: FileAssetBundle());
      Future<void> run() => service.sync(
        cycle(),
        lang: 'mr',
        baharLabel: 'मृग बहार',
        stageLabels: const {'flowering': 'फुलोरा', 'harvest': 'तोडणी'},
      );
      await run();
      await run();
      final tasks = await repo.watchAll().first;
      expect(
        tasks,
        hasLength(3),
      ); // stress_start has no planned date here; fruit_set does
      expect(tasks.map((t) => t.kind).toSet(), {'scouting', 'harvest'});
      expect(tasks.first.title, contains('मृग बहार'));

      await repo.setDone(tasks.first, done: true);
      await run();
      final after = await repo.watchAll().first;
      expect(after, hasLength(3));
      expect(after.firstWhere((t) => t.id == tasks.first.id).isDone, isTrue);
    },
  );
}
