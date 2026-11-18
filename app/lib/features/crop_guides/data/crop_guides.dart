import 'dart:convert';

import 'package:flutter/services.dart';

import '../../practices/data/practice_cards.dart' show PracticeSource;

/// One line of a crop guide (पीक मार्गदर्शक, owner 2026-11-14), with where it comes from.
/// [input] lines name a fertiliser, pesticide or organic input: no dose, and the text ends
/// with the expert-advice note (tested).
class CropGuideItem {
  const CropGuideItem({
    required this.id,
    required this.labels,
    required this.source,
    required this.sourceKeys,
    this.input = false,
  });

  final String id;
  final Map<String, String> labels;

  /// The reference inside the sources, e.g. "PDKV-LM, Variety NL-97".
  final String source;
  final List<String> sourceKeys;
  final bool input;

  String label(String lang) => labels[lang] ?? labels['en'] ?? '';
}

class CropGuideSection {
  const CropGuideSection(this.key, this.items);

  /// One of [CropGuidesData.sectionKeys]: land, sowing, varieties, seed, nutrition, water,
  /// intercultivation, protection, harvest.
  final String key;
  final List<CropGuideItem> items;

  Iterable<String> get sourceKeys => {for (final i in items) ...i.sourceKeys};
}

/// The guide for one crop, sowing to harvest.
class CropGuide {
  const CropGuide({
    required this.crop,
    required this.labels,
    required this.names,
    required this.sections,
    this.notNames = const [],
    this.aiWritten = false,
  });

  /// The crop slug of assets/config/crops.json.
  final String crop;
  final Map<String, String> labels;

  /// Names and common spellings that mean this crop in a text, per language (feed button).
  final Map<String, List<String>> names;

  /// Words that start with one of [names] but mean something else (मकान, a house, is not
  /// मका, maize): a match at such a word does not count.
  final List<String> notNames;
  final List<CropGuideSection> sections;

  /// The text was written by AI from the sources: the screen shows "AI ने निर्मित".
  final bool aiWritten;

  String label(String lang) => labels[lang] ?? labels['en'] ?? crop;

  Iterable<String> get sourceKeys => {
    for (final s in sections) ...s.sourceKeys,
  };
}

class CropGuidesData {
  const CropGuidesData({
    required this.sources,
    required this.sectionLabels,
    required this.guides,
  });

  static const sectionKeys = [
    'land',
    'sowing',
    'varieties',
    'seed',
    'nutrition',
    'water',
    'intercultivation',
    'protection',
    'harvest',
  ];

  final Map<String, PracticeSource> sources;
  final Map<String, Map<String, String>> sectionLabels;
  final List<CropGuide> guides;

  String sectionLabel(String key, String lang) =>
      sectionLabels[key]?[lang] ?? sectionLabels[key]?['en'] ?? key;

  CropGuide? forCrop(String? crop) =>
      guides.where((g) => g.crop == crop).firstOrNull;

  /// The guides whose crop [text] names, in guide order (a feed article, owner 2026-11-14).
  List<CropGuide> mentionedIn(String text) => [
    for (final g in guides)
      if (mentionsCrop(text, g)) g,
  ];
}

final _devanagari = RegExp(r'[ऀ-ॿ]');

/// Whether [text] names [guide]'s crop. Latin names match whole words, any case. A
/// Devanagari name matches where a word starts with it, so Marathi case endings count
/// (कापसाचे, तुरीचे, गव्हाचे, मक्याच्या) but a name inside another word does not (चना in
/// रचना), nor a word of the guide's [CropGuide.notNames] (मकान).
bool mentionsCrop(String text, CropGuide guide) {
  final lower = text.toLowerCase();
  for (final name in guide.names.values.expand((n) => n)) {
    final n = name.toLowerCase();
    if (_devanagari.hasMatch(n)) {
      var from = 0;
      while (true) {
        final at = lower.indexOf(n, from);
        if (at < 0) break;
        if ((at == 0 || !_devanagari.hasMatch(lower[at - 1])) &&
            !guide.notNames.any((w) => lower.startsWith(w.toLowerCase(), at))) {
          return true;
        }
        from = at + 1;
      }
    } else if (RegExp('(?<![a-z])${RegExp.escape(n)}(?![a-z])')
        .hasMatch(lower)) {
      return true;
    }
  }
  return false;
}

/// The bundled crop guides (assets/config/crop_guides.json): offline, a reviewer can correct
/// them without a code change, and a crop is added by config.
class CropGuidesConfig {
  CropGuidesConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/crop_guides.json';
  final AssetBundle _bundle;

  Future<CropGuidesData> load() async =>
      parseCropGuides(await _bundle.loadString(asset));
}

CropGuidesData parseCropGuides(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  Map<String, String> strings(Object? m) =>
      (m as Map? ?? const {}).cast<String, String>();
  List<Map<String, dynamic>> list(Object? l) =>
      (l as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  List<String> keys(Object? l) =>
      (l as List<dynamic>? ?? const []).cast<String>();
  return CropGuidesData(
    sources: {
      for (final e in (json['sources'] as Map<String, dynamic>).entries)
        if (e.value case final Map<String, dynamic> v)
          e.key: PracticeSource(
            v['title'] as String,
            v['url'] as String,
            publisher: v['publisher'] as String?,
            checked: DateTime.tryParse(v['checked'] as String? ?? ''),
          ),
    },
    sectionLabels: {
      for (final e in (json['section_labels'] as Map<String, dynamic>).entries)
        e.key: strings(e.value),
    },
    guides: [
      for (final g in list(json['crops']))
        CropGuide(
          crop: g['crop'] as String,
          labels: strings(g['labels']),
          names: {
            for (final e in (g['names'] as Map<String, dynamic>).entries)
              e.key: keys(e.value),
          },
          notNames: keys(g['not_names']),
          aiWritten: g['ai_written'] as bool? ?? false,
          sections: [
            for (final s in list(g['sections']))
              CropGuideSection(s['key'] as String, [
                for (final i in list(s['items']))
                  CropGuideItem(
                    id: i['id'] as String,
                    labels: strings(i['labels']),
                    source: i['source'] as String,
                    sourceKeys: keys(i['source_keys']),
                    input: i['input'] as bool? ?? false,
                  ),
              ]),
          ],
        ),
    ],
  );
}
