import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local/database.dart';
import '../features/auth/domain/auth.dart';
import '../features/lab_tests/data/lab_report_files.dart';
import '../features/scouting/data/photo_backup.dart';
import '../features/scouting/data/scouting_photos.dart';
import '../features/walkthrough/data/walkthrough_flag.dart';

/// What a sign-in means for the records already on the phone (OPEN_QUESTIONS Q36).
enum AccountCheck {
  /// The phone's records belong to this account (or to nobody yet): go straight in.
  same,

  /// They belong to another account and everything of it was sent: warn, then clear.
  switchable,

  /// They belong to another account that still has unsent writes: that account must sign
  /// back in first, or the writes would be lost or pushed under the wrong account.
  blocked,
}

/// Remembers which account owns the phone's local records (in `sync_meta`) and hands the
/// phone over to another account: every local user table, the outbox and the pull cursor
/// are cleared, so the next sync pulls the new account's records from the start.
class AccountGuard {
  /// [deletePhotos] removes the previous account's photo files after a switch; the app
  /// passes [photoFolderDeleter], tests may leave it out.
  AccountGuard(this._db, {this.deletePhotos});

  final AppDatabase _db;
  final Future<void> Function()? deletePhotos;

  /// Photo folders of the previous account (scouting, claim kit and lab reports); removed
  /// on a switch.
  static const photoFolders = [
    DeviceScoutingPhotos.folder,
    'claim_photos',
    labReportFolder,
  ];

  /// Deletes [photoFolders] under the app documents folder.
  static Future<void> Function() photoFolderDeleter([
    Future<Directory> Function() documents = getApplicationDocumentsDirectory,
  ]) => () async {
    final root = (await documents()).path;
    for (final name in photoFolders) {
      final dir = Directory(p.join(root, name));
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  };

  static const ownerKey = 'sync.owner.user_id';
  static const ownerPhoneKey = 'sync.owner.phone';

  /// `sync_meta` keys that belong to the phone, not to an account, and survive a switch.
  /// Everything else (cursor, receipts, caches keyed by plot …) is cleared: a key added
  /// later is private by default.
  static const _phoneKeys = {
    WalkthroughFlag.metaKey,
    PhotoBackupPrefs.mobileDataKey,
  };
  static const _phonePrefixes = ['reference.'];

  static bool _keepsOnSwitch(String key) =>
      _phoneKeys.contains(key) || _phonePrefixes.any(key.startsWith);

  Future<AccountCheck> check(String userId) async {
    final owner = await _db.readMeta(ownerKey);
    if (owner == null || owner == userId) return AccountCheck.same;
    return await unsentCount() > 0
        ? AccountCheck.blocked
        : AccountCheck.switchable;
  }

  /// Writes still waiting to reach the server.
  Future<int> unsentCount() async {
    final count = _db.outboxEntries.id.count();
    final query = _db.selectOnly(_db.outboxEntries)
      ..addColumns([count])
      ..where(_db.outboxEntries.state.equalsValue(OutboxState.pending));
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// The phone number of the account that owns the records, when it signed in with one.
  Future<String?> ownerPhone() => _db.readMeta(ownerPhoneKey);

  /// Records [session]'s account as the owner of the phone's records.
  Future<void> claim(AuthSession session) => _db.transaction(() async {
    await _db.writeMeta(ownerKey, session.userId);
    if (session.phone.isEmpty) {
      await (_db.delete(
        _db.syncMeta,
      )..where((t) => t.key.equals(ownerPhoneKey))).go();
    } else {
      await _db.writeMeta(ownerPhoneKey, session.phone);
    }
  });

  /// Clears the previous account's records and makes [session]'s account the owner.
  /// Throws [StateError] if writes are still unsent (checked inside the transaction).
  Future<void> switchTo(AuthSession session) async {
    await _clearRecords(session);
    await deletePhotos?.call();
  }

  Future<void> _clearRecords(AuthSession session) => _db.transaction(() async {
    if (await unsentCount() > 0) {
      throw StateError('unsent writes of the previous account');
    }
    for (final table in _db.allTables) {
      if (table == _db.syncMeta) continue;
      await _db.delete(table).go();
    }
    final meta = await _db.select(_db.syncMeta).get();
    for (final row in meta) {
      if (_keepsOnSwitch(row.key)) continue;
      await (_db.delete(
        _db.syncMeta,
      )..where((t) => t.key.equals(row.key))).go();
    }
    await claim(session);
  });
}
