import 'package:bagmitra/data/local/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

/// Upgrading from schema v1 (M0) must keep existing data and add the plots table.
void main() {
  test('v1 -> v2 adds plots and keeps the outbox', () async {
    // Capture the v1 tables' DDL from a fresh database (they are unchanged in v2).
    final fresh = memoryDb();
    final ddl = await fresh
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('outbox_entries', 'farmer_profiles', 'sync_meta')",
        )
        .map((r) => r.read<String>('sql'))
        .get();
    await fresh.close();
    expect(ddl, hasLength(3));

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
    await db.close();
  });
}
