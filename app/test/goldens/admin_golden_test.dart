@Tags(['golden'])
library;

import 'package:bagmitra/admin/admin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../admin/admin_sign_in_test.dart' show FakeAdminAuth;
import '../admin/billing_admin_test.dart' show FakeBillingAdmin;
import '../admin/feed_admin_test.dart' show FakeFeedAdmin;
import '../admin/feedback_admin_test.dart' show FakeFeedbackAdmin;
import '../admin/kb_admin_test.dart' show FakeKbAdmin;
import '../admin/market_link_admin_test.dart' show FakeMarketLinkAdmin;
import '../admin/package_admin_test.dart' show FakePackageAdmin;

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

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('admin_market_link_$mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _pump(
        tester,
        AdminApp(
          productName: 'BagMitra',
          auth: FakeAdminAuth(
            signedIn: true,
            roles: {'kb_admin', 'market_link_admin'},
          ),
          kb: FakeKbAdmin(),
          marketLink: FakeMarketLinkAdmin(),
        ),
      );
      await tester.tap(find.text('Verification queue'));
      await tester.pumpAndSettle();
      await _shot(tester, 'ml_queue_$mode');

      await tester.tap(find.text('Ramesh Traders'));
      await tester.pumpAndSettle();
      await _shot(tester, 'ml_subject_$mode');

      // L7: the per-check panel with one GST check recorded.
      await tester.ensureVisible(find.byKey(const ValueKey('record-gstin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('record-gstin')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('registered-year')), '2016');
      await tester.tap(find.widgetWithText(FilledButton, 'Record result').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('GSTIN · Passed'));
      await tester.pumpAndSettle();
      await _shot(tester, 'ml_checks_$mode');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Re-checks due'));
      await tester.pumpAndSettle();
      await _shot(tester, 'ml_rechecks_$mode');

      await tester.tap(find.text('Rating tags'));
      await tester.pumpAndSettle();
      await _shot(tester, 'ml_tags_$mode');
    });
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('admin_package_$mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final fake = FakePackageAdmin(filled: dark);
      await _pump(
        tester,
        AdminApp(
          productName: 'BagMitra',
          auth: FakeAdminAuth(signedIn: true, roles: {'market_link_admin'}),
          kb: FakeKbAdmin(),
          marketLink: FakeMarketLinkAdmin(),
          package: fake,
        ),
      );
      await tester.tap(find.text('Sale package'));
      await tester.pumpAndSettle();
      await _shot(tester, 'package_settings_$mode');

      await tester.tap(find.text('Package activation'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('pkg-phone')), '9812345678');
      await tester.tap(find.byKey(const Key('pkg-find')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('pkg-amount')), '1500');
      await tester.enterText(
        find.byKey(const Key('pkg-ref')),
        'UTR412345678901',
      );
      await tester.pumpAndSettle();
      await _shot(tester, 'package_activation_$mode');
    });
  }

  // Subscription settings (billing addendum §7), Marathi, light and dark.
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('admin_billing_$mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      tester.platformDispatcher.localesTestValue = const [Locale('mr')];
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AdminApp(
          productName: 'BagMitra',
          auth: FakeAdminAuth(signedIn: true, roles: {'billing_admin'}),
          kb: FakeKbAdmin(),
          // Both modes filled: a priced role, and a role made free again (audit L1).
          billing: FakeBillingAdmin(filled: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('सदस्यता'));
      await tester.pumpAndSettle();
      await _shot(tester, 'billing_$mode');
    });
  }

  // In-app feedback list (owner 2026-11-08), Marathi, light and dark.
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('admin_feedback_$mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      tester.platformDispatcher.localesTestValue = const [Locale('mr')];
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await _pump(
        tester,
        AdminApp(
          productName: 'BagMitra',
          auth: FakeAdminAuth(signedIn: true, roles: {'feedback_admin'}),
          kb: FakeKbAdmin(),
          feedback: FakeFeedbackAdmin(),
        ),
      );
      await tester.tap(find.text('अभिप्राय'));
      await tester.pumpAndSettle();
      await _shot(tester, 'feedback_$mode');
    });
  }
}
