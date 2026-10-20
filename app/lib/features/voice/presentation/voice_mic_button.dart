import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/speech.dart';

/// A microphone for a text field: tap, speak, and [onResult] receives what was heard (partial
/// results as they come, then the final one). Tapping again stops. The grower always reviews the
/// text before saving, so a misheard word is one tap to fix.
class VoiceMicButton extends ConsumerStatefulWidget {
  const VoiceMicButton({required this.onResult, super.key});

  final void Function(String text, {required bool isFinal}) onResult;

  @override
  ConsumerState<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends ConsumerState<VoiceMicButton> {
  StreamSubscription<SpeechResult>? _sub;
  bool _listening = false;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _toggle() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final locale = speechLocaleId(Localizations.localeOf(context).languageCode);
    final recognizer = ref.read(speechRecognizerProvider);
    if (_listening) {
      await recognizer.stop();
      return;
    }
    if (!await recognizer.isAvailable()) {
      messenger.showSnackBar(SnackBar(content: Text(t.voiceUnavailable)));
      return;
    }
    setState(() => _listening = true);
    _sub = recognizer
        .listen(localeId: locale)
        .listen(
          (r) => widget.onResult(r.text, isFinal: r.isFinal),
          onError: (Object _) {
            messenger.showSnackBar(SnackBar(content: Text(t.voiceUnavailable)));
            if (mounted) setState(() => _listening = false);
          },
          onDone: () {
            if (mounted) setState(() => _listening = false);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return IconButton(
      key: const Key('voice-mic'),
      tooltip: _listening ? t.voiceListening : t.voiceInput,
      onPressed: _toggle,
      icon: Icon(_listening ? Icons.mic : Icons.mic_none_rounded),
    );
  }
}
