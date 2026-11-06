import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/entitlements.dart';
import 'snapshot_signature.dart';

/// The last entitlement snapshot, kept on the phone so gated features keep working offline.
/// Refreshing is best effort: a failure keeps whatever is cached. The server's signed payload
/// is stored as it came and its signature is checked on every load: a snapshot that does not
/// verify (edited, unsigned, or no public key in this build) counts as no entitlement.
class EntitlementsCache {
  EntitlementsCache(
    this._db, {
    required this._api,
    required this._verifier,
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  static const metaKey = 'billing.entitlements';
  static const rulesAsset = 'assets/config/entitlements.json';

  final AppDatabase _db;
  final Bagmitra _api;
  final SnapshotVerifier _verifier;
  final AssetBundle _bundle;

  Future<EntitlementRules> rules() async => EntitlementRules.fromJson(
    jsonDecode(await _bundle.loadString(rulesAsset)) as Map<String, dynamic>,
  );

  Future<EntitlementSnapshot?> load() async {
    final raw = await _db.readMeta(metaKey);
    if (raw == null) return null;
    try {
      final stored = (jsonDecode(raw) as Map).cast<String, Object?>();
      final payload = (stored['entitlements'] as Map?)?.cast<String, Object?>();
      if (payload == null) return null;
      final signature = stored['signature'] as String?;
      if (!await _verifier.verify(payload, signature)) return null;
      return EntitlementSnapshot.fromServer(payload);
    } on Object {
      // A cache that cannot be read is no entitlement, never a crash.
      return null;
    }
  }

  /// Returns true when a fresh snapshot was stored.
  Future<bool> refresh() async {
    try {
      final res = await _api.v1BillingEntitlementsGet();
      if (!res.isSuccessful || res.body == null) return false;
      final body = (jsonDecode(res.bodyString) as Map).cast<String, Object?>();
      final payload = (body['entitlements']! as Map).cast<String, Object?>();
      // Parsed once here so a payload of the wrong shape is never stored.
      EntitlementSnapshot.fromServer(payload);
      await _db.writeMeta(
        metaKey,
        jsonEncode({'entitlements': payload, 'signature': body['signature']}),
      );
      return true;
    } on Object {
      return false;
    }
  }
}
