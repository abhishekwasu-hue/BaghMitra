import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../scouting/data/scouting_photos.dart';
import '../domain/claim_kit.dart';

/// Crop-loss claim kits, kept on this phone only (no outbox: photos and notes are not
/// synced, OPEN_QUESTIONS Q37). Removing a kit or a photo also removes the kept file.
class ClaimKitRepository {
  ClaimKitRepository(
    this._db, {
    this._clock = systemClock,
    this._photos,
    this._uuid = const Uuid(),
  });

  final AppDatabase _db;
  final Clock _clock;
  final ScoutingPhotos? _photos;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  /// Every kit, newest loss first, with its photos.
  Stream<List<ClaimKit>> watchAll() {
    final kits = _db.select(_db.claimKits)
      ..orderBy([
        (t) => OrderingTerm.desc(t.lossOn),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    final photos = _db.select(_db.claimPhotos)
      ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]);
    return kits.watch().asyncMap((rows) async {
      final all = await photos.get();
      return [for (final r in rows) _kit(r, all)];
    });
  }

  Future<ClaimKit?> find(String id) async {
    final row = await (_db.select(
      _db.claimKits,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final photos =
        await (_db.select(_db.claimPhotos)
              ..where((t) => t.claimId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
            .get();
    return _kit(row, photos);
  }

  /// Saves the kit and exactly [ClaimKit.photos]; kept photos no longer listed are deleted.
  Future<void> save(ClaimKit kit) async {
    final before = await find(kit.id);
    final keep = {for (final p in kit.photos) p.id};
    final gone = [
      for (final p in before?.photos ?? const <ClaimPhoto>[])
        if (!keep.contains(p.id)) p,
    ];
    await _db.transaction(() async {
      await _db
          .into(_db.claimKits)
          .insertOnConflictUpdate(
            ClaimKitsCompanion.insert(
              id: kit.id,
              plotId: kit.plotId,
              lossOn: kit.lossOn,
              note: Value(kit.note),
              checklist: Value(
                jsonEncode([...claimChecklist.where(kit.done.contains)]),
              ),
              updatedAt: _clock().toUtc(),
            ),
          );
      await (_db.delete(
        _db.claimPhotos,
      )..where((t) => t.claimId.equals(kit.id))).go();
      for (final p in kit.photos) {
        await _db
            .into(_db.claimPhotos)
            .insert(
              ClaimPhotosCompanion.insert(
                id: p.id,
                claimId: kit.id,
                path: p.path,
                takenAt: p.takenAt.toUtc(),
                lat: Value(p.lat),
                lon: Value(p.lon),
                accuracyM: Value(p.accuracyM),
              ),
            );
      }
    });
    for (final p in gone) {
      await _photos?.discard(p.path);
    }
  }

  Future<void> delete(String id) async {
    final kit = await find(id);
    await _db.transaction(() async {
      await (_db.delete(
        _db.claimPhotos,
      )..where((t) => t.claimId.equals(id))).go();
      await (_db.delete(_db.claimKits)..where((t) => t.id.equals(id))).go();
    });
    for (final p in kit?.photos ?? const <ClaimPhoto>[]) {
      await _photos?.discard(p.path);
    }
  }

  static ClaimKit _kit(ClaimKitRow r, List<ClaimPhotoRow> photos) => ClaimKit(
    id: r.id,
    plotId: r.plotId,
    lossOn: r.lossOn,
    note: r.note,
    done: {for (final k in jsonDecode(r.checklist) as List) k as String},
    photos: [
      for (final p in photos)
        if (p.claimId == r.id)
          ClaimPhoto(
            id: p.id,
            path: p.path,
            takenAt: p.takenAt,
            lat: p.lat,
            lon: p.lon,
            accuracyM: p.accuracyM,
          ),
    ],
  );
}
