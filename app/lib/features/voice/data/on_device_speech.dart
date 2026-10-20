import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../domain/speech.dart';

/// Android's own recogniser through `speech_to_text`: free, works offline where the phone has the
/// language pack (`mr-IN`, `hi-IN`). The default engine.
class OnDeviceSpeechRecognizer implements SpeechRecognizer {
  OnDeviceSpeechRecognizer({stt.SpeechToText? engine})
    : _engine = engine ?? stt.SpeechToText();

  final stt.SpeechToText _engine;
  bool _ready = false;

  @override
  Future<bool> isAvailable() async =>
      _ready = _ready || await _engine.initialize();

  @override
  Stream<SpeechResult> listen({required String localeId}) {
    final controller = StreamController<SpeechResult>();
    unawaited(() async {
      if (!await isAvailable()) {
        await controller.close();
        return;
      }
      await _engine.listen(
        listenOptions: stt.SpeechListenOptions(localeId: localeId),
        onResult: (r) {
          controller.add(
            SpeechResult(r.recognizedWords, isFinal: r.finalResult),
          );
          if (r.finalResult) unawaited(controller.close());
        },
      );
    }());
    controller.onCancel = _engine.stop;
    return controller.stream;
  }

  @override
  Future<void> stop() => _engine.stop();
}

/// Android's text-to-speech through `flutter_tts`.
class OnDeviceSpeechSynthesizer implements SpeechSynthesizer {
  OnDeviceSpeechSynthesizer({FlutterTts? engine})
    : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;

  @override
  Future<void> speak(String text, {required String localeId}) async {
    await _engine.setLanguage(localeId.replaceAll('_', '-'));
    await _engine.speak(text);
  }

  @override
  Future<void> stop() async {
    await _engine.stop();
  }
}
