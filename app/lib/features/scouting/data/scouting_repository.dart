import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/scouting_record.dart';
import 'scouting_photos.dart';

/// Offline-first scouting log: each write lands locally and in the outbox atomically; server
/// changes (including tombstones) apply through the sync engine. The photo path is local
/// only, so a server change never clears it.
class ScoutingRepository {
  ScoutingRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._photos,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'scouting_record';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final ScoutingPhotos? _photos;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<ScoutingRecord>> watchForPlot(String plotId) =>
      (_db.select(_db.scoutingRecords)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.observedOn),
              (t) => OrderingTerm.desc(t.clientUpdatedAt),
            ]))
          .watch()
          .map((rows) => [for (final r in rows) _record(r)]);

  Future<void> save(ScoutingRecord r) {
    final now = _clock();
    return _db.transaction(() async {
      await _db
          .into(_db.scoutingRecords)
          .insertOnConflictUpdate(
            _companion(r, now, photoPath: Value(r.photoPath)),
          );
      await _outbox.enqueue(
        entity: entity,
        entityId: r.id,
        payload: r.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<void> delete(String id) async {
    final now = _clock();
    final photo = await _photoOf(id);
    await _db.transaction(() async {
      await (_db.delete(
        _db.scoutingRecords,
      )..where((t) => t.id.equals(id))).go();
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: const {},
        clientUpdatedAt: now,
        op: 'delete',
      );
    });
    if (photo != null) await _photos?.discard(photo);
  }

  Future<void> applyRemote(RemoteChange c) async {
    if (c.deleted) {
      final photo = await _photoOf(c.entityId);
      await (_db.delete(
        _db.scoutingRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
      if (photo != null) await _photos?.discard(photo);
    } else {
      // photoPath stays absent: an upsert from the server keeps the photo on this phone.
      await _db
          .into(_db.scoutingRecords)
          .insertOnConflictUpdate(
            _companion(
              ScoutingRecord.fromPayload(c.entityId, c.data),
              c.updatedAt,
            ),
          );
    }
  }

  Future<String?> _photoOf(String id) async => (await (_db.select(
    _db.scoutingRecords,
  )..where((t) => t.id.equals(id))).getSingleOrNull())?.photoPath;

  static ScoutingRecordsCompanion _companion(
    ScoutingRecord r,
    DateTime at, {
    Value<String?> photoPath = const Value.absent(),
  }) => ScoutingRecordsCompanion.insert(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: Value(r.baharCycleId),
    observedOn: r.observedOn,
    item: r.item,
    severity: r.severity,
    note: Value(r.note),
    photoPath: photoPath,
    clientUpdatedAt: at.toUtc(),
  );

  static ScoutingRecord _record(ScoutingRecordRow r) => ScoutingRecord(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    observedOn: r.observedOn,
    item: r.item,
    severity: r.severity,
    note: r.note,
    photoPath: r.photoPath,
  );
}
