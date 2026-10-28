import 'dart:convert';

import 'package:flutter/services.dart';

/// A parameter name a lab report usually lists, offered as a typing shortcut. Name and
/// usual unit only: never a value, a range or a rating.
class LabParameter {
  const LabParameter(this.key, this.labels, {this.unit});

  final String key;
  final Map<String, String> labels;
  final String? unit;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

/// Parameter-name suggestions per test type from config
/// (`assets/config/lab_parameters.json`, a draft a reviewer can change without a release).
class LabParameters {
  LabParameters({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/lab_parameters.json';
  final AssetBundle _bundle;

  Future<Map<String, List<LabParameter>>> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return (json['types'] as Map<String, dynamic>).map(
      (type, list) => MapEntry(type, [
        for (final p in (list as List<dynamic>).cast<Map<String, dynamic>>())
          LabParameter(
            p['key'] as String,
            (p['labels'] as Map).cast<String, String>(),
            unit: p['unit'] as String?,
          ),
      ]),
    );
  }
}
