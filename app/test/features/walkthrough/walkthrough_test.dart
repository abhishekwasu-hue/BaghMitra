import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/walkthrough/data/walkthrough_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;
import '../test_build_test.dart' show testBuildConfig;

Future<String?> seenFlag(WidgetTester tester, AppDatabase db) =>
    tester.runAsync(() => db.readMeta(WalkthroughFlag.metaKey)).then((v) => v);

void main() {
  test('the flag is unset on a fresh install and set once marked', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final flag = WalkthroughFlag(db);
    expect(await flag.seen(), isFalse);
    await flag.markSeen();
    expect(await flag.seen(), isTrue);
  });

  testWidgets('shown on first run, before sign-in', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      walkthroughSeen: false,
    );
    await settle(tester);
    expect(find.text('Your plots and bahar calendar'), findsOneWidget);
    expect(find.text('Try the app first'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('Next walks through the pages; Start marks seen and goes on', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      walkthroughSeen: false,
    );
    await settle(tester);
    expect(find.byKey(const Key('walkthrough-start')), findsNothing);
    for (final title in [
      'Weather alerts for your plot',
      'Mandi prices across India',
      'Your records and accounts',
    ]) {
      await tester.tap(find.byKey(const Key('walkthrough-next')));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.byKey(const Key('walkthrough-next')), findsNothing);
    expect(find.byKey(const Key('walkthrough-skip')), findsNothing);
    await tester.tap(find.byKey(const Key('walkthrough-start')));
    await settle(tester);
    expect(await seenFlag(tester, db), '1');
    expect(find.text('Try the app first'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Skip marks seen and goes on to setup', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      onboarded: false,
      walkthroughSeen: false,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('walkthrough-skip')));
    await settle(tester);
    expect(await seenFlag(tester, db), '1');
    expect(find.text('Welcome to BagMitra'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('not shown again once seen', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));
    await settle(tester);
    expect(find.text('Your plots and bahar calendar'), findsNothing);
    expect(find.byKey(const Key('walkthrough-skip')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('can be opened again from settings', (tester) async {
    await pumpApp(tester, locale: const Locale('en'), config: testBuildConfig);
    await tester.tap(find.byKey(const Key('test-badge')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('show-walkthrough')));
    await settle(tester);
    expect(find.text('Your plots and bahar calendar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walkthrough-skip')));
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Marathi pages read in Marathi', (tester) async {
    await pumpApp(tester, session: null, walkthroughSeen: false);
    await settle(tester);
    expect(find.text('तुमचे प्लॉट आणि बहार कॅलेंडर'), findsOneWidget);
    expect(find.text('पुढे'), findsOneWidget);
    await unmountApp(tester);
  });
}
