import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/kb_admin_repository.dart';
import 'package:bagmitra/admin/package_activation_page.dart';
import 'package:bagmitra/admin/package_admin_repository.dart';
import 'package:bagmitra/admin/package_pages.dart';
import 'package:bagmitra/admin/package_print.dart';
import 'package:bagmitra/admin/package_strings.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'admin_sign_in_test.dart' show FakeAdminAuth;
import 'kb_admin_test.dart' show FakeKbAdmin;
import 'market_link_admin_test.dart' show FakeMarketLinkAdmin;

const _empty = {
  'legal_name': null,
  'trade_name': null,
  'address': null,
  'gstin': null,
  'pan': null,
  'bank_account_name': null,
  'bank_ifsc': null,
  'bank_account_last4': null,
  'upi_id': null,
  'invoice_prefix': null,
  'gst_rate_percent': null,
  'merchant_qr': false,
};

PackageGrantOut grantOut(String id, {String? revokedAt, int days = 45}) =>
    PackageGrantOut.fromJson({
      'id': id,
      'grower_id': 'g1',
      'lot_id': null,
      'amount_paise': 150000,
      'method': 'upi',
      'payment_ref': 'UTR$id',
      'paid_on': '2026-11-19',
      'activated_at': '2026-11-20T06:00:00Z',
      'valid_until': DateTime.now().add(Duration(days: days)).toIso8601String(),
      'receipt_no': 'BM/26-27/0000$id',
      'revoked_at': revokedAt,
      'revoked_reason': null,
      'admin_id': 'a1',
    });

ReceiptOut sampleReceipt({bool gst = true, bool revoked = false}) =>
    ReceiptOut.fromJson({
      'receipt_no': 'BM/26-27/00001',
      'issued_on': '2026-11-20',
      'legal_name': 'BagMitra Agritech Pvt Ltd',
      'trade_name': 'BagMitra',
      'address': 'Main Road, Warud, Amravati, Maharashtra 444906',
      'gstin': '27AABCB1234F1Z5',
      'pan': 'AABCB1234F',
      'grower_name': 'रमेश पाटील',
      'grower_phone': '+919812345678',
      'lot': 'santra · nagpur',
      'amount_paise': 150000,
      'method': 'upi',
      'payment_ref': 'UTR412345678901',
      'paid_on': '2026-11-19',
      'valid_from': '2026-11-20',
      'valid_until': '2027-01-04',
      'revoked': revoked,
      'gst': gst
          ? {'rate_percent': '18', 'taxable_paise': 127119, 'gst_paise': 22881}
          : null,
    });

/// In-memory package admin: the guard as the server applies it.
class FakePackageAdmin implements PackageAdminRepository {
  FakePackageAdmin({this.filled = false});
  final bool filled;
  late Map<String, dynamic> profile = {
    ..._empty,
    if (filled) ...{
      'legal_name': 'BagMitra Agritech Pvt Ltd',
      'address': 'Warud, Amravati',
      'gstin': '27AABCB1234F1Z5',
      'upi_id': 'bagmitra@okaxis',
      'invoice_prefix': 'BM/26-27/',
      'merchant_qr': true,
    },
  };
  late Map<String, dynamic> stored = {
    'enabled': false,
    'price_paise': filled ? 150000 : null,
    'validity_days': filled ? 45 : null,
    'starts_at': null,
  };
  final recorded = <PackageGrantIn>[];
  final revoked = <(String, String)>[];
  final grantList = <PackageGrantOut>[];

  List<String> get _missing => [
    for (final f in ['legal_name', 'gstin', 'upi_id'])
      if (profile[f] == null) f,
    if (stored['price_paise'] == null) 'price_paise',
  ];

  @override
  Future<PackageCompanyOut> company() async =>
      PackageCompanyOut.fromJson(profile);

  @override
  Future<PackageCompanyOut> saveCompany(PackageCompanyIn body) async {
    body.toJson().forEach((k, v) => profile[k] = v == '' ? null : v);
    return company();
  }

  @override
  Future<PackageCompanyOut> uploadQr(Uint8List bytes, String type) async {
    profile['merchant_qr'] = true;
    return company();
  }

  @override
  Future<Uint8List> merchantQr() async =>
      File('assets/icon/icon.png').readAsBytesSync();

  @override
  Future<PackageSettingsOut> settings() async =>
      PackageSettingsOut.fromJson({...stored, 'missing': _missing});

  @override
  Future<PackageSettingsOut> saveSettings(PackageSettingsIn body) async {
    final before = Map.of(stored);
    stored = {...stored, ...body.toJson()};
    stored['price_paise'] = body.pricePaise;
    if (body.enabled && _missing.isNotEmpty) {
      stored = before;
      throw PackageAdminException(
        'missing: ${_missing.join(', ')}',
        'package_fields_missing',
      );
    }
    return settings();
  }

  @override
  Future<List<PackageGrowerOut>> findGrower(String phone) async => [
    if (phone.endsWith('9812345678'))
      PackageGrowerOut.fromJson({
        'id': 'g1',
        'name': 'Ramesh Patil',
        'phone': '+919812345678',
        'village': 'Warud',
        'district': 'Amravati',
        'lots': [
          {
            'id': 'l1',
            'crop': 'santra',
            'variety': 'nagpur',
            'status': 'published',
          },
        ],
      }),
  ];

  @override
  Future<PackageGrantOut> recordGrant(PackageGrantIn body) async {
    if (recorded.any((r) => r.paymentRef == body.paymentRef)) {
      throw const PackageAdminException(
        'this payment reference is recorded',
        'duplicate_payment_ref',
      );
    }
    recorded.add(body);
    final g = grantOut('${recorded.length}');
    grantList.insert(0, g);
    return g;
  }

  @override
  Future<List<PackageGrantOut>> grants(String growerId) async => grantList;

  @override
  Future<ReceiptOut> receipt(String grantId) async {
    if (profile['legal_name'] == null) {
      throw const PackageAdminException(
        'missing: legal_name',
        'company_profile_empty',
      );
    }
    return sampleReceipt(gst: profile['gst_rate_percent'] != null);
  }

  @override
  Future<PackageGrantOut> revoke(String grantId, String reason) async {
    revoked.add((grantId, reason));
    final i = grantList.indexWhere((g) => g.id == grantId);
    grantList[i] = grantOut(grantId, revokedAt: '2026-11-21T06:00:00Z');
    return grantList[i];
  }
}

Future<void> pumpPackage(
  WidgetTester tester,
  FakePackageAdmin fake, {
  String? tab,
}) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AdminApp(
      productName: 'BagMitra',
      auth: FakeAdminAuth(signedIn: true, roles: {'market_link_admin'}),
      kb: FakeKbAdmin(),
      marketLink: FakeMarketLinkAdmin(),
      package: fake,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sale package'));
  await tester.pumpAndSettle();
  if (tab != null) {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }
}

void main() {
  test('every language has the same package strings', () {
    final tables = packageStringTables;
    expect(tables.keys, ['mr', 'hi', 'en']);
    for (final lang in ['hi', 'en']) {
      expect(
        tables[lang]!.keys.toSet(),
        tables['mr']!.keys.toSet(),
        reason: lang,
      );
    }
  });

  test('rupees become paise; empty or zero is no amount', () {
    expect(rupeesToPaise('1500'), 150000);
    expect(rupeesToPaise(''), isNull);
    expect(rupeesToPaise('0'), isNull);
  });

  testWidgets('starts empty and names the fields the switch needs', (
    tester,
  ) async {
    final fake = FakePackageAdmin();
    await pumpPackage(tester, fake);
    expect(
      find.text(
        'Cannot turn ON — fill first: Legal name, GSTIN, UPI ID, Price ₹',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('pkg-switch'))).value,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('pkg-switch')));
    await tester.tap(find.byKey(const Key('pkg-save-settings')));
    await tester.pumpAndSettle();
    expect(fake.stored['enabled'], isFalse);
    expect(
      find.text(
        'Cannot turn ON — fill first: Legal name, GSTIN, UPI ID, Price ₹',
      ),
      findsNWidgets(2), // the banner and the refusal
    );
  });

  testWidgets('saving the profile and price lets the switch turn ON', (
    tester,
  ) async {
    final fake = FakePackageAdmin();
    await pumpPackage(tester, fake);
    for (final (key, value) in [
      ('legal_name', 'BagMitra Agritech Pvt Ltd'),
      ('gstin', '27aabcb1234f1z5'),
      ('upi_id', 'bagmitra@okaxis'),
    ]) {
      await tester.enterText(find.byKey(Key('pkg-$key')), value);
    }
    await tester.tap(find.byKey(const Key('pkg-save-company')));
    await tester.pumpAndSettle();
    expect(fake.profile['gstin'], '27AABCB1234F1Z5');
    await tester.enterText(find.byKey(const Key('pkg-price_paise')), '1500');
    await tester.enterText(find.byKey(const Key('pkg-validity_days')), '45');
    await tester.tap(find.byKey(const Key('pkg-switch')));
    await tester.tap(find.byKey(const Key('pkg-save-settings')));
    await tester.pumpAndSettle();
    expect(fake.stored['enabled'], isTrue);
    expect(fake.stored['price_paise'], 150000);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.textContaining('Cannot turn ON'), findsNothing);
  });

  testWidgets('uploads the merchant QR image', (tester) async {
    final fake = FakePackageAdmin();
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BmTheme.light(),
        home: Scaffold(
          body: PackageSettingsPage(
            repo: fake,
            pickQr: () async => (Uint8List.fromList([1]), 'image/png'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Merchant QR image: No QR'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pkg-upload-qr')));
    await tester.pumpAndSettle();
    expect(find.text('Merchant QR image: QR saved'), findsOneWidget);
  });

  testWidgets('activation: find by phone, record, duplicate UTR, revoke', (
    tester,
  ) async {
    final fake = FakePackageAdmin(filled: true);
    await pumpPackage(tester, fake, tab: 'Package activation');
    await tester.enterText(find.byKey(const Key('pkg-phone')), '9800000000');
    await tester.tap(find.byKey(const Key('pkg-find')));
    await tester.pumpAndSettle();
    expect(find.text('No grower with this number'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pkg-phone')), '9812345678');
    await tester.tap(find.byKey(const Key('pkg-find')));
    await tester.pumpAndSettle();
    expect(find.text('Ramesh Patil · +919812345678'), findsOneWidget);
    Future<void> fill(String ref) async {
      await tester.enterText(find.byKey(const Key('pkg-amount')), '1500');
      await tester.enterText(find.byKey(const Key('pkg-ref')), ref);
      await tester.pump();
    }

    await fill('UTR123456789');
    final activate = find.byKey(const Key('pkg-activate'));
    expect(tester.widget<FilledButton>(activate).onPressed, isNull);
    await tester.tap(find.byKey(const Key('pkg-paid-on')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(activate);
    await tester.pumpAndSettle();
    expect(fake.recorded.single.amountPaise, 150000);
    expect(fake.recorded.single.lotId, isNull); // all lots
    expect(find.textContaining('BM/26-27/00001 · ₹1500 · UPI'), findsOneWidget);
    await fill('UTR123456789');
    await tester.tap(activate);
    await tester.pumpAndSettle();
    expect(find.text('This UTR is already recorded'), findsOneWidget);
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pkg-revoke-reason')),
      'bounced',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Revoke'));
    await tester.pumpAndSettle();
    expect(fake.revoked, [('1', 'bounced')]);
    expect(find.text('Revoked'), findsOneWidget);
  });

  testWidgets('receipt PDF and QR card are print files for the admin', (
    tester,
  ) async {
    final fake = FakePackageAdmin(filled: true);
    final saved = <(String, Uint8List)>[];
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<void> page(Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BmTheme.light(),
          home: Scaffold(body: child),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapAndWait(Finder f) async {
      await tester.runAsync(() async {
        await tester.tap(f);
        for (var i = 0; i < 50 && saved.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
    }

    Future<void> save(String name, Uint8List bytes) async =>
        saved.add((name, bytes));
    await page(PackageSettingsPage(repo: fake, saveFile: save));
    await tapAndWait(find.byKey(const Key('pkg-qr-card')));
    expect(saved.single.$1, 'bagmitra-qr-card.pdf');
    expect(ascii.decode(saved.single.$2.sublist(0, 4)), '%PDF');

    saved.clear();
    fake.grantList.add(grantOut('1'));
    await page(PackageActivationPage(repo: fake, saveFile: save));
    await tester.enterText(find.byKey(const Key('pkg-phone')), '9812345678');
    await tester.tap(find.byKey(const Key('pkg-find')));
    await tester.pumpAndSettle();
    await tapAndWait(find.byKey(const ValueKey('receipt-1')));
    expect(saved.single.$1, 'receipt-BM-26-27-00001.pdf');
    expect(ascii.decode(saved.single.$2.sublist(0, 4)), '%PDF');

    // Never with an empty company profile; no QR card without the QR.
    saved.clear();
    fake.profile['legal_name'] = null;
    await tester.tap(find.byKey(const ValueKey('receipt-1')));
    await tester.pumpAndSettle();
    expect(find.text('Fill the company profile first'), findsOneWidget);
    fake.profile['merchant_qr'] = false;
    await page(PackageSettingsPage(repo: fake, saveFile: save));
    await tester.tap(find.byKey(const Key('pkg-qr-card')));
    await tester.pumpAndSettle();
    expect(find.text('Upload the merchant QR first'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('the receipt shows the GST line only when the server sends it', (
    tester,
  ) async {
    const s = PackageStrings.forLanguage('en');
    for (final (gst, revoked) in [(true, false), (false, true)]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ReceiptSheet(sampleReceipt(gst: gst, revoked: revoked), s),
        ),
      );
      expect(
        find.text('GST 18% (included)'),
        gst ? findsOneWidget : findsNothing,
      );
      expect(find.text('Revoked'), revoked ? findsOneWidget : findsNothing);
      expect(find.text('रमेश पाटील · +919812345678'), findsOneWidget);
    }
  });

  test('the API repository calls the package endpoints', () async {
    final sent = <http.Request>[];
    Object body = _empty;
    var status = 200;
    final repo = ApiPackageAdminRepository(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient((req) async {
          sent.add(req);
          return http.Response(
            jsonEncode(body),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    expect((await repo.company()).merchantQr, isFalse);
    await repo.saveCompany(const PackageCompanyIn(gstin: ''));
    expect(jsonDecode(sent.last.body), {'gstin': ''});
    await repo.uploadQr(Uint8List.fromList([1, 2]), 'image/png');
    expect(sent.last.headers['Content-Type'], startsWith('image/png'));
    expect(sent.last.bodyBytes, [1, 2]);
    body = {'growers': <Object>[]};
    expect(await repo.findGrower('9812345678'), isEmpty);
    expect(sent.last.url.queryParameters['phone'], '9812345678');
    body = {
      'error': {'code': 'duplicate_payment_ref', 'message': 'recorded'},
    };
    status = 409;
    await expectLater(
      repo.recordGrant(
        PackageGrantIn(
          growerId: 'g1',
          amountPaise: 100,
          method: PackageGrantInMethod.cash,
          paymentRef: 'R123',
          paidOn: DateTime(2026, 11, 19),
        ),
      ),
      throwsA(
        isA<PackageAdminException>().having(
          (e) => e.code,
          'code',
          'duplicate_payment_ref',
        ),
      ),
    );
    await expectLater(repo.merchantQr(), throwsA(isA<KbAdminException>()));
    status = 200;
    body = {'grants': <Object>[]};
    expect(await repo.grants('g1'), isEmpty);
    body = grantOut('1').toJson();
    expect((await repo.revoke('1', 'bounced')).id, '1');
    body = {...stubSettings};
    expect((await repo.settings()).missing, ['gstin']);
    expect(
      (await repo.saveSettings(const PackageSettingsIn(enabled: false)))
          .enabled,
      isFalse,
    );
  });
}

const stubSettings = {
  'enabled': false,
  'price_paise': null,
  'validity_days': null,
  'starts_at': null,
  'missing': ['gstin'],
};
