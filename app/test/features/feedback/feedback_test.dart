import 'dart:io';
import 'dart:typed_data';

import 'package:bagmitra/app/router.dart';
import 'package:bagmitra/features/feedback/data/feedback_outbox.dart';
import 'package:bagmitra/features/feedback/data/feedback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';

class FakeFeedbackServer implements FeedbackServer {
  bool online = true;
  final sent = <String>[];
  final screenshots = <String>[];
  final shotBytes = <List<int>>[];

  /// Texts the server answers with this result instead of storing them.
  final answers = <String, SendResult>{};

  @override
  Future<SendResult> send(FeedbackDraft d) async {
    if (!online) return SendResult.retryLater;
    if (answers[d.text] case final answer?) return answer;
    sent.add('${d.kind.name}:${d.text}');
    return SendResult.sent;
  }

  /// What the screenshot upload answers (audit L4).
  SendResult shotAnswer = SendResult.sent;

  @override
  Future<SendResult> sendScreenshot(String id, List<int> jpeg) async {
    if (!online) return SendResult.retryLater;
    if (shotAnswer == SendResult.sent) {
      screenshots.add(id);
      shotBytes.add(jpeg);
    }
    return shotAnswer;
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
    'a refused message is removed and the next one still goes (audit M2)',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final server = FakeFeedbackServer()..online = false;
      var n = 0;
      final box = FeedbackOutbox(db, server, newId: () => 'id-${n++}');
      for (final text in ['bad', 'later', 'good']) {
        await box.add(
          kind: FeedbackKind.problem,
          text: text,
          appVersion: 'v',
          device: 'd',
        );
      }
      server
        ..online = true
        ..answers['bad'] = SendResult.refused;
      expect(await box.flush(), isTrue);
      expect(server.sent, ['problem:later', 'problem:good']);
      expect(await box.pending(), isEmpty);
    },
  );

  test('a 5xx keeps the message and the ones after it', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeFeedbackServer()
      ..answers['busy'] = SendResult.retryLater;
    var n = 0;
    final box = FeedbackOutbox(db, server, newId: () => 'id-${n++}');
    for (final text in ['busy', 'next']) {
      await box.add(
        kind: FeedbackKind.problem,
        text: text,
        appVersion: 'v',
        device: 'd',
      );
    }
    expect((await box.pending()).map((d) => d.text), ['busy', 'next']);
    expect(server.sent, isEmpty);
    server.answers.clear();
    expect(await box.flush(), isTrue);
    expect(server.sent, ['problem:busy', 'problem:next']);
  });

  test('server answers map to sent / retry later / refused', () {
    for (final (status, result) in [
      (201, SendResult.sent),
      (200, SendResult.sent),
      (400, SendResult.refused),
      (401, SendResult.refused),
      (403, SendResult.refused),
      (422, SendResult.refused),
      (408, SendResult.retryLater),
      (429, SendResult.retryLater),
      (500, SendResult.retryLater),
      (503, SendResult.retryLater),
    ]) {
      expect(sendResultOf(status), result, reason: '$status');
    }
  });

  test('a screenshot that could not go stays queued; its text is not sent twice and '
      'does not hold back the next message (audit L4)', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeFeedbackServer()..shotAnswer = SendResult.retryLater;
    final dir = await Directory.systemTemp.createTemp('fb');
    addTearDown(() => dir.delete(recursive: true));
    final shot = File('${dir.path}/s.jpg')
      ..writeAsBytesSync([0xff, 0xd8, 0xff]);
    var n = 0;
    final box = FeedbackOutbox(db, server, newId: () => 'id-${n++}');
    expect(
      await box.add(
        kind: FeedbackKind.problem,
        text: 'with shot',
        appVersion: 'v',
        device: 'd',
        screenshotPath: shot.path,
      ),
      isFalse,
    );
    await box.add(
      kind: FeedbackKind.question,
      text: 'next',
      appVersion: 'v',
      device: 'd',
    );
    expect(server.sent, ['problem:with shot', 'question:next']);
    expect((await box.pending()).map((d) => d.id), ['id-0']);
    server.shotAnswer = SendResult.sent;
    expect(await box.flush(), isTrue);
    expect(server.screenshots, ['id-0']);
    expect(server.sent, ['problem:with shot', 'question:next']); // text once
    expect(await box.pending(), isEmpty);
  });

  test('a refused screenshot is dropped; the message stays sent', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeFeedbackServer()..shotAnswer = SendResult.refused;
    final dir = await Directory.systemTemp.createTemp('fb');
    addTearDown(() => dir.delete(recursive: true));
    final shot = File('${dir.path}/s.png')..writeAsBytesSync([0x89, 0x50]);
    final box = FeedbackOutbox(db, server, newId: () => 'id-0');
    expect(
      await box.add(
        kind: FeedbackKind.problem,
        text: 'a',
        appVersion: 'v',
        device: 'd',
        screenshotPath: shot.path,
      ),
      isTrue,
    );
    expect(server.sent, ['problem:a']);
    expect(await box.pending(), isEmpty);
  });

  test('a PNG screenshot goes as JPEG, transparency on white (Q124)', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeFeedbackServer();
    final dir = await Directory.systemTemp.createTemp('fb');
    addTearDown(() => dir.delete(recursive: true));
    final png = img.Image(width: 4, height: 4, numChannels: 4)
      ..clear(img.ColorRgba8(0, 0, 0, 0));
    final shot = File('${dir.path}/s.png')
      ..writeAsBytesSync(img.encodePng(png));
    final box = FeedbackOutbox(db, server, newId: () => 'id-0');
    await box.add(
      kind: FeedbackKind.problem,
      text: 'a',
      appVersion: 'v',
      device: 'd',
      screenshotPath: shot.path,
    );
    final sent = server.shotBytes.single;
    expect(sent.take(2), [0xff, 0xd8]);
    final back = img.decodeJpg(Uint8List.fromList(sent))!;
    expect(back.getPixel(1, 1).r, greaterThan(240)); // white, not black
  });

  test('a JPEG screenshot goes unchanged', () async {
    expect(await toJpeg([0xff, 0xd8, 0xff, 1, 2]), [0xff, 0xd8, 0xff, 1, 2]);
  });

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
