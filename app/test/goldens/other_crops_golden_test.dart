// Owner 2026-11-14 (Q158): the block form's crop picker with "इतर पिके" open, and the home of
// a grower whose block is cotton (no bahar card), on a 360 px phone at 1.3x text, light
// and dark. Regenerate with:
//   flutter test --update-goldens test/goldens/other_crops_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/home/home_seed.dart' show realConfig;
import '../features/plots/other_crops_test.dart' show seedCotton;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

void main() {
  const narrow = Size(360, 780);
  for (final (name, mode) in [
    ('crop_picker_other_mr_light_360_x13', ThemeMode.light),
    ('crop_picker_other_mr_dark_360_x13', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        size: narrow,
        initialLocation: '/plots/new',
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('other-crops')));
      await settle(tester);
      // The crop question at the top of the screen, the open list below it.
      final top = tester.getTopLeft(find.text('पीक')).dy;
      await tester.drag(find.byType(ListView), Offset(0, -(top - 90)));
      await settle(tester);
      await tester.tap(find.byKey(const Key('crop-cotton')));
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  for (final (name, mode) in [
    ('home_cotton_mr_light_360_x13', ThemeMode.light),
    ('home_cotton_mr_dark_360_x13', ThemeMode.dark),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        size: narrow,
        config: realConfig,
        syncStatus: const SyncStatus(connectivity: Connectivity.online),
        seed: seedCotton,
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('plot_cotton_mr_light_360_x13', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      size: narrow,
      initialLocation: '/plots/c1',
      seed: seedCotton,
    );
    await settle(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('plot_cotton_mr_light_360_x13.png'),
    );
    await unmountApp(tester);
  });
}
