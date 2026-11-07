import 'dart:convert';

import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/home/presentation/home_screen.dart';
import 'package:bagmitra/features/market_link/data/market_link_store.dart';
import 'package:bagmitra/features/market_link/domain/market_link.dart';
import 'package:bagmitra/features/market_link/presentation/terms_acceptance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;

const marketConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
  marketLink: true,
);

Future<Map<String, Object?>> acceptedOnPhone(
  WidgetTester tester,
  AppDatabase db,
) async {
  final raw = await tester.runAsync(
    () => db.readMeta(MarketLinkStore.acceptedKey('u1')),
  );
  return raw == null ? {} : (jsonDecode(raw) as Map).cast<String, Object?>();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

/// Starts [ensureMarketRoleAccepted] from the grower home (a ConsumerWidget's element is
/// both its BuildContext and its WidgetRef).
Future<bool> gateFromHome(WidgetTester tester, MarketRole role) {
  final element = tester.element(find.byType(HomeScreen));
  return ensureMarketRoleAccepted(element, element as WidgetRef, role);
}

void main() {
  testWidgets('flag off: the terms route does not exist', (tester) async {
    await pumpApp(tester, initialLocation: '/roles/trader/terms');
    await settle(tester);
    expect(find.byType(TermsAcceptanceScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'trader: owner disclaimer, public phone, GPS; both ticks open the button',
    (tester) async {
      final db = await pumpApp(tester, config: marketConfig);
      final gate = gateFromHome(tester, MarketRole.trader);
      await settle(tester);
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
      expect(find.textContaining('अडत्या'), findsNothing);
      FilledButton accept() =>
          tester.widget<FilledButton>(find.byKey(const Key('terms-accept')));
      expect(accept().onPressed, isNull);
      await tapKey(tester, 'terms-adult');
      expect(accept().onPressed, isNull);
      await tapKey(tester, 'terms-agree');
      expect(accept().onPressed, isNotNull);
      await tapKey(tester, 'terms-accept');
      expect(await gate, isTrue);
      // Saved on the phone, waiting to be posted (this test has no server).
      final stored = await acceptedOnPhone(tester, db);
      expect((stored['trader']! as Map)['posted'], isFalse);
      // Accepted: the gate now passes without a screen.
      expect(
        await tester.runAsync(() => gateFromHome(tester, MarketRole.trader)),
        isTrue,
      );
      await unmountApp(tester);
    },
  );

  testWidgets(
    'grower (for L3): no public-phone or GPS point; back returns false',
    (tester) async {
      final db = await pumpApp(tester, config: marketConfig);
      final gate = gateFromHome(tester, MarketRole.grower);
      await settle(tester);
      expect(find.byType(TermsAcceptanceScreen), findsOneWidget);
      expect(find.textContaining('GPS'), findsNothing);
      expect(find.textContaining('फोन नंबर'), findsNothing);
      await tapKey(tester, 'terms-back');
      expect(await gate, isFalse);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(await acceptedOnPhone(tester, db), isEmpty);
      await unmountApp(tester);
    },
  );

  testWidgets('tap targets and contrast on the terms screen', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      config: marketConfig,
      initialLocation: '/roles/trader/terms',
    );
    await settle(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await unmountApp(tester);
    handle.dispose();
  });
}
