import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/article_reading.dart';
import '../../../design_system/sources_disclosure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../feed/presentation/feed_article_view.dart' show AiTag;
import '../data/crop_guides.dart';

/// पीक मार्गदर्शक (owner 2026-11-14): one field crop from land preparation to harvest, a
/// coloured card per stage, each line from a named public source behind the stage's folded
/// "स्रोत (n)" header. Fertilisers, pesticides and organic inputs are named without a dose
/// and end with the expert-advice note (tested on the data). "AI ने निर्मित" only when
/// the guide's text was written by AI. Bundled: works offline.
class CropGuideScreen extends ConsumerWidget {
  const CropGuideScreen({super.key, required this.crop});

  final String crop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(cropGuidesProvider).value;
    final guide = data?.forCrop(crop);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          guide == null ? t.cropGuideOpen : t.cropGuideTitle(guide.label(lang)),
        ),
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          // Only a crop with a guide links here; an unknown crop shows an empty page.
          : guide == null
          ? const SizedBox.shrink()
          : ListView(
              key: const Key('crop-guide'),
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                for (final (i, s) in guide.sections.indexed) ...[
                  if (i > 0) const SizedBox(height: BmSpace.md),
                  _SectionCard(
                    key: Key('crop-guide-${s.key}'),
                    data: data,
                    section: s,
                    lang: lang,
                  ),
                ],
                if (guide.aiWritten) ...[
                  const SizedBox(height: BmSpace.md),
                  const AiTag(key: Key('crop-guide-ai-tag')),
                ],
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.data,
    required this.section,
    required this.lang,
  });

  final CropGuidesData data;
  final CropGuideSection section;
  final String lang;

  static IconData _icon(String key) => switch (key) {
    'land' => Icons.landscape_rounded,
    'sowing' => Icons.event_rounded,
    'varieties' => Icons.grass_rounded,
    'seed' => Icons.spa_rounded,
    'nutrition' => Icons.eco_rounded,
    'water' => Icons.water_drop_rounded,
    'intercultivation' => Icons.agriculture_rounded,
    'protection' => Icons.bug_report_rounded,
    'harvest' => Icons.inventory_2_rounded,
    _ => Icons.info_outline_rounded,
  };

  static BmTone _tone(BmColors c, String key) => switch (key) {
    'land' || 'harvest' => c.toneAmber,
    'sowing' || 'water' => c.toneBlue,
    'varieties' || 'intercultivation' => c.toneTeal,
    'seed' || 'nutrition' => c.toneGreen,
    'protection' => c.toneViolet,
    _ => c.toneGrey,
  };

  @override
  Widget build(BuildContext context) {
    final tone = _tone(context.bm, section.key);
    return ReadingCard(
      heading: data.sectionLabel(section.key, lang),
      icon: _icon(section.key),
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in section.items)
            ReadingBullet(
              key: Key('crop-guide-item-${item.id}'),
              text: item.label(lang),
              tone: tone,
            ),
          const SizedBox(height: BmSpace.xs),
          SourcesDisclosure(
            notes: [
              for (final note in {for (final i in section.items) i.source})
                note,
            ],
            sources: [
              for (final k in section.sourceKeys)
                if (data.sources[k] case final s?)
                  SourceRef(s.title, url: s.url, publisher: s.publisher),
            ],
          ),
        ],
      ),
    );
  }
}

/// One button per guide whose crop [text] names (a feed article, owner 2026-11-14): e.g.
/// "मोहरी: लागवड ते काढणी मार्गदर्शक →" (arrow drawn as an icon). Nothing when no guide crop is named.
class CropGuideLinks extends ConsumerWidget {
  const CropGuideLinks({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = ref.watch(cropGuidesProvider).value?.mentionedIn(text);
    if (guides == null || guides.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in guides)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.xs),
            child: OutlinedButton.icon(
              key: Key('crop-guide-link-${g.crop}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.brandStrong,
                side: BorderSide(color: c.brand, width: 1.5),
                alignment: AlignmentDirectional.centerStart,
                minimumSize: const Size.fromHeight(BmSpace.tapTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: BmSpace.md,
                  vertical: BmSpace.sm,
                ),
              ),
              icon: const Icon(Icons.menu_book_rounded),
              // The owner's "… मार्गदर्शक →": the arrow is an icon (no → glyph in the font).
              label: Row(
                children: [
                  Flexible(
                    child: Text(t.cropGuideArticleButton(g.label(lang))),
                  ),
                  const SizedBox(width: BmSpace.xxs),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
              onPressed: () => context.push(Routes.cropGuide(g.crop)),
            ),
          ),
      ],
    );
  }
}
