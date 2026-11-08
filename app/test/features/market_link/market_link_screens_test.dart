import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/auth/presentation/login_screens.dart';
import 'package:bagmitra/features/home/presentation/home_screen.dart';
import 'package:bagmitra/features/market_link/data/market_link_store.dart';
import 'package:bagmitra/features/market_link/presentation/role_picker_screen.dart';
import 'package:bagmitra/features/market_link/presentation/terms_acceptance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'market_link_store_test.dart' show termsJson;
import 'terms_acceptance_test.dart' show marketConfig;

/// A phone where the trader role was picked and its version-1 terms were accepted.
Future<void> seedAcceptedTrader(AppDatabase db) async {
  await db.writeMeta(MarketLinkStore.roleKey, 'trader');
  await db.writeMeta(
    MarketLinkStore.acceptedKey('u1'),
    jsonEncode({
      'trader': {
        'versions': {'terms': '1', 'privacy': '1', 'disclaimer': '1'},
        'posted': true,
      },
    }),
  );
}

Future<void> seedTraderRole(AppDatabase db) =>
    db.writeMeta(MarketLinkStore.roleKey, 'trader');

Future<Map<String, Object?>> _accepted(
  WidgetTester tester,
  AppDatabase db,
) async {
  final raw = await tester.runAsync(
    () => db.readMeta(MarketLinkStore.acceptedKey('u1')),
  );
  return raw == null ? {} : (jsonDecode(raw) as Map).cast<String, Object?>();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

void main() {
  group('flag off (decision j)', () {
    testWidgets('no role entry on home and /roles goes home', (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/roles/trader',
        seed: seedTraderRole,
      );
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const Key('open-roles')), findsNothing);
      expect(find.byType(RolePickerScreen), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('signed out goes straight to sign-in', (tester) async {
      await pumpApp(tester, session: null);
      expect(find.byType(PhoneLoginScreen), findsOneWidget);
      expect(find.byKey(const Key('login-switch-role')), findsNothing);
      await unmountApp(tester);
    });
  });

  testWidgets(
    'signed out: the five role cards come first, then the same sign-in',
    (tester) async {
      final db = await pumpApp(tester, session: null, config: marketConfig);
      expect(find.byType(RolePickerScreen), findsOneWidget);
      // A welcome first (owner 2026-11-08), then the roles.
      expect(find.byKey(const Key('role-welcome')), findsOneWidget);
      expect(find.text('बागमित्र मध्ये आपले स्वागत'), findsOneWidget);
      for (final label in [
        'शेतकरी',
        'व्यापारी',
        'मध्यस्थ (दलाल)',
        'निर्यातदार',
        'सेवा देणारे',
        'वजनकाटा, वाहतूक, मजूर, क्रेट',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.textContaining('अडत्या'), findsNothing);
      await _tap(tester, 'role-broker');
      expect(find.byType(PhoneLoginScreen), findsOneWidget);
      final role = await tester.runAsync(
        () => db.readMeta(MarketLinkStore.roleKey),
      );
      expect(role, 'broker');
      // The sign-in names the picked card and leads back to the five (no dead end).
      expect(find.text('भूमिका: मध्यस्थ (दलाल)'), findsOneWidget);
      await _tap(tester, 'login-switch-role');
      expect(find.byType(RolePickerScreen), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('acceptance before first use: both ticks open the main button', (
    tester,
  ) async {
    final db = await pumpApp(tester, config: marketConfig);
    await _tap(tester, 'open-roles');
    await _tap(tester, 'role-trader');
    expect(find.byType(TermsAcceptanceScreen), findsOneWidget);
    for (final text in [
      'तुमच्या व्यवहारात या ॲपचा कोणताही लाभ किंवा नुकसान नाही.',
      'व्यवहारानंतर काय नोंदवायचे ते तुमची इच्छा.',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.textContaining('फोन नंबर'), findsOneWidget);
    expect(find.textContaining('GPS'), findsOneWidget);
    expect(find.textContaining('सौदा'), findsNothing);
    FilledButton accept() =>
        tester.widget<FilledButton>(find.byKey(const Key('terms-accept')));
    expect(accept().onPressed, isNull);
    await _tap(tester, 'terms-adult');
    expect(accept().onPressed, isNull);
    await _tap(tester, 'terms-agree');
    expect(accept().onPressed, isNotNull);
    await _tap(tester, 'terms-accept');
    // The role home, with the fixed notice; saved on the phone, to be posted (no server).
    expect(find.byKey(const Key('safety-notice')), findsOneWidget);
    expect(
      find.text('BagMitra कधीही पैसे, OTP किंवा बँक तपशील मागत नाही.'),
      findsOneWidget,
    );
    final stored = await _accepted(tester, db);
    expect((stored['trader']! as Map)['posted'], isFalse);
    // The grievance officer is behind a fold; the owner by default.
    expect(find.text('BagMitra चे मालक'), findsNothing);
    await _tap(tester, 'grievance');
    expect(find.text('BagMitra चे मालक'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('back on the acceptance screen returns to the role cards', (
    tester,
  ) async {
    await pumpApp(tester, config: marketConfig, seed: seedTraderRole);
    await settle(tester);
    expect(find.byType(TermsAcceptanceScreen), findsOneWidget);
    await _tap(tester, 'terms-back');
    expect(find.byType(RolePickerScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'the chosen role opens at home; the switch goes back to the grower app',
    (tester) async {
      await pumpApp(tester, config: marketConfig, seed: seedAcceptedTrader);
      await settle(tester);
      expect(find.byKey(const Key('safety-notice')), findsOneWidget);
      await _tap(tester, 'switch-role');
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await _tap(tester, 'role-grower');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const Key('open-roles')), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('a version change shows the terms again', (tester) async {
    await pumpApp(
      tester,
      config: marketConfig,
      seed: (db) async {
        await seedAcceptedTrader(db);
        await db.writeMeta(MarketLinkStore.termsKey, termsJson(privacy: '2'));
      },
    );
    await settle(tester);
    expect(find.byType(TermsAcceptanceScreen), findsOneWidget);
    await unmountApp(tester);
  });

  for (final location in ['/roles', '/roles/trader']) {
    testWidgets('tap targets and contrast on $location', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        config: marketConfig,
        initialLocation: location,
        seed: location == '/roles/trader' ? seedAcceptedTrader : null,
      );
      await settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await unmountApp(tester);
      handle.dispose();
    });
  }
}
