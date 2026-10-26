import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';

/// The registered-label facts for one crop, with the time the phone saved them.
class CachedLabelClaims {
  const CachedLabelClaims(this.claims, this.savedAt);

  final List<LabelClaimOut> claims;
  final DateTime savedAt;
}

/// CIB&RC label information per crop, cached on the phone so it reads offline. This is
/// label information only, never advice. Refreshing is best effort: a failure keeps the cache.
class LabelClaimsCache {
  LabelClaimsCache(this._db, {required this._api, required this._clock});

  final AppDatabase _db;
  final Bagmitra _api;
  final DateTime Function() _clock;

  static String keyFor(String crop) => 'reference.label_claims.$crop';

  Future<CachedLabelClaims?> load(String crop) async {
    final raw = await _db.readMeta(keyFor(crop));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    final res = LabelClaimsResponse.fromJson(
      (j['response']! as Map).cast<String, dynamic>(),
    );
    return CachedLabelClaims(
      res.claims,
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh(String crop) async {
    try {
      final res = await _api.v1ReferenceLabelClaimsGet(crop: crop);
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      await _db.writeMeta(
        keyFor(crop),
        jsonEncode({
          'saved_at': _clock().toUtc().toIso8601String(),
          'response': body.toJson(),
        }),
      );
      return true;
    } on Exception {
      return false;
    }
  }
}
