import 'dart:convert';

import 'package:bagmitra/core/formatting.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/data/accounts_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'accounts_summary_test.dart' show exp, sale;

Future<void> seedAccounts(AppDatabase db) async {
  await seedPlot(db);
  final repo = AccountsRepository(db);
  await repo.saveExpense(exp('e1', 'labour', 1500000));
  await repo.saveExpense(exp('e2', 'fertiliser', 2500000));
  await repo.saveIncome(sale('i1'));
}

void main() {
  test('rupee input parses to exact paise', () {
    expect(parseRupeesToPaise('1,500'), 150000);
    expect(parseRupeesToPaise('12.5'), 1250);
    expect(parseRupeesToPaise('0.05'), 5);
    expect(parseRupeesToPaise('१२३'), 12300); // Devanagari digits
    expect(parseRupeesToPaise('1.234'), isNull);
    expect(parseRupeesToPaise(''), isNull);
    expect(parseRupeesToPaise('abc'), isNull);
    expect(formatPaise(7950000, 'en'), '₹79,500');
    expect(formatPaise(1250, 'en'), '₹12.50');
  });

  testWidgets('summary shows cost, income, profit, dues and per-acre cost', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts',
      seed: seedAccounts,
    );
    await settle(tester);
    expect(find.text('₹40,000'), findsOneWidget); // expenses
    expect(find.text('₹79,500'), findsOneWidget); // net income
    expect(find.text('₹39,500'), findsOneWidget); // profit
    expect(find.text('₹29,500'), findsOneWidget); // dues
    expect(find.text('₹10,000'), findsOneWidget); // per acre (4 acres)
    await unmountApp(tester);
  });

  testWidgets('grower adds an expense offline', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('Add expense'));
    await settle(tester);
    await tester.tap(find.text('Transport'));
    await tester.enterText(find.byKey(const Key('expense-amount')), '1,500');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('₹1,500'), findsWidgets);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('expense'))).get(),
    );
    final payload = jsonDecode(queued!.single.payload) as Map<String, Object?>;
    expect(payload['amount_paise'], 150000);
    expect(payload['category'], 'transport');
    expect(payload['spent_on'], '2026-10-13');
    await unmountApp(tester);
  });

  testWidgets('grower records a sale with dues', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts/sale',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('sale-buyer')), 'Trader');
    await tester.enterText(find.byKey(const Key('sale-kg')), '2500');
    await tester.enterText(find.byKey(const Key('sale-rate')), '3200');
    await tester.enterText(find.byKey(const Key('sale-paid')), '50000');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final queued = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('income'))).get(),
    );
    final payload = jsonDecode(queued!.single.payload) as Map<String, Object?>;
    expect(payload['rate_paise_per_quintal'], 320000);
    expect(payload['paid_paise'], 5000000);
    expect(payload['payment_status'], 'partial');
    await unmountApp(tester);
  });

  testWidgets(
    'an expense whose category moved to input kinds keeps its label',
    (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/accounts',
        seed: seedAccounts,
      );
      await settle(tester);
      // seedAccounts has a legacy expense in category "fertiliser".
      expect(find.text('Fertiliser'), findsOneWidget);
      expect(find.text('fertiliser'), findsNothing);
      await unmountApp(tester);
    },
  );
}
