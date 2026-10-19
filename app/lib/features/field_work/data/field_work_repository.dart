import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/field_work.dart';

/// Offline-first harvest records and labour register: each write lands locally and in the
/// outbox atomically; server changes (including tombstones) apply through the sync engine.
class FieldWorkRepository {
  FieldWorkRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const harvestEntity = 'harvest_record';
  static const labourEntity = 'labour_record';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<HarvestRecord>> watchHarvests(String plotId) =>
      (_db.select(_db.harvestRecords)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.harvestedOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _harvest(r)]);

  Stream<List<LabourRecord>> watchLabour(String plotId) =>
      (_db.select(_db.labourRecords)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.workedOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _labour(r)]);

  Future<void> saveHarvest(HarvestRecord r) => _write(
    harvestEntity,
    r.id,
    r.toPayload(),
    () => _db
        .into(_db.harvestRecords)
        .insertOnConflictUpdate(_harvestCompanion(r, _clock())),
  );

  Future<void> saveLabour(LabourRecord r) => _write(
    labourEntity,
    r.id,
    r.toPayload(),
    () => _db
        .into(_db.labourRecords)
        .insertOnConflictUpdate(_labourCompanion(r, _clock())),
  );

  Future<void> deleteHarvest(String id) => _write(
    harvestEntity,
    id,
    const {},
    () => (_db.delete(_db.harvestRecords)..where((t) => t.id.equals(id))).go(),
    op: 'delete',
  );

  Future<void> deleteLabour(String id) => _write(
    labourEntity,
    id,
    const {},
    () => (_db.delete(_db.labourRecords)..where((t) => t.id.equals(id))).go(),
    op: 'delete',
  );

  Future<void> applyRemoteHarvest(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.harvestRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _db
          .into(_db.harvestRecords)
          .insertOnConflictUpdate(
            _harvestCompanion(
              HarvestRecord.fromPayload(c.entityId, c.data),
              c.updatedAt,
            ),
          );
    }
  }

  Future<void> applyRemoteLabour(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.labourRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _db
          .into(_db.labourRecords)
          .insertOnConflictUpdate(
            _labourCompanion(
              LabourRecord.fromPayload(c.entityId, c.data),
              c.updatedAt,
            ),
          );
    }
  }

  Future<void> _write(
    String entity,
    String id,
    Map<String, Object?> payload,
    Future<Object?> Function() local, {
    String op = 'upsert',
  }) {
    final now = _clock();
    return _db.transaction(() async {
      await local();
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: payload,
        clientUpdatedAt: now,
        op: op,
      );
    });
  }

  static HarvestRecordsCompanion _harvestCompanion(
    HarvestRecord r,
    DateTime at,
  ) => HarvestRecordsCompanion.insert(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: Value(r.baharCycleId),
    harvestedOn: r.harvestedOn,
    grade: Value(r.grade),
    sizeClass: Value(r.sizeClass),
    quantityKg: r.quantityKg,
    note: Value(r.note),
    clientUpdatedAt: at.toUtc(),
  );

  static LabourRecordsCompanion _labourCompanion(LabourRecord r, DateTime at) =>
      LabourRecordsCompanion.insert(
        id: r.id,
        plotId: r.plotId,
        baharCycleId: Value(r.baharCycleId),
        workerName: r.workerName,
        workedOn: r.workedOn,
        task: Value(r.task),
        wagePaise: r.wagePaise,
        advancePaise: r.advancePaise,
        settledOn: Value(r.settledOn),
        note: Value(r.note),
        clientUpdatedAt: at.toUtc(),
      );

  static HarvestRecord _harvest(HarvestRecordRow r) => HarvestRecord(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    harvestedOn: r.harvestedOn,
    grade: r.grade,
    sizeClass: r.sizeClass,
    quantityKg: r.quantityKg,
    note: r.note,
  );

  static LabourRecord _labour(LabourRecordRow r) => LabourRecord(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    workerName: r.workerName,
    workedOn: r.workedOn,
    task: r.task,
    wagePaise: r.wagePaise,
    advancePaise: r.advancePaise,
    settledOn: r.settledOn,
    note: r.note,
  );
}
