import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/lot_form_rules.dart';

/// The phone's copy of the admin's lot form settings (Q138): the asking-rate ranges and the
/// harvest window length. Read from the local database first, so the form works offline;
/// refreshed from the server at most once per app run.
class LotSettingsStore {
  LotSettingsStore(this._db, this._api);

  static const key = 'market_link.lot_settings';

  final AppDatabase _db;
  final Bagmitra _api;

  /// Asked at most once per app run; [refresh] sets it.
  bool refreshed = false;

  Future<LotFormSettings> load() async {
    final raw = await _db.readMeta(key);
    if (raw == null) return LotFormSettings.bundled;
    try {
      return LotFormSettings.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      return LotFormSettings.bundled;
    }
  }

  /// Best effort, online: keeps the server's current values. True when they were saved.
  Future<bool> refresh() async {
    refreshed = true;
    try {
      final res = await _api.v1MarketLinkLotSettingsGet();
      if (!res.isSuccessful) return false;
      // Parsed first: a body the phone cannot read is not kept.
      LotFormSettings.fromJson(
        (jsonDecode(res.bodyString) as Map).cast<String, Object?>(),
      );
      await _db.writeMeta(key, res.bodyString);
      return true;
    } on Object {
      return false;
    }
  }
}
