import 'dart:convert';

import 'dart:typed_data';

import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/document_picker.dart';
import 'package:bagmitra/admin/feed_admin_repository.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'admin_sign_in_test.dart' show FakeAdminAuth;
import 'kb_admin_test.dart' show FakeKbAdmin;

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _issues = [
  {
    'kind': 'number_not_in_source',
    'text': '₹6,000 is not in the source text',
    'where': 'texts.en.summary',
  },
  {
    'kind': 'date_not_in_source',
    'text': '2026-12-31 is not in the source text',
    'where': 'deadline',
  },
];

const _summary1 = {
  'id': 'i1',
  'type': 'scheme',
  'status': 'in_review',
  'trust': 'official',
  'title': 'PM-KISAN instalment',
  'gr_number': 'GR-2026/101',
  'department': 'Agriculture',
  'published_at': '2026-10-20T00:00:00Z',
  'check_issues': _issues,
  'approved': false,
};

const _summary2 = {
  'id': 'i2',
  'type': 'gr',
  'status': 'published',
  'trust': 'official',
  'title': 'Drip subsidy GR',
  'gr_number': 'GR-2026/102',
  'department': 'Agriculture',
  'published_at': '2026-10-22T00:00:00Z',
  'check_issues': <Object>[],
  'approved': true,
};

Map<String, dynamic> _detail(Map<String, dynamic> summary) => {
  ...summary,
  'source_key': 'mh_gr_portal',
  'external_id': '202610201234',
  'url': 'https://gr.maharashtra.gov.in/gr-101.pdf',
  'raw_hash': 'ab12',
  'raw_bytes': 1024,
  'has_text': false,
  'valid_from': '2026-10-20',
  'valid_to': '2027-03-31',
  'deadline': '2026-12-31',
  'payment_date': null,
  'replaced_by_id': null,
  'texts': {
    'en': {
      'title': summary['title'],
      'summary': 'Up to ₹6,000 a year in three instalments.',
    },
  },
  'card': {
    'version': 1,
    'fields': {
      'amount': {'value': '₹6,000 per year', 'page': 'p. 2'},
    },
  },
  'targets': [
    {'district': 'Nagpur', 'crop': 'santra', 'min_ha': null, 'max_ha': 2.0},
  ],
  'events': [
    {
      'kind': 'extracted',
      'actor_id': null,
      'detail': {
        'method': 'pdf_text',
        'quality': 'broken',
        'used': null,
        'pages': 3,
        'text_layer': 'ÉÉ´ÉÉ Kruti Dev text',
      },
      'created_at': '2026-10-20T00:00:00Z',
    },
  ],
};

class FakeFeedAdmin implements FeedAdminRepository {
  final approvals = <(String, bool, String?)>[];
  final published = <String>[];
  final withdrawn = <(String, String, String?)>[];
  final texts = <(String, String, String, String?)>[];
  final terms = <(String, String, String?)>[];
  final targetSaves = <List<FeedAdminTargetIn>>[];
  FeedAdminItemIn? created;

  static FeedAdminItemOut _item(String id) =>
      FeedAdminItemOut.fromJson(_detail(id == 'i1' ? _summary1 : _summary2));

  @override
  Future<List<FeedAdminItemSummaryOut>> items({
    String status = 'in_review',
  }) async => [
    for (final s in [_summary1, _summary2])
      if (s['status'] == status) FeedAdminItemSummaryOut.fromJson(s),
  ];

  @override
  Future<FeedAdminItemOut> item(String id) async => _item(id);

  @override
  Future<FeedAdminItemOut> create(FeedAdminItemIn body) async {
    created = body;
    return _item('i1');
  }

  @override
  Future<FeedAdminItemOut> setText(
    String id,
    String lang,
    String title,
    String? summary,
  ) async {
    texts.add((id, lang, title, summary));
    return _item(id);
  }

  @override
  Future<FeedAdminItemOut> setTargets(
    String id,
    List<FeedAdminTargetIn> targets,
  ) async {
    targetSaves.add(targets);
    return _item(id);
  }

  @override
  Future<FeedAdminItemOut> approve(
    String id, {
    bool acceptCheckIssues = false,
    String? comment,
  }) async {
    approvals.add((id, acceptCheckIssues, comment));
    return FeedAdminItemOut.fromJson({..._detail(_summary1), 'approved': true});
  }

  @override
  Future<FeedAdminItemOut> publish(String id) async {
    published.add(id);
    throw const FeedAdminException(
      'publish refused: no approval after the last change',
      status: 409,
      code: 'publish_refused',
    );
  }

  @override
  Future<FeedAdminItemOut> withdraw(
    String id,
    String reason,
    String? replacedById,
  ) async {
    withdrawn.add((id, reason, replacedById));
    return FeedAdminItemOut.fromJson({
      ..._detail(_summary1),
      'status': 'withdrawn',
      'replaced_by_id': replacedById,
    });
  }

  @override
  Future<FeedAdminItemOut> aiDraft(String id) async =>
      throw const FeedAdminException(
        'the AI summariser is off (FEED_AI_API_KEY not set)',
        status: 503,
        code: 'ai_off',
      );

  @override
  Future<List<FeedAdminSourceOut>> sources() async => [
    FeedAdminSourceOut.fromJson(const {
      'id': 's1',
      'key': 'mh_gr_portal',
      'name': 'Maharashtra GR portal',
      'url': 'https://gr.maharashtra.gov.in',
      'tier': 'official',
      'terms_status': 'unknown',
      'fetch_method': 'listing',
      'fetch_status': 'never',
      'last_ok_at': null,
      'last_error': null,
      'notes': null,
    }),
  ];

  @override
  Future<FeedAdminSourceOut> setTerms(
    String key,
    String status,
    String? notes,
  ) async {
    terms.add((key, status, notes));
    final s = (await sources()).single;
    return FeedAdminSourceOut.fromJson({
      ...s.toJson(),
      'terms_status': status,
      'notes': notes,
    });
  }
}

ApiFeedAdminRepository _repo(MockClientHandler handler) =>
    ApiFeedAdminRepository(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient(handler),
      ),
    );

/// Returns the queued picks in order: a [PickedDocument], null (cancelled) or an exception.
class FakeDocuments implements DocumentPicker {
  FakeDocuments(this.picks);
  final List<Object?> picks;

  @override
  Future<PickedDocument?> pick() async => switch (picks.removeAt(0)) {
    final PickedDocument d => d,
    final Exception e => throw e,
    _ => null,
  };
}

Future<FakeFeedAdmin> _pump(
  WidgetTester tester, {
  Set<String> roles = const {'feed_admin'},
  DocumentPicker? documents,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final feed = FakeFeedAdmin();
  await tester.pumpWidget(
    AdminApp(
      productName: 'BagMitra',
      kb: FakeKbAdmin(),
      feed: feed,
      documents: documents,
      auth: FakeAdminAuth(signedIn: true, roles: roles),
    ),
  );
  await tester.pumpAndSettle();
  return feed;
}

Future<FakeFeedAdmin> _openDetail(WidgetTester tester) async {
  final feed = await _pump(tester);
  await tester.tap(find.text('Govt feed'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('PM-KISAN instalment'));
  await tester.pumpAndSettle();
  return feed;
}

void main() {
  test('API repository sends the review calls and surfaces reasons', () async {
    final sent = <String, Object?>{};
    final repo = _repo((req) async {
      expect(req.headers['Authorization'], 'Bearer tok');
      final path = req.url.path;
      sent['${req.method} $path'] = req.body.isEmpty
          ? req.url.query
          : jsonDecode(req.body);
      return switch (path) {
        '/v1/admin/feed/items' when req.method == 'GET' => _json({
          'items': [_summary1],
        }),
        '/v1/admin/feed/items' => _json(_detail(_summary1), 201),
        '/v1/admin/feed/items/i1/ai-draft' => _json({
          'error': {
            'code': 'ai_off',
            'message': 'the AI summariser is off',
            'request_id': 'r',
          },
        }, 503),
        '/v1/admin/feed/items/i1/approve' => _json({
          'error': {
            'code': 'approve_refused',
            'message': 'output-check issues are open',
            'request_id': 'r',
          },
        }, 409),
        '/v1/admin/feed/sources' => _json({'sources': <Object>[]}),
        '/v1/admin/feed/sources/mh_gr_portal/terms' => _json({
          ...(await FakeFeedAdmin().sources()).single.toJson(),
          'terms_status': 'allowed',
        }),
        _ when path.startsWith('/v1/admin/feed/items/i1') => _json(
          _detail(_summary1),
        ),
        _ => _json({}, 404),
      };
    });

    final items = await repo.items(status: 'published');
    expect(items.single.checkIssues, hasLength(2));
    expect(sent['GET /v1/admin/feed/items'], 'status=published');
    final item = await repo.item('i1');
    expect(item.texts['en'], isA<Map<String, dynamic>>());
    expect(item.targets.single.maxHa, 2.0);
    expect(item.deadline, DateTime(2026, 12, 31));

    await expectLater(
      repo.approve('i1', acceptCheckIssues: true, comment: 'checked p. 2'),
      throwsA(
        isA<FeedAdminException>()
            .having((e) => e.code, 'code', 'approve_refused')
            .having((e) => e.message, 'message', contains('issues are open')),
      ),
    );
    expect(sent['POST /v1/admin/feed/items/i1/approve'], {
      'accept_check_issues': true,
      'comment': 'checked p. 2',
    });
    await expectLater(
      repo.aiDraft('i1'),
      throwsA(
        isA<FeedAdminException>().having((e) => e.aiUnavailable, 'ai', true),
      ),
    );

    await repo.setText('i1', 'mr', 'पीएम-किसान', null);
    expect(sent['PUT /v1/admin/feed/items/i1/texts/mr'], {
      'title': 'पीएम-किसान',
    });
    await repo.setTargets('i1', const [FeedAdminTargetIn(district: 'Nagpur')]);
    expect(sent['PUT /v1/admin/feed/items/i1/targets'], {
      'targets': [
        {'district': 'Nagpur'},
      ],
    });
    await repo.publish('i1');
    await repo.withdraw('i1', 'superseded', 'i2');
    expect(sent['POST /v1/admin/feed/items/i1/withdraw'], {
      'reason': 'superseded',
      'replaced_by_id': 'i2',
    });
    await repo.create(
      FeedAdminItemIn(
        sourceKey: 'mh_gr_portal',
        type: FeedAdminItemInType.scheme,
        url: 'https://gr.maharashtra.gov.in/x.pdf',
        publishedAt: DateTime.utc(2026, 10, 26),
        deadline: DateTime(2026, 12, 31),
        extractedText: 'text',
      ),
    );
    expect(
      sent['POST /v1/admin/feed/items'],
      containsPair('deadline', '2026-12-31'),
    );
    expect(sent['POST /v1/admin/feed/items'], containsPair('type', 'scheme'));
    expect(await repo.sources(), isEmpty);
    final source = await repo.setTerms('mh_gr_portal', 'allowed', 'ToS read');
    expect(source.termsStatus, 'allowed');
    expect(sent['PUT /v1/admin/feed/sources/mh_gr_portal/terms'], {
      'terms_status': 'allowed',
      'notes': 'ToS read',
    });
  });

  testWidgets('feed section only for role feed_admin', (tester) async {
    await _pump(tester, roles: {'kb_admin'});
    expect(find.text('Knowledge cards'), findsWidgets);
    expect(find.text('Govt feed'), findsNothing);

    await _pump(tester);
    expect(find.text('Govt feed'), findsOneWidget);
  });

  testWidgets('queue lists by status with badges and issue counts', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Govt feed'));
    await tester.pumpAndSettle();
    expect(find.text('PM-KISAN instalment'), findsOneWidget);
    expect(find.text('scheme'), findsOneWidget);
    expect(find.text('official'), findsOneWidget);
    expect(find.text('2 check issues'), findsOneWidget);
    expect(find.text('Drip subsidy GR'), findsNothing);

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();
    expect(find.text('Drip subsidy GR'), findsOneWidget);
    expect(find.text('0 check issues'), findsOneWidget);
    await tester.tap(find.text('Withdrawn'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing in this list'), findsOneWidget);
  });

  testWidgets('approve with open issues needs accept + comment', (
    tester,
  ) async {
    final feed = await _openDetail(tester);
    expect(find.textContaining('gr-101.pdf'), findsOneWidget);
    expect(find.text('₹6,000 is not in the source text'), findsOneWidget);
    expect(find.textContaining('Kruti Dev'), findsOneWidget);
    expect(find.textContaining('No usable text'), findsOneWidget);
    expect(find.textContaining('Last date: 2026-12-31'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Accept open check issues?'), findsOneWidget);
    final accept = find.widgetWithText(FilledButton, 'Accept and approve');
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(feed.approvals, isEmpty);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('accept-comment')),
      'amount on p. 2',
    );
    await tester.pumpAndSettle();
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(feed.approvals, [('i1', true, 'amount on p. 2')]);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('publish refusal, AI off and text / target saves', (
    tester,
  ) async {
    final feed = await _openDetail(tester);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(feed.published, ['i1']);
    expect(find.textContaining('no approval after'), findsOneWidget);

    await tester.tap(find.text('AI draft'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('AI not configured'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('title-mr')),
      'पीएम-किसान हप्ता',
    );
    await tester.enterText(
      find.byKey(const Key('summary-mr')),
      'वर्षाला ₹6,000',
    );
    await tester.ensureVisible(find.byKey(const Key('save-mr')));
    await tester.tap(find.byKey(const Key('save-mr')));
    await tester.pumpAndSettle();
    expect(feed.texts, [('i1', 'mr', 'पीएम-किसान हप्ता', 'वर्षाला ₹6,000')]);

    await tester.ensureVisible(find.text('Save targets'));
    await tester.enterText(find.byKey(const Key('target-0-min')), '1');
    await tester.tap(find.text('Save targets'));
    await tester.pumpAndSettle();
    final saved = feed.targetSaves.single.single;
    expect(
      (saved.district, saved.crop, saved.minHa, saved.maxHa),
      ('Nagpur', 'santra', 1.0, 2.0),
    );
    await tester.enterText(find.byKey(const Key('target-0-max')), 'two');
    await tester.tap(find.text('Save targets'));
    await tester.pumpAndSettle();
    expect(find.text('Hectares must be numbers.'), findsOneWidget);
    expect(feed.targetSaves, hasLength(1));
  });

  testWidgets('withdraw picks a replacement item', (tester) async {
    final feed = await _openDetail(tester);
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('withdraw-reason')),
      'superseded by GR-102',
    );
    await tester.tap(find.byKey(const Key('withdraw-replacement')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drip subsidy GR · Published').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
    await tester.pumpAndSettle();
    expect(feed.withdrawn, [('i1', 'superseded by GR-102', 'i2')]);
    expect(find.text('Replaced by i2'), findsOneWidget);
  });

  testWidgets('sources: set terms with a note', (tester) async {
    final feed = await _pump(tester);
    await tester.tap(find.text('Govt feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feed sources'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Terms: unknown'), findsOneWidget);
    await tester.tap(find.text('Allowed'));
    await tester.enterText(
      find.byKey(const Key('terms-note-mh_gr_portal')),
      'ToS read: listing + link allowed',
    );
    await tester.tap(find.byKey(const Key('terms-save-mh_gr_portal')));
    await tester.pumpAndSettle();
    expect(feed.terms, [
      ('mh_gr_portal', 'allowed', 'ToS read: listing + link allowed'),
    ]);
    expect(find.textContaining('Terms: allowed'), findsOneWidget);
  });

  testWidgets('upload validates and sends pasted text + metadata', (
    tester,
  ) async {
    final feed = await _pump(tester);
    await tester.tap(find.text('Govt feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send to review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to review'));
    await tester.pumpAndSettle();
    expect(find.textContaining('are required'), findsOneWidget);

    Future<void> type(String key, String text) =>
        tester.enterText(find.byKey(Key('upload-$key')), text);
    await tester.ensureVisible(find.text('scheme'));
    await tester.tap(find.text('scheme'));
    await type('source', 'mh_gr_portal');
    await type('published', '2026-10-26');
    await type('url', 'https://gr.maharashtra.gov.in/x.pdf');
    await type('deadline', '31-12-2026');
    await tester.ensureVisible(find.text('Send to review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to review'));
    await tester.pumpAndSettle();
    expect(find.textContaining('YYYY-MM-DD.'), findsOneWidget);

    await type('deadline', '2026-12-31');
    await type('title', 'PM-KISAN instalment');
    await type('text', 'GR text copied from the PDF');
    await tester.ensureVisible(find.text('Send to review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to review'));
    await tester.pumpAndSettle();
    final body = feed.created!;
    expect(body.type, FeedAdminItemInType.scheme);
    expect(body.publishedAt, DateTime.utc(2026, 10, 26));
    expect(body.deadline, DateTime(2026, 12, 31));
    expect(body.texts, {
      'en': {'title': 'PM-KISAN instalment'},
    });
    expect(body.extractedText, 'GR text copied from the PDF');
    expect(body.documentBase64, isNull);
    expect(find.text('Created: In review, 2 check issues'), findsOneWidget);
    await tester.ensureVisible(find.text('Open item'));
    await tester.tap(find.text('Open item'));
    await tester.pumpAndSettle();
    expect(find.text('Output-check issues'), findsOneWidget);
  });

  test('picked document type follows the extension', () {
    expect(PickedDocument('GR.PDF', Uint8List(1)).type, 'pdf');
    expect(PickedDocument('gr.htm', Uint8List(1)).type, 'html');
    expect(maxDocumentBytes, 20 * 1024 * 1024);
  });

  testWidgets('upload sends a picked document as base64 and shows extraction', (
    tester,
  ) async {
    final pdf = Uint8List.fromList(utf8.encode('%PDF-1.7 GR'));
    final feed = await _pump(
      tester,
      documents: FakeDocuments([
        const DocumentTooLarge(),
        const DocumentTypeNotAllowed(),
        null,
        PickedDocument('gr-101.pdf', pdf),
      ]),
    );
    await tester.tap(find.text('Govt feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    expect(find.text('No document chosen'), findsOneWidget);

    Future<void> pick() async {
      await tester.ensureVisible(find.byKey(const Key('upload-pick')));
      await tester.tap(find.byKey(const Key('upload-pick')));
      await tester.pumpAndSettle();
    }

    await pick();
    expect(find.text('The document is larger than 20 MB.'), findsOneWidget);
    await pick();
    expect(find.text('Only .pdf, .html or .htm files.'), findsOneWidget);
    await pick();
    expect(find.text('No document chosen'), findsOneWidget);
    await pick();
    expect(find.text('gr-101.pdf · 1 KB'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('upload-source')),
      'mh_gr_portal',
    );
    await tester.enterText(
      find.byKey(const Key('upload-published')),
      '2026-10-26',
    );
    await tester.enterText(
      find.byKey(const Key('upload-url')),
      'https://gr.maharashtra.gov.in/gr-101.pdf',
    );
    await tester.ensureVisible(find.text('Send to review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to review'));
    await tester.pumpAndSettle();
    final body = feed.created!;
    expect(body.documentBase64, base64Encode(pdf));
    expect(body.documentType, 'pdf');
    expect(body.extractedText, isNull);
    expect(find.text('Extraction result'), findsOneWidget);
    expect(find.textContaining('quality: broken'), findsOneWidget);
    expect(find.textContaining('number_not_in_source: ₹6,000'), findsOneWidget);
  });
}
