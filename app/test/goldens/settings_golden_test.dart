// Settings (buttons audit, owner 2026-11-12): a 360 px phone, Marathi, 1.3x text, light and
// dark. The page is a column of buttons: the santra main action and the tonal secondary ones.
// Regenerate with:
//   flutter test --update-goldens test/goldens/settings_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = 'settings_mr_${mode.name}_360_x13';
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/settings',
        size: _phone,
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
