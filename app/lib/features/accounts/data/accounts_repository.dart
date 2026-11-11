import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../../bills/data/bill_photos.dart';
import '../../scouting/data/scouting_photos.dart';
import '../domain/accounts.dart';

/// Offline-first expenses and incomes: each write lands locally and in the outbox
/// atomically; server changes (including tombstones) apply through the sync engine. An
/// expense's bill photo path is local only; its backed-up key is synced (Q136).
class AccountsRepository implements BillPhotoRecords {
  AccountsRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._photos,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const expenseEntity = 'expense';
  static const incomeEntity = 'income';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;

  /// Removes kept bill photos with their expense.
  final ScoutingPhotos? _photos;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Stream<List<Expense>> watchExpenses(String plotId) =>
      (_db.select(_db.expenses)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.spentOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _expense(r)]);

  Stream<List<Income>> watchIncomes(String plotId) =>
      (_db.select(_db.incomes)
            ..where((t) => t.plotId.equals(plotId))
            ..orderBy([(t) => OrderingTerm.desc(t.soldOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _income(r)]);

  Future<void> saveExpense(Expense e) => _write(
    expenseEntity,
    e.id,
    e.toPayload(),
    (at) => _upsertExpense(e, at, billPhotoPath: Value(e.billPhotoPath)),
  );

  Future<void> saveIncome(Income i) =>
      _write(incomeEntity, i.id, i.toPayload(), (at) => _upsertIncome(i, at));

  Future<void> deleteExpense(String id) async {
    final photo = (await findExpense(id))?.billPhotoPath;
    await _write(
      expenseEntity,
      id,
      const {},
      (_) => (_db.delete(_db.expenses)..where((t) => t.id.equals(id))).go(),
      op: 'delete',
    );
    if (photo != null) await _photos?.discard(photo);
  }

  Future<Expense?> findExpense(String id) async {
    final row = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _expense(row);
  }

  @override
  Future<List<({String id, String path})>> billPhotosToBackUp() async {
    final rows =
        await (_db.select(_db.expenses)
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
      final current = await findExpense(id);
      if (current == null) return; // deleted meanwhile
      await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(
          billPhotoKey: Value(photoKey),
          clientUpdatedAt: Value(now.toUtc()),
        ),
      );
      await _outbox.enqueue(
        entity: expenseEntity,
        entityId: id,
        payload: current.withBillPhoto(key: photoKey).toPayload(),
        clientUpdatedAt: now,
      );
    });
  }

  @override
  Future<void> keepDownloadedBill(String id, String path) =>
      (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(billPhotoPath: Value(path)),
      );

  @override
  Future<BillPhotoRef?> billPhotoOf(String id) async {
    final e = await findExpense(id);
    return e == null ? null : (path: e.billPhotoPath, key: e.billPhotoKey);
  }

  Future<void> deleteIncome(String id) => _write(
    incomeEntity,
    id,
    const {},
    (_) => (_db.delete(_db.incomes)..where((t) => t.id.equals(id))).go(),
    op: 'delete',
  );

  Future<void> applyRemoteExpense(RemoteChange c) async {
    if (c.deleted) {
      final photo = (await findExpense(c.entityId))?.billPhotoPath;
      await (_db.delete(
        _db.expenses,
      )..where((t) => t.id.equals(c.entityId))).go();
      if (photo != null) await _photos?.discard(photo);
    } else {
      // billPhotoPath stays absent: an upsert from the server keeps the photo on this phone.
      await _upsertExpense(
        Expense.fromPayload(c.entityId, c.data),
        c.updatedAt,
      );
    }
  }

  Future<void> applyRemoteIncome(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.incomes,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _upsertIncome(Income.fromPayload(c.entityId, c.data), c.updatedAt);
    }
  }

  Future<void> _write(
    String entity,
    String id,
    Map<String, Object?> payload,
    Future<Object?> Function(DateTime at) local, {
    String op = 'upsert',
  }) {
    final now = _clock();
    return _db.transaction(() async {
      await local(now);
      await _outbox.enqueue(
        entity: entity,
        entityId: id,
        payload: payload,
        clientUpdatedAt: now,
        op: op,
      );
    });
  }

  Future<void> _upsertExpense(
    Expense e,
    DateTime at, {
    Value<String?> billPhotoPath = const Value.absent(),
  }) => _db
      .into(_db.expenses)
      .insertOnConflictUpdate(
        ExpensesCompanion.insert(
          id: e.id,
          plotId: e.plotId,
          baharCycleId: Value(e.baharCycleId),
          spentOn: e.spentOn,
          category: e.category,
          amountPaise: e.amountPaise,
          note: Value(e.note),
          clientUpdatedAt: at.toUtc(),
          billPhotoPath: billPhotoPath,
          billPhotoKey: Value(e.billPhotoKey),
        ),
      );

  Future<void> _upsertIncome(Income i, DateTime at) => _db
      .into(_db.incomes)
      .insertOnConflictUpdate(
        IncomesCompanion.insert(
          id: i.id,
          plotId: i.plotId,
          baharCycleId: Value(i.baharCycleId),
          soldOn: i.soldOn,
          buyerName: i.buyerName,
          grade: Value(i.grade),
          quantityKg: i.quantityKg,
          ratePaisePerQuintal: i.ratePaisePerQuintal,
          deductionsPaise: i.deductionsPaise,
          paymentStatus: i.paymentStatus,
          paidPaise: i.paidPaise,
          paidOn: Value(i.paidOn),
          clientUpdatedAt: at.toUtc(),
        ),
      );

  static Expense _expense(ExpenseRow r) => Expense(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    spentOn: r.spentOn,
    category: r.category,
    amountPaise: r.amountPaise,
    note: r.note,
    billPhotoPath: r.billPhotoPath,
    billPhotoKey: r.billPhotoKey,
  );

  static Income _income(IncomeRow r) => Income(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    soldOn: r.soldOn,
    buyerName: r.buyerName,
    grade: r.grade,
    quantityKg: r.quantityKg,
    ratePaisePerQuintal: r.ratePaisePerQuintal,
    deductionsPaise: r.deductionsPaise,
    paymentStatus: r.paymentStatus,
    paidPaise: r.paidPaise,
    paidOn: r.paidOn,
  );
}
