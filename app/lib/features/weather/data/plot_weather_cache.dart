import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../core/net_failure.dart';
import '../../../data/local/database.dart';

/// How long the saved current reading may stand as "now" on the home header (Q140). An
/// older one (offline) gives way to today's max / min, labelled as such.
const currentReadingFreshFor = Duration(hours: 3);

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
  Future<bool> refresh(String plotId, String lang) async =>
      await refreshOrFailure(plotId, lang) == null;

  /// Stores a fresh answer and returns null, or says why none came; the cache stays as is.
  Future<NetFailure?> refreshOrFailure(String plotId, String lang) async {
    try {
      final res = await _api.v1PlotsPlotIdWeatherGet(
        plotId: plotId,
        lang: lang,
      );
      final body = res.body;
      if (!res.isSuccessful) return netFailureForStatus(res.statusCode);
      if (body == null) return NetFailure.server;
      await _db.writeMeta(
        keyFor(plotId, lang),
        jsonEncode({
          'saved_at': _clock().toUtc().toIso8601String(),
          'weather': body.toJson(),
        }),
      );
      return null;
    } on Object catch (e) {
      return netFailureForError(e);
    }
  }
}
