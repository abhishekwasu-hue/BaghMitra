import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../../scouting/data/scouting_photos.dart';
import '../domain/lab_test.dart';

/// Offline-first soil, water and leaf tests: each write lands locally and in the outbox
/// atomically; server changes (including tombstones) apply through the sync engine. The
/// report photo or file is kept by [files] and its path never leaves the phone.
class LabTestRepository {
  LabTestRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this.files,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'lab_test';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  /// Removes a report file the record no longer uses; tests may leave it out.
  final ScoutingPhotos? files;

  String newId() => _uuid.v4();

  /// One plot's tests, newest sample first.
  Stream<List<LabTest>> watchForPlot(String plotId) =>
      (_db.select(_db.labTests)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.sampledOn),
              (t) => OrderingTerm.desc(t.clientUpdatedAt),
            ]))
          .watch()
          .map((rows) => [for (final r in rows) _test(r)]);

  Future<LabTest?> find(String id) async {
    final row = await (_db.select(
      _db.labTests,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _test(row);
  }

  /// Saves [test] with its kept report path; a report the record used before and no
  /// longer does is removed from the phone.
  Future<void> save(LabTest test) async {
    final now = _clock();
    final before = (await find(test.id))?.reportPath;
    await _db.transaction(() async {
      await _db
          .into(_db.labTests)
          .insertOnConflictUpdate(
            _companion(test, now, reportPath: Value(test.reportPath)),
          );
      await _outbox.enqueue(
        entity: entity,
        entityId: test.id,
        payload: test.toPayload(),
        clientUpdatedAt: now,
      );
    });
    if (before != null && before != test.reportPath) {
      await files?.discard(before);
    }
  }

  Future<void> delete(String id) async {
    final now = _clock();
    final path = (await find(id))?.reportPath;
    await _db.transaction(() async {
      await (_db.delete(_db.labTests)..where((t) => t.id.equals(id))).go();
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: const {},
        clientUpdatedAt: now,
        op: 'delete',
      );
    });
    if (path != null) await files?.discard(path);
  }

  Future<void> applyRemote(RemoteChange c) async {
    if (c.deleted) {
      final path = (await find(c.entityId))?.reportPath;
      await (_db.delete(
        _db.labTests,
      )..where((t) => t.id.equals(c.entityId))).go();
      if (path != null) await files?.discard(path);
    } else {
      // reportPath stays absent: an upsert from the server keeps the report on this phone.
      await _db
          .into(_db.labTests)
          .insertOnConflictUpdate(
            _companion(LabTest.fromPayload(c.entityId, c.data), c.updatedAt),
          );
    }
  }

  static LabTestsCompanion _companion(
    LabTest t,
    DateTime at, {
    Value<String?> reportPath = const Value.absent(),
  }) => LabTestsCompanion.insert(
    id: t.id,
    plotId: t.plotId,
    testType: t.testType,
    sampledOn: t.sampledOn,
    labName: Value(t.labName),
    reportedOn: Value(t.reportedOn),
    readings: Value(jsonEncode([for (final r in t.readings) r.toJson()])),
    note: Value(t.note),
    reportPath: reportPath,
    clientUpdatedAt: at.toUtc(),
  );

  static LabTest _test(LabTestRow r) => LabTest(
    id: r.id,
    plotId: r.plotId,
    testType: r.testType,
    sampledOn: r.sampledOn,
    labName: r.labName,
    reportedOn: r.reportedOn,
    readings: LabTest.readingsFromJson(jsonDecode(r.readings)),
    note: r.note,
    reportPath: r.reportPath,
  );
}
