/// One recognition update: what was heard so far, and whether the engine is done with it.
class SpeechResult {
  const SpeechResult(this.text, {required this.isFinal});
  final String text;
  final bool isFinal;
}

/// Speech to text. Implementations are swappable (on-device default, a cloud engine behind
/// config, later Bhashini or Sarvam) so screens never touch a platform plugin.
abstract interface class SpeechRecognizer {
  /// False when the phone has no recogniser or the microphone permission was refused.
  Future<bool> isAvailable();

  /// Starts listening in [localeId] (for example `mr_IN`). The stream emits partial results and
  /// one final one, then closes.
  Stream<SpeechResult> listen({required String localeId});

  Future<void> stop();
}

/// Text to speech.
abstract interface class SpeechSynthesizer {
  Future<void> speak(String text, {required String localeId});
  Future<void> stop();
}

/// Maps an app language code to the locale the speech engines expect.
String speechLocaleId(String languageCode) => switch (languageCode) {
  'mr' => 'mr_IN',
  'hi' => 'hi_IN',
  _ => 'en_IN',
};
