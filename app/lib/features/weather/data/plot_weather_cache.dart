import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';

/// The last weather answer for one plot, with the time the phone saved it.
class CachedWeather {
  const CachedWeather(this.weather, this.savedAt);

  final PlotWeather weather;
  final DateTime savedAt;
}

/// Per-plot weather and risk alerts, cached on the phone so the card works offline.
/// Refreshing is best effort: a failure keeps whatever is cached.
class PlotWeatherCache {
  PlotWeatherCache(this._db, {required this._api, required this._clock});

  final AppDatabase _db;
  final Bagmitra _api;
  final DateTime Function() _clock;

  static String keyFor(String plotId, String lang) => 'weather.$plotId.$lang';

  Future<CachedWeather?> load(String plotId, String lang) async {
    final raw = await _db.readMeta(keyFor(plotId, lang));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return CachedWeather(
      PlotWeather.fromJson((j['weather']! as Map).cast<String, dynamic>()),
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh(String plotId, String lang) async {
    try {
      final res = await _api.v1PlotsPlotIdWeatherGet(
        plotId: plotId,
        lang: lang,
      );
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      await _db.writeMeta(
        keyFor(plotId, lang),
        jsonEncode({
          'saved_at': _clock().toUtc().toIso8601String(),
          'weather': body.toJson(),
        }),
      );
      return true;
    } on Exception {
      return false;
    }
  }
}
