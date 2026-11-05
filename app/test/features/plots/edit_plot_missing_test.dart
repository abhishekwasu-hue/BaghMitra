// L5: editing a block that is not on the phone (deleted, or a stale link) never leaves a
// blank page: it returns to the list of blocks.
import 'package:bagmitra/features/plots/presentation/add_plot_screen.dart';
import 'package:bagmitra/features/plots/presentation/plots_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import 'plots_screen_test.dart' show settle;

void main() {
  testWidgets('a block that is gone returns to the list', (tester) async {
    await pumpApp(tester, initialLocation: '/plots/gone/edit', seed: seedPlot);
    await settle(tester);
    expect(find.byType(AddPlotScreen), findsNothing);
    expect(find.byType(PlotsScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a known block still opens for editing', (tester) async {
    await pumpApp(tester, initialLocation: '/plots/p1/edit', seed: seedPlot);
    await settle(tester);
    expect(find.byType(AddPlotScreen), findsOneWidget);
    expect(find.text('बाग संपादित करा'), findsOneWidget);
    await unmountApp(tester);
  });
}
