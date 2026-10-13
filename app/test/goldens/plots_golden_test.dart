@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/accounts/accounts_screen_test.dart' show seedAccounts;
import '../features/bahar/bahar_screen_test.dart' show seedPlotWithCycle;
import '../features/plots/plots_screen_test.dart' show seedTwo, settle;
import '../helpers/pump_app.dart';

void main() {
  for (final (name, mode) in [
    ('plots_mr_light', ThemeMode.light),
    ('plots_mr_dark', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/plots',
        seed: seedTwo,
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('plots_empty_mr_light', (tester) async {
    await pumpApp(tester, initialLocation: '/plots');
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('plots_empty_mr_light.png'),
    );
    await unmountApp(tester);
  });

  testWidgets('add_plot_mr_light', (tester) async {
    await pumpApp(tester, initialLocation: '/plots/new');
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('add_plot_mr_light.png'),
    );
    await unmountApp(tester);
  });

  for (final (name, location) in [
    ('bahar_mr_light', '/plots/p1/bahar'),
    ('start_bahar_mr_light', '/plots/p1/bahar/new'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedPlotWithCycle);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, location) in [
    ('accounts_mr_light', '/plots/p1/accounts'),
    ('add_expense_mr_light', '/plots/p1/accounts/expense'),
    ('add_sale_mr_light', '/plots/p1/accounts/sale'),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(tester, initialLocation: location, seed: seedAccounts);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
