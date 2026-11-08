import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../market_link/terms_acceptance_test.dart' show marketConfig;
import '../plots/plots_screen_test.dart' show settle;

Future<void> _tapVisible(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

void main() {
  testWidgets('market link home card: sell produce and traders in one tap', (
    tester,
  ) async {
    await pumpApp(tester, config: marketConfig);
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('home-ml-lots')));
    expect(find.text('माल विक्रीसाठी दाखवा'), findsOneWidget);
    expect(find.text('व्यापारी व मध्यस्थ'), findsOneWidget);
    expect(find.byKey(const Key('open-roles')), findsOneWidget);
    await _tapVisible(tester, 'home-ml-lots');
    expect(find.text('माझा विक्रीचा माल'), findsWidgets);
    await unmountApp(tester);

    await pumpApp(tester, config: marketConfig);
    await settle(tester);
    await _tapVisible(tester, 'home-ml-people');
    expect(find.text('व्यापारी व मध्यस्थ'), findsWidgets);
    expect(find.byKey(const Key('home-ml-people')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('without the market link flag the buttons are absent', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);
    expect(find.byKey(const Key('home-ml-lots')), findsNothing);
    expect(find.byKey(const Key('home-ml-people')), findsNothing);
    await unmountApp(tester);
  });
}
