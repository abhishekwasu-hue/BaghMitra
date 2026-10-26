import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/bahar_cycle.dart';

/// Offline-first bahar cycles: each write lands locally and in the outbox atomically.
class BaharRepository {
  BaharRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'bahar_cycle';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<BaharCycle>> watchForPlot(String plotId) =>
      (_db.select(_db.baharCycles)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.seasonYear)]))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  /// Every cycle on every block (season calendar).
  Stream<List<BaharCycle>> watchAll() => _db
      .select(_db.baharCycles)
      .watch()
      .map((rows) => rows.map(_toDomain).toList());

  Future<void> save(BaharCycle cycle) {
    final now = _clock();
    return _db.transaction(() async {
      await _upsert(cycle, now);
      await _outbox.enqueue(
        entity: entity,
        entityId: cycle.id,
        payload: cycle.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<void> applyRemote(RemoteChange change) async {
    if (change.deleted) {
      await (_db.delete(
        _db.baharCycles,
      )..where((t) => t.id.equals(change.entityId))).go();
      return;
    }
    await _upsert(
      BaharCycle.fromPayload(change.entityId, change.data),
      change.updatedAt,
    );
  }

  Future<void> _upsert(BaharCycle c, DateTime updatedAt) => _db
      .into(_db.baharCycles)
      .insertOnConflictUpdate(
        BaharCyclesCompanion.insert(
          id: c.id,
          plotId: c.plotId,
          bahar: c.bahar,
          seasonYear: c.seasonYear,
          status: c.status,
          templateId: Value(c.templateId),
          planned: jsonEncode(BaharCycle.encodeDates(c.planned)),
          actual: jsonEncode(BaharCycle.encodeDates(c.actual)),
          clientUpdatedAt: updatedAt.toUtc(),
        ),
      );

  static BaharCycle _toDomain(BaharCycleRow r) => BaharCycle(
    id: r.id,
    plotId: r.plotId,
    bahar: r.bahar,
    seasonYear: r.seasonYear,
    status: r.status,
    templateId: r.templateId,
    planned: BaharCycle.decodeDates(jsonDecode(r.planned)),
    actual: BaharCycle.decodeDates(jsonDecode(r.actual)),
  );
}
