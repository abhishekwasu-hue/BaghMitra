import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/insurance_policy.dart';

/// Enrolment deadlines from published official notices (`GET /v1/insurance/deadlines`),
/// cached on the phone so they show offline. Refreshing is best effort: a failure keeps
/// whatever is cached, and nothing cached means no deadline is shown (never a guess).
class InsuranceDeadlinesCache {
  InsuranceDeadlinesCache(this._db, {required this._api});

  final AppDatabase _db;
  final Bagmitra _api;

  static String keyFor(String lang) => 'insurance.deadlines.$lang';

  Future<List<InsuranceDeadline>> load(String lang) async {
    final raw = await _db.readMeta(keyFor(lang));
    if (raw == null) return const [];
    return [
      for (final j in jsonDecode(raw) as List)
        InsuranceDeadline.fromJson((j as Map).cast<String, Object?>()),
    ];
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh(String lang) async {
    try {
      final res = await _api.v1InsuranceDeadlinesGet(
        lang: V1InsuranceDeadlinesGetLang.values
            .where((l) => l.value == lang)
            .firstOrNull,
      );
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      final items = [
        for (final o in body.items)
          InsuranceDeadline(
            itemId: o.itemId,
            title: o.title,
            dueDate: o.dueDate,
            url: o.url,
            season: o.season,
          ).toJson(),
      ];
      await _db.writeMeta(keyFor(lang), jsonEncode(items));
      return true;
    } on Exception {
      return false;
    }
  }
}
