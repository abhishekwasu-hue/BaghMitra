import 'dart:convert';

import 'package:flutter/services.dart';

/// A published page a practice comes from.
class PracticeSource {
  const PracticeSource(this.title, this.url);

  final String title;
  final String url;
}

/// One non-chemical orchard practice, with where it comes from and how strong that source is.
class PracticeItem {
  const PracticeItem({
    required this.id,
    required this.labels,
    required this.source,
    required this.sourceKeys,
    required this.evidence,
  });

  final int id;
  final Map<String, String> labels;

  /// The reference inside the sources, e.g. "N1 §5.7.1".
  final String source;
  final List<String> sourceKeys;

  /// Any of [PracticeCardsData.evidenceKinds].
  final List<String> evidence;

  String label(String lang) => labels[lang] ?? labels['en'] ?? '';
}

class PracticeSection {
  const PracticeSection(this.key, this.labels, this.items);

  final String key;
  final Map<String, String> labels;
  final List<PracticeItem> items;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

class PracticeCardsData {
  const PracticeCardsData({
    required this.sources,
    required this.sections,
    required this.gaps,
    this.isDraft = true,
  });

  static const evidenceKinds = {
    'official',
    'university',
    'research',
    'inferred',
  };

  final Map<String, PracticeSource> sources;
  final List<PracticeSection> sections;

  /// Problems with no non-chemical practice in the sources, per language.
  final List<Map<String, String>> gaps;

  /// Kept for the reviewer; the screen does not show it (owner 2026-10-26, Q30).
  final bool isDraft;
}

/// Sourced practice cards from config, so a reviewer can correct them without a release.
class PracticeCardsConfig {
  PracticeCardsConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/practice_cards.json';
  final AssetBundle _bundle;

  Future<PracticeCardsData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    List<Map<String, dynamic>> list(Object? l) =>
        (l as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final sources = (json['sources'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        k,
        PracticeSource(
          (v as Map<String, dynamic>)['title'] as String,
          v['url'] as String,
        ),
      ),
    );
    return PracticeCardsData(
      sources: sources,
      sections: [
        for (final s in list(json['sections']))
          PracticeSection(s['key'] as String, strings(s['labels']), [
            for (final i in list(s['items']))
              PracticeItem(
                id: i['id'] as int,
                labels: strings(i['labels']),
                source: i['source'] as String,
                sourceKeys: (i['source_keys'] as List<dynamic>).cast<String>(),
                evidence: (i['evidence'] as List<dynamic>).cast<String>(),
              ),
          ]),
      ],
      gaps: [for (final g in list(json['gaps'])) strings(g)],
      isDraft: json['status'] != 'reviewed',
    );
  }
}
