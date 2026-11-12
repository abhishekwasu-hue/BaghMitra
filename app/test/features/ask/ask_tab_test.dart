// The विचारा tab's question box (owner 2026-11-12, Q144): the stored answer comes at once,
// with the server unreachable (offline) and with a server that answers (online) alike; voice
// input fills the question; sources show as text; related questions open their answer; the
// card opens; an unrelated question points to the guide and the KVK.
import 'package:bagmitra/features/voice/domain/speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;

const note = 'ही माहिती ॲपमध्ये साठवलेल्या तपासलेल्या स्रोतांवरून आहे.';
const symptoms = Key('ask-answer-seed-psylla-symptoms');

Future<void> ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byKey(const Key('ask-field')), question);
  await tester.tap(find.byKey(const Key('ask-go')));
  await settle(tester);
}

void main() {
  testWidgets('offline: the stored answer, its note and sources as text', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/ask');
    await settle(tester);
    expect(find.text('प्रश्न विचारा'), findsOneWidget);
    // The guide stays below the box.
    expect(find.byKey(const Key('practices-psylla')), findsOneWidget);
    await ask(tester, 'सायलाची लक्षणे काय?');
    expect(find.byKey(symptoms), findsOneWidget);
    expect(find.text(note), findsOneWidget);
    expect(find.text('संबंधित प्रश्न'), findsOneWidget);
    final toggle = find.descendant(
      of: find.byKey(const Key('ask-sources')),
      matching: find.byKey(const Key('sources-toggle')),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await settle(tester);
    expect(
      find.text('https://www.nhb.gov.in/pdf/fruits/citrus/cit008.pdf'),
      findsOneWidget,
    );
    // A related question opens its own answer.
    final related = find.byKey(const Key('ask-related-seed-psylla-scouting'));
    await tester.ensureVisible(related);
    await tester.tap(related);
    await settle(tester);
    expect(
      find.byKey(const Key('ask-answer-seed-psylla-scouting')),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('online: the same stored answer at once', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/ask',
      apiHttp: MockClient((_) async => http.Response('{}', 200)),
    );
    await settle(tester);
    await ask(tester, 'sayla lakshane');
    expect(find.byKey(symptoms), findsOneWidget);
    expect(find.text(note), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a spoken question is answered', (tester) async {
    final recognizer = FakeRecognizer(
      words: const [SpeechResult('सायलाची लक्षणे', isFinal: true)],
    );
    await pumpApp(tester, initialLocation: '/ask', recognizer: recognizer);
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('ask-box')),
        matching: find.byKey(const Key('voice-mic')),
      ),
    );
    await settle(tester);
    expect(recognizer.heardLocale, 'mr_IN');
    expect(find.byKey(symptoms), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the card of the answer opens', (tester) async {
    await pumpApp(tester, initialLocation: '/ask');
    await settle(tester);
    await ask(tester, 'सायलाची लक्षणे काय?');
    await tester.ensureVisible(find.byKey(const Key('ask-open-card')));
    await tester.tap(find.byKey(const Key('ask-open-card')));
    await settle(tester);
    expect(find.byKey(const Key('practices-see-psylla')), findsOneWidget);
    expect(find.byKey(const Key('ask-box')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('an unrelated question points to the guide and the KVK', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/ask');
    await settle(tester);
    await ask(tester, 'ट्रॅक्टर कर्ज');
    expect(find.byKey(const Key('ask-no-match')), findsOneWidget);
    expect(find.text(note), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the guide opened from a page has no question box', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/practices');
    await settle(tester);
    expect(find.byKey(const Key('ask-box')), findsNothing);
    await unmountApp(tester);
  });
}
