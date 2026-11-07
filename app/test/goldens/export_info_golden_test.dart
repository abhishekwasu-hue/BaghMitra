// Export information page (market linkage L8, information only), Marathi, 360 dp phone.
// Regenerate with:
//   flutter test --update-goldens test/goldens/export_info_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/export_info/export_info_test.dart'
    show exportInfoAsset, linkOn;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

void main() {
  for (final (name, mode, scale) in [
    ('export_info_mr_light', ThemeMode.light, 1.0),
    ('export_info_mr_dark', ThemeMode.dark, 1.0),
    ('export_info_mr_x13', ThemeMode.light, 1.3),
    ('export_info_mosambi_mr_light', ThemeMode.light, 1.0),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        config: linkOn,
        initialLocation: '/market/export',
        size: const Size(360, 800),
        overrides: [exportInfoAsset],
      );
      await settle(tester);
      if (name.contains('mosambi')) {
        // Mosambi: the shared rules and the official pages.
        await tester.tap(find.byKey(const Key('export-crop-mosambi')));
        await settle(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$name.png'),
        );
        await unmountApp(tester);
        return;
      }
      // The first section open, and the source of its first line, as a grower would.
      await tester.tap(find.byKey(const Key('export-section-destinations')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('sources-toggle')).first);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
