import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/auth/domain/auth.dart';
import 'package:bagmitra/features/profile/data/profile_repository.dart';
import 'package:bagmitra/features/profile/domain/farmer_profile.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'onboarding_test.dart' show savedProfile;

const googleUser = AuthSession(userId: 'g1', phone: '', accessToken: 't');

Future<void> seedProfile(AppDatabase db, {String id = 'u1'}) =>
    ProfileRepository(db).save(
      FarmerProfile(
        id: id,
        language: 'en',
        displayName: 'Ramesh',
        village: 'Kalmeshwar',
        taluka: 'Kalmeshwar',
        district: 'Nagpur',
        consentDataProcessing: true,
      ),
    );

Future<int> profileWrites(WidgetTester tester, AppDatabase db) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.outboxEntries,
    )..where((t) => t.entity.equals('farmer_profile'))).get(),
  );
  return rows!.length;
}

Future<AppDatabase> openProfile(
  WidgetTester tester, {
  AuthSession session = signedIn,
  Locale? locale = const Locale('en'),
}) async {
  final db = await pumpApp(
    tester,
    locale: locale,
    session: session,
    onboarded: false,
    seed: (db) => seedProfile(db, id: session.userId),
  );
  await settle(tester);
  // Reached from the avatar on the home header.
  await tester.tap(find.byKey(const Key('open-profile')));
  await settle(tester);
  return db;
}

/// Scrolls the profile list until [key] is built and on screen, then taps it.
Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('profile-list')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

Future<void> tapSave(WidgetTester tester) => tapKey(tester, 'profile-save');

void main() {
  testWidgets('the avatar opens the profile with the saved details', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.text('My profile'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ramesh'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Nagpur'), findsOneWidget);
    // Data consent is shown as on, with why it cannot be switched off here.
    final consent = tester.widget<CheckboxListTile>(
      find.byKey(const Key('consent-data')),
    );
    expect(consent.value, isTrue);
    expect(consent.onChanged, isNull);
    expect(find.textContaining('cannot be turned off'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('editing and saving writes the profile and queues it', (
    tester,
  ) async {
    final db = await openProfile(tester);
    final before = await profileWrites(tester, db);
    await tester.enterText(find.byKey(const Key('profile-name')), 'Suresh');
    await tester.enterText(find.byKey(const Key('profile-village')), 'Katol');
    await tapKey(tester, 'consent-whatsapp');
    await tapSave(tester);

    expect(await profileWrites(tester, db), before + 1);
    final p = await savedProfile(tester, db);
    expect(p['display_name'], 'Suresh');
    expect(p['village'], 'Katol');
    expect(p['taluka'], 'Kalmeshwar');
    expect(p['district'], 'Nagpur');
    expect(p['language'], 'en');
    expect(p['consent_data_processing'], true);
    expect(p['consent_whatsapp'], true);
    final row = await tester.runAsync(
      () => db.select(db.farmerProfiles).getSingle(),
    );
    expect(row!.displayName, 'Suresh');
    expect(row.consentWhatsapp, isTrue);
    await unmountApp(tester);
  });

  testWidgets('choosing a language switches the app at once and is saved', (
    tester,
  ) async {
    final db = await openProfile(tester, locale: null);
    expect(find.text('My profile'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'मराठी'));
    await settle(tester);
    expect(find.text('माझी माहिती'), findsOneWidget);
    await tapSave(tester);
    expect((await savedProfile(tester, db))['language'], 'mr');
    expect(find.text('माझी माहिती'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('leaving without saving puts the language back', (tester) async {
    await openProfile(tester, locale: null);
    await tester.tap(find.widgetWithText(ChoiceChip, 'हिन्दी'));
    await settle(tester);
    expect(find.text('मेरी जानकारी'), findsOneWidget);
    // pageBack() looks for the English "Back" tooltip; the app is in Hindi here.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text("Today's tasks"), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a phone sign-in shows the number read-only', (tester) async {
    await openProfile(tester);
    expect(find.text('+919800000000'), findsOneWidget);
    expect(find.byKey(const Key('profile-phone')), findsNothing);
    expect(find.text('You sign in with this number.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a Google user can add a contact number', (tester) async {
    final db = await openProfile(tester, session: googleUser);
    expect(find.text('Add mobile number (optional)'), findsOneWidget);
    expect(find.textContaining('not for signing in'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('profile-phone')),
      '098230 12345',
    );
    await tapSave(tester);
    expect((await savedProfile(tester, db))['phone'], '+919823012345');
    final row = await tester.runAsync(
      () => db.select(db.farmerProfiles).getSingle(),
    );
    expect(row!.phone, '+919823012345');
    await unmountApp(tester);
  });

  testWidgets('a wrong contact number is not saved', (tester) async {
    final db = await openProfile(tester, session: googleUser);
    final before = await profileWrites(tester, db);
    await tester.enterText(find.byKey(const Key('profile-phone')), '12345');
    await tapSave(tester);
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
    expect(await profileWrites(tester, db), before);
    await unmountApp(tester);
  });

  testWidgets('sign out asks first, then goes to login and keeps the data', (
    tester,
  ) async {
    final db = await openProfile(tester);
    await tapKey(tester, 'sign-out');
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('My profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-out')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('sign-out-confirm')));
    await settle(tester);
    expect(find.text('My profile'), findsNothing);
    expect(find.text('Mobile number'), findsOneWidget); // the login screen
    expect(
      await tester.runAsync(() => db.select(db.farmerProfiles).get()),
      hasLength(1),
    );
    await unmountApp(tester);
  });

  testWidgets('settings links to the profile', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/settings',
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('settings-profile')));
    await settle(tester);
    expect(find.text('My profile'), findsOneWidget);
    await unmountApp(tester);
  });

  test(
    'a server copy without a phone keeps the local contact number',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = ProfileRepository(db);
      await repo.save(
        const FarmerProfile(id: 'g1', language: 'mr', phone: '+919823012345'),
      );
      await repo.applyRemote(
        RemoteChange(
          entity: ProfileRepository.entity,
          entityId: 'g1',
          data: const {'language': 'hi', 'phone': null},
          updatedAt: DateTime.utc(2026, 11),
        ),
      );
      final p = await repo.watch('g1').first;
      expect(p!.language, 'hi');
      expect(p.phone, '+919823012345');
    },
  );
}
