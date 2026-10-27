@Tags(['golden'])
library;

import 'package:bagmitra/admin/admin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../admin/admin_sign_in_test.dart' show FakeAdminAuth;
import '../admin/feed_admin_test.dart' show FakeFeedAdmin;
import '../admin/kb_admin_test.dart' show FakeKbAdmin;

Future<void> _pump(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('admin_$name.png'));

void main() {
  testWidgets('admin_sign_in', (tester) async {
    await _pump(
      tester,
      AdminApp(
        productName: 'BagMitra',
        auth: FakeAdminAuth(),
        kb: FakeKbAdmin(),
      ),
    );
    await _shot(tester, 'sign_in');
  });

  testWidgets('admin_sections', (tester) async {
    await _pump(tester, AdminApp(productName: 'BagMitra', kb: FakeKbAdmin()));
    await _shot(tester, 'cards');

    await tester.tap(find.text('Imports'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('import-source')),
      'cibrc_insecticides_pgr',
    );
    await tester.enterText(
      find.byKey(const Key('import-csv')),
      'active_ingredient,formulation,crop,target,dose,interval_days,phi_days,max_sprays\n'
      'imidacloprid,17.8 SL,citrus,psylla,per label,,15,',
    );
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await _shot(tester, 'imports');

    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    await _shot(tester, 'alerts');

    await tester.tap(find.text('Sources'));
    await tester.pumpAndSettle();
    await _shot(tester, 'sources');
  });

  testWidgets('admin_feed', (tester) async {
    await _pump(
      tester,
      AdminApp(
        productName: 'BagMitra',
        auth: FakeAdminAuth(signedIn: true, roles: {'kb_admin', 'feed_admin'}),
        kb: FakeKbAdmin(),
        feed: FakeFeedAdmin(),
      ),
    );
    await tester.tap(find.text('Govt feed'));
    await tester.pumpAndSettle();
    await _shot(tester, 'feed_queue');

    await tester.tap(find.text('PM-KISAN instalment'));
    await tester.pumpAndSettle();
    await _shot(tester, 'feed_item');
  });
}
