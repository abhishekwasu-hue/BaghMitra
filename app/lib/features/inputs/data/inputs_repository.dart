import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/field_records.dart';

/// Offline-first input and irrigation records: each write lands locally and in the outbox
/// atomically; server changes (including tombstones) apply through the sync engine.
class InputsRepository {
  InputsRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const inputEntity = 'input_record';
  static const irrigationEntity = 'irrigation_record';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<InputRecord>> watchInputs(String plotId) =>
      (_db.select(_db.inputRecords)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.appliedOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _input(r)]);

  Stream<List<IrrigationRecord>> watchIrrigations(String plotId) =>
      (_db.select(_db.irrigationRecords)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.irrigatedOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _irrigation(r)]);

  Future<void> saveInput(InputRecord r) => _write(
    inputEntity,
    r.id,
    r.toPayload(),
    () => _db
        .into(_db.inputRecords)
        .insertOnConflictUpdate(_inputCompanion(r, _clock())),
  );

  Future<void> saveIrrigation(IrrigationRecord r) => _write(
    irrigationEntity,
    r.id,
    r.toPayload(),
    () => _db
        .into(_db.irrigationRecords)
        .insertOnConflictUpdate(_irrigationCompanion(r, _clock())),
  );

  Future<void> deleteInput(String id) => _write(
    inputEntity,
    id,
    const {},
    () => (_db.delete(_db.inputRecords)..where((t) => t.id.equals(id))).go(),
    op: 'delete',
  );

  Future<void> deleteIrrigation(String id) => _write(
    irrigationEntity,
    id,
    const {},
    () =>
        (_db.delete(_db.irrigationRecords)..where((t) => t.id.equals(id))).go(),
    op: 'delete',
  );

  Future<void> applyRemoteInput(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.inputRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _db
          .into(_db.inputRecords)
          .insertOnConflictUpdate(
            _inputCompanion(
              InputRecord.fromPayload(c.entityId, c.data),
              c.updatedAt,
            ),
          );
    }
  }

  Future<void> applyRemoteIrrigation(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.irrigationRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _db
          .into(_db.irrigationRecords)
          .insertOnConflictUpdate(
            _irrigationCompanion(
              IrrigationRecord.fromPayload(c.entityId, c.data),
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

  static InputRecordsCompanion _inputCompanion(InputRecord r, DateTime at) =>
      InputRecordsCompanion.insert(
        id: r.id,
        plotId: r.plotId,
        baharCycleId: Value(r.baharCycleId),
        appliedOn: r.appliedOn,
        kind: r.kind,
        productName: r.productName,
        quantity: Value(r.quantity),
        unit: Value(r.unit),
        costPaise: r.costPaise,
        note: Value(r.note),
        clientUpdatedAt: at.toUtc(),
      );

  static IrrigationRecordsCompanion _irrigationCompanion(
    IrrigationRecord r,
    DateTime at,
  ) => IrrigationRecordsCompanion.insert(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: Value(r.baharCycleId),
    irrigatedOn: r.irrigatedOn,
    durationHours: Value(r.durationHours),
    waterLitres: Value(r.waterLitres),
    note: Value(r.note),
    clientUpdatedAt: at.toUtc(),
  );

  static InputRecord _input(InputRecordRow r) => InputRecord(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    appliedOn: r.appliedOn,
    kind: r.kind,
    productName: r.productName,
    quantity: r.quantity,
    unit: r.unit,
    costPaise: r.costPaise,
    note: r.note,
  );

  static IrrigationRecord _irrigation(IrrigationRecordRow r) =>
      IrrigationRecord(
        id: r.id,
        plotId: r.plotId,
        baharCycleId: r.baharCycleId,
        irrigatedOn: r.irrigatedOn,
        durationHours: r.durationHours,
        waterLitres: r.waterLitres,
        note: r.note,
      );
}
