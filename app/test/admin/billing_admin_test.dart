import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/billing_admin_repository.dart';
import 'package:bagmitra/admin/billing_pages.dart';
import 'package:bagmitra/admin/package_admin_repository.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_sign_in_test.dart' show FakeAdminAuth;
import 'billing_admin_repository_test.dart' show billingRoleJson;
import 'kb_admin_test.dart' show FakeKbAdmin;

/// In-memory billing admin, answering like the API (Play is a switch: set up or not).
class FakeBillingAdmin implements BillingAdminRepository {
  FakeBillingAdmin({this.playSetUp = true, bool filled = false}) {
    if (filled) {
      _enabled = true;
      _start = DateTime.utc(2026, 12, 7);
      _roles['grower'] = billingRoleJson('grower', amount: 9900, play: true);
      _roles['trader'] = billingRoleJson('trader', amount: 29900, play: true);
    }
  }

  final bool playSetUp;
  bool _enabled = false;
  DateTime? _start;
  final Map<String, Map<String, Object?>> _roles = {
    for (final r in billingRoles) r: billingRoleJson(r),
  };
  final calls = <String>[];

  BillingSettingsOut _out() => BillingSettingsOut.fromJson({
    'enabled': _enabled,
    'starts_on': _start?.toIso8601String().substring(0, 10),
    'roles': [for (final r in billingRoles) _roles[r]],
  });

  @override
  Future<BillingSettingsOut> settings() async => _out();

  @override
  Future<BillingSettingsOut> saveSwitch({
    required bool enabled,
    DateTime? startsOn,
  }) async {
    calls.add('switch $enabled ${startsOn?.toIso8601String()}');
    _enabled = enabled;
    _start = startsOn;
    return _out();
  }

  @override
  Future<BillingSettingsOut> saveAmount(String role, int? paise) async {
    calls.add('amount $role $paise');
    if (paise != null && !playSetUp) {
      throw const PackageAdminException('play_not_set_up', 'play_not_set_up');
    }
    _roles[role] = billingRoleJson(role, amount: paise, play: paise != null);
    return _out();
  }

  @override
  Future<BillingSettingsOut> migratePrices(String role) async {
    calls.add('migrate $role');
    return _out();
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  String lang = 'en',
}) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: BmTheme.light(),
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the switch starts OFF, every role free, rules shown before saving',
    (tester) async {
      await _pump(tester, BillingSettingsPage(repo: FakeBillingAdmin()));
      final sw = tester.widget<SwitchListTile>(
        find.byKey(const Key('billing-switch')),
      );
      expect(sw.value, isFalse);
      expect(find.text('Free (no amount)'), findsNWidgets(5));
      expect(find.byKey(const Key('billing-rules')), findsOneWidget);
      expect(
        find.textContaining('existing subscribers keep the old price'),
        findsOneWidget,
      );
      expect(find.textContaining('nothing is locked today'), findsOneWidget);
      expect(find.textContaining("CA's GST opinion"), findsOneWidget);
      // Nothing to move before Play has a price.
      final move = tester.widget<OutlinedButton>(
        find.byKey(const Key('billing-migrate-grower')),
      );
      expect(move.onPressed, isNull);
    },
  );

  testWidgets('saving an amount shows the price Play reports', (tester) async {
    final fake = FakeBillingAdmin();
    await _pump(tester, BillingSettingsPage(repo: fake));
    await tester.enterText(
      find.byKey(const Key('billing-amount-trader')),
      '299',
    );
    await tester.tap(find.byKey(const Key('billing-save-trader')));
    await tester.pumpAndSettle();
    expect(fake.calls, ['amount trader 29900']);
    expect(find.text('Play price: INR 299.00 · 2026-11-08'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('Play not set up: nothing saved, the page says why', (
    tester,
  ) async {
    final fake = FakeBillingAdmin(playSetUp: false);
    await _pump(tester, BillingSettingsPage(repo: fake));
    await tester.enterText(
      find.byKey(const Key('billing-amount-grower')),
      '99',
    );
    await tester.tap(find.byKey(const Key('billing-save-grower')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not connected yet'), findsOneWidget);
    expect(find.text('Free (no amount)'), findsNWidgets(5));
  });

  testWidgets('switch and start date are saved together', (tester) async {
    final fake = FakeBillingAdmin();
    await _pump(tester, BillingSettingsPage(repo: fake));
    await tester.tap(find.byKey(const Key('billing-switch')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('billing-save-switch')));
    await tester.pumpAndSettle();
    expect(fake.calls, ['switch true null']);
  });

  testWidgets('moving existing subscribers needs a confirmation', (
    tester,
  ) async {
    final fake = FakeBillingAdmin(filled: true);
    await _pump(tester, BillingSettingsPage(repo: fake));
    await tester.tap(find.byKey(const Key('billing-migrate-grower')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(fake.calls, isEmpty);
    await tester.tap(find.byKey(const Key('billing-migrate-grower')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('billing-migrate-confirm')));
    await tester.pumpAndSettle();
    expect(fake.calls, ['migrate grower']);
  });

  testWidgets('Marathi page uses the owner words', (tester) async {
    await _pump(
      tester,
      BillingSettingsPage(repo: FakeBillingAdmin()),
      lang: 'mr',
    );
    expect(find.text('मध्यस्थ (दलाल)'), findsOneWidget);
    expect(find.text('शेतकरी'), findsOneWidget);
  });

  testWidgets('the section is shown only to billing_admin', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app(Set<String> roles) => AdminApp(
      productName: 'BagMitra',
      auth: FakeAdminAuth(signedIn: true, roles: roles),
      kb: FakeKbAdmin(),
      billing: FakeBillingAdmin(),
    );
    await tester.pumpWidget(app({'kb_admin'}));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsNothing);
    await tester.pumpWidget(app({billingAdminRole}));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsOneWidget);
  });
}
