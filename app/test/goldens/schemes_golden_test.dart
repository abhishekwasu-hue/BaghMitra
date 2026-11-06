// Scheme list and scheme checklist. Regenerate with:
//   flutter test --update-goldens test/goldens/schemes_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/schemes/data/scheme_ticks_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/plots/plots_screen_test.dart' show settle;
import '../features/schemes/schemes_test.dart' show schemeFeed;
import '../helpers/pump_app.dart';

void main() {
  for (final (name, location, scale) in [
    ('schemes_mr_light', '/schemes', 1.0),
    ('scheme_detail_mr_light', '/schemes/pm_kisan', 1.0),
    // On a 360 dp phone at 1.3x text, a long Marathi scheme name wraps to two lines
    // instead of "पीएम-किसान सन्मान …".
    ('scheme_detail_mr_x13', '/schemes/pm_kisan', 1.3),
  ]) {
    testWidgets(name, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        size: scale > 1 ? const Size(360, 800) : phoneSize,
        initialLocation: location,
        seed: (db) async {
          final store = SchemeTicksStore(db);
          await store.set('pm_kisan', 'aadhaar', has: true);
          await store.set('pm_kisan', 'satbara', has: true);
        },
        overrides: [
          feedProvider.overrideWith((ref, lang) async => schemeFeed()),
        ],
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
