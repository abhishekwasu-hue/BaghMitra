import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/profile/data/profile_repository.dart';
import 'package:bagmitra/features/profile/domain/farmer_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;

Future<Map<String, Object?>> savedProfile(
  WidgetTester tester,
  AppDatabase db,
) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.outboxEntries,
    )..where((t) => t.entity.equals('farmer_profile'))).get(),
  );
  return jsonDecode(rows!.last.payload) as Map<String, Object?>;
}

void main() {
  testWidgets('a new grower is asked to set up before anything else', (
    tester,
  ) async {
    await pumpApp(tester, locale: const Locale('en'), onboarded: false);
    await settle(tester);
    expect(find.text('Welcome to BagMitra'), findsOneWidget);
    expect(find.text("Today's tasks"), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('Marathi comes first in the language choice', (tester) async {
    await pumpApp(tester, locale: const Locale('en'), onboarded: false);
    await settle(tester);
    final marathi = tester.getTopLeft(find.text('मराठी')).dx;
    final hindi = tester.getTopLeft(find.text('हिन्दी')).dx;
    final english = tester.getTopLeft(find.text('English')).dx;
    expect(marathi, lessThan(hindi));
    expect(hindi, lessThan(english));
    await unmountApp(tester);
  });

  testWidgets('consent is required before the grower can continue', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      onboarded: false,
    );
    await settle(tester);
    final button = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byKey(const Key('consent-data')));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(find.text('Welcome to BagMitra'), findsOneWidget);
    expect(
      await tester.runAsync(() => db.select(db.farmerProfiles).get()),
      isEmpty,
    );
    await unmountApp(tester);
  });

  testWidgets(
    'finishing saves the profile offline, switches language, opens home',
    (tester) async {
      final db = await pumpApp(tester, locale: null, onboarded: false);
      await settle(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'मराठी'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('profile-name')), 'Ramesh');
      await tester.enterText(
        find.byKey(const Key('profile-village')),
        'Kalmeshwar',
      );
      await tester.enterText(
        find.byKey(const Key('profile-taluka')),
        'Kalmeshwar',
      );
      await tester.enterText(
        find.byKey(const Key('profile-district')),
        'Nagpur',
      );
      await tester.tap(find.byKey(const Key('consent-data')));
      await tester.tap(find.byKey(const Key('consent-whatsapp')));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await settle(tester);

      final p = await savedProfile(tester, db);
      expect(p['language'], 'mr');
      expect(p['display_name'], 'Ramesh');
      expect(p['village'], 'Kalmeshwar');
      expect(p['district'], 'Nagpur');
      expect(p['consent_data_processing'], true);
      expect(p['consent_whatsapp'], true);
      // Home, now in Marathi.
      expect(find.text('Welcome to BagMitra'), findsNothing);
      expect(find.text('आजची कामं'), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('name and place are optional; WhatsApp stays off unless ticked', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      onboarded: false,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('consent-data')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await settle(tester);
    final p = await savedProfile(tester, db);
    expect(p['language'], 'mr'); // Marathi is preselected
    expect(p['display_name'], isNull);
    expect(p['consent_whatsapp'], false);
    await unmountApp(tester);
  });

  testWidgets('an existing profile opens home and sets the app language', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: null,
      seed: (db) => ProfileRepository(db).save(
        const FarmerProfile(
          id: 'u1',
          language: 'hi',
          consentDataProcessing: true,
        ),
      ),
      onboarded: false,
    );
    await settle(tester);
    expect(find.text('Welcome to BagMitra'), findsNothing);
    expect(find.text('आज के काम'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a profile without consent still goes through setup', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      seed: (db) =>
          ProfileRepository(db)
              .save(const FarmerProfile(id: 'u1', language: 'mr')),
      onboarded: false,
    );
    await settle(tester);
    expect(find.text('Welcome to BagMitra'), findsOneWidget);
    await unmountApp(tester);
  });
}
