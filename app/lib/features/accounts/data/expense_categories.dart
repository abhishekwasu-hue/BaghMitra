import 'dart:convert';

import 'package:flutter/services.dart';

import '../../bahar/data/bahar_catalog.dart';

/// Expense categories from config (`assets/config/expense_categories.json`).
class ExpenseCategories {
  ExpenseCategories({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/expense_categories.json';
  final AssetBundle _bundle;

  Future<List<LabeledOption>> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    return [
      for (final c
          in (json['categories'] as List<dynamic>).cast<Map<String, dynamic>>())
        LabeledOption(
          c['slug'] as String,
          (c['labels'] as Map).cast<String, String>(),
        ),
    ];
  }
}
