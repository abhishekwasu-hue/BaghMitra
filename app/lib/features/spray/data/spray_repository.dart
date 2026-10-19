import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/spray_record.dart';

/// Offline-first spray records: each write lands locally and in the outbox atomically.
class SprayRepository {
  SprayRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'spray_record';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<SprayRecord>> watchForPlot(String plotId) =>
      (_db.select(_db.sprayRecords)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.sprayedOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  Future<void> save(SprayRecord s) {
    final now = _clock();
    return _db.transaction(() async {
      await _upsert(s, now);
      await _outbox.enqueue(
        entity: entity,
        entityId: s.id,
        payload: s.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<void> delete(String id) {
    final now = _clock();
    return _db.transaction(() async {
      await (_db.delete(_db.sprayRecords)..where((t) => t.id.equals(id))).go();
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: const {},
        clientUpdatedAt: now,
        op: 'delete',
      );
    });
  }

  Future<void> applyRemote(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.sprayRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _upsert(SprayRecord.fromPayload(c.entityId, c.data), c.updatedAt);
    }
  }

  Future<void> _upsert(SprayRecord s, DateTime at) => _db
      .into(_db.sprayRecords)
      .insertOnConflictUpdate(
        SprayRecordsCompanion.insert(
          id: s.id,
          plotId: s.plotId,
          baharCycleId: Value(s.baharCycleId),
          sprayedOn: s.sprayedOn,
          productName: s.productName,
          activeIngredient: Value(s.activeIngredient),
          dose: Value(s.dose),
          waterLitres: Value(s.waterLitres),
          areaAcres: Value(s.areaAcres),
          costPaise: s.costPaise,
          operator: Value(s.operator),
          phiDays: Value(s.phiDays),
          target: Value(s.target),
          clientUpdatedAt: at.toUtc(),
        ),
      );

  static SprayRecord _toDomain(SprayRecordRow r) => SprayRecord(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    sprayedOn: r.sprayedOn,
    productName: r.productName,
    activeIngredient: r.activeIngredient,
    dose: r.dose,
    waterLitres: r.waterLitres,
    areaAcres: r.areaAcres,
    costPaise: r.costPaise,
    operator: r.operator,
    phiDays: r.phiDays,
    target: r.target,
  );
}
