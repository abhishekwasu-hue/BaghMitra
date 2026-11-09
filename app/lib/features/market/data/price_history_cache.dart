import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../core/net_failure.dart';
import '../../../data/local/database.dart';

/// One mandi's price series as named by the prices list (crop, mandi, variety, grade).
typedef PriceSeriesKey = ({
  String crop,
  String market,
  String variety,
  String grade,
});

/// The last price history of one mandi (Q130), with the time the phone saved it.
class CachedPriceHistory {
  const CachedPriceHistory(this.history, this.savedAt);

  final MarketPriceHistory history;
  final DateTime savedAt;
}

/// The trend chart's data: the last 90 days of one mandi, cached on the phone so the chart
/// opens offline. The phone always asks for 90 days and cuts the shorter ranges itself.
/// Refreshing is best effort: a failure keeps whatever is cached.
class PriceHistoryCache {
  PriceHistoryCache(this._db, {required this._api, required this._clock});

  static const days = 90;

  final AppDatabase _db;
  final Bagmitra _api;
  final DateTime Function() _clock;

  static String keyFor(PriceSeriesKey k) =>
      'market.history.${k.crop}.${k.market}.${k.variety}.${k.grade}';

  Future<CachedPriceHistory?> load(PriceSeriesKey k) async {
    final raw = await _db.readMeta(keyFor(k));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return CachedPriceHistory(
      MarketPriceHistory.fromJson(
        (j['history']! as Map).cast<String, dynamic>(),
      ),
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Stores a fresh answer and returns null, or says why none came; the cache stays as is.
  Future<NetFailure?> refreshOrFailure(PriceSeriesKey k) async {
    try {
      final res = await _api.v1MarketPricesHistoryGet(
        crop: k.crop,
        market: k.market,
        variety: k.variety,
        grade: k.grade,
        days: days,
      );
      if (!res.isSuccessful) return netFailureForStatus(res.statusCode);
      final body = res.body;
      if (body == null) return NetFailure.server;
      await _db.writeMeta(
        keyFor(k),
        jsonEncode({
          'saved_at': _clock().toUtc().toIso8601String(),
          'history': body.toJson(),
        }),
      );
      return null;
    } on Object catch (e) {
      return netFailureForError(e);
    }
  }
}
