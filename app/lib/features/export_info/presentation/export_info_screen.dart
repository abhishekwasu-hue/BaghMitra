import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/info_note.dart';
import '../../../design_system/sources_disclosure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart';
import '../data/export_info_config.dart';

/// Export information per crop (spec v1.5 §4A): where the fruit goes, season fit and buyer
/// specs as quoted, and the rules a grower meets, each line with its source and the day it
/// was read (folded), plus the official pages. Information only: BagMitra takes no part in
/// any export. Behind the market-link flag (router).
class ExportInfoScreen extends ConsumerStatefulWidget {
  const ExportInfoScreen({super.key});

  @override
  ConsumerState<ExportInfoScreen> createState() => _ExportInfoScreenState();
}

String exportSectionLabel(AppLocalizations t, String section) =>
    switch (section) {
      'destinations' => t.exportSectionDestinations,
      'season' => t.exportSectionSeason,
      'specs' => t.exportSectionSpecs,
      _ => t.exportSectionRules,
    };

class _ExportInfoScreenState extends ConsumerState<ExportInfoScreen> {
  String _crop = 'santra';

  Future<void> _open(ExportLink link) async {
    final t = AppLocalizations.of(context);
    final opened = await ref.read(urlOpenerProvider)(Uri.parse(link.url));
    if (opened || !mounted) return;
    // No app could open it: the link is copied so the grower can paste it.
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.feedLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final info = ref.watch(exportInfoProvider).value;
    final crops = ref.watch(cropsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.exportInfoTitle)),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton.icon(
            key: const Key('export-record-open'),
            onPressed: () => context.push(Routes.exportRecord),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(t.exportRecordAction),
          ),
        ],
      ),
      body: info == null
          ? LoadingState(label: t.loadingLabel)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                InfoNote(t.exportInfoNote),
                const SizedBox(height: BmSpace.sm),
                Wrap(
                  spacing: BmSpace.xs,
                  runSpacing: BmSpace.xs,
                  children: [
                    for (final slug in info.crops.keys)
                      ChoiceChip(
                        key: Key('export-crop-$slug'),
                        label: Text(
                          crops
                                  .where((k) => k.slug == slug)
                                  .firstOrNull
                                  ?.label(lang) ??
                              slug,
                        ),
                        selected: _crop == slug,
                        onSelected: (_) => setState(() => _crop = slug),
                      ),
                  ],
                ),
                const SizedBox(height: BmSpace.sm),
                for (final s in info.sections)
                  if (info.factsFor(_crop, s) case final facts
                      when facts.isNotEmpty)
                    ExpansionTile(
                      key: Key('export-section-$s'),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(
                        bottom: BmSpace.sm,
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Text(
                        '${exportSectionLabel(t, s)} · '
                        '${formatInt(facts.length, lang)}',
                        style: BmType.bodyStrong,
                      ),
                      children: [
                        for (final f in facts) _FactLine(fact: f, info: info),
                      ],
                    ),
                const SizedBox(height: BmSpace.md),
                SectionHeader(title: t.exportLinksTitle),
                const SizedBox(height: BmSpace.xs),
                BmCard(
                  elevated: false,
                  radius: BmRadius.card,
                  padding: const EdgeInsets.symmetric(vertical: BmSpace.xxs),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        for (final l in info.links)
                          ListTile(
                            key: Key('export-link-${l.id}'),
                            leading: Icon(Icons.open_in_new, color: c.brand),
                            title: Text(l.labelIn(lang), style: BmType.body),
                            onTap: () => _open(l),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One fact, its source and read date folded under it.
class _FactLine extends StatelessWidget {
  const _FactLine({required this.fact, required this.info});

  final ExportFact fact;
  final ExportInfo info;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final src = info.sources[fact.source];
    return Padding(
      key: Key('export-fact-${fact.id}'),
      padding: const EdgeInsets.only(top: BmSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.textIn(lang), style: BmType.body),
          SourcesDisclosure(
            sources: [
              SourceRef(
                src?.title ?? fact.source,
                url: src?.url,
                publisher: src?.publisher,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
