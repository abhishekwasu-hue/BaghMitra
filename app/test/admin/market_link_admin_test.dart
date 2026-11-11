import 'dart:convert';

import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/kb_admin_repository.dart';
import 'package:bagmitra/admin/lot_settings_page.dart';
import 'package:bagmitra/admin/market_link_admin_repository.dart';
import 'package:bagmitra/admin/market_link_pages.dart';
import 'package:bagmitra/admin/market_link_rechecks.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.enums.swagger.dart' as enums;
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'admin_sign_in_test.dart' show FakeAdminAuth;
import 'kb_admin_test.dart' show FakeKbAdmin;

const _buyer = {
  'subject_type': 'buyer',
  'subject_id': 'b1',
  'name': 'Ramesh Traders',
  'fields': {
    'name': 'Ramesh Traders',
    'firm': 'RT & Sons',
    'phone': '919800000001',
    'markets': 'Kalamna',
    'district': 'Nagpur',
    'crops': 'santra',
    'apmc_licence_no': 'APMC-42',
    'gst_no': '27ABCDE1234F1Z5',
  },
  'document_keys': ['docs/apmc.jpg', 'docs/shop.jpg'],
  'waiting_since': '2026-11-01T09:00:00Z',
  'status': 'pending',
  'flags': ['duplicate_number'],
  'related': [
    {
      'flag': 'duplicate_number',
      'why': 'apmc_licence_no',
      'subject_type': 'buyer',
      'subject_id': 'b9',
      'name': 'Other Traders',
    },
  ],
};

const _links = [
  {
    'kind': 'gstin',
    'number': '27ABCDE1234F1Z5',
    'url': 'https://services.gst.gov.in/services/searchtp',
  },
  {'kind': 'phone_call', 'number': '919800000001', 'url': 'tel:919800000001'},
  {'kind': 'place_photo', 'number': null, 'url': null},
];

Map<String, dynamic> _checkRow(String kind, String result, {int? year}) => {
  'id': 'c-$kind-$result',
  'kind': kind,
  'number': kind == 'gstin' ? '27ABCDE1234F1Z5' : null,
  'result': result,
  'registered_year': year,
  'official_url': null,
  'checked_by': 'admin-1',
  'checked_at': '2026-11-03T10:00:00Z',
  'recheck_listed_at': null,
};

const _provider = {
  'subject_type': 'provider',
  'subject_id': 'p1',
  'name': 'Warud Kata',
  'fields': {
    'kind': 'weighbridge',
    'name': 'Warud Kata',
    'phone': '919800000003',
    'district': 'Amravati',
    'refrigerated': 'no',
  },
  'document_keys': <String>[],
  'waiting_since': '2026-10-28T09:00:00Z',
  'status': 'pending',
};

Map<String, dynamic> _row(String status, {String? reason, String? by}) => {
  'id': 'v-$status',
  'status': status,
  'reason': reason,
  'document_keys': ['docs/apmc.jpg'],
  'checked_by': by,
  'checked_at': by == null ? null : '2026-11-02T10:00:00Z',
  'created_at': '2026-11-01T09:00:00Z',
};

List<RatingTagAdminOut> _tags() => [
  for (final (key, q, pol, mr, status) in const [
    (
      'trader_on_date_yes',
      'trader_on_date',
      'positive',
      'ठरल्या दिवशी आले',
      'active',
    ),
    ('trader_on_date_no', 'trader_on_date', 'negative', 'उशिरा आले', 'draft'),
    ('trader_paid_yes', 'trader_paid', 'positive', 'पैसे वेळेवर', 'draft'),
  ])
    RatingTagAdminOut.fromJson({
      'id': key,
      'key': key,
      'question_key': q,
      'polarity': pol,
      'label_mr': mr,
      'label_hi': 'हिंदी $key',
      'label_en': 'English $key',
      'status': status,
      'sort_order': 0,
    }),
];

class FakeMarketLinkAdmin implements MarketLinkAdminRepository {
  FakeMarketLinkAdmin({this.empty = false});
  final bool empty;
  final queries = <String?>[];
  final decisions = <(String, String, bool, String?)>[];
  final opened = <int>[];
  final saved = <(String, RatingTagIn)>[];
  final checks = <(String, String, int?)>[];
  late final tags = _tags();

  SubjectOut _subject(String id) =>
      SubjectOut.fromJson(id == 'b1' ? _buyer : _provider);

  @override
  Future<List<SubjectOut>> queue({String? type}) async {
    queries.add(type);
    if (empty) return [];
    final all = [_subject('p1'), _subject('b1')];
    return [
      for (final s in all)
        if (type == null || s.subjectType == type) s,
    ];
  }

  @override
  Future<SubjectDetailOut> subject(String type, String id) async =>
      SubjectDetailOut(
        subject: _subject(id),
        history: [
          VerificationOut.fromJson(
            _row('rejected', reason: 'Licence copy unreadable', by: 'admin-1'),
          ),
          VerificationOut.fromJson(_row('pending')),
        ],
        links: id == 'b1'
            ? [for (final l in _links) OfficialLinkOut.fromJson(l)]
            : [],
        checks: [
          for (final (kind, result, year) in checks.reversed)
            CheckOut.fromJson(_checkRow(kind, result, year: year)),
        ],
      );

  @override
  Future<SubjectDetailOut> recordCheck(
    String type,
    String id, {
    required String kind,
    required String result,
    int? registeredYear,
  }) async {
    checks.add((kind, result, registeredYear));
    return subject(type, id);
  }

  @override
  Future<List<RecheckItemOut>> rechecks() async => [
    if (!empty)
      RecheckItemOut.fromJson({
        'subject_type': 'buyer',
        'subject_id': 'b1',
        'name': 'Ramesh Traders',
        'check_id': 'c1',
        'kind': 'gstin',
        'number': '27ABCDE1234F1Z5',
        'checked_at': '2025-11-01T09:00:00Z',
        'listed_at': '2026-11-07T00:00:00Z',
      }),
  ];

  @override
  Future<SubjectDetailOut> decide(
    String type,
    String id, {
    required bool approve,
    String? reason,
  }) async {
    decisions.add((type, id, approve, reason));
    final base = await subject(type, id);
    return SubjectDetailOut(
      subject: base.subject.copyWith(status: approve ? 'approved' : 'rejected'),
      history: [
        VerificationOut.fromJson(
          _row(
            approve ? 'approved' : 'rejected',
            reason: reason,
            by: 'admin-1',
          ),
        ),
        ...base.history,
      ],
    );
  }

  @override
  Future<String> documentUrl(String type, String id, int index) async {
    opened.add(index);
    if (index > 0) throw const KbAdminException('photo backup not configured');
    return 'https://storage.test/doc-$index';
  }

  @override
  Future<List<RatingTagAdminOut>> ratingTags() async => empty ? [] : tags;

  @override
  Future<RatingTagAdminOut> saveRatingTag(String id, RatingTagIn body) async {
    saved.add((id, body));
    return tags.first;
  }

  final lotSaves = <AdminLotSettingsIn>[];
  AdminLotSettingsIn _lot = const AdminLotSettingsIn();

  @override
  Future<AdminLotSettingsOut> lotSettings() async => lotSettingsOut(_lot);

  @override
  Future<AdminLotSettingsOut> saveLotSettings(AdminLotSettingsIn body) async {
    lotSaves.add(body);
    _lot = body;
    return lotSettingsOut(body);
  }
}

const _lotDefaults = {
  'per_quintal': (250000, 1000000),
  'per_crate': (40000, 120000),
};

/// What the server answers for [s]: every crop and basis, the stored values (null =
/// default) beside the defaults.
AdminLotSettingsOut lotSettingsOut(AdminLotSettingsIn s) {
  AdminRangeIn? sent(String crop, String basis) => s.rateRanges
      ?.where((r) => r.crop.value == crop && r.basis.value == basis)
      .firstOrNull;
  return AdminLotSettingsOut(
    rateRanges: [
      for (final crop in ['santra', 'mosambi'])
        for (final MapEntry(key: basis, value: (lo, hi))
            in _lotDefaults.entries)
          AdminRangeOut(
            crop: enums.AdminRangeOutCrop.values.byName(crop),
            basis: enums.AdminRangeOutBasis.values.firstWhere(
              (b) => b.value == basis,
            ),
            minPaise: sent(crop, basis)?.minPaise,
            maxPaise: sent(crop, basis)?.maxPaise,
            defaultMinPaise: lo,
            defaultMaxPaise: hi,
          ),
    ],
    harvestWindowDays: s.harvestWindowDays,
    harvestWindowDaysDefault: 15,
    effective: const LotSettingsOut(rateRanges: [], harvestWindowDays: 15),
  );
}

Widget _page(Widget child) => MaterialApp(
  theme: BmTheme.light(),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

Future<void> _wide(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('menu entries', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      MarketLinkAdminRepository? repo,
      Set<String> roles = const {},
    }) async {
      await _wide(tester);
      await tester.pumpWidget(
        AdminApp(
          productName: 'BagMitra',
          auth: FakeAdminAuth(signedIn: true, roles: {'kb_admin', ...roles}),
          kb: FakeKbAdmin(),
          marketLink: repo,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('hidden while the MARKET_LINK flag is off (no repository)', (
      tester,
    ) async {
      await pumpShell(tester, roles: {marketLinkAdminRole});
      expect(find.text('Verification queue'), findsNothing);
      expect(find.text('Rating tags'), findsNothing);
    });

    testWidgets('hidden without the market_link_admin role', (tester) async {
      await pumpShell(
        tester,
        repo: FakeMarketLinkAdmin(),
        roles: {'feed_admin'},
      );
      expect(find.text('Verification queue'), findsNothing);
    });

    testWidgets('shown with the flag and the role', (tester) async {
      await pumpShell(
        tester,
        repo: FakeMarketLinkAdmin(),
        roles: {marketLinkAdminRole},
      );
      await tester.tap(find.text('Rating tags'));
      await tester.pumpAndSettle();
      expect(find.text('उशिरा आले'), findsOneWidget);
      await tester.tap(find.text('Verification queue').first);
      await tester.pumpAndSettle();
      expect(find.text('Ramesh Traders'), findsOneWidget);
    });
  });

  testWidgets('queue lists oldest first and filters by type', (tester) async {
    await _wide(tester);
    final repo = FakeMarketLinkAdmin();
    await tester.pumpWidget(_page(VerificationQueuePage(repo: repo)));
    await tester.pumpAndSettle();
    final warud = tester.getTopLeft(find.text('Warud Kata')).dy;
    final ramesh = tester.getTopLeft(find.text('Ramesh Traders')).dy;
    expect(warud, lessThan(ramesh));
    expect(find.text('Waiting since 2026-11-01'), findsOneWidget);
    await tester.tap(find.text('Trader'));
    await tester.pumpAndSettle();
    expect(repo.queries, [null, 'buyer']);
    expect(find.text('Warud Kata'), findsNothing);
  });

  testWidgets('empty queue shows the empty state', (tester) async {
    await _wide(tester);
    await tester.pumpWidget(
      _page(VerificationQueuePage(repo: FakeMarketLinkAdmin(empty: true))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Everyone is checked'), findsOneWidget);
    await tester.pumpWidget(
      _page(RatingTagsPage(repo: FakeMarketLinkAdmin(empty: true))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rating tags appear here'), findsOneWidget);
  });

  testWidgets('detail: fields, documents, history, approve and reject', (
    tester,
  ) async {
    await _wide(tester);
    final repo = FakeMarketLinkAdmin();
    final opened = <Uri>[];
    await tester.pumpWidget(
      _page(
        VerificationQueuePage(repo: repo, openUrl: (u) async => opened.add(u)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ramesh Traders'));
    await tester.pumpAndSettle();
    expect(find.text('APMC licence no.'), findsOneWidget);
    expect(find.text('APMC-42'), findsOneWidget);
    await tester.dragUntilVisible(
      find.textContaining('Licence copy unreadable'),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    expect(find.textContaining('Licence copy unreadable'), findsOneWidget);
    expect(find.textContaining('by admin-1'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('document-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('document-0')));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://storage.test/doc-0')]);
    await tester.tap(find.byKey(const ValueKey('document-1')));
    await tester.pumpAndSettle();
    expect(find.text('photo backup not configured'), findsOneWidget);

    // Reject needs a reason: the button stays off until one is typed.
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    final dialogReject = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Reject'),
    );
    expect(tester.widget<FilledButton>(dialogReject).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('reject-reason')),
      ' No shop photo ',
    );
    await tester.pump();
    await tester.tap(dialogReject);
    await tester.pumpAndSettle();
    expect(repo.decisions.single, ('buyer', 'b1', false, 'No shop photo'));

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(repo.decisions.last, ('buyer', 'b1', true, null));
    expect(find.text('Verified'), findsWidgets);

    // Cancelling the reject dialog writes nothing.
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.decisions, hasLength(2));
  });

  testWidgets('flags, official page, record a check (L7)', (tester) async {
    await _wide(tester);
    final repo = FakeMarketLinkAdmin();
    final opened = <Uri>[];
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await tester.pumpWidget(
      _page(
        VerificationQueuePage(repo: repo, openUrl: (u) async => opened.add(u)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Same number on another profile'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ramesh Traders'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flag-duplicate_number')), findsOneWidget);
    expect(find.text('Other Traders · APMC licence'), findsOneWidget);
    expect(find.text('Checks you record show here'), findsOneWidget);
    // No page for the place photo: record only.
    expect(find.byKey(const ValueKey('open-place_photo')), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('open-gstin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-gstin')));
    await tester.pumpAndSettle();
    expect(copied, '27ABCDE1234F1Z5');
    expect(opened.single.host, 'services.gst.gov.in');
    await tester.ensureVisible(find.byKey(const ValueKey('open-phone_call')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-phone_call')));
    await tester.pumpAndSettle();
    expect(opened.last.scheme, 'tel');

    await tester.ensureVisible(find.byKey(const ValueKey('record-gstin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-gstin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('registered-year')), '2016');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Record result'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.checks.single, ('gstin', 'passed', 2016));
    expect(find.text('GSTIN · Passed · registered 2016'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('record-phone_call')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-phone_call')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelled / deactivated'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('registered-year')), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Record result'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.checks.last, ('phone_call', 'cancelled', null));
  });

  testWidgets('re-check list opens the subject', (tester) async {
    await _wide(tester);
    final repo = FakeMarketLinkAdmin();
    await tester.pumpWidget(
      _page(RecheckListPage(repo: repo, openUrl: (_) async {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('last checked 2025-11-01'), findsOneWidget);
    await tester.tap(find.text('Ramesh Traders'));
    await tester.pumpAndSettle();
    expect(find.text('Checks'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _page(
        RecheckListPage(
          key: const ValueKey('empty'),
          repo: FakeMarketLinkAdmin(empty: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All yearly re-checks are done'), findsOneWidget);
  });

  testWidgets('provider values are shown in words', (tester) async {
    await _wide(tester);
    await tester.pumpWidget(
      _page(
        VerificationDetailPage(
          repo: FakeMarketLinkAdmin(),
          type: 'provider',
          id: 'p1',
          openUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weighbridge'), findsOneWidget);
    expect(find.text('Documents appear here once sent'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
  });

  testWidgets('rating tags: edit labels and activate', (tester) async {
    await _wide(tester);
    final repo = FakeMarketLinkAdmin();
    await tester.pumpWidget(_page(RatingTagsPage(repo: repo)));
    await tester.pumpAndSettle();
    expect(find.text('trader_on_date'), findsOneWidget);
    expect(find.text('trader_paid'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tag-trader_on_date_no')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tag-mr')),
      ' उशिरा आले (बदल) ',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Active'),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('tag-en')), '');
    await tester.pump();
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('tag-en')), 'Came late');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    final (id, body) = repo.saved.single;
    expect(id, 'trader_on_date_no');
    expect(body.labelMr, 'उशिरा आले (बदल)');
    expect(body.labelEn, 'Came late');
    expect(body.status, RatingTagInStatus.active);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets(
    'lot form settings: a block per crop, defaults in grey, rupees as paise (Q138)',
    (tester) async {
      await _wide(tester);
      final repo = FakeMarketLinkAdmin();
      await tester.pumpWidget(_page(LotSettingsPage(repo: repo)));
      await tester.pumpAndSettle();
      TextField field(String f) =>
          tester.widget<TextField>(find.byKey(Key('admin-lot-$f')));
      // A santra block and a mosambi block, the defaults in grey.
      expect(find.text('Santra (orange)'), findsOneWidget);
      expect(find.text('Mosambi (sweet lime)'), findsOneWidget);
      expect(field('santra-per_quintal-min').decoration!.hintText, '2500');
      expect(field('mosambi-per_crate-max').decoration!.hintText, '1200');
      expect(field('harvest_window_days').decoration!.hintText, '15');
      expect(field('mosambi-per_quintal-min').controller!.text, isEmpty);
      await tester.enterText(
        find.byKey(const Key('admin-lot-mosambi-per_quintal-min')),
        '3000',
      );
      await tester.enterText(
        find.byKey(const Key('admin-lot-harvest_window_days')),
        '20',
      );
      await tester.tap(find.byKey(const Key('admin-lot-save')));
      await tester.pumpAndSettle();
      final body = repo.lotSaves.single;
      AdminRangeIn sent(String crop, String basis) => body.rateRanges!
          .singleWhere((r) => r.crop.value == crop && r.basis.value == basis);
      expect(body.rateRanges, hasLength(4));
      expect(sent('mosambi', 'per_quintal').minPaise, 300000);
      expect(sent('santra', 'per_quintal').minPaise, isNull); // empty = default
      expect(sent('mosambi', 'per_quintal').maxPaise, isNull);
      expect(body.harvestWindowDays, 20);
      expect(find.text('Done'), findsOneWidget);
      expect(field('mosambi-per_quintal-min').controller!.text, '3000');
      expect(rupeesToPaise(' 12 '), 1200);
      expect(rupeesToPaise(''), isNull);
    },
  );

  group('ApiMarketLinkAdminRepository', () {
    late List<http.Request> sent;
    ApiMarketLinkAdminRepository repo(int status, Object body) {
      sent = [];
      return ApiMarketLinkAdminRepository(
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
    }

    test('queue filter and decision body', () async {
      var r = repo(200, {
        'subjects': [_buyer],
      });
      final queue = await r.queue(type: 'buyer');
      expect(queue.single.name, 'Ramesh Traders');
      expect(sent.single.url.path, '/v1/admin/market-link/verifications');
      expect(sent.single.url.queryParameters, {'subject_type': 'buyer'});

      r = repo(200, {
        'subject': _buyer,
        'history': [_row('rejected', reason: 'x', by: 'a')],
      });
      await r.decide('buyer', 'b1', approve: false, reason: 'x');
      expect(sent.single.method, 'POST');
      expect(
        sent.single.url.path,
        '/v1/admin/market-link/verifications/buyer/b1/decision',
      );
      expect(jsonDecode(sent.single.body), {
        'status': 'rejected',
        'reason': 'x',
      });
      await r.subject('provider', 'p1');
      expect(
        sent.last.url.path,
        '/v1/admin/market-link/verifications/provider/p1',
      );
    });

    test('record a check and the re-check list', () async {
      var r = repo(200, {
        'subject': _buyer,
        'history': <Object>[],
        'checks': [_checkRow('gstin', 'passed', year: 2016)],
        'links': _links,
      });
      final d = await r.recordCheck(
        'buyer',
        'b1',
        kind: 'phone_call',
        result: 'passed',
      );
      expect(d.checks!.single.registeredYear, 2016);
      expect(
        sent.single.url.path,
        '/v1/admin/market-link/verifications/buyer/b1/checks',
      );
      expect(jsonDecode(sent.single.body), {
        'kind': 'phone_call',
        'result': 'passed',
      });
      r = repo(200, {'items': <Object>[]});
      expect(await r.rechecks(), isEmpty);
      expect(sent.single.url.path, '/v1/admin/market-link/rechecks');
    });

    test('document url, tags and errors', () async {
      var r = repo(200, {
        'url': 'https://s/x',
        'photo_key': 'k',
        'expires_in': 300,
      });
      expect(await r.documentUrl('broker', 'k1', 2), 'https://s/x');
      expect(
        sent.single.url.path,
        '/v1/admin/market-link/verifications/broker/k1/documents/2/url',
      );
      r = repo(200, {
        'tags': [_tags().first.toJson()],
      });
      expect((await r.ratingTags()).single.key, 'trader_on_date_yes');
      r = repo(200, lotSettingsOut(const AdminLotSettingsIn()).toJson());
      expect((await r.lotSettings()).harvestWindowDaysDefault, 15);
      expect(sent.single.url.path, '/v1/admin/market-link/lot-settings');
      await r.saveLotSettings(const AdminLotSettingsIn(harvestWindowDays: 9));
      expect(sent.last.method, 'PUT');
      expect(jsonDecode(sent.last.body), {'harvest_window_days': 9});
      r = repo(200, _tags().first.toJson());
      await r.saveRatingTag(
        'trader_on_date_yes',
        const RatingTagIn(
          labelEn: 'a',
          labelMr: 'b',
          labelHi: 'c',
          status: RatingTagInStatus.retired,
        ),
      );
      expect(sent.single.method, 'PUT');
      expect(
        (jsonDecode(sent.single.body) as Map<String, dynamic>)['status'],
        'retired',
      );
      r = repo(403, {
        'error': {
          'code': 'forbidden',
          'message': 'requires role market_link_admin',
        },
      });
      await expectLater(
        r.ratingTags(),
        throwsA(
          isA<KbAdminException>().having(
            (e) => e.message,
            'message',
            'requires role market_link_admin',
          ),
        ),
      );
    });
  });
}
