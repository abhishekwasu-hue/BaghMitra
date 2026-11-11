// The spray form's two-step active-ingredient picker (owner Q137) on a 360 px phone with the
// text raised to 1.3x. Regenerate with:
//   flutter test --update-goldens test/goldens/spray_picker_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/spray/spray_ingredient_picker_test.dart'
    show chooseIngredient, chooseIngredientType;
import '../helpers/pump_app.dart';

void main() {
  for (final (name, mode, open) in [
    ('add_spray_picker_list_mr_light', ThemeMode.light, true),
    ('add_spray_picker_list_mr_dark', ThemeMode.dark, true),
    ('add_spray_picker_chosen_mr_light', ThemeMode.light, false),
    ('add_spray_picker_chosen_mr_dark', ThemeMode.dark, false),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        size: const Size(360, 780),
        initialLocation: '/plots/p1/sprays/new',
        seed: seedPlot,
      );
      await settle(tester);
      await chooseIngredientType(tester, 'बुरशीनाशक');
      if (open) {
        await tester.tap(find.byKey(const Key('spray-active-pick')));
        await settle(tester);
      } else {
        await chooseIngredient(tester, 'Captan 75% WP');
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
