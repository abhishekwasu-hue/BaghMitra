import 'dart:convert';

import '../../../data/local/database.dart';

/// Which documents the grower already has for a scheme ("माझ्याकडे आहे"). On this phone only
/// (a `sync_meta` key per scheme, never synced; cleared on an account switch).
class SchemeTicksStore {
  SchemeTicksStore(this._db);

  final AppDatabase _db;

  static String keyFor(String schemeId) => 'schemes.docs.$schemeId';

  Stream<Set<String>> watch(String schemeId) =>
      (_db.select(_db.syncMeta)..where((t) => t.key.equals(keyFor(schemeId))))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value));

  Future<Set<String>> load(String schemeId) async =>
      _decode(await _db.readMeta(keyFor(schemeId)));

  Future<void> set(
    String schemeId,
    String documentKey, {
    required bool has,
  }) async {
    final ticks = await load(schemeId);
    has ? ticks.add(documentKey) : ticks.remove(documentKey);
    await _db.writeMeta(keyFor(schemeId), jsonEncode(ticks.toList()..sort()));
  }

  static Set<String> _decode(String? raw) => raw == null
      ? <String>{}
      : {for (final k in jsonDecode(raw) as List<dynamic>) k as String};
}
