// B1 / LD-01 / C1 / H2 / B2 / H3: the home screen of a production build (a backend is
// configured) shows only the grower's own data, and every bottom-bar button goes somewhere.
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/design_system/navigation.dart';
import 'package:bagmitra/features/accounts/presentation/accounts_screen.dart';
import 'package:bagmitra/features/bahar/presentation/bahar_screen.dart';
import 'package:bagmitra/features/bahar/presentation/start_bahar_screen.dart';
import 'package:bagmitra/features/dev/component_gallery_screen.dart';
import 'package:bagmitra/features/market/presentation/market_prices_screen.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/features/plots/presentation/add_plot_screen.dart';
import 'package:bagmitra/features/plots/presentation/plots_screen.dart';
import 'package:bagmitra/features/practices/presentation/practices_screen.dart';
import 'package:bagmitra/features/scouting/presentation/scouting_screens.dart';
import 'package:bagmitra/features/tasks/presentation/add_task_screen.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'home_seed.dart';

/// Every string of the bundled sample home that a real grower must never see.
const _demoStrings = [
  'अभिषेक',
  'काटोल',
  'कळमना',
  '₹3,200',
  '₹३,२००',
  'नमुना माहिती',
  'उष्णतेची लहर',
  'झिंक + बोरॉन',
  'सायला पाहणी — १०',
  'मृग बहार · बाग १ · ४ एकर',
  'मातीतील ओलावा',
];

Future<AppDatabase> _pumpReal(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db)? seed,
  bool devGallery = false,
  Locale locale = const Locale('mr'),
}) async {
  final db = await pumpApp(
    tester,
    locale: locale,
    config: devGallery ? realDevConfig : realConfig,
    // The sync engine is not under test here; a settled status keeps it out.
    syncStatus: const SyncStatus(connectivity: Connectivity.online),
    seed: seed,
  );
  await settle(tester);
  return db;
}

Future<void> _plainPlot(AppDatabase db, {String id = 'p1', String? name}) =>
    PlotRepository(db).save(
      Plot(
        id: id,
        name: name ?? 'बाग १',
        crop: 'santra',
        areaSqM: 2 * Plot.sqMPerAcre,
      ),
    );

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(BmBottomBar), matching: find.text(label)),
  );
  await settle(tester);
}

void main() {
  testWidgets('a new grower sees no sample content, only the first step', (
    tester,
  ) async {
    await _pumpReal(tester);
    for (final s in _demoStrings) {
      expect(find.textContaining(s), findsNothing, reason: s);
    }
    expect(find.byKey(const Key('home-add-first-plot')), findsOneWidget);
    expect(find.text('तुमची पहिली बाग जोडा'), findsOneWidget);
    expect(find.text('आजचा दिवस मोकळा'), findsOneWidget);
    expect(find.byKey(const Key('home-market-empty')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('home-add-first-plot')),
        matching: find.text('बाग जोडा'),
      ),
    );
    await settle(tester);
    expect(find.byType(AddPlotScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('seeded data shows the grower name, weather, alert, stage, tasks '
      'and the saved mandi price', (tester) async {
    await _pumpReal(tester, seed: seedHomeData);
    for (final s in _demoStrings) {
      expect(find.textContaining(s), findsNothing, reason: s);
    }
    expect(find.text('सुनील जी'), findsOneWidget);
    expect(find.text('३५°'), findsOneWidget);
    expect(find.textContaining('किमान २१°'), findsOneWidget);
    expect(find.textContaining('risk of fruit drop'), findsOneWidget);
    expect(find.textContaining('ICAR-CCRI Nagpur'), findsOneWidget);
    expect(find.textContaining('मृग बहार · बाग १ · ३'), findsOneWidget);
    // 10 May (stress) to 13 Oct: 156 days; fruit set (25 Jul) is the stage reached.
    expect(find.text('१५६'), findsOneWidget);
    expect(find.text('फळधारणा'), findsWidgets);
    expect(find.textContaining('तोडणी · १२५ दिवसांत'), findsOneWidget);
    expect(find.text('ठिबक ३ तास — बाग १'), findsOneWidget);
    expect(find.text('सिल्ला पाहणी — १० झाडं'), findsOneWidget);
    // The local market is preferred over a newer price from a far one.
    expect(find.text('Warud बाजार'), findsOneWidget);
    expect(find.text('₹३,४००'), findsOneWidget);
    expect(find.byKey(const Key('home-add-first-plot')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('home-price')));
    await tester.tap(find.byKey(const Key('home-price')));
    await settle(tester);
    expect(find.byType(MarketPricesScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the stage card opens the bahar of the block', (tester) async {
    await _pumpReal(tester, seed: seedHomeData);
    await tester.tap(find.byKey(const Key('home-stage')));
    await settle(tester);
    expect(find.byType(BaharScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a block with no location or bahar shows its next steps', (
    tester,
  ) async {
    await _pumpReal(tester, seed: _plainPlot, locale: const Locale('en'));
    expect(
      find.text("Add the block's location to see its weather here."),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-start-bahar')), findsOneWidget);
    await tester.tap(find.text('Start a bahar'));
    await settle(tester);
    expect(find.byType(StartBaharScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('no task today offers "add a task"', (tester) async {
    await _pumpReal(tester, seed: _plainPlot);
    await tester.ensureVisible(find.byKey(const Key('home-add-task')));
    await tester.tap(find.byKey(const Key('home-add-task')));
    await settle(tester);
    expect(find.byType(AddTaskScreen), findsOneWidget);
    await unmountApp(tester);
  });

  group('bottom bar', () {
    testWidgets('बाग opens the blocks', (tester) async {
      await _pumpReal(tester, seed: _plainPlot);
      await _tapNav(tester, 'बाग');
      expect(find.byType(PlotsScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('हिशोब opens the accounts of the only block', (tester) async {
      await _pumpReal(tester, seed: _plainPlot);
      await _tapNav(tester, 'हिशोब');
      expect(find.byType(AccountsScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('हिशोब asks which block when there are several', (
      tester,
    ) async {
      await _pumpReal(
        tester,
        seed: (db) async {
          await _plainPlot(db);
          await _plainPlot(db, id: 'p2', name: 'बाग २');
        },
      );
      await _tapNav(tester, 'हिशोब');
      expect(find.text('बाग निवडा'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pick-plot-p2')));
      await settle(tester);
      final screen = tester.widget<AccountsScreen>(find.byType(AccountsScreen));
      expect(screen.plotId, 'p2');
      await unmountApp(tester);
    });

    testWidgets('विचारा opens the practices guide', (tester) async {
      await _pumpReal(tester);
      await _tapNav(tester, 'विचारा');
      expect(find.byType(PracticesScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the camera starts a scouting record with a photo', (
      tester,
    ) async {
      await _pumpReal(tester, seed: _plainPlot);
      await tester.tap(find.byType(CameraButton));
      await settle(tester);
      expect(find.byType(AddScoutingScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('with no block yet, the camera and हिशोब add the first one', (
      tester,
    ) async {
      await _pumpReal(tester);
      await tester.tap(find.byType(CameraButton));
      await settle(tester);
      expect(find.byType(AddPlotScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('a production build never opens the dev gallery', (
      tester,
    ) async {
      await _pumpReal(tester, seed: _plainPlot);
      await tester.longPress(find.byType(CameraButton));
      await settle(tester);
      expect(find.byType(ComponentGalleryScreen), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('a DEV_GALLERY build opens it on a long press', (tester) async {
      await _pumpReal(tester, seed: _plainPlot, devGallery: true);
      await tester.longPress(find.byType(CameraButton));
      await settle(tester);
      expect(find.byType(ComponentGalleryScreen), findsOneWidget);
      await unmountApp(tester);
    });
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('weather line keeps its text on a 360 dp phone at x$scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpReal(tester, seed: seedHomeData);
      tester.view.physicalSize = const Size(360, 800) * 3;
      await settle(tester);
      final line = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(const Key('weather-details')),
          matching: find.byType(RichText),
        ),
      );
      expect(line.didExceedMaxLines, isFalse);
      expect(find.text('३५°'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });
  }
}
