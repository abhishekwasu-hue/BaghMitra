import 'dart:io';

import 'package:bagmitra/app/router.dart';
import 'package:bagmitra/features/feedback/data/feedback_outbox.dart';
import 'package:bagmitra/features/feedback/data/feedback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';

class FakeFeedbackServer implements FeedbackServer {
  bool online = true;
  final sent = <String>[];
  final screenshots = <String>[];

  @override
  Future<bool> send(FeedbackDraft d) async {
    if (!online) return false;
    sent.add('${d.kind.name}:${d.text}');
    return true;
  }

  @override
  Future<bool> sendScreenshot(String id, List<int> jpeg) async {
    screenshots.add(id);
    return true;
  }
}

List<Override> feedbackOverrides(FakeFeedbackServer server) => [
  feedbackServerProvider.overrideWithValue(server),
  deviceNameProvider.overrideWith((ref) async => 'Redmi Note 12 · Android 14'),
  screenshotPickerProvider.overrideWithValue(() async => null),
];

void main() {
  test(
    'offline feedback waits on the phone and goes later, in order',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final server = FakeFeedbackServer()..online = false;
      var n = 0;
      final box = FeedbackOutbox(db, server, newId: () => 'id-${n++}');
      Future<bool> add(String text) => box.add(
        kind: FeedbackKind.problem,
        text: text,
        appVersion: '0.1.0+12',
        device: 'Redmi',
      );
      expect(await add(' one '), isFalse);
      expect(await add('two'), isFalse);
      expect((await box.pending()).map((d) => d.id), ['id-0', 'id-1']);
      server.online = true;
      expect(await box.flush(), isTrue);
      expect(server.sent, ['problem:one', 'problem:two']);
      expect(await box.pending(), isEmpty);
    },
  );

  test(
    'a screenshot goes after its message; a missing file is skipped',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final server = FakeFeedbackServer();
      final dir = await Directory.systemTemp.createTemp('fb');
      addTearDown(() => dir.delete(recursive: true));
      final shot = File('${dir.path}/s.jpg')
        ..writeAsBytesSync([0xff, 0xd8, 0xff]);
      var n = 0;
      final box = FeedbackOutbox(db, server, newId: () => 'id-${n++}');
      await box.add(
        kind: FeedbackKind.suggestion,
        text: 'a',
        appVersion: 'v',
        device: 'd',
        screenshotPath: shot.path,
      );
      await box.add(
        kind: FeedbackKind.question,
        text: 'b',
        appVersion: 'v',
        device: 'd',
        screenshotPath: '${dir.path}/gone.jpg',
      );
      expect(server.screenshots, ['id-0']);
      expect(server.sent, ['suggestion:a', 'question:b']);
    },
  );

  testWidgets('Settings → Send feedback: kind, text, send', (tester) async {
    final server = FakeFeedbackServer();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: Routes.settings,
      overrides: feedbackOverrides(server),
    );
    await tester.tap(find.byKey(const Key('settings-feedback')));
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('feedback-send'));
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.tap(find.byKey(const Key('feedback-kind-suggestion')));
    await tester.enterText(
      find.byKey(const Key('feedback-text')),
      'Add a Hindi voice',
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(send);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(server.sent, ['suggestion:Add a Hindi voice']);
    expect(find.text('Received. Thank you!'), findsOneWidget);
    await unmountApp(tester);
  });
}
