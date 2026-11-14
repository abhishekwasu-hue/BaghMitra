import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/plot.dart';

class CropOption {
  const CropOption(
    this.slug,
    this.labels, {
    this.labelAliases = const [],
    this.groups = const [],
    this.primary = false,
    this.category = 'other',
    this.nameTyped = false,
  });

  final String slug;
  final Map<String, String> labels;

  /// Crop names as written on pesticide labels, and gazette crop groups (spray check).
  final List<String> labelAliases;
  final List<String> groups;

  /// One of the two big choices (santra, mosambi): the crops the citrus features are for.
  final bool primary;

  /// The section of the "other crops" list ([CropCategory.key]).
  final String category;

  /// The grower types the crop's name (vegetables, flowers, other): saved as the variety.
  final bool nameTyped;

  /// Label in [languageCode], falling back to English, then the slug (never blank).
  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? slug;
}

/// A section of the "other crops" list (fruit, field crops, vegetables, flowers, other).
class CropCategory {
  const CropCategory(this.key, this.labels);

  final String key;
  final Map<String, String> labels;

  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? key;
}

/// The crops and the sections of the "other crops" list, from config.
class CropCatalogData {
  const CropCatalogData(this.crops, this.categories);

  final List<CropOption> crops;
  final List<CropCategory> categories;
}

/// Crops a grower can pick. Loaded from config (bundled asset now, synced reference data
/// later) so adding a crop never needs a code change.
class CropCatalog {
  CropCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/crops.json';
  final AssetBundle _bundle;

  Future<List<CropOption>> load() async => (await loadAll()).crops;

  Future<CropCatalogData> loadAll() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return CropCatalogData(
      [
        for (final c
            in (json['crops'] as List<dynamic>).cast<Map<String, dynamic>>())
          CropOption(
            c['slug'] as String,
            (c['labels'] as Map).cast<String, String>(),
            labelAliases: ((c['label_aliases'] as List?) ?? const [])
                .cast<String>(),
            groups: ((c['groups'] as List?) ?? const []).cast<String>(),
            primary: c['primary'] as bool? ?? false,
            category: c['category'] as String? ?? 'other',
            nameTyped: c['name_typed'] as bool? ?? false,
          ),
      ],
      [
        for (final g
            in ((json['categories'] as List<dynamic>?) ?? const [])
                .cast<Map<String, dynamic>>())
          CropCategory(
            g['key'] as String,
            (g['labels'] as Map).cast<String, String>(),
          ),
      ],
    );
  }
}

/// The crop name of [plot] for display: the name the grower typed for a crop that asks for
/// one (vegetables, flowers, other), else the crop's label, else its slug.
String plotCropName(Plot plot, List<CropOption> crops, String lang) {
  final option = crops.where((c) => c.slug == plot.crop).firstOrNull;
  final typed = plot.variety?.trim();
  if (option != null && option.nameTyped && typed != null && typed.isNotEmpty) {
    return typed;
  }
  return option?.label(lang) ?? plot.crop;
}
