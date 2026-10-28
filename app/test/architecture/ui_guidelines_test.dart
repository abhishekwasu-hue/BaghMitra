// Sunlight and thumb checks on the main list and form screens: every labelled tap target
// is at least 48 dp and text meets WCAG contrast (the santra buttons once failed at 2.4:1).
import 'package:flutter_test/flutter_test.dart';

import '../features/accounts/accounts_screen_test.dart' show seedAccounts;
import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/plots/plots_screen_test.dart' show seedTwo, settle;
import '../features/spray/spray_screen_test.dart' show seedWithSpray;
import '../helpers/pump_app.dart';

void main() {
  for (final (location, seed) in [
    ('/', null),
    ('/plots', seedTwo),
    ('/tasks/new', seedPlot),
    ('/plots/p1/sprays', seedWithSpray),
    ('/plots/p1/sprays/new', seedWithSpray),
    ('/plots/p1/accounts', seedAccounts),
    ('/plots/p1/labour/new', seedPlot),
  ]) {
    testWidgets('tap targets and contrast on $location', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, initialLocation: location, seed: seed);
      await settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await unmountApp(tester);
      handle.dispose();
    });
  }
}
