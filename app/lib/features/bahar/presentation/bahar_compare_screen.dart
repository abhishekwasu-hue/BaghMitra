import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/bahar_catalog.dart';
import '../data/bahar_compare.dart';

/// Decision support for choosing a bahar: the grower's own last bahar on this block, a few
/// questions about their orchard, and sourced points per bahar. Never ranks or recommends;
/// "Use this bahar" returns the grower's choice to the start screen.
class BaharCompareScreen extends ConsumerStatefulWidget {
  const BaharCompareScreen({required this.plotId, super.key});

  final String plotId;

  @override
  ConsumerState<BaharCompareScreen> createState() => _BaharCompareScreenState();
}

class _BaharCompareScreenState extends ConsumerState<BaharCompareScreen> {
  final Map<String, String> _answers = {};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(baharOptionsProvider).value;
    final data = ref.watch(baharCompareProvider).value;
    final crop = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == widget.plotId)
        .firstOrNull
        ?.crop;
    final cycles = [...?ref.watch(baharCyclesProvider(widget.plotId)).value]
      ..sort((a, b) => b.seasonYear.compareTo(a.seasonYear));
    final last = cycles.firstOrNull;
    final bahars = crop == null || catalog == null
        ? const <LabeledOption>[]
        : catalog.forCrop(crop);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.baharCompareTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(t.baharCompareIntro, style: BmType.meta),
          const SizedBox(height: BmSpace.lg),
          Text(
            last == null
                ? t.baharCompareNoLast
                : t.baharCompareLast(
                    '${catalog?.baharLabel(last.bahar, lang) ?? last.bahar} · '
                    '${formatYear(last.seasonYear, lang)}',
                  ),
            style: BmType.bodyStrong,
          ),
          for (final q in data?.questions ?? const <CompareQuestion>[]) ...[
            const SizedBox(height: BmSpace.lg),
            Text(q.label(lang), style: BmType.label),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              children: [
                for (final o in q.options)
                  ChoiceChip(
                    key: Key('answer-${q.key}-${o.slug}'),
                    label: Text(o.label(lang)),
                    selected: _answers[q.key] == o.slug,
                    onSelected: (on) => setState(
                      () => on
                          ? _answers[q.key] = o.slug
                          : _answers.remove(q.key),
                    ),
                  ),
              ],
            ),
          ],
          for (final b in bahars) ...[
            const SizedBox(height: BmSpace.xl),
            Text(b.label(lang), style: BmType.section),
            if (data?.pointsFor(b.slug, _answers) case final points?
                when points.isNotEmpty)
              for (final p in points)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline, color: c.inkMuted),
                  title: Text(p.label(lang), style: BmType.body),
                  subtitle: Text(
                    t.baharCompareSource(p.source),
                    style: BmType.meta,
                  ),
                )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
                child: Text(t.baharCompareNoPoints, style: BmType.meta),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: Key('use-${b.slug}'),
                onPressed: () => context.pop(b.slug),
                child: Text(t.baharCompareUse),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
