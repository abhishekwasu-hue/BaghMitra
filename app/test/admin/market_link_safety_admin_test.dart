import 'dart:convert';

import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/kb_admin_repository.dart';
import 'package:bagmitra/admin/market_link_safety_admin.dart';
import 'package:bagmitra/admin/market_link_safety_pages.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'admin_sign_in_test.dart' show FakeAdminAuth;
import 'kb_admin_test.dart' show FakeKbAdmin;
import 'market_link_admin_test.dart' show FakeMarketLinkAdmin;

final _t0 = DateTime.utc(2026, 11, 1, 9);

ReportAdminOut report(
  String id, {
  String reason = 'fake_identity',
  bool ackLate = false,
  bool closeLate = false,
  int photos = 0,
}) => ReportAdminOut(
  id: id,
  reporterId: 'u-reporter',
  subjectType: 'buyer',
  subjectId: 'b1',
  subjectUserId: 'u-trader',
  reason: reason,
  photoCount: photos,
  status: 'open',
  createdAt: _t0,
  acknowledgedAt: null,
  decidedAt: null,
  decidedBy: null,
  adminActionId: null,
  ackOverdue: ackLate,
  closeOverdue: closeLate,
);

ActionOut appeal(String id, {bool ackLate = false}) => ActionOut(
  id: id,
  subjectType: 'lot',
  subjectId: 'lot-1',
  userId: 'u-grower',
  action: 'hide',
  reasonCode: 'fake_lot',
  actorId: 'admin',
  actedAt: _t0,
  appealState: 'appealed',
  appealReason: 'lot_genuine',
  appealedAt: _t0.add(const Duration(days: 1)),
  appealPhotoCount: 1,
  appealAcknowledgedAt: null,
  appealDecidedBy: null,
  appealDecidedAt: null,
  ackOverdue: ackLate,
  closeOverdue: false,
);

class FakeSafetyAdmin implements MarketLinkSafetyAdmin {
  final calls = <String>[];
  List<ReportAdminOut> open = [
    report('r1', ackLate: true, photos: 1),
    report('r2', reason: 'abuse', closeLate: true),
  ];
  List<ActionOut> pending = [appeal('a1', ackLate: true)];

  @override
  Future<List<ReportAdminOut>> reports(String status) async =>
      status == 'open' ? open : [];
  @override
  Future<void> acknowledgeReport(String id) async => calls.add('ack $id');
  @override
  Future<void> actOnReport(String id, String action, String code) async {
    calls.add('act $id $action $code');
    open = [];
  }

  @override
  Future<void> dismissReport(String id) async => calls.add('dismiss $id');
  @override
  Future<String> reportPhotoUrl(String id, int index) async =>
      'https://storage.test/$id/$index';
  @override
  Future<List<ActionOut>> appeals() async => pending;
  @override
  Future<void> acknowledgeAppeal(String id) async =>
      calls.add('ack-appeal $id');
  @override
  Future<void> decideAppeal(String id, {required bool upheld}) async {
    calls.add('appeal $id ${upheld ? 'upheld' : 'rejected'}');
    pending = [];
  }

  @override
  Future<String> appealPhotoUrl(String id, int index) async =>
      'https://storage.test/$id/$index';
}

Future<void> pumpAdmin(WidgetTester tester, FakeSafetyAdmin safety) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AdminApp(
      productName: 'BagMitra',
      auth: FakeAdminAuth(signedIn: true, roles: {'market_link_admin'}),
      kb: FakeKbAdmin(),
      marketLink: FakeMarketLinkAdmin(),
      safety: safety,
    ),
  );
  await tester.pumpAndSettle();
}

/// A Bagmitra client that records requests and answers [body].
(Bagmitra, List<http.Request>) mockApi(Object body) {
  final sent = <http.Request>[];
  final api = createApi(
    baseUrl: Uri.parse('https://api.example.test'),
    token: () => 'tok',
    httpClient: MockClient((req) async {
      sent.add(req);
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  return (api, sent);
}

void main() {
  final en = AppLocalizationsEn();

  testWidgets('reports: overdue badges, act with a platform reason code', (
    tester,
  ) async {
    final fake = FakeSafetyAdmin();
    await pumpAdmin(tester, fake);
    await tester.tap(find.text(en.adminMlReports));
    await tester.pumpAndSettle();
    expect(find.text(en.adminMlAckOverdue), findsOneWidget);
    expect(find.text(en.adminMlCloseOverdue), findsOneWidget);
    expect(find.text(en.mlReasonFakeIdentity), findsOneWidget);
    await tester.tap(find.text(en.adminMlAcknowledge).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.adminMlDismiss).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('act-r1')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('action-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.text(en.adminMlActionNote), findsWidgets);
    await tester.tap(find.text(en.mlActionSuspend));
    await tester.tap(find.byKey(const ValueKey('code-duplicate_user')));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(fake.calls, [
      'ack r1',
      'dismiss r2',
      'act r1 suspend duplicate_user',
    ]);
    expect(find.text(en.adminMlReportsEmpty), findsOneWidget);
  });

  testWidgets('a report photo opens by its short link', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: BmTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ReportsPage(
            repo: FakeSafetyAdmin(),
            openPhoto: (u) async => opened.add(u),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-0')));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://storage.test/r1/0');
  });

  test('admin repository sends codes, never text', () async {
    final (api, sent) = mockApi(report('r1').toJson());
    final repo = ApiMarketLinkSafetyAdmin(api);
    await repo.actOnReport('r1', 'hide', 'fake_lot');
    expect(sent.last.url.path, '/v1/admin/market-link/reports/r1/decision');
    expect(jsonDecode(sent.last.body), {
      'action': 'hide',
      'reason_code': 'fake_lot',
    });
    await repo.dismissReport('r1');
    await repo.acknowledgeReport('r1');
    expect(sent.last.url.path, '/v1/admin/market-link/reports/r1/acknowledge');
    final (api2, sent2) = mockApi(appeal('a1').toJson());
    final repo2 = ApiMarketLinkSafetyAdmin(api2);
    await repo2.decideAppeal('a1', upheld: false);
    expect(jsonDecode(sent2.last.body), {'outcome': 'rejected'});
    await repo2.acknowledgeAppeal('a1');
    final (api3, _) = mockApi({
      'url': 'https://s.test/x',
      'photo_key': 'k',
      'expires_in': 60,
    });
    expect(
      await ApiMarketLinkSafetyAdmin(api3).appealPhotoUrl('a1', 0),
      'https://s.test/x',
    );
    expect(
      await ApiMarketLinkSafetyAdmin(api3).reportPhotoUrl('r1', 0),
      'https://s.test/x',
    );
    final (api4, sent4) = mockApi({
      'reports': [report('r1').toJson()],
    });
    expect(await ApiMarketLinkSafetyAdmin(api4).reports('open'), hasLength(1));
    expect(sent4.last.url.queryParameters['status'], 'open');
    final (api5, _) = mockApi({
      'actions': [appeal('a1').toJson()],
    });
    expect(await ApiMarketLinkSafetyAdmin(api5).appeals(), hasLength(1));
  });

  test('admin errors surface as KbAdminException', () async {
    final repo = ApiMarketLinkSafetyAdmin(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => null,
        httpClient: MockClient((_) async => http.Response('{}', 403)),
      ),
    );
    await expectLater(repo.appeals(), throwsA(isA<KbAdminException>()));
  });
}
