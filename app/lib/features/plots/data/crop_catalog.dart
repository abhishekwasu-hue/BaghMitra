import 'dart:convert';

import 'package:flutter/services.dart';

class CropOption {
  const CropOption(
    this.slug,
    this.labels, {
    this.labelAliases = const [],
    this.groups = const [],
  });

  final String slug;
  final Map<String, String> labels;

  /// Crop names as written on pesticide labels, and gazette crop groups (spray check).
  final List<String> labelAliases;
  final List<String> groups;

  /// Label in [languageCode], falling back to English, then the slug (never blank).
  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? slug;
}

/// Crops a grower can pick. Loaded from config (bundled asset now, synced reference data
/// later) so adding a crop never needs a code change.
class CropCatalog {
  CropCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/crops.json';
  final AssetBundle _bundle;

  Future<List<CropOption>> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return [
      for (final c
          in (json['crops'] as List<dynamic>).cast<Map<String, dynamic>>())
        CropOption(
          c['slug'] as String,
          (c['labels'] as Map).cast<String, String>(),
          labelAliases: ((c['label_aliases'] as List?) ?? const [])
              .cast<String>(),
          groups: ((c['groups'] as List?) ?? const []).cast<String>(),
        ),
    ];
  }
}
