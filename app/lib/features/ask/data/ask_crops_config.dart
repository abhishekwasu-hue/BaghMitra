import 'dart:convert';

import 'package:flutter/services.dart';

import '../../crop_guides/data/crop_guides.dart';
import '../../plots/data/crop_catalog.dart';
import '../domain/ask_crops.dart';

/// The question box's crop names (assets/config/ask_crops.json, owner 2026-11-15).
class AskCropsConfig {
  AskCropsConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/ask_crops.json';
  final AssetBundle _bundle;

  Future<Map<String, dynamic>> load() async =>
      jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
}

List<String> _strings(Object? l) =>
    (l as List<dynamic>? ?? const []).cast<String>();

Iterable<String> _allNames(Object? byLanguage) => [
  for (final v in (byLanguage as Map<String, dynamic>? ?? const {}).values)
    ..._strings(v),
];

/// The parts of a crop label that are names: "Tur (pigeon pea)" -> "Tur", "pigeon pea";
/// "Lime / lemon" -> "Lime", "lemon".
Iterable<String> labelNames(String label) => [
  for (final part in label.split(RegExp(r'[()/,]')))
    if (part.trim().isNotEmpty) part.trim(),
];

/// Joins the config with the crop list (labels and label aliases) and the crop guides'
/// names, so a crop added there is known here without a change.
AskCrops buildAskCrops(
  Map<String, dynamic> config,
  CropCatalogData catalog,
  CropGuidesData? guides,
) {
  final skip = _strings(config['skip_slugs']).toSet();
  final extra = config['names'] as Map<String, dynamic>? ?? const {};
  final endings = config['endings'] as Map<String, dynamic>? ?? const {};
  return AskCrops(
    qaCrops: _strings(config['qa_crops']).toSet(),
    ignoreNames: _strings(config['ignore_names']),
    notCropPhrases: _strings(config['not_crop_phrases']),
    devanagariEndings: _strings(endings['devanagari']),
    latinEndings: _strings(endings['latin']),
    crops: [
      for (final c in catalog.crops)
        if (!skip.contains(c.slug))
          (
            slug: c.slug,
            labels: c.labels,
            names: [
              for (final l in c.labels.values) ...labelNames(l),
              ...c.labelAliases,
              ...?guides?.forCrop(c.slug)?.names.values.expand((n) => n),
              ..._allNames(extra[c.slug]),
              // Citrus words that hold another crop's word count as santra.
              if (c.slug == 'santra') ..._strings(config['citrus_terms']),
            ],
          ),
      for (final o
          in (config['other_crops'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        (
          slug: o['slug'] as String,
          labels: (o['labels'] as Map).cast<String, String>(),
          names: [
            for (final l in (o['labels'] as Map).values.cast<String>())
              ...labelNames(l),
            ..._allNames(o['names']),
          ],
        ),
    ],
  );
}
