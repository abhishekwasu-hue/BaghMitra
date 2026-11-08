import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_bar_title.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../data/feedback_outbox.dart';
import '../data/feedback_providers.dart';

/// "Send feedback" (owner 2026-11-08): a problem, a suggestion or a question, typed or
/// spoken, with an optional screenshot. The app version and the phone model go with it.
/// Offline it waits on the phone and goes when the internet is back.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  var _kind = FeedbackKind.problem;
  String? _screenshot;
  var _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final version = ref.read(installedVersionProvider).value;
    final sent = await ref
        .read(feedbackOutboxProvider)
        .add(
          kind: _kind,
          text: _text.text,
          appVersion: version == null ? '?' : '${version.name}+${version.code}',
          device: await ref.read(deviceNameProvider.future),
          screenshotPath: _screenshot,
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(sent ? t.feedbackSent : t.feedbackQueued)),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final labels = {
      FeedbackKind.problem: t.feedbackKindProblem,
      FeedbackKind.suggestion: t.feedbackKindSuggestion,
      FeedbackKind.question: t.feedbackKindQuestion,
    };
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.feedbackTitle)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Wrap(
            spacing: BmSpace.sm,
            children: [
              for (final k in FeedbackKind.values)
                ChoiceChip(
                  key: Key('feedback-kind-${k.name}'),
                  label: Text(labels[k]!),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.md),
          TextField(
            key: const Key('feedback-text'),
            controller: _text,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t.feedbackHint,
              suffixIcon: VoiceMicButton(
                onResult: (text, {required isFinal}) =>
                    setState(() => _text.text = text),
              ),
            ),
          ),
          const SizedBox(height: BmSpace.sm),
          OutlinedButton.icon(
            key: const Key('feedback-screenshot'),
            onPressed: () async {
              final path = await ref.read(screenshotPickerProvider)();
              if (path != null) setState(() => _screenshot = path);
            },
            icon: Icon(
              _screenshot == null
                  ? Icons.add_photo_alternate_outlined
                  : Icons.check_circle_rounded,
            ),
            label: Text(
              _screenshot == null
                  ? t.feedbackAddScreenshot
                  : t.feedbackScreenshotAdded,
            ),
          ),
          const SizedBox(height: BmSpace.sm),
          Text(
            t.feedbackIncluded,
            style: BmType.meta.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: BmSpace.lg),
          FilledButton(
            key: const Key('feedback-send'),
            onPressed: _sending || _text.text.trim().isEmpty ? null : _send,
            child: Text(t.feedbackSend),
          ),
        ],
      ),
    );
  }
}
