import 'dart:convert';

import 'package:flutter/services.dart';

import '../../bahar/data/bahar_catalog.dart';

/// Languages a grower can pick, from config (`assets/config/languages.json`). Each name is
/// written in its own language, so it reads the same whatever language the app is in.
class LanguageCatalog {
  LanguageCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/languages.json';
  final AssetBundle _bundle;

  Future<List<LabeledOption>> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return [
      for (final o
          in (json['languages'] as List<dynamic>).cast<Map<String, dynamic>>())
        LabeledOption(
          o['slug'] as String,
          (o['labels'] as Map).cast<String, String>(),
        ),
    ];
  }
}
