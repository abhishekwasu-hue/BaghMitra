import 'dart:convert';

import '../../../data/local/database.dart';

/// Which risk alert types the grower switched off with the ⚠ button (owner Q133), by rule
/// key (e.g. `psylla_degree_days`). On this phone only: one `sync_meta` key, never synced.
/// Home and the plot weather card read the same set. Push notifications are not affected.
class AlertSwitches {
  AlertSwitches(this._db);

  final AppDatabase _db;

  static const metaKey = 'alerts.off';

  Stream<Set<String>> watch() =>
      (_db.select(_db.syncMeta)..where((t) => t.key.equals(metaKey)))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value));

  /// The rule keys switched off.
  Future<Set<String>> load() async => _decode(await _db.readMeta(metaKey));

  Future<void> setOn(String ruleKey, {required bool on}) async {
    final off = await load();
    on ? off.remove(ruleKey) : off.add(ruleKey);
    await _db.writeMeta(metaKey, jsonEncode(off.toList()..sort()));
  }

  static Set<String> _decode(String? raw) => raw == null
      ? <String>{}
      : {for (final k in jsonDecode(raw) as List<dynamic>) k as String};
}
