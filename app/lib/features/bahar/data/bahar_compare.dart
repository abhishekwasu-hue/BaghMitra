import 'dart:convert';

import 'package:flutter/services.dart';

import 'bahar_catalog.dart';

/// A question the grower answers about their own orchard (e.g. water in April–May).
class CompareQuestion {
  const CompareQuestion(this.key, this.labels, this.options);

  final String key;
  final Map<String, String> labels;
  final List<LabeledOption> options;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

/// One sourced consideration about a bahar, shown when every `when` answer matches.
class ComparePoint {
  const ComparePoint({
    required this.bahar,
    required this.when,
    required this.labels,
    required this.source,
  });

  final String bahar;
  final Map<String, String> when;
  final Map<String, String> labels;
  final String source;

  String label(String lang) => labels[lang] ?? labels['en'] ?? '';
}

class BaharCompareData {
  const BaharCompareData(this.questions, this.points, {this.isDraft = true});

  final List<CompareQuestion> questions;
  final List<ComparePoint> points;
  final bool isDraft;

  /// Points for [bahar] whose conditions all hold. Never ranks bahars: the choice is the grower's.
  List<ComparePoint> pointsFor(String bahar, Map<String, String> answers) => [
    for (final p in points)
      if (p.bahar == bahar &&
          p.when.entries.every((w) => answers[w.key] == w.value))
        p,
  ];
}

/// Bahar comparison points from config, so sources can be corrected without a release.
class BaharCompareConfig {
  BaharCompareConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/bahar_compare.json';
  final AssetBundle _bundle;

  Future<BaharCompareData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    List<Map<String, dynamic>> list(Object? l) =>
        (l as List<dynamic>).cast<Map<String, dynamic>>();
    return BaharCompareData(
      [
        for (final q in list(json['questions']))
          CompareQuestion(q['key'] as String, strings(q['labels']), [
            for (final o in list(q['options']))
              LabeledOption(o['slug'] as String, strings(o['labels'])),
          ]),
      ],
      [
        for (final p in list(json['points']))
          ComparePoint(
            bahar: p['bahar'] as String,
            when: strings(p['when']),
            labels: strings(p['labels']),
            source: p['source'] as String,
          ),
      ],
      isDraft: json['status'] != 'reviewed',
    );
  }
}
