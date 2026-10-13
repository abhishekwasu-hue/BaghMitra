import 'dart:convert';

import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/kb_admin_repository.dart';
import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _card = {
  'id': 'c1',
  'topic': 'psylla',
  'crop': 'santra',
  'version': 1,
  'status': 'expert_reviewed',
  'title': 'Citrus psylla',
  'has_chemical_options': true,
  'review_due_at': null,
};

ApiKbAdminRepository _repo(MockClientHandler handler) => ApiKbAdminRepository(
  createApi(
    baseUrl: Uri.parse('https://api.example.test'),
    token: () => 'tok',
    httpClient: MockClient(handler),
  ),
);

class FakeKbAdmin implements KbAdminRepository {
  final published = <String>[];
  final resolved = <String>[];
  String? importedCsv;

  @override
  Future<List<CardOut>> cards({String? status}) async => [
    CardOut.fromJson(_card),
  ];

  @override
  Future<CardOut> publish(String cardId) async {
    published.add(cardId);
    throw const KbAdminException('gate: imidacloprid (no_label_claim)');
  }

  @override
  Future<CardOut> review(
    String cardId,
    ReviewInDecision decision,
    String? comments,
  ) async => CardOut.fromJson({..._card, 'status': 'expert_reviewed'});

  @override
  Future<ImportOut> import(String kind, String sourceKey, String csv) async {
    importedCsv = csv;
    return const ImportOut(
      added: 2,
      changed: 0,
      removed: 1,
      unchanged: 3,
      cardsPulled: 1,
    );
  }

  @override
  Future<List<AlertOut>> alerts() async => resolved.isEmpty
      ? [
          AlertOut(
            id: 'a1',
            kind: 'card_pulled',
            cardId: 'c1',
            detail: 're-gate: imidacloprid (banned)',
            createdAt: DateTime.utc(2026, 10, 13),
          ),
        ]
      : [];

  @override
  Future<void> resolve(String alertId) async => resolved.add(alertId);

  @override
  Future<List<SourceOut>> sources() async => const [
    SourceOut(
      id: 's1',
      key: 'ccri',
      title: 'ICAR-CCRI advisories',
      publisher: 'ICAR-CCRI',
      url: 'https://ccri.icar.gov.in',
      tier: 'tier1',
      allowedUse: 'summarise_cite',
      verification: 'V',
    ),
  ];
}

Future<FakeKbAdmin> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final kb = FakeKbAdmin();
  await tester.pumpWidget(AdminApp(productName: 'BagMitra', kb: kb));
  await tester.pumpAndSettle();
  return kb;
}

void main() {
  test('API repository maps lists and surfaces refusal reasons', () async {
    final repo = _repo((req) async {
      expect(req.headers['Authorization'], 'Bearer tok');
      return switch (req.url.path) {
        '/v1/admin/kb/cards' => _json({
          'cards': [_card],
        }),
        '/v1/admin/kb/cards/c1/publish' => _json({
          'error': {
            'code': 'publish_refused',
            'message': 'no_valid_review',
            'request_id': 'r',
          },
        }, 409),
        '/v1/admin/kb/imports/claims' => _json({
          'added': 1,
          'changed': 0,
          'removed': 0,
          'unchanged': 0,
          'cards_pulled': 0,
        }),
        '/v1/admin/kb/alerts/a1/resolve' => _json({
          'id': 'a1',
          'kind': 'card_pulled',
          'card_id': null,
          'detail': 'x',
          'created_at': '2026-10-13T00:00:00Z',
        }),
        _ => _json({}, 404),
      };
    });
    expect((await repo.cards()).single.title, 'Citrus psylla');
    await expectLater(
      repo.publish('c1'),
      throwsA(
        isA<KbAdminException>().having(
          (e) => e.message,
          'message',
          'no_valid_review',
        ),
      ),
    );
    expect((await repo.import('claims', 'cibrc', 'a,b')).added, 1);
    await repo.resolve('a1');
  });

  testWidgets('cards page shows why publishing was refused', (tester) async {
    final kb = await _pump(tester);
    expect(find.text('Citrus psylla'), findsOneWidget);
    expect(find.text('Chemical'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(kb.published, ['c1']);
    expect(find.textContaining('no_label_claim'), findsOneWidget);
  });

  testWidgets('import page shows the diff', (tester) async {
    final kb = await _pump(tester);
    await tester.tap(find.text('Imports'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('import-source')), 'cibrc');
    await tester.enterText(find.byKey(const Key('import-csv')), 'a,b\n1,2');
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(kb.importedCsv, 'a,b\n1,2');
    expect(find.textContaining('Added 2'), findsOneWidget);
    expect(find.textContaining('Cards pulled 1'), findsOneWidget);
  });

  testWidgets('alerts can be resolved; sources list licence', (tester) async {
    final kb = await _pump(tester);
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('banned'), findsOneWidget);
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();
    expect(kb.resolved, ['a1']);
    expect(find.textContaining('banned'), findsNothing);
    await tester.tap(find.text('Sources'));
    await tester.pumpAndSettle();
    expect(find.textContaining('summarise_cite'), findsOneWidget);
  });

  testWidgets('without a signed-in admin the KB pages say so', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const AdminApp(productName: 'BagMitra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('admin account'), findsOneWidget);
  });
}
