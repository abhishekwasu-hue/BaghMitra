import 'dart:convert';

import 'package:flutter/services.dart';

class CropOption {
  const CropOption(this.slug, this.labels);

  final String slug;
  final Map<String, String> labels;

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
        ),
    ];
  }
}
