import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/practice_cards.dart';

/// Non-chemical orchard practices from published sources, grouped by problem. Every practice
/// names its source and evidence level. No chemical advice (owner Q28); no draft banner (Q30).
class PracticesScreen extends ConsumerWidget {
  const PracticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(practiceCardsProvider).value;

    String evidence(String e) => switch (e) {
      'official' => t.practicesEvidenceOfficial,
      'university' => t.practicesEvidenceUniversity,
      'research' => t.practicesEvidenceResearch,
      _ => t.practicesEvidenceInferred,
    };

    Widget item(PracticeItem p) => Padding(
      key: Key('practice-${p.id}'),
      padding: const EdgeInsets.symmetric(vertical: BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.label(lang), style: BmType.body),
          const SizedBox(height: BmSpace.xs),
          Text(t.practicesSource(p.source), style: BmType.meta),
          for (final k in p.sourceKeys)
            if (data?.sources[k] case final s?)
              Text('$k: ${s.title}', style: BmType.meta),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.xs,
            children: [
              for (final e in p.evidence)
                Text(evidence(e), style: BmType.meta.copyWith(color: c.brand)),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.practicesTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                for (final s in data.sections)
                  ExpansionTile(
                    key: Key('practices-${s.key}'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(s.label(lang), style: BmType.bodyStrong),
                    children: [for (final p in s.items) item(p)],
                  ),
                if (data.gaps.isNotEmpty) ...[
                  const SizedBox(height: BmSpace.lg),
                  Text(t.practicesGapsTitle, style: BmType.label),
                  const SizedBox(height: BmSpace.xs),
                  for (final g in data.gaps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: BmSpace.xs),
                      child: Text(g[lang] ?? g['en'] ?? '', style: BmType.meta),
                    ),
                ],
                const SizedBox(height: BmSpace.lg),
                Text(
                  t.practicesSourcesLine,
                  key: const Key('practices-sources'),
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
              ],
            ),
    );
  }
}
