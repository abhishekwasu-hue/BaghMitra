import 'dart:convert';

import 'package:flutter/services.dart';

/// A parameter name a lab report usually lists, offered as a typing shortcut. Name and
/// usual unit only: never a value or a rating of the grower's own value.
class LabParameter {
  const LabParameter(this.key, this.labels, {this.unit});

  final String key;
  final Map<String, String> labels;
  final String? unit;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

/// One class of a rating range as the official source prints it, e.g. "Low  < 0.5".
/// [tone] is the source's colour meaning: `ok` (sufficient / normal), `mid` (moderate) or
/// `bad` (deficient / beyond normal).
class LabNormRange {
  const LabNormRange(this.classLabels, this.range, {required this.tone});

  final Map<String, String> classLabels;
  final String range;
  final String tone;

  String label(String lang) => classLabels[lang] ?? classLabels['en'] ?? '';
}

/// The rating ranges of one parameter ([key] matches a [LabParameter.key]).
class LabNormRow {
  const LabNormRow(this.key, this.ranges, {this.unit});

  final String key;
  final String? unit;
  final List<LabNormRange> ranges;
}

/// General rating ranges for one test type from a named official source (Q57: shown as
/// general information with the source and the day it was read). Only a reference table:
/// the app never rates the grower's values and never turns a range into fertiliser advice.
class LabNorms {
  const LabNorms({
    required this.sourceShort,
    required this.sourceUrl,
    required this.checked,
    required this.rows,
    required this.gap,
  });

  final String sourceShort;
  final String sourceUrl;
  final DateTime checked;
  final List<LabNormRow> rows;

  /// What the source leaves out, per language.
  final Map<String, String> gap;

  String gapIn(String lang) => gap[lang] ?? gap['en'] ?? '';
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

  /// Rating ranges per test type (only types the source covers).
  Future<Map<String, LabNorms>> loadNorms() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    return (json['norms'] as Map<String, dynamic>? ?? const {}).map((type, v) {
      final n = v as Map<String, dynamic>;
      final source = n['source'] as Map<String, dynamic>;
      final classes = (n['classes'] as Map<String, dynamic>).map(
        (k, l) => MapEntry(k, strings(l)),
      );
      return MapEntry(
        type,
        LabNorms(
          sourceShort: source['short'] as String,
          sourceUrl: source['url'] as String,
          checked: DateTime.parse(source['checked'] as String),
          gap: strings(n['gap']),
          rows: [
            for (final r
                in (n['rows'] as List<dynamic>).cast<Map<String, dynamic>>())
              LabNormRow(r['key'] as String, unit: r['unit'] as String?, [
                for (final g
                    in (r['ranges'] as List<dynamic>)
                        .cast<Map<String, dynamic>>())
                  LabNormRange(
                    classes[g['class']] ?? const {},
                    g['range'] as String,
                    tone: g['tone'] as String,
                  ),
              ]),
          ],
        ),
      );
    });
  }
}
