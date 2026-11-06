import 'dart:convert';

import 'package:flutter/services.dart';

/// One pest or disease the label screen groups rows under, with its name in each language.
class LabelTarget {
  const LabelTarget(this.key, this.labels, this.match);

  final String key;
  final Map<String, String> labels;

  /// Lower-case words looked for in the target as printed on the label.
  final List<String> match;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

/// Display keys for CIB&RC label targets (owner Q57). Rows are grouped by key only for the
/// grower's language; the printed target is still shown on every row, and a printed target
/// that matches no key keeps its own printed name.
class LabelTargetsData {
  const LabelTargetsData({
    required this.targets,
    required this.practiceSections,
    required this.scoutingItems,
  });

  final List<LabelTarget> targets;

  /// Practice section key -> target keys (practice cards link to the label screen).
  final Map<String, List<String>> practiceSections;

  /// Scouting item -> target keys (scouting records and look-alike cards).
  final Map<String, List<String>> scoutingItems;

  static final _nonLetters = RegExp('[^a-z]+');

  LabelTarget? byKey(String key) =>
      targets.where((t) => t.key == key).firstOrNull;

  /// The display key for a target as printed on the label, or null when none matches.
  String? keyFor(String printed) {
    final words = ' ${printed.toLowerCase().replaceAll(_nonLetters, ' ')} '
        .replaceAll(RegExp(' +'), ' ');
    for (final t in targets) {
      for (final m in t.match) {
        if (words.contains(' $m ') || words.contains(' ${m}s ')) return t.key;
      }
    }
    return null;
  }
}

class LabelTargetsConfig {
  LabelTargetsConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/label_targets.json';
  final AssetBundle _bundle;

  Future<LabelTargetsData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, List<String>> links(Object? m) => {
      for (final e in (m as Map? ?? const {}).entries)
        e.key as String: (e.value as List).cast<String>(),
    };
    return LabelTargetsData(
      targets: [
        for (final t
            in (json['targets'] as List<dynamic>).cast<Map<String, dynamic>>())
          LabelTarget(
            t['key'] as String,
            (t['labels'] as Map).cast<String, String>(),
            (t['match'] as List).cast<String>(),
          ),
      ],
      practiceSections: links(json['practice_sections']),
      scoutingItems: links(json['scouting_items']),
    );
  }
}
