import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/market_link.dart';

/// The phone's side of the market-link role entry (spec v1.5 §2.1, §4C): the active role,
/// the last current terms from the server, and what this user accepted per role. An
/// acceptance made offline counts on the phone at once and is posted when the server answers;
/// the server blocks the role's writes until then (Q85).
class MarketLinkStore {
  MarketLinkStore(this._db, this._api);

  static const roleKey = 'market_link.role';
  static const termsKey = 'market_link.terms';
  static String acceptedKey(String userId) => 'market_link.accepted.$userId';

  final AppDatabase _db;
  final Bagmitra _api;

  /// Synced at most once per app run; [sync] sets it.
  bool synced = false;

  Future<MarketRole?> activeRole() async =>
      MarketRole.fromName(await _db.readMeta(roleKey));

  Future<void> setActiveRole(MarketRole role) =>
      _db.writeMeta(roleKey, role.name);

  Future<MarketTerms> terms() async {
    final raw = await _db.readMeta(termsKey);
    if (raw == null) return MarketTerms.bundled;
    try {
      return MarketTerms.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      return MarketTerms.bundled;
    }
  }

  Future<bool> isAccepted(String userId, MarketRole role) async {
    final entry = (await _accepted(userId))[role.name];
    return entry != null && mapEquals(entry.versions, (await terms()).versions);
  }

  /// Accepts the current versions for [role] on the phone, then tries to post them.
  Future<void> accept(String userId, MarketRole role) async {
    final all = await _accepted(userId);
    all[role.name] = (versions: (await terms()).versions, posted: false);
    await _write(userId, all);
    await _postPending(userId);
  }

  /// Best effort, online: fresh terms, the roles the server already holds as accepted (a
  /// new phone), then every acceptance still waiting. True when anything changed.
  Future<bool> sync(String userId) async {
    synced = true;
    var changed = false;
    try {
      final res = await _api.v1MarketLinkTermsGet();
      if (res.isSuccessful) {
        final json = (jsonDecode(res.bodyString) as Map)
            .cast<String, Object?>();
        final fresh = MarketTerms.fromJson(json);
        await _db.writeMeta(termsKey, res.bodyString);
        changed = true;
        final mine = await _api.v1MarketLinkMeAcceptancesGet();
        if (mine.isSuccessful) {
          final roles = (jsonDecode(mine.bodyString) as Map)['roles'] as List;
          final all = await _accepted(userId);
          for (final role in roles.whereType<String>()) {
            if (MarketRole.fromName(role) == null) continue;
            all[role] = (versions: fresh.versions, posted: true);
          }
          await _write(userId, all);
        }
      }
    } on Object {
      // Offline or the module is off on the server: the phone keeps what it has.
    }
    return await _postPending(userId) || changed;
  }

  /// Posts acceptances made offline. A version that changed meanwhile (409) drops the
  /// local acceptance, so the new text is shown again.
  Future<bool> _postPending(String userId) async {
    final all = await _accepted(userId);
    var changed = false;
    for (final MapEntry<String, _Acceptance>(key: role, value: entry)
        in all.entries.toList()) {
      if (entry.posted) continue;
      try {
        final res = await _api.v1MarketLinkTermsAcceptPost(
          body: AcceptIn(
            role: AcceptInRole.values.firstWhere((r) => r.value == role),
            adultDeclared: true,
            termsVersion: entry.versions['terms'] ?? '',
            privacyVersion: entry.versions['privacy'] ?? '',
            disclaimerVersion: entry.versions['disclaimer'] ?? '',
          ),
        );
        if (res.isSuccessful) {
          all[role] = (versions: entry.versions, posted: true);
          changed = true;
        } else if (res.statusCode == 409) {
          all.remove(role);
          changed = true;
        }
      } on Object {
        // Offline: posted on the next try.
      }
    }
    if (changed) await _write(userId, all);
    return changed;
  }

  Future<Map<String, _Acceptance>> _accepted(String userId) async {
    final raw = await _db.readMeta(acceptedKey(userId));
    if (raw == null) return {};
    try {
      return {
        for (final MapEntry(:key, :value) in (jsonDecode(
          raw,
        ) as Map).cast<String, Map<String, Object?>>().entries)
          key: (
            versions: (value['versions']! as Map).cast<String, String>(),
            posted: value['posted'] == true,
          ),
      };
    } on Object {
      // An unreadable record means "not accepted": the screen shows again.
      return {};
    }
  }

  Future<void> _write(String userId, Map<String, _Acceptance> all) =>
      _db.writeMeta(
        acceptedKey(userId),
        jsonEncode({
          for (final MapEntry(:key, :value) in all.entries)
            key: {'versions': value.versions, 'posted': value.posted},
        }),
      );
}

typedef _Acceptance = ({Map<String, String> versions, bool posted});
