import 'dart:convert';

import 'package:flutter/services.dart';

import '../../bahar/domain/bahar_cycle.dart';
import '../domain/cycle_tasks.dart';
import 'tasks_repository.dart';

/// Makes (or updates) the reminders for a bahar cycle's planned stage dates. A reminder the
/// grower already ticked off is left alone.
class CycleTasksService {
  CycleTasksService(this._tasks, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/task_templates.json';

  final TasksRepository _tasks;
  final AssetBundle _bundle;

  Future<({List<TaskTemplate> templates, String source})> _load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return (
      source: json['source'] as String,
      templates: [
        for (final t
            in (json['templates'] as List<dynamic>)
                .cast<Map<String, dynamic>>())
          TaskTemplate(
            stage: t['stage'] as String,
            kind: t['kind'] as String,
            titles: (t['titles'] as Map).cast<String, String>(),
          ),
      ],
    );
  }

  Future<void> sync(
    BaharCycle cycle, {
    required String lang,
    required String baharLabel,
    required Map<String, String> stageLabels,
  }) async {
    final cfg = await _load();
    final existing = {for (final t in await _tasks.watchAll().first) t.id: t};
    for (final task in tasksForCycle(
      cycle,
      templates: cfg.templates,
      source: cfg.source,
      lang: lang,
      baharLabel: baharLabel,
      stageLabels: stageLabels,
    )) {
      if (existing[task.id]?.isDone ?? false) continue;
      await _tasks.save(task);
    }
  }
}
