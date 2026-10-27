import '../../../data/local/database.dart';

/// Whether this phone has already shown the first-run walkthrough. Kept in the local meta
/// table (per install, never synced), like the other on-device flags and caches.
class WalkthroughFlag {
  WalkthroughFlag(this._db);

  static const metaKey = 'walkthrough_seen';

  final AppDatabase _db;

  Future<bool> seen() async => await _db.readMeta(metaKey) == '1';

  Future<void> markSeen() => _db.writeMeta(metaKey, '1');
}
