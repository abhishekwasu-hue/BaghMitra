import 'package:uuid/uuid.dart';

import '../../bahar/domain/bahar_cycle.dart';
import 'farm_task.dart';

/// One reminder made from a bahar stage date. Config, not code (`assets/config/task_templates.json`).
class TaskTemplate {
  const TaskTemplate({
    required this.stage,
    required this.kind,
    required this.titles,
  });

  final String stage;
  final String kind;
  final Map<String, String> titles;

  String title(
    String lang, {
    required String stageLabel,
    required String baharLabel,
  }) => (titles[lang] ?? titles['en'] ?? stageLabel)
      .replaceAll('{stage}', stageLabel)
      .replaceAll('{bahar}', baharLabel);
}

const _namespace =
    '6ba7b811-9dad-11d1-80b4-00c04fd430c8'; // the standard URL namespace

/// The same bahar stage always gets the same task id, so making them again updates instead of
/// duplicating (and the id is a valid UUID, as the sync API requires).
String cycleTaskId(String cycleId, String stage) =>
    const Uuid().v5(_namespace, 'bagmitra:cycle-task:$cycleId:$stage');

/// Reminders for the stage dates the grower planned. Stages that already have an actual date are
/// skipped: they have happened.
List<FarmTask> tasksForCycle(
  BaharCycle cycle, {
  required List<TaskTemplate> templates,
  required String source,
  required String lang,
  required String baharLabel,
  required Map<String, String> stageLabels,
}) => [
  for (final t in templates)
    if (cycle.planned[t.stage] case final due?
        when !cycle.actual.containsKey(t.stage))
      FarmTask(
        id: cycleTaskId(cycle.id, t.stage),
        plotId: cycle.plotId,
        baharCycleId: cycle.id,
        title: t.title(
          lang,
          stageLabel: stageLabels[t.stage] ?? t.stage,
          baharLabel: baharLabel,
        ),
        kind: t.kind,
        dueOn: due,
        source: source,
      ),
];
