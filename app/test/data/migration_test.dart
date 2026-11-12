import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

/// Tables added in v12 (crop insurance and claim kits) and later.
const v12Tables =
    "('insurance_policies', 'claim_kits', 'claim_photos', 'lab_tests', "
    "'market_lots', 'market_lot_photos')";

/// Tables added in v13 (soil, water and leaf tests) and later.
const v13Tables = "('lab_tests', 'market_lots', 'market_lot_photos')";

/// Tables added in v14 (market linkage lots and their photos).
const v14Tables = "('market_lots', 'market_lot_photos')";

/// The spraying labour column on spray records came in v18 (Q143).
String beforeV18(String sql) =>
    sql.replaceAll(RegExp(r',\s*"labour_paise" INTEGER NULL'), '');

/// The tank mix products column on spray records came in v17 (Q142).
String beforeV17(String sql) =>
    beforeV18(sql).replaceAll(RegExp(r',\s*"products" TEXT NULL'), '');

/// The bill photo columns on expenses and spray records came in v15 (Q136).
String beforeV15(String sql) =>
    beforeV17(sql)
        .replaceAll(RegExp(r',\s*"bill_photo_(path|key)" TEXT NULL'), '');

/// Upgrading from schema v1 (M0) must keep existing data and add later tables.
void main() {
  test(
    'v1 -> latest adds plots, bahar cycles and accounts and keeps the outbox',
    () async {
      // Capture the v1 tables' DDL from a fresh database (they are unchanged in v2).
      final fresh = memoryDb();
      final ddl = await fresh
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('outbox_entries', 'farmer_profiles', 'sync_meta')",
          )
          .map((r) => r.read<String>('sql'))
          .map(beforeV15)
          // The profile's phone column came later (v10); v1 did not have it.
          .map((sql) => sql.replaceFirst(RegExp(r',\s*"phone" TEXT NULL'), ''))
          .get();
      await fresh.close();
      expect(ddl, hasLength(3));
      expect(ddl.join(), isNot(contains('"phone"')));

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final stmt in ddl) {
              raw.execute(stmt);
            }
            raw.execute(
              "INSERT INTO sync_meta (key, value) VALUES ('sync.pull.cursor', '42')",
            );
            raw.execute(
              'INSERT INTO farmer_profiles (id, language, client_updated_at) '
              "VALUES ('u1', 'mr', '2026-01-01T00:00:00.000Z')",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      expect(await db.readMeta('sync.pull.cursor'), '42');
      await db
          .into(db.plots)
          .insert(
            PlotsCompanion.insert(
              id: 'p1',
              name: 'Bag 1',
              crop: 'santra',
              areaSqM: 100,
              clientUpdatedAt: DateTime.utc(2026),
            ),
          );
      expect(await db.select(db.plots).get(), hasLength(1));
      await db
          .into(db.baharCycles)
          .insert(
            BaharCyclesCompanion.insert(
              id: 'b1',
              plotId: 'p1',
              bahar: 'ambia',
              seasonYear: 2027,
              status: 'planned',
              planned: '{}',
              actual: '{}',
              clientUpdatedAt: DateTime.utc(2026),
            ),
          );
      expect(await db.select(db.baharCycles).get(), hasLength(1));
      expect(await db.select(db.expenses).get(), isEmpty);
      expect(await db.select(db.incomes).get(), isEmpty);
      expect(await db.select(db.sprayRecords).get(), isEmpty);
      expect(await db.select(db.inputRecords).get(), isEmpty);
      expect(await db.select(db.irrigationRecords).get(), isEmpty);
      expect(await db.select(db.harvestRecords).get(), isEmpty);
      expect(await db.select(db.labourRecords).get(), isEmpty);
      expect(await db.select(db.scoutingRecords).get(), isEmpty);
      // v10: the kept profile gains an empty contact number.
      final profile = await db.select(db.farmerProfiles).getSingle();
      expect(profile.language, 'mr');
      expect(profile.phone, isNull);
      await db.close();
    },
  );

  test('v10 -> latest adds the scouting photo key column', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT IN $v12Tables",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV15)
        .map(
          (sql) => sql.replaceFirst(RegExp(r',\s*"photo_key" TEXT NULL'), ''),
        )
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('"photo_key"')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw.execute('PRAGMA user_version = 10');
        },
      ),
    );
    final cols = await db
        .customSelect("PRAGMA table_info('scouting_records')")
        .map((r) => r.read<String>('name'))
        .get();
    expect(cols, contains('photo_key'));
    await db.close();
  });

  test('v11 -> v12 adds insurance policies and claim kits, keeps data', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT IN $v12Tables",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV15)
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('insurance_policies')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw.execute(
            'INSERT INTO plots (id, name, crop, area_sq_m, client_updated_at) '
            "VALUES ('p1', 'Bag 1', 'santra', 100, '2026-01-01T00:00:00.000Z')",
          );
          raw.execute('PRAGMA user_version = 11');
        },
      ),
    );
    expect(db.schemaVersion, greaterThanOrEqualTo(12));
    expect(await db.select(db.plots).get(), hasLength(1));
    await db
        .into(db.insurancePolicies)
        .insert(
          InsurancePoliciesCompanion.insert(
            id: 'i1',
            plotId: 'p1',
            scheme: 'rwbcis',
            season: 'ambia',
            clientUpdatedAt: DateTime.utc(2026),
          ),
        );
    final policy = await db.select(db.insurancePolicies).getSingle();
    expect(policy.premiumPaidPaise, isNull);
    await db
        .into(db.claimKits)
        .insert(
          ClaimKitsCompanion.insert(
            id: 'k1',
            plotId: 'p1',
            lossOn: DateTime(2026, 10, 12),
            updatedAt: DateTime.utc(2026),
          ),
        );
    expect((await db.select(db.claimKits).getSingle()).checklist, '[]');
    expect(await db.select(db.claimPhotos).get(), isEmpty);
    await db.close();
  });

  test('v12 -> v13 adds the lab test log, keeps data', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT IN $v13Tables",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV15)
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('lab_tests')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw.execute(
            'INSERT INTO plots (id, name, crop, area_sq_m, client_updated_at) '
            "VALUES ('p1', 'Bag 1', 'santra', 100, '2026-01-01T00:00:00.000Z')",
          );
          raw.execute(
            'INSERT INTO insurance_policies '
            '(id, plot_id, scheme, season, client_updated_at) '
            "VALUES ('i1', 'p1', 'pmfby', 'mrig', '2026-01-01T00:00:00.000Z')",
          );
          raw.execute('PRAGMA user_version = 12');
        },
      ),
    );
    expect(db.schemaVersion, greaterThanOrEqualTo(13));
    expect(await db.select(db.plots).get(), hasLength(1));
    expect(await db.select(db.insurancePolicies).get(), hasLength(1));
    await db
        .into(db.labTests)
        .insert(
          LabTestsCompanion.insert(
            id: 'l1',
            plotId: 'p1',
            testType: 'soil',
            sampledOn: DateTime(2026, 10),
            clientUpdatedAt: DateTime.utc(2026),
          ),
        );
    final row = await db.select(db.labTests).getSingle();
    expect(row.readings, '[]');
    expect(row.reportPath, isNull);
    await db.close();
  });

  test('v13 -> v14 adds market lots and their photos, keeps data', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT IN $v14Tables",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV15)
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('market_lots')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw.execute(
            'INSERT INTO plots (id, name, crop, area_sq_m, client_updated_at) '
            "VALUES ('p1', 'Bag 1', 'santra', 100, '2026-01-01T00:00:00.000Z')",
          );
          raw.execute('PRAGMA user_version = 13');
        },
      ),
    );
    expect(db.schemaVersion, greaterThanOrEqualTo(14));
    expect(await db.select(db.plots).get(), hasLength(1));
    await db
        .into(db.marketLots)
        .insert(
          MarketLotsCompanion.insert(
            id: 'l1',
            plotId: 'p1',
            crop: 'santra',
            quantityT: 10,
            harvestFrom: DateTime(2026, 12),
            harvestTo: DateTime(2026, 12, 20),
            basis: 'per_quintal',
            clientUpdatedAt: DateTime.utc(2026),
          ),
        );
    expect((await db.select(db.marketLots).getSingle()).status, 'draft');
    expect(await db.select(db.marketLotPhotos).get(), isEmpty);
    await db.close();
  });

  test('v14 -> v15 adds the bill photo columns, keeps data', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV15)
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('bill_photo')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw.execute(
            'INSERT INTO expenses (id, plot_id, spent_on, category, '
            'amount_paise, client_updated_at) VALUES '
            "('e1', 'p1', '2026-01-01T00:00:00.000', 'other', 5000, "
            "'2026-01-01T00:00:00.000Z')",
          );
          raw.execute(
            'INSERT INTO spray_records (id, plot_id, sprayed_on, product_name, '
            'cost_paise, client_updated_at) VALUES '
            "('s1', 'p1', '2026-01-01T00:00:00.000', 'Imida', 0, "
            "'2026-01-01T00:00:00.000Z')",
          );
          raw.execute('PRAGMA user_version = 14');
        },
      ),
    );
    expect(db.schemaVersion, greaterThanOrEqualTo(15));
    for (final table in ['expenses', 'spray_records']) {
      final cols = await db
          .customSelect("PRAGMA table_info('$table')")
          .map((r) => r.read<String>('name'))
          .get();
      expect(cols, containsAll(['bill_photo_path', 'bill_photo_key']));
    }
    final expense = await db.select(db.expenses).getSingle();
    expect(expense.amountPaise, 5000);
    expect(expense.billPhotoPath, isNull);
    expect(expense.billPhotoKey, isNull);
    final spray = await db.select(db.sprayRecords).getSingle();
    expect(spray.productName, 'Imida');
    expect(spray.billPhotoKey, isNull);
    await db.close();
  });

  test('v15 -> v16 turns per-tonne lots and their queued payloads per quintal '
      '(rate / 10, Q138)', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV17)
        .get();
    await fresh.close();

    String lot(String id, String basis, String rate) =>
        'INSERT INTO market_lots (id, plot_id, crop, quantity_t, harvest_from, '
        'harvest_to, basis, asking_rate_paise, status, client_updated_at) '
        "VALUES ('$id', 'p1', 'santra', 10, '2026-12-01T00:00:00.000', "
        "'2026-12-16T00:00:00.000', '$basis', $rate, 'draft', "
        "'2026-11-01T00:00:00.000Z')";
    String queued(String id, String entity, Map<String, Object?> payload) =>
        'INSERT INTO outbox_entries (id, entity, entity_id, op, payload, '
        'client_updated_at, attempts, next_attempt_at, state) '
        "VALUES ('$id', '$entity', 'l1', 'upsert', '${jsonEncode(payload)}', "
        "'2026-11-01T00:00:00.000Z', 0, '2026-11-01T00:00:00.000Z', 'pending')";

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw
            ..execute(lot('l1', 'per_tonne', '3000000'))
            ..execute(lot('l2', 'per_tonne', 'NULL'))
            ..execute(lot('l3', 'per_crate', '50000'))
            ..execute(
              queued('o1', 'market_lot', {
                'basis': 'per_tonne',
                'asking_rate_paise': 3000005,
              }),
            )
            ..execute(
              queued('o2', 'market_lot', {
                'basis': 'lump_sum',
                'asking_rate_paise': 900,
              }),
            )
            ..execute(queued('o3', 'market_lot_photo', {'basis': 'per_tonne'}))
            ..execute('PRAGMA user_version = 15');
        },
      ),
    );
    expect(db.schemaVersion, greaterThanOrEqualTo(16));
    final lots = {
      for (final r in await db.select(db.marketLots).get())
        r.id: (r.basis, r.askingRatePaise),
    };
    expect(lots, {
      'l1': ('per_quintal', 300000),
      'l2': ('per_quintal', null),
      'l3': ('per_crate', 50000),
    });
    final payloads = {
      for (final e in await db.select(db.outboxEntries).get())
        e.id: jsonDecode(e.payload),
    };
    expect(payloads['o1'], {
      'basis': 'per_quintal',
      'asking_rate_paise': 300001,
    });
    expect(payloads['o2'], {'basis': 'lump_sum', 'asking_rate_paise': 900});
    // Only lot payloads carry a basis; anything else is left as it is.
    expect(payloads['o3'], {'basis': 'per_tonne'});
    await db.close();
  });

  test('v16 -> v17 adds the tank mix products column; an old spray reads as '
      'one product (Q142)', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV17)
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('"products"')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw
            ..execute(
              'INSERT INTO spray_records (id, plot_id, sprayed_on, product_name, '
              'active_ingredient, cost_paise, phi_days, client_updated_at) '
              "VALUES ('s1', 'p1', '2026-01-01T00:00:00.000', 'Imida', "
              "'imidacloprid', 65000, 15, '2026-01-01T00:00:00.000Z')",
            )
            ..execute('PRAGMA user_version = 16');
        },
      ),
    );
    expect(db.schemaVersion, greaterThanOrEqualTo(17));
    final cols = await db
        .customSelect("PRAGMA table_info('spray_records')")
        .map((r) => r.read<String>('name'))
        .get();
    expect(cols, contains('products'));
    final row = await db.select(db.sprayRecords).getSingle();
    expect(row.products, isNull);
    final old = await SprayRepository(db).find('s1');
    expect(old!.isMix, isFalse);
    expect(old.products.single.productName, 'Imida');
    expect(old.products.single.costPaise, 65000);
    expect(old.phiDays, 15);
    await db.close();
  });

  test('v17 -> v18 adds the spraying labour column; old sprays have none '
      '(Q143)', () async {
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r.read<String>('sql'))
        .map(beforeV18)
        .get();
    await fresh.close();
    expect(ddl.join(), isNot(contains('"labour_paise"')));

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in ddl) {
            raw.execute(stmt);
          }
          raw
            ..execute(
              'INSERT INTO spray_records (id, plot_id, sprayed_on, product_name, '
              'cost_paise, client_updated_at) '
              "VALUES ('s1', 'p1', '2026-01-01T00:00:00.000', 'Imida', 65000, "
              "'2026-01-01T00:00:00.000Z')",
            )
            ..execute('PRAGMA user_version = 17');
        },
      ),
    );
    expect(db.schemaVersion, 18);
    final old = await SprayRepository(db).find('s1');
    expect(old!.labourPaise, isNull);
    expect(old.totalPaise, 65000);
    expect(old.toPayload().containsKey('labour_paise'), isFalse);
    await db.close();
  });
}
