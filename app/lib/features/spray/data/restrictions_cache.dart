import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/spray_check.dart';

/// The gazette ban / restriction list, cached on the phone so spray checks work offline.
/// Refreshing is best effort: a failure keeps whatever is cached.
class RestrictionsCache {
  RestrictionsCache(this._db, {required this._api});

  static const metaKey = 'reference.restrictions';

  final AppDatabase _db;
  final Bagmitra _api;

  Future<RestrictionList> load() async {
    final raw = await _db.readMeta(metaKey);
    if (raw == null) return RestrictionList.empty();
    return RestrictionList.fromJson(
      (jsonDecode(raw) as Map).cast<String, Object?>(),
    );
  }

  /// Returns true when a fresh list was stored.
  Future<bool> refresh() async {
    try {
      final res = await _api.v1ReferenceRestrictionsGet();
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      final list = RestrictionList(
        rules: [
          for (final r in body.restrictions)
            RestrictionRule(
              activeIngredient: r.activeIngredient,
              kind: r.kind,
              crops: r.crops,
              cropGroups: r.cropGroups,
              notification: r.notification,
              effectiveFrom: r.effectiveFrom,
            ),
        ],
        synonyms: {for (final s in body.synonyms) s.name: s.activeIngredient},
      );
      await _db.writeMeta(metaKey, jsonEncode(list.toJson()));
      return true;
    } on Exception {
      return false;
    }
  }
}
