// Owner request (audit of the "only add-block opens" report): with no block yet, an action
// that is kept per block first says why a block is needed, then opens for the new block once
// it is saved. Pages that need no block open straight away.
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/presentation/accounts_screen.dart';
import 'package:bagmitra/features/accounts/presentation/add_entry_screens.dart';
import 'package:bagmitra/features/calendar/presentation/season_calendar_screen.dart';
import 'package:bagmitra/features/directory/presentation/directory_screen.dart';
import 'package:bagmitra/features/home/presentation/home_screen.dart';
import 'package:bagmitra/features/insurance/presentation/claim_kit_screen.dart';
import 'package:bagmitra/features/lookalikes/presentation/lookalikes_screen.dart';
import 'package:bagmitra/features/market/presentation/market_prices_screen.dart';
import 'package:bagmitra/features/plots/presentation/add_plot_screen.dart';
import 'package:bagmitra/features/plots/presentation/plots_screen.dart';
import 'package:bagmitra/features/practices/presentation/irrigation_guide_screen.dart';
import 'package:bagmitra/features/practices/presentation/practices_screen.dart';
import 'package:bagmitra/features/schemes/presentation/scheme_screens.dart';
import 'package:bagmitra/features/tasks/presentation/tasks_screen.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../feed/feed_data_test.dart' show FakeFeedRepository;
import '../plots/plots_screen_test.dart' show settle;
import 'home_seed.dart';

Future<AppDatabase> _pump(WidgetTester tester, {String? at}) async {
  final db = await pumpApp(
    tester,
    config: realConfig,
    initialLocation: at,
    syncStatus: const SyncStatus(connectivity: Connectivity.online),
    overrides: [
      feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
    ],
  );
  await settle(tester);
  return db;
}

Future<void> _open(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.byKey(key));
  await settle(tester);
  await tester.tap(find.byKey(key));
  await settle(tester);
}

Future<void> _addBlock(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('plot-name')), 'उत्तर बाग');
  await tester.enterText(find.byKey(const Key('plot-acres')), '2');
  await tester.tap(find.text('जतन करा'));
  await settle(tester);
}

Finder _inSheet(String text) => find.descendant(
  of: find.byKey(const Key('no-plot-sheet')),
  matching: find.text(text),
);

void main() {
  testWidgets(
    'add expense: the sheet names it and says why a block is needed',
    (tester) async {
      await _pump(tester);
      await _open(tester, const Key('quick-expense'));
      expect(_inSheet('खर्च जोडा'), findsOneWidget);
      expect(_inSheet('आधी तुमची बाग जोडा'), findsOneWidget);
      expect(_inSheet('बाग जोडा'), findsOneWidget);
      expect(_inSheet('रद्द करा'), findsOneWidget);
      expect(find.byType(AddPlotScreen), findsNothing);

      await tester.tap(find.byKey(const Key('no-plot-cancel')));
      await settle(tester);
      expect(find.byKey(const Key('no-plot-sheet')), findsNothing);
      expect(find.byType(AddPlotScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('after the block is saved, add expense opens for it', (
    tester,
  ) async {
    final db = await _pump(tester);
    await _open(tester, const Key('quick-expense'));
    await tester.tap(find.byKey(const Key('no-plot-add')));
    await settle(tester);
    expect(find.byType(AddPlotScreen), findsOneWidget);
    await _addBlock(tester);

    final plots = await tester.runAsync(() => db.select(db.plots).get());
    expect(plots, hasLength(1));
    final screen = tester.widget<AddExpenseScreen>(
      find.byType(AddExpenseScreen),
    );
    expect(screen.plotId, plots!.single.id);

    // Back from the expense form returns to where the grower started.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('हिशोब from the list of all features continues the same way', (
    tester,
  ) async {
    await _pump(tester, at: '/more');
    await _open(tester, const Key('more-accounts'));
    expect(_inSheet('हिशोब'), findsOneWidget);
    await tester.tap(find.byKey(const Key('no-plot-add')));
    await settle(tester);
    await _addBlock(tester);
    expect(find.byType(AccountsScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the plain add-block flow still returns to the block list', (
    tester,
  ) async {
    await _pump(tester, at: '/plots');
    await tester.tap(find.text('बाग जोडा').first);
    await settle(tester);
    await _addBlock(tester);
    expect(find.byType(AddPlotScreen), findsNothing);
    expect(find.byType(PlotsScreen), findsOneWidget);
    expect(find.text('उत्तर बाग'), findsOneWidget);
    await unmountApp(tester);
  });

  group('pages that need no block open straight away with none', () {
    for (final (key, screen) in [
      ('quick-market', MarketPricesScreen),
      ('more-plots', PlotsScreen),
      ('more-tasks', TasksScreen),
      ('more-calendar', SeasonCalendarScreen),
      ('more-practices', PracticesScreen),
      ('more-irrigation', IrrigationGuideScreen),
      ('more-lookalikes', LookalikesScreen),
      ('more-labs', LabDirectoryScreen),
      ('more-market', MarketPricesScreen),
      ('more-market-directory', MarketDirectoryScreen),
      ('more-schemes', SchemesScreen),
      ('more-claim-kit', ClaimKitScreen),
    ]) {
      testWidgets('$key opens $screen', (tester) async {
        await _pump(tester, at: key.startsWith('more-') ? '/more' : null);
        await _open(tester, Key(key));
        expect(find.byKey(const Key('no-plot-sheet')), findsNothing);
        expect(find.byType(screen), findsOneWidget);
        await unmountApp(tester);
      });
    }
  });
}
