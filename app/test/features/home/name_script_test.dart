// Owner request: the grower's name on screen in the app language ("अभिषेक जी"). No machine
// transliteration: in Marathi / Hindi, a name saved in Latin letters gets a small card on home
// to write it once in the script; the name fields ask for it in that script too.
import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/profile/data/name_script_flag.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'home_seed.dart';

Future<void> Function(AppDatabase) _named(String name) => (db) async {
  await seedHomeData(db);
  await (db.update(db.farmerProfiles)..where((p) => p.id.equals('u1'))).write(
    FarmerProfilesCompanion(displayName: Value(name)),
  );
};

Future<AppDatabase> _pump(
  WidgetTester tester, {
  required String name,
  Locale locale = const Locale('mr'),
}) async {
  final db = await pumpApp(
    tester,
    locale: locale,
    config: realConfig,
    seed: _named(name),
    syncStatus: const SyncStatus(connectivity: Connectivity.online),
  );
  await settle(tester);
  return db;
}

final _prompt = find.byKey(const Key('name-script-prompt'));

void main() {
  test('a name needs the script only with Latin letters and no Devanagari', () {
    expect(nameNeedsScript('Abhishek'), isTrue);
    expect(nameNeedsScript('अभिषेक'), isFalse);
    expect(nameNeedsScript('अभिषेक Patil'), isFalse);
    expect(nameNeedsScript('१२३'), isFalse);
  });

  for (final (lang, title) in [
    ('mr', 'तुमचे नाव मराठीत लिहा'),
    ('hi', 'अपना नाम हिंदी में लिखें'),
  ]) {
    testWidgets('$lang with a Latin name: the card asks for the name', (
      tester,
    ) async {
      await _pump(tester, name: 'Abhishek', locale: Locale(lang));
      expect(_prompt, findsOneWidget);
      expect(find.text(title), findsOneWidget);
      await unmountApp(tester);
    });
  }

  for (final (lang, name) in [('en', 'Abhishek'), ('mr', 'अभिषेक')]) {
    testWidgets('no card for $lang and "$name"', (tester) async {
      await _pump(tester, name: name, locale: Locale(lang));
      expect(_prompt, findsNothing);
      await unmountApp(tester);
    });
  }

  testWidgets('saving updates the greeting and queues the profile for sync', (
    tester,
  ) async {
    final db = await _pump(tester, name: 'Abhishek');
    expect(find.text('Abhishek जी'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('name-script-field')),
      'अभिषेक',
    );
    await tester.tap(find.byKey(const Key('name-script-save')));
    await settle(tester);
    expect(find.text('अभिषेक जी'), findsOneWidget);
    expect(_prompt, findsNothing);
    final rows = await tester.runAsync(
      () => (db.select(
        db.outboxEntries,
      )..where((t) => t.entity.equals('farmer_profile'))).get(),
    );
    final payload = jsonDecode(rows!.last.payload) as Map<String, Object?>;
    expect(payload['display_name'], 'अभिषेक');
    await unmountApp(tester);
  });

  testWidgets('"नको" hides the card for this language on this phone', (
    tester,
  ) async {
    final db = await _pump(tester, name: 'Abhishek');
    await tester.tap(find.byKey(const Key('name-script-later')));
    await settle(tester);
    expect(_prompt, findsNothing);
    expect(find.text('Abhishek जी'), findsOneWidget);
    final flag = NameScriptFlag(db);
    expect(await tester.runAsync(() => flag.dismissed('mr')), isTrue);
    expect(await tester.runAsync(() => flag.dismissed('hi')), isFalse);
    await unmountApp(tester);
  });

  testWidgets('a dismissed card stays hidden on the next start', (
    tester,
  ) async {
    await pumpApp(
      tester,
      config: realConfig,
      seed: (db) async {
        await _named('Abhishek')(db);
        await NameScriptFlag(db).dismiss('mr');
      },
      syncStatus: const SyncStatus(connectivity: Connectivity.online),
    );
    await settle(tester);
    expect(_prompt, findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the profile name field asks for the name in Marathi', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/profile');
    await settle(tester);
    expect(find.text('तुमचे नाव मराठीत लिहा (उदा. अभिषेक)'), findsOneWidget);
    await unmountApp(tester);
  });
}
