import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/market_link_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'terms_acceptance_test.dart' show marketConfig;

/// A phone where [role] was picked and its version-1 terms were accepted.
Future<void> Function(AppDatabase) acceptedRole(String role) => (db) async {
  await db.writeMeta(MarketLinkStore.roleKey, role);
  await db.writeMeta(
    MarketLinkStore.acceptedKey('u1'),
    jsonEncode({
      role: {
        'versions': {'terms': '1', 'privacy': '1', 'disclaimer': '1'},
        'posted': true,
      },
    }),
  );
};

const _buyerTools = [
  'role-tool-browse',
  'role-tool-offers',
  'role-tool-mine',
  'role-tool-prices',
  'role-tool-actions',
];

void main() {
  for (final role in ['trader', 'broker', 'exporter']) {
    testWidgets('$role home holds the role tools, not a "soon" note', (
      tester,
    ) async {
      await pumpApp(tester, config: marketConfig, seed: acceptedRole(role));
      await settle(tester);
      for (final key in _buyerTools) {
        await tester.ensureVisible(find.byKey(Key(key)));
        expect(find.byKey(Key(key)), findsOneWidget, reason: '$role $key');
      }
      expect(
        find.byKey(const Key('role-tool-export')),
        role == 'exporter' ? findsOneWidget : findsNothing,
      );
      expect(find.textContaining('लवकरच'), findsNothing);
      await unmountApp(tester);
    });
  }

  testWidgets('a trader opens the published lots from home', (tester) async {
    await pumpApp(tester, config: marketConfig, seed: acceptedRole('trader'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('role-tool-browse')));
    await settle(tester);
    expect(find.text('विक्रीसाठी माल'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('a service provider has the registration and account actions', (
    tester,
  ) async {
    await pumpApp(tester, config: marketConfig, seed: acceptedRole('provider'));
    await settle(tester);
    expect(find.byKey(const Key('role-tool-mine')), findsOneWidget);
    expect(find.byKey(const Key('role-tool-actions')), findsOneWidget);
    expect(find.byKey(const Key('role-tool-browse')), findsNothing);
    expect(find.byKey(const Key('role-tool-offers')), findsNothing);
    await unmountApp(tester);
  });
}
