import 'dart:convert';

import 'package:flutter/services.dart';

/// A localized config entry (bahar or stage). Never renders blank.
class LabeledOption {
  const LabeledOption(this.slug, this.labels, {this.crops = const []});

  final String slug;
  final Map<String, String> labels;
  final List<String> crops;

  String get key => slug;
  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? slug;
}

class BaharCatalogData {
  const BaharCatalogData(this.bahars, this.stages);

  final List<LabeledOption> bahars;
  final List<LabeledOption> stages;

  List<LabeledOption> forCrop(String crop) =>
      bahars.where((b) => b.crops.contains(crop)).toList();

  String baharLabel(String slug, String lang) =>
      bahars.where((b) => b.slug == slug).firstOrNull?.label(lang) ?? slug;
}

/// Bahar names and hand-dated stages, from config so no release is needed to change them.
class BaharCatalog {
  BaharCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/bahars.json';
  final AssetBundle _bundle;

  Future<BaharCatalogData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    LabeledOption parse(Map<String, dynamic> m, String id) => LabeledOption(
      m[id] as String,
      (m['labels'] as Map).cast<String, String>(),
      crops: ((m['crops'] as List?) ?? const []).cast<String>(),
    );
    List<Map<String, dynamic>> list(String k) =>
        (json[k] as List<dynamic>).cast<Map<String, dynamic>>();
    return BaharCatalogData(
      [for (final b in list('bahars')) parse(b, 'slug')],
      [for (final s in list('manual_stages')) parse(s, 'key')],
    );
  }
}
