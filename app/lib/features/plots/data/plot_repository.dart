import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/plot.dart';

/// Offline-first plots: every write lands locally and in the outbox in one transaction.
class PlotRepository {
  PlotRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'plot';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<Plot>> watchAll() =>
      (_db.select(_db.plots)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  Future<void> save(Plot plot) {
    final now = _clock();
    return _db.transaction(() async {
      await _upsert(plot, now);
      await _outbox.enqueue(
        entity: entity,
        entityId: plot.id,
        payload: plot.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<void> delete(String id) {
    final now = _clock();
    return _db.transaction(() async {
      await (_db.delete(_db.plots)..where((t) => t.id.equals(id))).go();
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: const {},
        clientUpdatedAt: now,
        op: 'delete',
      );
    });
  }

  /// Sync applier for server changes, including tombstones.
  Future<void> applyRemote(RemoteChange change) async {
    if (change.deleted) {
      await (_db.delete(
        _db.plots,
      )..where((t) => t.id.equals(change.entityId))).go();
      return;
    }
    await _upsert(
      Plot.fromPayload(change.entityId, change.data),
      change.updatedAt,
    );
  }

  Future<void> _upsert(Plot p, DateTime updatedAt) => _db
      .into(_db.plots)
      .insertOnConflictUpdate(
        PlotsCompanion.insert(
          id: p.id,
          name: p.name,
          crop: p.crop,
          areaSqM: p.areaSqM,
          variety: Value(p.variety),
          plantingYear: Value(p.plantingYear),
          treeCount: Value(p.treeCount),
          rowSpacingM: Value(p.rowSpacingM),
          plantSpacingM: Value(p.plantSpacingM),
          irrigationType: Value(p.irrigationType),
          waterSource: Value(p.waterSource),
          soilType: Value(p.soilType),
          centroidLat: Value(p.centroidLat),
          centroidLon: Value(p.centroidLon),
          boundary: Value(p.boundary == null ? null : jsonEncode(p.boundary)),
          clientUpdatedAt: updatedAt.toUtc(),
        ),
      );

  static Plot _toDomain(PlotRow r) => Plot(
    id: r.id,
    name: r.name,
    crop: r.crop,
    areaSqM: r.areaSqM,
    variety: r.variety,
    plantingYear: r.plantingYear,
    treeCount: r.treeCount,
    rowSpacingM: r.rowSpacingM,
    plantSpacingM: r.plantSpacingM,
    irrigationType: r.irrigationType,
    waterSource: r.waterSource,
    soilType: r.soilType,
    centroidLat: r.centroidLat,
    centroidLon: r.centroidLon,
    boundary: r.boundary == null
        ? null
        : (jsonDecode(r.boundary!) as Map<String, dynamic>)
              .cast<String, Object?>(),
  );
}
