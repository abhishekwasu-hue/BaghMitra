import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/home_snapshot.dart';

/// Reads the sample "today's orchard" from a language-keyed asset. Demo mode only (no backend
/// configured); every other build reads the grower's own data (`local_home_repository.dart`).
/// The sample carries no spray task, no spray advice and no mandi price (C1).
class DemoHomeRepository {
  DemoHomeRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/demo/home_demo.json';
  static const fallbackLanguage = 'en';

  final AssetBundle _bundle;

  Future<HomeSnapshot> load(String languageCode) async {
    final all =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    final data = all[languageCode] ?? all[fallbackLanguage];
    return HomeSnapshot.fromJson(
      (data as Map<String, dynamic>).cast(),
      isDemo: true,
    );
  }
}
