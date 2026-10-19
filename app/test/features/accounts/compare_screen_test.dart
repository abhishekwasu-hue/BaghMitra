import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/data/accounts_repository.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'accounts_summary_test.dart' show exp, sale;
import 'year_comparison_test.dart' show cycle;

Future<void> seedTwoSeasons(AppDatabase db) async {
  await seedPlot(db);
  final bahars = BaharRepository(db);
  await bahars.save(cycle('a25', 'ambia', 2025));
  await bahars.save(cycle('a26', 'ambia', 2026));
  final accounts = AccountsRepository(db);
  await accounts.saveExpense(exp('e1', 'transport', 100000, cycle: 'a25'));
  await accounts.saveExpense(exp('e2', 'transport', 150000, cycle: 'a26'));
  await accounts.saveIncome(
    sale('i1', cycle: 'a25', kg: 1000, rate: 100000, deductions: 0),
  );
  await accounts.saveIncome(
    sale('i2', cycle: 'a26', kg: 1000, rate: 300000, deductions: 0),
  );
}

void main() {
  testWidgets('each season shows cost, income, profit and the change', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/compare',
      seed: seedTwoSeasons,
    );
    await settle(tester);
    expect(find.text('Ambia bahar 2026'), findsOneWidget);
    expect(find.text('Ambia bahar 2025'), findsOneWidget);
    expect(find.text('₹1,500'), findsOneWidget); // 2026 cost
    expect(find.text('₹28,500'), findsOneWidget); // 2026 profit
    // 2026 against 2025: costs ₹500 more, profit ₹19,500 more.
    expect(find.text('vs Ambia bahar 2025: ₹500 more'), findsOneWidget);
    expect(find.text('vs Ambia bahar 2025: ₹19,500 more'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('without any bahar the screen says what to do', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/compare',
      seed: seedPlot,
    );
    await settle(tester);
    expect(find.textContaining('Start a bahar'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('accounts screen links to the comparison', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts',
      seed: seedTwoSeasons,
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Compare seasons'));
    await settle(tester);
    expect(find.text('Ambia bahar 2026'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('comparison in Marathi', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/plots/p1/compare',
      seed: seedTwoSeasons,
    );
    await settle(tester);
    expect(find.textContaining('₹५००'), findsWidgets);
    expect(find.textContaining('जास्त'), findsWidgets);
    await unmountApp(tester);
  });
}
