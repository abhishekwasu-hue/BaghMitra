import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/entitlements.dart';

/// The last entitlement snapshot, kept on the phone so gated features keep working offline.
/// Refreshing is best effort: a failure keeps whatever is cached.
class EntitlementsCache {
  EntitlementsCache(this._db, {required this._api, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const metaKey = 'billing.entitlements';
  static const rulesAsset = 'assets/config/entitlements.json';

  final AppDatabase _db;
  final Bagmitra _api;
  final AssetBundle _bundle;

  Future<EntitlementRules> rules() async => EntitlementRules.fromJson(
    jsonDecode(await _bundle.loadString(rulesAsset)) as Map<String, dynamic>,
  );

  Future<EntitlementSnapshot?> load() async {
    final raw = await _db.readMeta(metaKey);
    if (raw == null) return null;
    return EntitlementSnapshot.fromJson(
      (jsonDecode(raw) as Map).cast<String, Object?>(),
    );
  }

  /// Returns true when a fresh snapshot was stored.
  Future<bool> refresh() async {
    try {
      final res = await _api.v1BillingEntitlementsGet();
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      final e = body.entitlements;
      final snapshot = EntitlementSnapshot(
        features: {for (final f in e.features.entries) f.key: f.value as int?},
        plans: e.plans,
        computedAt: DateTime.parse(e.computedAt),
        validUntil: DateTime.parse(e.validUntil),
      );
      await _db.writeMeta(metaKey, jsonEncode(snapshot.toJson()));
      return true;
    } on Exception {
      return false;
    }
  }
}
