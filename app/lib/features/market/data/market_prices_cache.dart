import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../core/net_failure.dart';
import '../../../data/local/database.dart';

/// The last mandi prices for one crop and scope, with the time the phone saved them.
class CachedMarketPrices {
  const CachedMarketPrices(this.prices, this.savedAt);

  final MarketPrices prices;
  final DateTime savedAt;
}

/// Mandi prices per crop and scope, cached on the phone so the screen works offline.
/// Refreshing is best effort: a failure keeps whatever is cached. Prices are stored
/// exactly as the API returned them.
class MarketPricesCache {
  MarketPricesCache(this._db, {required this._api, required this._clock});

  final AppDatabase _db;
  final Bagmitra _api;
  final DateTime Function() _clock;

  static String keyFor(String crop, V1MarketPricesGetScope scope) =>
      'market.$crop.${scope.value}';

  Future<CachedMarketPrices?> load(
    String crop,
    V1MarketPricesGetScope scope,
  ) async {
    final raw = await _db.readMeta(keyFor(crop, scope));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return CachedMarketPrices(
      MarketPrices.fromJson((j['prices']! as Map).cast<String, dynamic>()),
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh(String crop, V1MarketPricesGetScope scope) async =>
      await refreshOrFailure(crop, scope) == null;

  /// Stores a fresh answer and returns null, or says why none came; the cache stays as is.
  Future<NetFailure?> refreshOrFailure(
    String crop,
    V1MarketPricesGetScope scope,
  ) async {
    try {
      final res = await _api.v1MarketPricesGet(crop: crop, scope: scope);
      final MarketPrices? body;
      if (res.isSuccessful) {
        body = res.body;
      } else if (res.statusCode == 404 && _isCropNotPriced(res.error)) {
        // An older server answers 404 `crop_not_priced` for a fruit it does not price
        // yet: stored as an empty list, the same as a newer server's answer.
        body = const MarketPrices(prices: [], stale: false);
      } else {
        return netFailureForStatus(res.statusCode);
      }
      if (body == null) return NetFailure.server;
      await _db.writeMeta(
        keyFor(crop, scope),
        jsonEncode({
          'saved_at': _clock().toUtc().toIso8601String(),
          'prices': body.toJson(),
        }),
      );
      return null;
    } on Object catch (e) {
      return netFailureForError(e);
    }
  }

  static bool _isCropNotPriced(Object? error) {
    Object? decoded = error;
    if (error is String) {
      try {
        decoded = jsonDecode(error);
      } on FormatException {
        return false;
      }
    }
    return decoded is Map &&
        decoded['error'] is Map &&
        (decoded['error'] as Map)['code'] == 'crop_not_priced';
  }
}
