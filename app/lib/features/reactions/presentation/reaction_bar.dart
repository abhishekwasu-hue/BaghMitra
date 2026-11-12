import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/reaction_providers.dart';
import '../domain/reaction.dart';

/// Emoji glyphs come from the phone's own emoji font; tests load this family by name.
const reactionEmojiFonts = ['NotoColorEmoji'];

/// "How was this article?" with one 48 dp chip per reaction (owner 2026-11-12, Q146): the
/// count next to each emoji and the reader's own choice highlighted. A tap shows at once and
/// says "धन्यवाद!"; it is sent now, or waits on the phone and goes later. Only when it really
/// waits (the send failed) a muted line says so.
class ReactionBar extends ConsumerStatefulWidget {
  const ReactionBar({required this.target, required this.title, super.key});

  /// A feed item id or `qa:<answer id>` ([qaReactionTarget]).
  final String target;

  /// The question above the chips ([AppLocalizations.reactionsArticleTitle] …).
  final String title;

  @override
  ConsumerState<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends ConsumerState<ReactionBar> {
  /// The view right after a tap, until the send attempt ends (the waiting note is not shown
  /// while a send is still under way).
  ReactionView? _justTapped;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didUpdateWidget(ReactionBar old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _justTapped = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  /// The latest counts when online; offline the saved copy stays.
  Future<void> _refresh() async {
    if (!mounted) return;
    final target = widget.target;
    try {
      await ref.read(reactionStoreProvider).refresh([target]);
    } on Object {
      // Offline or refused: the phone's copy is shown.
    }
    if (mounted) ref.invalidate(reactionViewProvider(target));
  }

  Future<void> _tap(Reaction reaction) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final store = ref.read(reactionStoreProvider);
    final target = widget.target;
    final shown = await store.choose(target, reaction);
    if (!mounted) return;
    setState(() => _justTapped = shown);
    if (shown.mine != null) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('reaction-toast'),
            content: Text(t.reactionThanksToast),
            duration: const Duration(seconds: 2),
          ),
        );
    }
    try {
      await store.flush();
    } on Object {
      // stays queued
    }
    if (!mounted) return;
    ref.invalidate(reactionViewProvider(target));
    await ref.read(reactionViewProvider(target).future);
    if (mounted && widget.target == target) setState(() => _justTapped = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final stored = ref.watch(reactionViewProvider(widget.target)).value;
    final view = _justTapped ?? stored ?? const ReactionView();
    final waiting = _justTapped == null && (stored?.pending ?? false);
    return Column(
      key: Key('reaction-bar-${widget.target}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: BmType.formLabel),
        const SizedBox(height: BmSpace.xs),
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            for (final r in Reaction.values)
              _ReactionChip(
                reaction: r,
                label: r.label(t),
                count: view.count(r),
                selected: view.mine == r,
                onTap: () => unawaited(_tap(r)),
              ),
          ],
        ),
        if (waiting) ...[
          const SizedBox(height: BmSpace.xs),
          Row(
            key: const Key('reaction-pending'),
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: BmSpace.md,
                color: c.inkMuted,
              ),
              const SizedBox(width: BmSpace.xs),
              Expanded(
                child: Text(
                  t.reactionPending,
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One tinted chip: emoji, word and count. Chosen: brand-soft fill, strong brand border and
/// text (the design-system "selected" look); otherwise the card fill with a quiet line.
class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Reaction reaction;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final ink = selected ? c.brandStrong : c.ink;
    final radius = BorderRadius.circular(BmRadius.pill);
    return Semantics(
      button: true,
      selected: selected,
      label: t.reactionChipSemantics(label, count),
      excludeSemantics: true,
      child: Material(
        color: selected ? c.brandSoft : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? c.brandStrong : c.line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          key: Key('reaction-${reaction.value}'),
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BmSpace.tapTarget,
              minWidth: BmSpace.tapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BmSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reaction.emoji,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamilyFallback: reactionEmojiFonts,
                    ),
                  ),
                  const SizedBox(width: BmSpace.xxs),
                  Text(label, style: BmType.bodyStrong.copyWith(color: ink)),
                  if (count > 0) ...[
                    const SizedBox(width: BmSpace.xs),
                    Text(
                      formatInt(
                        count,
                        Localizations.localeOf(context).languageCode,
                      ),
                      key: Key('reaction-${reaction.value}-count'),
                      style: BmType.bodyStrong.copyWith(
                        color: selected ? c.brandStrong : c.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
