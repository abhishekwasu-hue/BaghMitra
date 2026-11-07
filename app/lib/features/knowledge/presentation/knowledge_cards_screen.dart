import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/general_info_note.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/sources_disclosure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// The knowledge cards (bahar, pests, diseases, nutrition, irrigation, planting, harvest) as
/// general information: the API leaves out chemicals, rates and doses, and every card that an
/// expert has not reviewed carries the "general information" mark with its sources and the
/// date each was read (owner decision Q57). With [topic] the screen opens on that card.
class KnowledgeCardsScreen extends ConsumerWidget {
  const KnowledgeCardsScreen({super.key, this.topic});

  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final loaded = ref.watch(knowledgeCardsProvider);
    final all = loaded.value?.cards;
    final cards = all == null
        ? null
        : [
            for (final c in all)
              if (topic == null || c.topic == topic) c,
          ];
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.knowledgeTitle)),
      body: loaded.isLoading && all == null
          ? LoadingState(label: t.loadingLabel)
          : cards == null || cards.isEmpty
          ? EmptyState(glyph: BmGlyph.camera, message: t.knowledgeEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                Text(t.knowledgeIntro, style: BmType.body),
                const SizedBox(height: BmSpace.md),
                for (final card in cards) ...[
                  _KnowledgeCardView(card: card),
                  const SizedBox(height: BmSpace.md),
                ],
              ],
            ),
    );
  }
}

class _KnowledgeCardView extends StatelessWidget {
  const _KnowledgeCardView({required this.card});

  final GrowerCardOut card;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    CardText? text(String l) => switch (card.text[l]) {
      final Map<String, dynamic> m => CardText.fromJson(m),
      _ => null,
    };
    final own = text(lang);
    final en = text('en');
    String? pick(String? Function(CardText) f) =>
        (own == null ? null : f(own)) ?? (en == null ? null : f(en));
    final title =
        pick((x) => x.title) ??
        (card.topicLabels[lang] ?? card.topicLabels['en'] ?? card.topic)
            as String;

    Widget part(String? heading, String? body) => body == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: BmSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading != null)
                  Text(
                    heading,
                    style: BmType.label.copyWith(color: c.brandStrong),
                  ),
                if (heading != null) const SizedBox(height: BmSpace.xxs),
                Text(body, style: BmType.body),
              ],
            ),
          );

    return BmCard(
      key: Key('knowledge-${card.topic}-${card.crop}'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: BmType.cardTitle),
          if (!card.reviewed)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xxs),
              // The source and date fold into "See sources" at the end of the card.
              child: GeneralInfoNote(
                key: Key('knowledge-general-${card.topic}-${card.crop}'),
              ),
            ),
          part(null, pick((x) => x.summary)),
          part(t.practicesWhatToDo, pick((x) => x.cultural)),
          part(t.knowledgeWarnings, pick((x) => x.warnings)),
          part(t.knowledgeCallExpert, pick((x) => x.whenToCallExpert)),
          const SizedBox(height: BmSpace.xs),
          SourcesDisclosure(
            key: Key('knowledge-sources-${card.topic}-${card.crop}'),
            sources: [
              for (final s in card.sources)
                SourceRef(
                  s.title,
                  url: s.url,
                  publisher: s.publisher,
                  checked: switch (s.checked) {
                    final d? => formatDate(d, lang),
                    null => null,
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
