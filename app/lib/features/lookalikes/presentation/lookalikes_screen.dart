import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/lookalike_cards.dart';

/// Symptoms that look alike in santra / mosambi, as sourced cards: what the grower may
/// see, what it can be confused with, and who can confirm it. Never a diagnosis and never
/// a treatment; each card ends in "log it, get it checked" (research gap #8).
class LookalikesScreen extends ConsumerWidget {
  const LookalikesScreen({super.key, this.plotId});

  /// The block "Log this" records against; else the grower's first block, if any.
  final String? plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final loaded = ref.watch(lookalikeCardsProvider);
    final data = loaded.value;
    final plot = plotId ?? ref.watch(plotsProvider).value?.firstOrNull?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.lookalikesTitle),
        actions: [
          IconButton(
            key: const Key('open-labs'),
            tooltip: t.labsOpen,
            icon: Icon(Icons.biotech_outlined, color: c.brand),
            onPressed: () => context.push(Routes.labs),
          ),
        ],
      ),
      body: data == null
          ? LoadingState(label: t.loadingLabel)
          : data.cards.isEmpty
          ? EmptyState(glyph: BmGlyph.camera, message: t.lookalikesEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                Text(t.lookalikesIntro, style: BmType.body),
                const SizedBox(height: BmSpace.md),
                for (final card in data.cards) ...[
                  _LookalikeCardView(card: card, data: data, plotId: plot),
                  const SizedBox(height: BmSpace.md),
                ],
                Text(
                  t.lookalikesCheckLine,
                  key: const Key('lookalikes-check-line'),
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
              ],
            ),
    );
  }
}

class _LookalikeCardView extends StatelessWidget {
  const _LookalikeCardView({
    required this.card,
    required this.data,
    required this.plotId,
  });

  final LookalikeCard card;
  final LookalikeCardsData data;
  final String? plotId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    Widget part(String heading, Map<String, String> field) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: BmType.label.copyWith(color: c.brandStrong)),
          const SizedBox(height: BmSpace.xxs),
          Text(card.text(field, lang), style: BmType.body),
        ],
      ),
    );
    return BmCard(
      key: Key('lookalike-${card.id}'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.text(card.title, lang), style: BmType.cardTitle),
          if (card.isDraftIn(data.sources))
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xxs),
              child: Text(
                t.lookalikesDraft,
                style: BmType.meta.copyWith(color: c.accentInk),
              ),
            ),
          part(t.lookalikesSee, card.see),
          part(t.lookalikesConfusedWith, card.confusedWith),
          part(t.lookalikesConfirm, card.confirm),
          const SizedBox(height: BmSpace.sm),
          Text(t.lookalikesSources, style: BmType.meta),
          for (final k in card.sourceKeys)
            if (data.sources[k] case final s?)
              Text(s.title, style: BmType.meta.copyWith(color: c.inkMuted)),
          const SizedBox(height: BmSpace.sm),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              if (plotId case final plot?)
                OutlinedButton.icon(
                  key: Key('lookalike-log-${card.id}'),
                  onPressed: () => context.push(
                    Routes.addScouting(plot, item: card.scoutingItem),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t.lookalikesLogThis),
                ),
              OutlinedButton.icon(
                key: Key('lookalike-labs-${card.id}'),
                onPressed: () => context.push(Routes.labs),
                icon: const Icon(Icons.biotech_outlined),
                label: Text(t.lookalikesFindLab),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
