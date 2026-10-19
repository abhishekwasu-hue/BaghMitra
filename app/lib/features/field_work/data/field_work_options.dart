import 'dart:convert';

import 'package:flutter/services.dart';

import '../../bahar/data/bahar_catalog.dart';

class FieldWorkOptionsData {
  const FieldWorkOptionsData(this.grades, this.sizeClasses, this.tasks);
  final List<LabeledOption> grades;
  final List<LabeledOption> sizeClasses;
  final List<LabeledOption> tasks;
}

/// Harvest grades, size classes and labour tasks from config (`assets/config/field_work.json`).
class FieldWorkOptions {
  FieldWorkOptions({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/field_work.json';
  final AssetBundle _bundle;

  Future<FieldWorkOptionsData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    List<LabeledOption> options(String key) => [
      for (final o in (json[key] as List<dynamic>).cast<Map<String, dynamic>>())
        LabeledOption(
          o['slug'] as String,
          (o['labels'] as Map).cast<String, String>(),
        ),
    ];
    return FieldWorkOptionsData(
      options('grades'),
      options('size_classes'),
      options('tasks'),
    );
  }
}
