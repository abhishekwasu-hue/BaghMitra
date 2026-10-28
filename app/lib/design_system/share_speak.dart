import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hands a short text on (WhatsApp and the rest of the share sheet). A 48 dp icon button
/// with a tooltip, so it fits beside a row without crowding it.
class ShareAction extends StatelessWidget {
  const ShareAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _ActionIcon(
    icon: Icons.share_outlined,
    label: label,
    onPressed: onPressed,
  );
}

/// Reads a short text aloud in the app language. Same size and look as [ShareAction].
class SpeakAction extends StatelessWidget {
  const SpeakAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _ActionIcon(
    icon: Icons.volume_up_outlined,
    label: label,
    onPressed: onPressed,
  );
}

/// The pair, speak first then share, as used on alerts, prices, tasks and feed items.
class ShareSpeakActions extends StatelessWidget {
  const ShareSpeakActions({
    super.key,
    required this.shareLabel,
    required this.speakLabel,
    required this.onShare,
    required this.onSpeak,
    this.keyPrefix = 'item',
  });

  final String shareLabel;
  final String speakLabel;
  final VoidCallback onShare;
  final VoidCallback onSpeak;

  /// Keys the buttons `<prefix>-speak` and `<prefix>-share` for tests.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SpeakAction(
        key: Key('$keyPrefix-speak'),
        label: speakLabel,
        onPressed: onSpeak,
      ),
      ShareAction(
        key: Key('$keyPrefix-share'),
        label: shareLabel,
        onPressed: onShare,
      ),
    ],
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: label,
    color: context.bm.brandStrong,
    constraints: const BoxConstraints(
      minWidth: BmSpace.tapTarget,
      minHeight: BmSpace.tapTarget,
    ),
    onPressed: onPressed,
  );
}
