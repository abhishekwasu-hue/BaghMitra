// H1: the core tasks are one tap from home, and "more" lists an entry to every screen so
// no feature is reachable only from deep inside another one.
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/accounts/presentation/accounts_screen.dart';
import 'package:bagmitra/features/accounts/presentation/add_entry_screens.dart';
import 'package:bagmitra/features/calendar/presentation/season_calendar_screen.dart';
import 'package:bagmitra/features/directory/presentation/directory_screen.dart';
import 'package:bagmitra/features/feed/presentation/feed_check_screen.dart';
import 'package:bagmitra/features/feed/presentation/feed_screen.dart';
import 'package:bagmitra/features/field_work/presentation/harvest_screen.dart';
import 'package:bagmitra/features/field_work/presentation/labour_screens.dart';
import 'package:bagmitra/features/inputs/presentation/field_log_screen.dart';
import 'package:bagmitra/features/insurance/presentation/claim_kit_screen.dart';
import 'package:bagmitra/features/insurance/presentation/insurance_screens.dart';
import 'package:bagmitra/features/lab_tests/presentation/lab_test_screens.dart';
import 'package:bagmitra/features/lookalikes/presentation/lookalikes_screen.dart';
import 'package:bagmitra/features/market/presentation/market_prices_screen.dart';
import 'package:bagmitra/features/more/presentation/more_screen.dart';
import 'package:bagmitra/features/plots/presentation/add_plot_screen.dart';
import 'package:bagmitra/features/plots/presentation/plots_screen.dart';
import 'package:bagmitra/features/practices/presentation/irrigation_guide_screen.dart';
import 'package:bagmitra/features/practices/presentation/practices_screen.dart';
import 'package:bagmitra/features/profile/presentation/profile_screen.dart';
import 'package:bagmitra/features/schemes/presentation/scheme_screens.dart';
import 'package:bagmitra/features/scouting/presentation/scouting_screens.dart';
import 'package:bagmitra/features/settings/presentation/settings_screen.dart';
import 'package:bagmitra/features/spray/presentation/add_spray_screen.dart';
import 'package:bagmitra/features/spray/presentation/spray_log_screen.dart';
import 'package:bagmitra/features/tasks/presentation/tasks_screen.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../feed/feed_data_test.dart' show FakeFeedRepository;
import '../home/home_seed.dart';
import '../plots/plots_screen_test.dart' show settle;

Future<void> _pump(
  WidgetTester tester, {
  String? at,
  bool withPlot = true,
  bool feedOn = false,
}) async {
  await pumpApp(
    tester,
    config: feedOn ? testConfig : realConfig,
    initialLocation: at,
    syncStatus: const SyncStatus(connectivity: Connectivity.online),
    seed: withPlot ? seedPlot : null,
    overrides: [
      feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
    ],
  );
  await settle(tester);
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

void main() {
  group('home quick actions', () {
    for (final (key, screen) in [
      ('quick-spray', AddSprayScreen),
      ('quick-expense', AddExpenseScreen),
      ('quick-photo', AddScoutingScreen),
      ('quick-market', MarketPricesScreen),
    ]) {
      testWidgets('$key opens $screen', (tester) async {
        await _pump(tester);
        await _open(tester, Key(key));
        expect(find.byType(screen), findsOneWidget);
        await unmountApp(tester);
      });
    }

    testWidgets('with no block yet, a record action says so, then adds one', (
      tester,
    ) async {
      await _pump(tester, withPlot: false);
      await _open(tester, const Key('quick-spray'));
      expect(find.byKey(const Key('no-plot-sheet')), findsOneWidget);
      expect(find.byType(AddPlotScreen), findsNothing);
      await tester.tap(find.byKey(const Key('no-plot-add')));
      await settle(tester);
      expect(find.byType(AddPlotScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('"आणखी" opens the list of all features', (tester) async {
      await _pump(tester);
      await tester.scrollUntilVisible(
        find.text('आणखी'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('आणखी'));
      await settle(tester);
      expect(find.byType(MoreScreen), findsOneWidget);
      expect(find.text('सर्व सुविधा'), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('all features', () {
    for (final (id, screen) in [
      ('plots', PlotsScreen),
      ('sprays', SprayLogScreen),
      ('accounts', AccountsScreen),
      ('field-log', FieldLogScreen),
      ('labour', LabourScreen),
      ('harvest', HarvestScreen),
      ('scouting', ScoutingScreen),
      ('insurance', InsuranceScreen),
      ('lab-tests', LabTestsScreen),
      ('tasks', TasksScreen),
      ('calendar', SeasonCalendarScreen),
      ('practices', PracticesScreen),
      ('irrigation', IrrigationGuideScreen),
      ('lookalikes', LookalikesScreen),
      ('labs', LabDirectoryScreen),
      ('market', MarketPricesScreen),
      ('market-directory', MarketDirectoryScreen),
      ('schemes', SchemesScreen),
      ('claim-kit', ClaimKitScreen),
      ('profile', ProfileScreen),
      ('settings', SettingsScreen),
    ]) {
      testWidgets('more-$id opens $screen', (tester) async {
        await _pump(tester, at: '/more');
        await _open(tester, Key('more-$id'));
        expect(find.byType(screen), findsOneWidget);
        await unmountApp(tester);
      });
    }

    testWidgets('government messages are listed only where the feed is on', (
      tester,
    ) async {
      await _pump(tester, at: '/more');
      for (final id in ['more-feed', 'more-feed-check']) {
        expect(find.byKey(Key(id), skipOffstage: false), findsNothing);
      }
      await unmountApp(tester);
    });

    for (final (id, screen) in [
      ('more-feed', FeedScreen),
      ('more-feed-check', FeedCheckScreen),
    ]) {
      testWidgets('$id opens $screen where the feed is on', (tester) async {
        await _pump(tester, at: '/more', feedOn: true);
        await _open(tester, Key(id));
        expect(find.byType(screen), findsOneWidget);
        await unmountApp(tester);
      });
    }

    for (final scale in [1.0, 1.3]) {
      testWidgets('fits a 360 dp phone at x$scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pump(tester, at: '/more');
        tester.view.physicalSize = const Size(360, 800) * 3;
        await settle(tester);
        expect(tester.takeException(), isNull);
        await unmountApp(tester);
      });
    }
  });
}
