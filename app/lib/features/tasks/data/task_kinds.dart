import 'dart:convert';

import 'package:flutter/services.dart';

import '../../bahar/data/bahar_catalog.dart';

/// Task kinds from config (`assets/config/task_kinds.json`).
class TaskKinds {
  TaskKinds({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/task_kinds.json';
  final AssetBundle _bundle;

  Future<List<LabeledOption>> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return [
      for (final k
          in (json['kinds'] as List<dynamic>).cast<Map<String, dynamic>>())
        LabeledOption(
          k['slug'] as String,
          (k['labels'] as Map).cast<String, String>(),
        ),
    ];
  }
}
