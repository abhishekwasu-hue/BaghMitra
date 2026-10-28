import '../domain/speech.dart';

/// Google Cloud Speech-to-Text behind config (`SPEECH_ENGINE=cloud`, key from the environment).
/// A stub for now: it is never selected by default and never called in CI. Wiring the real calls
/// needs the key, a billing decision and a server-side proxy so the key never ships in the app.
class CloudSpeechRecognizer implements SpeechRecognizer {
  const CloudSpeechRecognizer();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<SpeechResult> listen({required String localeId}) => Stream.error(
    UnsupportedError('Cloud speech recognition is not wired yet'),
  );

  @override
  Future<void> stop() async {}
}

/// Google Cloud Text-to-Speech stub, see [CloudSpeechRecognizer].
class CloudSpeechSynthesizer implements SpeechSynthesizer {
  const CloudSpeechSynthesizer();

  @override
  Future<bool> speak(String text, {required String localeId}) async =>
      throw UnsupportedError('Cloud speech synthesis is not wired yet');

  @override
  Future<void> stop() async {}
}
