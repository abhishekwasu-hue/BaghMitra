import 'package:bagmitra/features/voice/data/cloud_speech.dart';
import 'package:bagmitra/features/voice/domain/speech.dart';
import 'package:bagmitra/features/voice/domain/voice_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('parseVoiceNote', () {
    test('takes the first number as the amount and keeps the rest as text', () {
      final v = parseVoiceNote('diesel for the pump 1,500 rupees');
      expect(v.amountPaise, 150000);
      expect(v.text, 'diesel for the pump rupees');
    });

    test('reads Devanagari digits and decimals', () {
      expect(parseVoiceNote('डिझेल ५००').amountPaise, 50000);
      expect(parseVoiceNote('डिझेल ५००').text, 'डिझेल');
      expect(parseVoiceNote('rope 12.5').amountPaise, 1250);
    });

    test('no number means the whole transcript is the note', () {
      final v = parseVoiceNote('  sprayed the north block ');
      expect(v.amountPaise, isNull);
      expect(v.text, 'sprayed the north block');
    });

    test('amount text drops pointless decimals', () {
      expect(amountFieldText(50000), '500');
      expect(amountFieldText(1250), '12.50');
    });
  });

  test('app languages map to speech locales', () {
    expect(speechLocaleId('mr'), 'mr_IN');
    expect(speechLocaleId('hi'), 'hi_IN');
    expect(speechLocaleId('en'), 'en_IN');
  });

  test('the cloud engine is a stub that is never available', () async {
    expect(await const CloudSpeechRecognizer().isAvailable(), isFalse);
    await expectLater(
      const CloudSpeechRecognizer().listen(localeId: 'mr_IN'),
      emitsError(isA<UnsupportedError>()),
    );
    await expectLater(
      const CloudSpeechSynthesizer().speak('hi', localeId: 'mr_IN'),
      throwsUnsupportedError,
    );
  });

  testWidgets('speaking on the expense form fills the note and the amount', (
    tester,
  ) async {
    final recognizer = FakeRecognizer(
      words: const [
        SpeechResult('diesel', isFinal: false),
        SpeechResult('diesel 800', isFinal: true),
      ],
    );
    await pumpApp(
      tester,
      initialLocation: '/plots/p1/accounts/expense',
      recognizer: recognizer,
    );
    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump();
    await tester.pump();

    expect(recognizer.heardLocale, 'mr_IN');
    final note = tester.widget<TextFormField>(
      find.byKey(const Key('expense-note')),
    );
    expect(note.controller!.text, 'diesel');
    final amount = tester.widget<TextFormField>(
      find.byKey(const Key('expense-amount')),
    );
    expect(amount.controller!.text, '800');
    await unmountApp(tester);
  });

  testWidgets('an unavailable recogniser says so instead of failing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/accounts/expense',
      recognizer: FakeRecognizer(available: false),
    );
    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Voice input is not available on this phone'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
