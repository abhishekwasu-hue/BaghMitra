import 'dart:convert';

import 'package:bagmitra/features/accounts/data/accounts_repository.dart';
import 'package:bagmitra/features/accounts/data/expense_categories.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import 'accounts_summary_test.dart' show exp, sale;

void main() {
  test('writes queue expense/income mutations; remote changes apply', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = AccountsRepository(db, clock: TestClock().call);
    await repo.saveExpense(exp('e1', 'labour', 150000, cycle: 'b1'));
    await repo.saveIncome(sale('i1'));
    final queued = await db.select(db.outboxEntries).get();
    expect(queued.map((q) => q.entity), ['expense', 'income']);
    expect(
      jsonDecode(queued.first.payload),
      exp('e1', 'labour', 150000, cycle: 'b1').toPayload(),
    );
    expect((await repo.watchExpenses('p1').first).single.amountPaise, 150000);
    expect((await repo.watchIncomes('p1').first).single.duesPaise, 2950000);

    await repo.applyRemoteExpense(
      RemoteChange(
        entity: 'expense',
        entityId: 'e2',
        data: exp('e2', 'fertiliser', 99).toPayload(),
        updatedAt: DateTime.utc(2026, 10, 13),
      ),
    );
    expect(await repo.watchExpenses('p1').first, hasLength(2));
    await repo.applyRemoteIncome(
      RemoteChange(
        entity: 'income',
        entityId: 'i1',
        data: const {},
        updatedAt: DateTime.utc(2026, 10, 14),
        deleted: true,
      ),
    );
    expect(await repo.watchIncomes('p1').first, isEmpty);

    await repo.deleteExpense('e1');
    expect((await repo.watchExpenses('p1').first).single.id, 'e2');
    expect((await db.select(db.outboxEntries).get()).last.op, 'delete');
  });

  test('expense categories come from config with labels', () async {
    final cats = await ExpenseCategories(bundle: FileAssetBundle()).load();
    expect(cats.map((c) => c.slug), contains('labour'));
    expect(cats.first.label('mr'), isNotEmpty);
  });
}
