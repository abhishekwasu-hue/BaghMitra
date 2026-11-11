import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/spray_check.dart' show normaliseName;

/// A kind of spray input the picker's first step offers (fungicide, insecticide, ...).
class SprayIngredientType {
  const SprayIngredientType(this.key, this.labels);

  final String key;
  final Map<String, String> labels;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

/// One compound the second step offers. [name] is what is saved in the record's active
/// ingredient, so the ban check reads it; the formulations are shown beside it.
class SprayIngredient {
  const SprayIngredient({
    required this.type,
    required this.name,
    required this.formulations,
    required this.source,
  });

  final String type;
  final String name;
  final List<String> formulations;
  final String source;

  /// "Captan 75% WP", or the name alone when the source prints no formulation.
  String get display =>
      formulations.isEmpty ? name : '$name ${formulations.join(', ')}';
}

/// The picker's list, bundled with the app so it works with no network (owner Q137). The
/// CIB&RC rows are generated from the label claims the API seeds.
class SprayIngredients {
  const SprayIngredients({required this.types, required this.entries});

  final List<SprayIngredientType> types;
  final List<SprayIngredient> entries;

  /// Compounds of one type, sorted by name.
  List<SprayIngredient> ofType(String type) =>
      entries.where((e) => e.type == type).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// The list entry a typed, saved or filled-in value names: the bare name, or the name with
  /// one of its formulations ("Captan 75% WP"), in any case and spacing. Null otherwise.
  SprayIngredient? match(String text) {
    final n = normaliseName(text);
    if (n.isEmpty) return null;
    for (final e in entries) {
      if (normaliseName(e.name) == n) return e;
    }
    for (final e in entries) {
      final name = normaliseName(e.name);
      for (final f in e.formulations) {
        if ('$name ${normaliseName(f)}' == n) return e;
      }
      if (normaliseName(e.display) == n) return e;
    }
    return null;
  }

  static SprayIngredients parse(Map<String, dynamic> json) => SprayIngredients(
    types: [
      for (final t
          in (json['types'] as List<dynamic>).cast<Map<String, dynamic>>())
        SprayIngredientType(
          t['key'] as String,
          (t['labels'] as Map).cast<String, String>(),
        ),
    ],
    entries: [
      for (final e
          in (json['entries'] as List<dynamic>).cast<Map<String, dynamic>>())
        SprayIngredient(
          type: e['type'] as String,
          name: e['name'] as String,
          formulations: ((e['formulations'] as List?) ?? const [])
              .cast<String>(),
          source: e['source'] as String,
        ),
    ],
  );
}

class SprayIngredientsConfig {
  SprayIngredientsConfig({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/spray_ingredients.json';
  final AssetBundle _bundle;

  Future<SprayIngredients> load() async => SprayIngredients.parse(
    jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>,
  );
}

final sprayIngredientsConfigProvider = Provider<SprayIngredientsConfig>(
  (ref) => SprayIngredientsConfig(),
);

/// The picker's bundled list; read from the app's assets, so it needs no network.
final sprayIngredientsProvider = FutureProvider<SprayIngredients>(
  (ref) => ref.watch(sprayIngredientsConfigProvider).load(),
);
