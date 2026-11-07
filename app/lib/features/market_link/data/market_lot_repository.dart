import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../../scouting/data/scouting_photos.dart';
import '../domain/market_lot.dart';

/// Offline-first lots and their photos: every write lands locally and in the outbox
/// atomically; server changes (the published state too) apply through the sync engine.
/// Photo files stay on this phone; only their uploaded keys are synced.
class MarketLotRepository {
  MarketLotRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._photos,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const lotEntity = 'market_lot';
  static const photoEntity = 'market_lot_photo';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final ScoutingPhotos? _photos;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<MarketLot>> watchAll() =>
      (_db.select(_db.marketLots)
            ..orderBy([(t) => OrderingTerm.desc(t.clientUpdatedAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _lot(r)]);

  Future<MarketLot?> find(String id) async {
    final row = await (_db.select(
      _db.marketLots,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _lot(row);
  }

  Stream<List<LotPhoto>> watchPhotos(String lotId) =>
      (_db.select(_db.marketLotPhotos)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.asc(t.capturedAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _photo(r)]);

  Future<List<LotPhoto>> photosOf(String lotId) => watchPhotos(lotId).first;

  /// Saves the draft (a new one or an edit). Only drafts change on the phone.
  Future<void> save(MarketLot lot) {
    final now = _clock();
    return _db.transaction(() async {
      await _db.into(_db.marketLots).insertOnConflictUpdate(_lotRow(lot, now));
      await _outbox.enqueue(
        entity: lotEntity,
        entityId: lot.id,
        payload: lot.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<void> savePhoto(LotPhoto p) {
    final now = _clock();
    return _db.transaction(() async {
      await _db
          .into(_db.marketLotPhotos)
          .insertOnConflictUpdate(
            _photoRow(p, now, photoPath: Value(p.photoPath)),
          );
      await _outbox.enqueue(
        entity: photoEntity,
        entityId: p.id,
        payload: p.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  /// The photo was uploaded: keep its key and send it like any other edit.
  Future<void> markUploaded(String photoId, String key) async {
    final row = await (_db.select(
      _db.marketLotPhotos,
    )..where((t) => t.id.equals(photoId))).getSingleOrNull();
    if (row == null) return;
    await savePhoto(_photo(row).withKey(key));
  }

  Future<void> deletePhoto(String photoId) async {
    final now = _clock();
    final path = await _pathOf(photoId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.marketLotPhotos,
      )..where((t) => t.id.equals(photoId))).go();
      await _outbox.enqueue(
        entity: photoEntity,
        entityId: photoId,
        payload: const {},
        clientUpdatedAt: now,
        op: 'delete',
      );
    });
    if (path != null) await _photos?.discard(path);
  }

  /// Deletes a draft and its photos.
  Future<void> delete(String lotId) async {
    for (final p in await photosOf(lotId)) {
      await deletePhoto(p.id);
    }
    final now = _clock();
    await _db.transaction(() async {
      await (_db.delete(_db.marketLots)..where((t) => t.id.equals(lotId))).go();
      await _outbox.enqueue(
        entity: lotEntity,
        entityId: lotId,
        payload: const {},
        clientUpdatedAt: now,
        op: 'delete',
      );
    });
  }

  /// The server published or closed the lot (an online call): keep its state here. Not
  /// queued; the same change also comes down with the next pull.
  Future<void> keepServerState(
    String lotId, {
    required String status,
    required DateTime? publishedAt,
    String? orchardCheck,
  }) => (_db.update(_db.marketLots)..where((t) => t.id.equals(lotId))).write(
    MarketLotsCompanion(
      status: Value(status),
      publishedAt: Value(publishedAt?.toUtc()),
      orchardCheck: Value(orchardCheck),
    ),
  );

  Future<void> applyRemoteLot(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.marketLots,
      )..where((t) => t.id.equals(c.entityId))).go();
      return;
    }
    await _db
        .into(_db.marketLots)
        .insertOnConflictUpdate(
          _lotRow(MarketLot.fromPayload(c.entityId, c.data), c.updatedAt),
        );
  }

  Future<void> applyRemotePhoto(RemoteChange c) async {
    if (c.deleted) {
      final path = await _pathOf(c.entityId);
      await (_db.delete(
        _db.marketLotPhotos,
      )..where((t) => t.id.equals(c.entityId))).go();
      if (path != null) await _photos?.discard(path);
      return;
    }
    // photoPath stays absent: a server upsert keeps the file on this phone.
    await _db
        .into(_db.marketLotPhotos)
        .insertOnConflictUpdate(
          _photoRow(LotPhoto.fromPayload(c.entityId, c.data), c.updatedAt),
        );
  }

  Future<String?> _pathOf(String photoId) async => (await (_db.select(
    _db.marketLotPhotos,
  )..where((t) => t.id.equals(photoId))).getSingleOrNull())?.photoPath;

  static MarketLotsCompanion _lotRow(MarketLot l, DateTime at) =>
      MarketLotsCompanion.insert(
        id: l.id,
        plotId: l.plotId,
        baharCycleId: Value(l.baharCycleId),
        crop: l.crop,
        variety: Value(l.variety),
        quantityT: l.quantityT,
        quality: Value(l.quality),
        harvestFrom: l.harvestFrom,
        harvestTo: l.harvestTo,
        basis: l.basis,
        askingRatePaise: Value(l.askingRatePaise),
        status: Value(l.status),
        publishedAt: Value(l.publishedAt?.toUtc()),
        orchardCheck: Value(l.orchardCheck),
        clientUpdatedAt: at.toUtc(),
      );

  static MarketLotPhotosCompanion _photoRow(
    LotPhoto p,
    DateTime at, {
    Value<String?> photoPath = const Value.absent(),
  }) => MarketLotPhotosCompanion.insert(
    id: p.id,
    lotId: p.lotId,
    capturedAt: p.capturedAt.toUtc(),
    lat: p.lat,
    lon: p.lon,
    photoPath: photoPath,
    photoKey: Value(p.photoKey),
    clientUpdatedAt: at.toUtc(),
  );

  static MarketLot _lot(MarketLotRow r) => MarketLot(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    crop: r.crop,
    variety: r.variety,
    quantityT: r.quantityT,
    quality: r.quality,
    harvestFrom: r.harvestFrom,
    harvestTo: r.harvestTo,
    basis: r.basis,
    askingRatePaise: r.askingRatePaise,
    status: r.status,
    publishedAt: r.publishedAt,
    orchardCheck: r.orchardCheck,
  );

  static LotPhoto _photo(MarketLotPhotoRow r) => LotPhoto(
    id: r.id,
    lotId: r.lotId,
    capturedAt: r.capturedAt,
    lat: r.lat,
    lon: r.lon,
    photoPath: r.photoPath,
    photoKey: r.photoKey,
  );
}
