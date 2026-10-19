import 'dart:convert';

import 'package:flutter/services.dart';

import '../../bahar/data/bahar_catalog.dart';

class InputKindsData {
  const InputKindsData(this.kinds, this.units);
  final List<LabeledOption> kinds;
  final List<LabeledOption> units;
}

/// Input kinds and units from config (`assets/config/input_kinds.json`).
class InputKinds {
  InputKinds({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/input_kinds.json';
  final AssetBundle _bundle;

  Future<InputKindsData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    List<LabeledOption> options(String key) => [
      for (final o in (json[key] as List<dynamic>).cast<Map<String, dynamic>>())
        LabeledOption(
          o['slug'] as String,
          (o['labels'] as Map).cast<String, String>(),
        ),
    ];
    return InputKindsData(options('kinds'), options('units'));
  }
}
