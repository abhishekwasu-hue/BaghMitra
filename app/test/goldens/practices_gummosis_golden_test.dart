// The gummosis (Phytophthora) card with its drawings (owner 2026-11-09), phone width,
// Marathi, 1.3x text, light and dark: symptoms, the drainage trench and ring, pruning and roots.
//   flutter test --update-goldens test/goldens/practices_gummosis_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (part, target) in [
      ('symptoms', 'practice-figure-phytophthora'),
      ('trench', 'practice-figure-19'),
      ('prune', 'practice-figure-21'),
    ]) {
      final name = 'practices_gummosis_${part}_mr_${mode.name}';
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: '/practices',
          seed: seedPlot,
          size: _phone,
        );
        await settle(tester);
        await tester.tap(find.text('फायटोफ्थोरा: डिंक्या, खोडकूज, मूळकूज'));
        await settle(tester);
        await tester.scrollUntilVisible(
          find.byKey(Key(target)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byKey(Key(target)));
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
}
