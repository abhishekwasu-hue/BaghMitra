import 'package:uuid/uuid.dart';

import '../../bahar/domain/bahar_cycle.dart';
import 'farm_task.dart';

/// One reminder made from a bahar stage date. Config, not code (`assets/config/task_templates.json`).
class TaskTemplate {
  const TaskTemplate({
    required this.stage,
    required this.kind,
    required this.titles,
    this.id,
    this.crops = const [],
    this.bahars = const [],
    this.offsetDays = 0,
    this.source,
  });

  final String stage;
  final String kind;
  final Map<String, String> titles;

  /// Set for a stage operation (several per stage); null for the one plain stage reminder.
  final String? id;

  /// Limits the template to these crops / bahars; empty means all.
  final List<String> crops;
  final List<String> bahars;

  /// Days after the stage date the task is due.
  final int offsetDays;

  /// Where the operation comes from; null uses the file's source.
  final String? source;

  bool appliesTo(String? crop, String bahar) =>
      (bahars.isEmpty || bahars.contains(bahar)) &&
      (crops.isEmpty || (crop != null && crops.contains(crop)));

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
String cycleTaskId(String cycleId, String stage, [String? operation]) =>
    const Uuid().v5(
      _namespace,
      operation == null
          ? 'bagmitra:cycle-task:$cycleId:$stage'
          : 'bagmitra:cycle-task:$cycleId:$stage:$operation',
    );

/// Reminders for the stage dates the grower planned. Stages that already have an actual date are
/// skipped: they have happened. A template limited to other crops or bahars is skipped too.
List<FarmTask> tasksForCycle(
  BaharCycle cycle, {
  required List<TaskTemplate> templates,
  required String source,
  required String lang,
  required String baharLabel,
  required Map<String, String> stageLabels,
  String? crop,
}) => [
  for (final t in templates)
    if (cycle.planned[t.stage] case final due?
        when !cycle.actual.containsKey(t.stage) &&
            t.appliesTo(crop, cycle.bahar))
      FarmTask(
        id: cycleTaskId(cycle.id, t.stage, t.id),
        plotId: cycle.plotId,
        baharCycleId: cycle.id,
        title: t.title(
          lang,
          stageLabel: stageLabels[t.stage] ?? t.stage,
          baharLabel: baharLabel,
        ),
        kind: t.kind,
        dueOn: DateTime(due.year, due.month, due.day + t.offsetDays),
        source: t.source ?? source,
      ),
];
