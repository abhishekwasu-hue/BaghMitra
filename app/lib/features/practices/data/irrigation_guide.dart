import 'dart:convert';

import 'package:flutter/services.dart';

import 'practice_cards.dart' show PracticeSource;

typedef Labels = Map<String, String>;

String _pick(Labels l, String lang, [String fallback = '']) =>
    l[lang] ?? l['en'] ?? fallback;

/// A tree-age band, e.g. young = 0–4 years. [max] is null for the open top band.
class IrrigationAgeBand {
  const IrrigationAgeBand(this.key, this.min, this.max, this.labels);

  final String key;
  final int min;
  final int? max;
  final Labels labels;

  bool contains(int age) => age >= min && (max == null || age <= max!);

  String label(String lang) => _pick(labels, lang, key);
}

/// One sourced amount or interval for some ages in one season.
class IrrigationRow {
  const IrrigationRow({
    required this.id,
    required this.ages,
    required this.season,
    required this.method,
    required this.labels,
    required this.source,
    required this.sourceKeys,
  });

  final String id;
  final List<String> ages;
  final String season;
  final String method;
  final Labels labels;

  /// The reference inside the sources, e.g. "N1 §5.7.1".
  final String source;
  final List<String> sourceKeys;

  String label(String lang) => _pick(labels, lang);
}

/// A sourced point that holds for every age (critical stages, bahar rest).
class IrrigationNote {
  const IrrigationNote(this.id, this.labels, this.source, this.sourceKeys);

  final String id;
  final Labels labels;
  final String source;
  final List<String> sourceKeys;

  String label(String lang) => _pick(labels, lang);
}

class IrrigationCropGuide {
  const IrrigationCropGuide(this.rows, this.notes, this.gaps);

  final List<IrrigationRow> rows;
  final List<IrrigationNote> notes;

  /// What no readable source answered, per language.
  final List<Labels> gaps;

  List<IrrigationRow> rowsFor(String ageBand, String season) => [
    for (final r in rows)
      if (r.season == season && r.ages.contains(ageBand)) r,
  ];
}

class IrrigationGuideData {
  const IrrigationGuideData({
    required this.sources,
    required this.ageBands,
    required this.seasons,
    required this.methods,
    required this.crops,
    this.isDraft = true,
  });

  final Map<String, PracticeSource> sources;
  final List<IrrigationAgeBand> ageBands;

  /// Season key → labels, in display order.
  final Map<String, Labels> seasons;
  final Map<String, Labels> methods;
  final Map<String, IrrigationCropGuide> crops;

  /// Kept for the reviewer; the screen does not show it (Q30 / Q35).
  final bool isDraft;

  /// The band for trees planted in [plantingYear], or null when unknown or in the future.
  IrrigationAgeBand? bandFor(int? plantingYear, int thisYear) {
    if (plantingYear == null || plantingYear > thisYear) return null;
    final age = thisYear - plantingYear;
    for (final b in ageBands) {
      if (b.contains(age)) return b;
    }
    return null;
  }

  String seasonLabel(String key, String lang) =>
      _pick(seasons[key] ?? const {}, lang, key);

  String methodLabel(String key, String lang) =>
      _pick(methods[key] ?? const {}, lang, key);
}

/// Sourced irrigation guide from config, so a reviewer can correct it without a release.
class IrrigationGuideConfig {
  IrrigationGuideConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/irrigation_guide.json';
  final AssetBundle _bundle;

  Future<IrrigationGuideData> load() async => parse(
    jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>,
  );

  static IrrigationGuideData parse(Map<String, dynamic> json) {
    Labels strings(Object? m) => (m as Map? ?? const {}).cast<String, String>();
    List<Map<String, dynamic>> list(Object? l) =>
        (l as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    List<String> keys(Object? l) =>
        (l as List<dynamic>? ?? const []).cast<String>();
    return IrrigationGuideData(
      sources: (json['sources'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          PracticeSource(
            (v as Map<String, dynamic>)['title'] as String,
            v['url'] as String,
          ),
        ),
      ),
      ageBands: [
        for (final b in list(json['age_bands']))
          IrrigationAgeBand(
            b['key'] as String,
            b['min'] as int,
            b['max'] as int?,
            strings(b['labels']),
          ),
      ],
      seasons: {
        for (final s in list(json['seasons']))
          s['key'] as String: strings(s['labels']),
      },
      methods: (json['methods'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, strings(v)),
      ),
      crops: (json['crops'] as Map<String, dynamic>).map((crop, v) {
        final c = v as Map<String, dynamic>;
        return MapEntry(
          crop,
          IrrigationCropGuide(
            [
              for (final r in list(c['rows']))
                IrrigationRow(
                  id: r['id'] as String,
                  ages: keys(r['ages']),
                  season: r['season'] as String,
                  method: r['method'] as String,
                  labels: strings(r['labels']),
                  source: r['source'] as String,
                  sourceKeys: keys(r['source_keys']),
                ),
            ],
            [
              for (final n in list(c['notes']))
                IrrigationNote(
                  n['id'] as String,
                  strings(n['labels']),
                  n['source'] as String,
                  keys(n['source_keys']),
                ),
            ],
            [for (final g in list(c['gaps'])) strings(g)],
          ),
        );
      }),
      isDraft: json['status'] != 'reviewed',
    );
  }
}
