import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/feedback_admin.dart';
import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_sign_in_test.dart' show FakeAdminAuth;
import 'kb_admin_test.dart' show FakeKbAdmin;

FeedbackOut _item(String id, String kind, String status, {String? shot}) =>
    FeedbackOut.fromJson({
      'id': id,
      'kind': kind,
      'text': 'हवामान कार्ड उघडायला वेळ लागतो.',
      'app_version': '0.1.0+12',
      'device': 'Xiaomi Redmi Note 12 · Android 14',
      'status': status,
      'created_at': '2026-11-08T06:00:00Z',
      'screenshot_url': shot,
    });

class FakeFeedbackAdmin implements FeedbackAdminRepository {
  final items = [
    _item('f1', 'problem', 'new', shot: 'https://files.test/u/feedback-f1.jpg'),
    _item('f2', 'suggestion', 'new'),
    _item('f3', 'question', 'done'),
  ];
  final marked = <String>[];

  @override
  Future<List<FeedbackOut>> list({String? status}) async => [
    for (final f in items)
      if (status == null || f.status == status) f,
  ];

  @override
  Future<FeedbackOut> mark(String id, String status) async {
    marked.add('$id $status');
    final i = items.indexWhere((f) => f.id == id);
    items[i] = _item(id, items[i].kind, status);
    return items[i];
  }
}

Future<void> pumpFeedback(WidgetTester tester, FakeFeedbackAdmin fake) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AdminApp(
      productName: 'BagMitra',
      auth: FakeAdminAuth(signedIn: true, roles: {feedbackAdminRole}),
      kb: FakeKbAdmin(),
      feedback: fake,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Feedback'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new feedback first; marking done moves it out of the list', (
    tester,
  ) async {
    final fake = FakeFeedbackAdmin();
    final opened = <Uri>[];
    await pumpFeedback(tester, fake);
    expect(find.byKey(const Key('fb-f1')), findsOneWidget);
    expect(find.byKey(const Key('fb-f3')), findsNothing);
    expect(find.text('Open screenshot'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fb-f1-done')));
    await tester.pumpAndSettle();
    expect(fake.marked, ['f1 done']);
    expect(find.byKey(const Key('fb-f1')), findsNothing);
    await tester.tap(find.byKey(const Key('fb-filter-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fb-f3')), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('hidden without the feedback_admin role', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AdminApp(
        productName: 'BagMitra',
        auth: FakeAdminAuth(signedIn: true, roles: {'kb_admin'}),
        kb: FakeKbAdmin(),
        feedback: FakeFeedbackAdmin(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Feedback'), findsNothing);
  });
}
