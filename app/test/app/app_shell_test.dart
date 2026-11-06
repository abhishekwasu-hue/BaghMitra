// M3: the bottom bar is a real tab shell. It stays on home, बाग and विचारा, each tab keeps
// its state, back on a tab returns home, detail pages open above it with a back arrow,
// and deep links and the existing route names keep working.
import 'dart:io';

import 'package:bagmitra/app/app_shell.dart';
import 'package:bagmitra/design_system/navigation.dart';
import 'package:bagmitra/features/home/presentation/home_screen.dart';
import 'package:bagmitra/features/plots/presentation/plot_detail_screen.dart';
import 'package:bagmitra/features/plots/presentation/plots_screen.dart';
import 'package:bagmitra/features/practices/presentation/practices_screen.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/home/home_seed.dart';
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

Future<void> _pump(WidgetTester tester, {String? at}) async {
  await pumpApp(
    tester,
    config: realConfig,
    initialLocation: at,
    syncStatus: const SyncStatus(connectivity: Connectivity.online),
    seed: seedPlot,
  );
  await settle(tester);
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(BmBottomBar), matching: find.text(label)),
  );
  await settle(tester);
}

String _location(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(AppShell, skipOffstage: false).first),
).state.matchedLocation;

int _selected(WidgetTester tester) =>
    tester.widget<BmBottomBar>(find.byType(BmBottomBar)).selected;

void main() {
  for (final (location, screen, item) in [
    ('/', HomeScreen, 0),
    ('/plots', PlotsScreen, 1),
    ('/ask', PracticesScreen, 3),
  ]) {
    testWidgets('$location opens inside the shell with its tab selected', (
      tester,
    ) async {
      await _pump(tester, at: location);
      expect(find.byType(screen), findsOneWidget);
      expect(find.byType(BmBottomBar), findsOneWidget);
      expect(_selected(tester), item);
      // A tab is a top-level page: no back arrow.
      expect(find.byType(BackButton), findsNothing);
      await unmountApp(tester);
    });
  }

  testWidgets('switching tabs keeps the bar and each tab stays alive', (
    tester,
  ) async {
    await _pump(tester);
    await _tab(tester, 'बाग');
    expect(find.byType(PlotsScreen), findsOneWidget);
    expect(_selected(tester), 1);
    expect(_location(tester), '/plots');
    // Home is kept (offstage), not rebuilt from scratch.
    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
    await _tab(tester, 'विचारा');
    expect(find.byType(PracticesScreen), findsOneWidget);
    expect(_selected(tester), 3);
    await _tab(tester, 'मुख्य पान');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_selected(tester), 0);
    await unmountApp(tester);
  });

  testWidgets('back on another tab returns home first', (tester) async {
    await _pump(tester);
    await _tab(tester, 'बाग');
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_selected(tester), 0);
    await unmountApp(tester);
  });

  testWidgets('a block opens above the tabs and back returns to बाग', (
    tester,
  ) async {
    await _pump(tester, at: '/plots');
    await tester.tap(find.text('बाग १'));
    await settle(tester);
    expect(find.byType(PlotDetailScreen), findsOneWidget);
    expect(find.byType(BmBottomBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(PlotsScreen), findsOneWidget);
    expect(_selected(tester), 1);
    await unmountApp(tester);
  });

  testWidgets('a deep link to a block still opens it, and back reaches home', (
    tester,
  ) async {
    await _pump(tester, at: '/plots/p1');
    expect(find.byType(PlotDetailScreen), findsOneWidget);
    expect(find.byType(BmBottomBar), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a page that pushes a tab route (practices) still opens it', (
    tester,
  ) async {
    await _pump(tester, at: '/plots');
    await tester.tap(find.text('बाग १'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-practices')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open-practices')));
    await settle(tester);
    expect(find.byType(PracticesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Above the tabs, with a way back to the block.
    expect(find.byType(BmBottomBar), findsNothing);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(PlotDetailScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a second tap on the open tab brings it back to its first page', (
    tester,
  ) async {
    await _pump(tester, at: '/ask');
    await _tab(tester, 'विचारा');
    expect(find.byType(PracticesScreen), findsOneWidget);
    expect(_location(tester), '/ask');
    await unmountApp(tester);
  });

  // Pushing a tab route on top of the shell builds a second shell (duplicate page keys).
  test('tab routes are opened with go, never pushed', () {
    final pushed = RegExp(r'push\(\s*Routes\.(home|plots|ask)\s*\)');
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            pushed.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
