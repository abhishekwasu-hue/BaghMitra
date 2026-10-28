import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/share_speak.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/speech.dart';

/// [ShareSpeakActions] wired to the phone: share hands [shareText] to the share sheet
/// (WhatsApp …); speak reads [speakText] (default: the same text) aloud in the app
/// language, falling back to a near voice, and says so when the phone has none.
class ShareSpeakButtons extends ConsumerWidget {
  const ShareSpeakButtons({
    super.key,
    required this.shareText,
    this.speakText,
    this.keyPrefix = 'item',
  });

  final String shareText;
  final String? speakText;
  final String keyPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ShareSpeakActions(
      keyPrefix: keyPrefix,
      shareLabel: t.shareAction,
      speakLabel: t.speakAction,
      onShare: () => ref.read(textSharerProvider).shareText(shareText),
      onSpeak: () => _speak(context, ref, t),
    );
  }

  Future<void> _speak(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations t,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final locale = speechLocaleId(Localizations.localeOf(context).languageCode);
    var spoken = false;
    try {
      spoken = await ref
          .read(speechSynthesizerProvider)
          .speak(speakText ?? shareText, localeId: locale);
    } on Object catch (e) {
      ref.read(appLogProvider).log('speak: $e');
    }
    if (!spoken) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.speakUnavailable)));
    }
  }
}

/// The last line of every shared text, so the person it reaches knows where it came from.
String shareFooter(AppLocalizations t, String productName) =>
    t.shareSentFrom(productName);
