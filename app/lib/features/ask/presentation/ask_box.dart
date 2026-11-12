import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/sources_disclosure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../reactions/domain/reaction.dart';
import '../../reactions/presentation/reaction_bar.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../data/qa_kb.dart';

/// The question box at the top of the विचारा tab (owner 2026-11-12, Q144). The farmer types or
/// says a question; the answer comes at once from the questions and answers stored in the app
/// (checked sources only), so it works the same with and without internet. Shown: the best
/// answer with its sources (links as text), one muted line that the answer is stored, the card
/// to open, and two or three related questions. A weaker match offers the closest questions;
/// no match points to the guide below and the KVK.
class AskBox extends ConsumerStatefulWidget {
  const AskBox({super.key});

  @override
  ConsumerState<AskBox> createState() => _AskBoxState();
}

class _AskBoxState extends ConsumerState<AskBox> {
  final _controller = TextEditingController();
  String? _asked;
  QaEntry? _chosen;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    final text = _controller.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _asked = text.isEmpty ? null : text;
      _chosen = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final kb = ref.watch(qaKbProvider).value;
    return Container(
      key: const Key('ask-box'),
      padding: const EdgeInsets.all(BmSpace.md),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(BmRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.askTitle, style: BmType.bodyStrong),
          const SizedBox(height: BmSpace.xs),
          TextField(
            key: const Key('ask-field'),
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _ask(),
            decoration: InputDecoration(
              hintText: t.askHint,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VoiceMicButton(
                    onResult: (text, {required isFinal}) {
                      _controller.text = text;
                      if (isFinal) _ask();
                    },
                  ),
                  IconButton(
                    key: const Key('ask-go'),
                    tooltip: t.askSearch,
                    onPressed: _ask,
                    icon: Icon(Icons.search_rounded, color: c.brand),
                  ),
                ],
              ),
            ),
          ),
          if (kb != null && _asked != null) ..._result(context, kb, _asked!),
        ],
      ),
    );
  }

  List<Widget> _result(BuildContext context, QaKb kb, String asked) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final quiet = BmType.meta.copyWith(color: c.inkMuted);
    final hits = kb.search(asked);
    final best = _chosen ?? hits.firstOrNull?.entry;
    final strong =
        _chosen != null ||
        (hits.isNotEmpty && hits.first.score >= qaAnswerScore);

    Widget question(QaEntry e) => InkWell(
      key: Key('ask-related-${e.id}'),
      onTap: () => setState(() => _chosen = e),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, size: BmSpace.md, color: c.brand),
            const SizedBox(width: BmSpace.xs),
            Expanded(
              child: Text(
                e.question(lang),
                style: BmType.body.copyWith(color: c.brandStrong),
              ),
            ),
          ],
        ),
      ),
    );

    if (best == null || !strong) {
      final close = [
        for (final h in hits)
          if (h.score >= qaCloseScore) h.entry,
      ].take(3).toList();
      return [
        const SizedBox(height: BmSpace.sm),
        if (close.isEmpty)
          Text(t.askNoMatch, key: const Key('ask-no-match'), style: quiet)
        else ...[
          Text(t.askCloser, key: const Key('ask-closer'), style: quiet),
          for (final e in close) question(e),
        ],
      ];
    }

    final related = <QaEntry>[
      for (final h in hits)
        if (h.entry.id != best.id && h.score >= qaCloseScore) h.entry,
    ];
    for (final e in kb.sameSection(best, limit: 4)) {
      if (!related.any((r) => r.id == e.id)) related.add(e);
    }
    return [
      const SizedBox(height: BmSpace.sm),
      Container(
        key: Key('ask-answer-${best.id}'),
        padding: const EdgeInsets.all(BmSpace.sm),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(BmRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(best.question(lang), style: BmType.bodyStrong),
            const SizedBox(height: BmSpace.xs),
            for (final line in best.answer(lang))
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: BmType.body.copyWith(color: c.brand)),
                    Expanded(child: Text(line, style: BmType.body)),
                  ],
                ),
              ),
            SourcesDisclosure(
              key: const Key('ask-sources'),
              sources: [
                for (final k in best.sources)
                  if (kb.sources[k] case final s?)
                    SourceRef(s.title, url: s.url.isEmpty ? null : s.url),
              ],
            ),
            Text(t.askStoredNote, key: const Key('ask-note'), style: quiet),
            if (best.section case final section?)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('ask-open-card'),
                  onPressed: () =>
                      context.push(Routes.practicesSection(section)),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(t.askOpenCard),
                ),
              ),
            const SizedBox(height: BmSpace.sm),
            ReactionBar(
              key: Key('ask-reactions-${best.id}'),
              target: qaReactionTarget(best.id),
              title: t.reactionsAnswerTitle,
            ),
          ],
        ),
      ),
      if (related.isNotEmpty) ...[
        const SizedBox(height: BmSpace.sm),
        Text(t.askRelated, style: BmType.label),
        for (final e in related.take(3)) question(e),
      ],
    ];
  }
}
