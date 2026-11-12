import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../../bills/data/bill_photos.dart';
import '../../scouting/data/scouting_photos.dart';
import '../domain/spray_record.dart';

/// Offline-first spray records: each write lands locally and in the outbox atomically. The
/// bill photo path is local only, so a server change never clears it; its backed-up key is
/// synced (OPEN_QUESTIONS Q136).
class SprayRepository implements BillPhotoRecords {
  SprayRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._photos,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'spray_record';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;

  /// Removes kept bill photos with their record.
  final ScoutingPhotos? _photos;
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
      await _upsert(s, now, billPhotoPath: Value(s.billPhotoPath));
      await _outbox.enqueue(
        entity: entity,
        entityId: s.id,
        payload: s.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<SprayRecord?> find(String id) async {
    final row = await (_db.select(
      _db.sprayRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> delete(String id) async {
    final now = _clock();
    final photo = (await find(id))?.billPhotoPath;
    await _db.transaction(() async {
      await (_db.delete(_db.sprayRecords)..where((t) => t.id.equals(id))).go();
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
      final photo = (await find(c.entityId))?.billPhotoPath;
      await (_db.delete(
        _db.sprayRecords,
      )..where((t) => t.id.equals(c.entityId))).go();
      if (photo != null) await _photos?.discard(photo);
    } else {
      // billPhotoPath stays absent: an upsert from the server keeps the photo on this phone.
      await _upsert(SprayRecord.fromPayload(c.entityId, c.data), c.updatedAt);
    }
  }

  @override
  Future<List<({String id, String path})>> billPhotosToBackUp() async {
    final rows =
        await (_db.select(_db.sprayRecords)
              ..where(
                (t) => t.billPhotoPath.isNotNull() & t.billPhotoKey.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.clientUpdatedAt)]))
            .get();
    return [for (final r in rows) (id: r.id, path: r.billPhotoPath!)];
  }

  @override
  Future<void> markBillBackedUp(String id, String photoKey) {
    final now = _clock();
    return _db.transaction(() async {
      final current = await find(id);
      if (current == null) return; // deleted meanwhile
      await (_db.update(_db.sprayRecords)..where((t) => t.id.equals(id))).write(
        SprayRecordsCompanion(
          billPhotoKey: Value(photoKey),
          clientUpdatedAt: Value(now.toUtc()),
        ),
      );
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: current.withBillPhoto(key: photoKey).toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  @override
  Future<void> keepDownloadedBill(String id, String path) =>
      (_db.update(_db.sprayRecords)..where((t) => t.id.equals(id))).write(
        SprayRecordsCompanion(billPhotoPath: Value(path)),
      );

  @override
  Future<BillPhotoRef?> billPhotoOf(String id) async {
    final r = await find(id);
    return r == null ? null : (path: r.billPhotoPath, key: r.billPhotoKey);
  }

  Future<void> _upsert(
    SprayRecord s,
    DateTime at, {
    Value<String?> billPhotoPath = const Value.absent(),
  }) => _db
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
          billPhotoPath: billPhotoPath,
          billPhotoKey: Value(s.billPhotoKey),
          products: Value(
            s.mix.isEmpty
                ? null
                : jsonEncode([for (final p in s.mix) p.toPayload()]),
          ),
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
    billPhotoPath: r.billPhotoPath,
    billPhotoKey: r.billPhotoKey,
    mix: r.products == null
        ? const []
        : SprayRecord.productsFrom(jsonDecode(r.products!)),
  );
}
