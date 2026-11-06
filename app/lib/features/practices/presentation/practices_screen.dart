import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/general_info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/practice_cards.dart';

/// Non-chemical orchard practices from published sources, grouped by problem. Every practice
/// names its source and evidence level. No synthetic chemical advice (owner Q28); no draft
/// banner (Q30). A problem section with a profile also says what the grower sees, when it
/// comes, how to scout and any published action level, lists organic / bio options as
/// published, links to the label screen for that target, and carries the "general
/// information" mark with its sources and the date read (owner decision Q57).
class PracticesScreen extends ConsumerWidget {
  const PracticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(practiceCardsProvider).value;
    final plot = ref.watch(plotsProvider).value?.firstOrNull?.id;

    String evidence(String e) => switch (e) {
      'official' => t.practicesEvidenceOfficial,
      'university' => t.practicesEvidenceUniversity,
      'research' => t.practicesEvidenceResearch,
      _ => t.practicesEvidenceInferred,
    };

    Widget sources(List<String> keys) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final k in keys)
          if (data?.sources[k] case final s?)
            Text('$k: ${s.title}', style: BmType.meta),
      ],
    );

    Widget evidenceRow(List<String> kinds) => Wrap(
      spacing: BmSpace.xs,
      children: [
        for (final e in kinds)
          Text(evidence(e), style: BmType.meta.copyWith(color: c.brand)),
      ],
    );

    Widget item(PracticeItem p) => Padding(
      key: Key('practice-${p.id}'),
      padding: const EdgeInsets.symmetric(vertical: BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.label(lang), style: BmType.body),
          const SizedBox(height: BmSpace.xs),
          Text(t.practicesSource(p.source), style: BmType.meta),
          sources(p.sourceKeys),
          const SizedBox(height: BmSpace.xs),
          evidenceRow(p.evidence),
        ],
      ),
    );

    Widget heading(String text, {Key? key, IconData? icon}) => Padding(
      key: key,
      padding: const EdgeInsets.only(top: BmSpace.sm, bottom: BmSpace.xxs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: c.brand),
            const SizedBox(width: BmSpace.xxs),
          ],
          Flexible(
            child: Text(
              text,
              style: BmType.label.copyWith(color: c.brandStrong),
            ),
          ),
        ],
      ),
    );

    Widget part(String title, PracticePart p, String key) => Column(
      key: Key(key),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(title),
        Text(p.label(lang), style: BmType.body),
        const SizedBox(height: BmSpace.xxs),
        Text(t.practicesSource(p.source), style: BmType.meta),
      ],
    );

    Widget bio(PracticeBio b) {
      final prep = data?.preparations[b.preparation];
      return Padding(
        key: Key('practice-bio-${b.id}'),
        padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.label(lang), style: BmType.body),
            const SizedBox(height: BmSpace.xxs),
            Text(
              b.kind == 'registered'
                  ? t.practicesBioRegistered
                  : t.practicesBioHome,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
            Text(t.practicesSource(b.source), style: BmType.meta),
            evidenceRow(b.evidence),
            if (prep != null)
              ExpansionTile(
                key: Key('practice-prep-${b.id}'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: BmSpace.xs),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(t.practicesHowToPrepare, style: BmType.label),
                children: [
                  Text(prep.label(lang), style: BmType.body),
                  const SizedBox(height: BmSpace.xxs),
                  Text(t.practicesSource(prep.source), style: BmType.meta),
                  sources(prep.sourceKeys),
                ],
              ),
          ],
        ),
      );
    }

    List<Widget> profiled(PracticeSection s, PracticeProfile p) {
      final keys = {...p.sourceKeys, for (final i in s.items) ...i.sourceKeys};
      final publishers = {for (final k in keys) ?data?.sources[k]?.publisher};
      final checked = p.checked;
      final pest = p.kind == 'pest';
      return [
        GeneralInfoNote(
          key: Key('practices-general-${s.key}'),
          source: publishers.join(', '),
          checked: checked == null ? null : formatDate(checked, lang),
        ),
        if (p.symptoms case final x?)
          part(t.practicesSee, x, 'practices-see-${s.key}'),
        if (p.when case final x?)
          part(t.practicesWhen, x, 'practices-when-${s.key}'),
        if (p.scouting case final x?)
          part(t.practicesScout, x, 'practices-scout-${s.key}'),
        if (p.actionLevel case final x?)
          part(t.practicesActionLevel, x, 'practices-action-${s.key}')
        else if (pest) ...[
          heading(t.practicesActionLevel),
          Text(
            t.practicesNoActionLevel,
            key: Key('practices-no-action-${s.key}'),
            style: BmType.meta,
          ),
        ],
        if (s.items.isNotEmpty) heading(t.practicesWhatToDo),
        for (final i in s.items) item(i),
        if (p.bio.isNotEmpty) ...[
          heading(
            t.practicesBioTitle,
            key: Key('practices-bio-${s.key}'),
            icon: Icons.eco_outlined,
          ),
          for (final b in p.bio) bio(b),
        ],
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            if ((p.labelTarget, plot) case (final target?, final id?))
              OutlinedButton.icon(
                key: Key('practices-labels-${s.key}'),
                onPressed: () => context.push(
                  '${Routes.labels(id)}?target=${Uri.encodeQueryComponent(target)}',
                ),
                icon: const Icon(Icons.verified_outlined),
                label: Text(t.practicesLabelLink),
              ),
            if (p.kbTopic case final topic?)
              OutlinedButton.icon(
                key: Key('practices-kb-${s.key}'),
                onPressed: () => context.push(Routes.knowledgeTopic(topic)),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(t.practicesKnowledgeCard),
              ),
          ],
        ),
        const SizedBox(height: BmSpace.sm),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(t.practicesTitle),
        actions: [
          IconButton(
            key: const Key('open-knowledge-all'),
            tooltip: t.knowledgeTitle,
            icon: Icon(Icons.menu_book_outlined, color: c.brand),
            onPressed: () => context.push(Routes.knowledge),
          ),
          IconButton(
            key: const Key('open-lookalikes-all'),
            tooltip: t.lookalikesOpen,
            icon: Icon(Icons.compare_outlined, color: c.brand),
            onPressed: () => context.push(Routes.lookalikes),
          ),
          IconButton(
            key: const Key('open-irrigation-guide-all'),
            tooltip: t.irrigationOpen,
            icon: Icon(Icons.water_drop_outlined, color: c.brand),
            onPressed: () => context.push(Routes.irrigation),
          ),
        ],
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
                    children: [
                      if (s.profile case final p?)
                        ...profiled(s, p)
                      else
                        for (final p in s.items) item(p),
                    ],
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
                  t.practicesSourcesLineAll,
                  key: const Key('practices-sources'),
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
              ],
            ),
    );
  }
}
