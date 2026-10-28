import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/insurance_policy.dart';

/// Offline-first crop insurance policies: each write lands locally and in the outbox
/// atomically; server changes (including tombstones) apply through the sync engine.
class InsuranceRepository {
  InsuranceRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'insurance_policy';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<InsurancePolicy>> watchForPlot(String plotId) =>
      (_db.select(_db.insurancePolicies)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.seasonYear),
              (t) => OrderingTerm.desc(t.clientUpdatedAt),
            ]))
          .watch()
          .map((rows) => [for (final r in rows) _policy(r)]);

  Future<InsurancePolicy?> find(String id) async {
    final row = await (_db.select(
      _db.insurancePolicies,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _policy(row);
  }

  Future<void> save(InsurancePolicy p) {
    final now = _clock();
    return _db.transaction(() async {
      await _db
          .into(_db.insurancePolicies)
          .insertOnConflictUpdate(_companion(p, now));
      await _outbox.enqueue(
        entity: entity,
        entityId: p.id,
        payload: p.toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  Future<void> delete(String id) {
    final now = _clock();
    return _db.transaction(() async {
      await (_db.delete(
        _db.insurancePolicies,
      )..where((t) => t.id.equals(id))).go();
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
        _db.insurancePolicies,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _db
          .into(_db.insurancePolicies)
          .insertOnConflictUpdate(
            _companion(
              InsurancePolicy.fromPayload(c.entityId, c.data),
              c.updatedAt,
            ),
          );
    }
  }

  static InsurancePoliciesCompanion _companion(
    InsurancePolicy p,
    DateTime at,
  ) => InsurancePoliciesCompanion.insert(
    id: p.id,
    plotId: p.plotId,
    scheme: p.scheme,
    season: p.season,
    seasonYear: Value(p.seasonYear),
    insurerName: Value(p.insurerName),
    policyNumber: Value(p.policyNumber),
    sumInsuredPaise: Value(p.sumInsuredPaise),
    premiumPaidPaise: Value(p.premiumPaidPaise),
    enrolledOn: Value(p.enrolledOn),
    note: Value(p.note),
    clientUpdatedAt: at.toUtc(),
  );

  static InsurancePolicy _policy(InsurancePolicyRow r) => InsurancePolicy(
    id: r.id,
    plotId: r.plotId,
    scheme: r.scheme,
    season: r.season,
    seasonYear: r.seasonYear,
    insurerName: r.insurerName,
    policyNumber: r.policyNumber,
    sumInsuredPaise: r.sumInsuredPaise,
    premiumPaidPaise: r.premiumPaidPaise,
    enrolledOn: r.enrolledOn,
    note: r.note,
  );
}
