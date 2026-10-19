import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum OutboxState { pending, rejected }

/// Every local user write is queued here in the same transaction as the write itself.
@DataClassName('OutboxEntry')
class OutboxEntries extends Table {
  /// Also the server-side idempotency key (client_mutation_id).
  TextColumn get id => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get state => textEnum<OutboxState>()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FarmerProfileRow')
class FarmerProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get language => text()();
  TextColumn get village => text().nullable()();
  TextColumn get taluka => text().nullable()();
  TextColumn get district => text().nullable()();
  BoolColumn get consentDataProcessing =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get consentWhatsapp =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Orchard blocks (mirror of the API `plot` entity). Boundary is GeoJSON text.
@DataClassName('PlotRow')
class Plots extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get crop => text()();
  TextColumn get variety => text().nullable()();
  RealColumn get areaSqM => real()();
  IntColumn get plantingYear => integer().nullable()();
  IntColumn get treeCount => integer().nullable()();
  RealColumn get rowSpacingM => real().nullable()();
  RealColumn get plantSpacingM => real().nullable()();
  TextColumn get irrigationType => text().nullable()();
  TextColumn get waterSource => text().nullable()();
  TextColumn get soilType => text().nullable()();
  RealColumn get centroidLat => real().nullable()();
  RealColumn get centroidLon => real().nullable()();
  TextColumn get boundary => text().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Bahar cycles (mirror of the API `bahar_cycle` entity). Dates are JSON {stage: date}.
@DataClassName('BaharCycleRow')
class BaharCycles extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text()();
  TextColumn get bahar => text()();
  IntColumn get seasonYear => integer()();
  TextColumn get templateId => text().nullable()();
  TextColumn get status => text()();
  TextColumn get planned => text()();
  TextColumn get actual => text()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Expenses (mirror of the API `expense` entity). Money in whole paise.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text()();
  TextColumn get baharCycleId => text().nullable()();
  DateTimeColumn get spentOn => dateTime()();
  TextColumn get category => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Sales income (mirror of the API `income` entity). Money in whole paise.
@DataClassName('IncomeRow')
class Incomes extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text()();
  TextColumn get baharCycleId => text().nullable()();
  DateTimeColumn get soldOn => dateTime()();
  TextColumn get buyerName => text()();
  TextColumn get grade => text().nullable()();
  RealColumn get quantityKg => real()();
  IntColumn get ratePaisePerQuintal => integer()();
  IntColumn get deductionsPaise => integer()();
  TextColumn get paymentStatus => text()();
  IntColumn get paidPaise => integer()();
  DateTimeColumn get paidOn => dateTime().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Spray records (mirror of the API `spray_record` entity). Cost in whole paise.
@DataClassName('SprayRecordRow')
class SprayRecords extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text()();
  TextColumn get baharCycleId => text().nullable()();
  DateTimeColumn get sprayedOn => dateTime()();
  TextColumn get productName => text()();
  TextColumn get activeIngredient => text().nullable()();
  TextColumn get dose => text().nullable()();
  RealColumn get waterLitres => real().nullable()();
  RealColumn get areaAcres => real().nullable()();
  IntColumn get costPaise => integer()();
  TextColumn get operator => text().nullable()();
  IntColumn get phiDays => integer().nullable()();
  TextColumn get target => text().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Input records (mirror of the API `input_record` entity). Cost in whole paise.
@DataClassName('InputRecordRow')
class InputRecords extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text()();
  TextColumn get baharCycleId => text().nullable()();
  DateTimeColumn get appliedOn => dateTime()();
  TextColumn get kind => text()();
  TextColumn get productName => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get costPaise => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Irrigation events (mirror of the API `irrigation_record` entity).
@DataClassName('IrrigationRecordRow')
class IrrigationRecords extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text()();
  TextColumn get baharCycleId => text().nullable()();
  DateTimeColumn get irrigatedOn => dateTime()();
  RealColumn get durationHours => real().nullable()();
  RealColumn get waterLitres => real().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get clientUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small key/value store for sync cursors and similar bookkeeping.
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    OutboxEntries,
    FarmerProfiles,
    SyncMeta,
    Plots,
    BaharCycles,
    Expenses,
    Incomes,
    SprayRecords,
    InputRecords,
    IrrigationRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.open(String name) : super(driftDatabase(name: name));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(plots);
      if (from < 3) await m.createTable(baharCycles);
      if (from < 4) {
        await m.createTable(expenses);
        await m.createTable(incomes);
      }
      if (from < 5) await m.createTable(sprayRecords);
      if (from < 6) {
        await m.createTable(inputRecords);
        await m.createTable(irrigationRecords);
      }
    },
  );

  Future<String?> readMeta(String key) async {
    final row = await (select(
      syncMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeMeta(String key, String value) =>
      into(syncMeta)
          .insertOnConflictUpdate(SyncMetaData(key: key, value: value));
}
