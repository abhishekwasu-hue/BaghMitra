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
  /// Speaks [text] in [localeId], or in the nearest voice the phone has (see
  /// [speechFallbackLocales]). False when the phone has no usable voice at all.
  Future<bool> speak(String text, {required String localeId});
  Future<void> stop();
}

/// The voices to try, best first, for text written in [localeId]'s language. Marathi and
/// Hindi share the Devanagari script, so each falls back to the other; an English voice
/// cannot read Devanagari, so it is never a fallback for them.
List<String> speechFallbackLocales(String localeId) => switch (localeId) {
  'mr_IN' => const ['mr-IN', 'hi-IN'],
  'hi_IN' => const ['hi-IN', 'mr-IN'],
  _ => const ['en-IN', 'en-US', 'en-GB'],
};

/// Maps an app language code to the locale the speech engines expect.
String speechLocaleId(String languageCode) => switch (languageCode) {
  'mr' => 'mr_IN',
  'hi' => 'hi_IN',
  _ => 'en_IN',
};
