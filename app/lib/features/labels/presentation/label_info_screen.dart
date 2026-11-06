import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/general_info_note.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart';
import '../data/label_targets.dart';

/// What CIB&RC registered labels say for a crop, grouped by pest / disease, chemical and
/// 🌿 bio apart (owner decision Q57). Label information only, never a recommendation: the
/// banner stays pinned above the list, every field is shown exactly as the API gives it
/// (dose and dilution in bold), brand names are a plain alphabetical list, banned or
/// restricted rows are red and carry no dose, and nothing is added by the app.
///
/// Opened for a block ([plotId]: its crop) or from practices / look-alikes ([crop], or the
/// grower's first block, or santra; the grower can switch crop). [target] is a key from
/// `label_targets.json`: only that pest / disease is shown, with a clear message when no
/// label claim is registered for it.
class LabelInfoScreen extends ConsumerStatefulWidget {
  const LabelInfoScreen({this.plotId, this.crop, this.target, super.key});

  final String? plotId;
  final String? crop;
  final String? target;

  @override
  ConsumerState<LabelInfoScreen> createState() => _LabelInfoScreenState();
}

class _Group {
  _Group(this.key, this.name);

  final String key;
  final String name;
  final List<LabelClaimOut> chemical = [];
  final List<LabelClaimOut> bio = [];
  final List<BlockedClaimOut> blocked = [];
}

class _LabelInfoScreenState extends ConsumerState<LabelInfoScreen> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plots = ref.watch(plotsProvider).value;
    final plotCrop = widget.plotId == null
        ? null
        : plots?.where((p) => p.id == widget.plotId).firstOrNull?.crop;
    final crop = widget.plotId != null
        ? plotCrop
        : _picked ?? widget.crop ?? plots?.firstOrNull?.crop ?? 'santra';
    final cached = crop == null
        ? null
        : ref.watch(labelClaimsProvider(crop)).value;
    final targets = ref.watch(labelTargetsProvider).value;
    final claims = cached?.claims ?? const <LabelClaimOut>[];
    final blocked = cached?.blocked ?? const <BlockedClaimOut>[];

    String keyOf(String printed) =>
        targets?.keyFor(printed) ?? 'label:${printed.trim().toLowerCase()}';
    final groups = <String, _Group>{};
    _Group group(String printed) {
      final key = keyOf(printed);
      return groups[key] ??= _Group(
        key,
        targets?.byKey(key)?.label(lang) ?? printed,
      );
    }

    for (final cl in claims) {
      final g = group(cl.target);
      (cl.category == LabelClaimOutCategory.bio ? g.bio : g.chemical).add(cl);
    }
    for (final b in blocked) {
      group(b.target).blocked.add(b);
    }

    final wanted = widget.target;
    final shown = wanted == null ? groups.values.toList() : [?groups[wanted]];
    final wantedName = wanted == null
        ? null
        : targets?.byKey(wanted)?.label(lang) ?? wanted;
    final sources = {for (final cl in claims) cl.sourceTitle}.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.labelInfoTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BmSpace.lg,
              BmSpace.xs,
              BmSpace.lg,
              BmSpace.xs,
            ),
            child: DecoratedBox(
              key: const Key('label-banner'),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.warnBg),
                border: Border.all(color: c.warnBorder, width: 1.5),
                borderRadius: BorderRadius.circular(BmRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(BmSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: c.warnTitle),
                    const SizedBox(width: BmSpace.sm),
                    Expanded(
                      child: Text(
                        t.labelInfoBanner,
                        style: BmType.bodyStrong.copyWith(color: c.warnBody),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                InfoNote(
                  t.labelReadNote,
                  key: const Key('label-read-note'),
                  style: BmType.bodyStrong,
                ),
                if (widget.plotId == null)
                  _CropChoice(
                    crop: crop,
                    onPick: (v) => setState(() => _picked = v),
                  ),
                if (cached != null)
                  Text(
                    t.labelInfoUpdated(
                      formatDate(cached.savedAt.toLocal(), lang),
                    ),
                    style: BmType.meta,
                  ),
                if (wantedName != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.md),
                    child: Text(
                      wantedName,
                      key: const Key('label-target-heading'),
                      style: BmType.section.copyWith(color: c.brand),
                    ),
                  ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: BmSpace.xs),
                      child: EmptyNote(
                        t.labelInfoNoClaim(wantedName),
                        key: const Key('label-no-claim'),
                      ),
                    ),
                ] else if (shown.isEmpty)
                  EmptyNote(t.labelInfoEmpty),
                for (final g in shown) ...[
                  if (wanted == null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: BmSpace.md,
                        bottom: BmSpace.xs,
                      ),
                      child: Text(
                        g.name,
                        key: Key('label-group-${g.key}'),
                        style: BmType.section.copyWith(color: c.brand),
                      ),
                    ),
                  if (g.chemical.isNotEmpty) ...[
                    _SubHeading(t.labelInfoChemical),
                    for (final cl in g.chemical)
                      _ClaimCard(claim: cl, lang: lang),
                  ],
                  if (g.bio.isNotEmpty) ...[
                    _SubHeading(t.labelInfoBio, key: Key('label-bio-${g.key}')),
                    for (final cl in g.bio) _ClaimCard(claim: cl, lang: lang),
                  ],
                  for (final b in g.blocked) _BlockedCard(row: b),
                ],
                if (wanted != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('label-all-targets'),
                      onPressed: () => context.pushReplacement(
                        Routes.labelsFor(
                          plotId: widget.plotId,
                          crop: widget.plotId == null ? crop : null,
                        ),
                      ),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: Text(t.labelInfoAllTargets),
                    ),
                  ),
                const SizedBox(height: BmSpace.md),
                GeneralInfoNote(
                  source: sources.isEmpty ? null : sources.join('; '),
                  checked: cached == null
                      ? null
                      : formatDate(cached.savedAt.toLocal(), lang),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Santra / mosambi switch when the screen is not opened for one block.
class _CropChoice extends ConsumerWidget {
  const _CropChoice({required this.crop, required this.onPick});

  final String? crop;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final crops = ref.watch(cropsProvider).value ?? const [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
      child: Wrap(
        spacing: BmSpace.xs,
        children: [
          for (final o in crops)
            ChoiceChip(
              key: Key('label-crop-${o.slug}'),
              label: Text(o.label(lang)),
              selected: o.slug == crop,
              onSelected: (_) => onPick(o.slug),
            ),
        ],
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BmSpace.xs, bottom: BmSpace.xs),
    child: Text(
      text,
      style: BmType.label.copyWith(color: context.bm.brandStrong),
    ),
  );
}

class _ClaimCard extends ConsumerWidget {
  const _ClaimCard({required this.claim, required this.lang});

  final LabelClaimOut claim;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final meta = BmType.meta.copyWith(color: c.inkMuted);
    final strong = BmType.bodyStrong.copyWith(
      color: c.ink,
      fontWeight: FontWeight.w700,
    );
    String n(int v) => formatInt(v, lang);
    final maker = claim.makerUrl;
    final brands = claim.brandNames ?? const <String>[];
    final photo = claim.photoUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: BmCard(
        elevated: false,
        radius: BmRadius.card,
        padding: const EdgeInsets.all(BmSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${claim.activeIngredient} ${claim.formulation}',
              style: BmType.bodyStrong.copyWith(color: c.ink),
            ),
            const SizedBox(height: BmSpace.xxs),
            Wrap(
              spacing: BmSpace.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t.labelInfoDose, style: meta),
                Text(claim.dose, key: const Key('label-dose'), style: strong),
              ],
            ),
            if (claim.dilution case final d?)
              Text(
                t.labelInfoDilution(d),
                key: const Key('label-dilution'),
                style: strong,
              ),
            if (claim.phiDays != null)
              Text(t.labelInfoPhi(n(claim.phiDays!)), style: BmType.body),
            if (claim.intervalDays != null)
              Text(t.labelInfoInterval(n(claim.intervalDays!)), style: meta),
            if (claim.maxSprays != null)
              Text(t.labelInfoMaxSprays(n(claim.maxSprays!)), style: meta),
            if (claim.description case final d?) ...[
              const SizedBox(height: BmSpace.xxs),
              Text(d, style: BmType.body),
            ],
            if (brands.isNotEmpty)
              Text(
                t.labelInfoBrands(brands.join(', ')),
                key: const Key('label-brands'),
                style: meta,
              ),
            if (photo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
                child: Image.network(
                  photo,
                  height: 120,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Text(t.labelInfoTargetPrinted(claim.target), style: meta),
            Text(t.labelInfoCrop(claim.labelCrop), style: meta),
            Text(t.labelInfoSource(claim.sourceTitle), style: meta),
            if (claim.pageRef case final p?)
              Text(t.labelInfoPage(p), style: meta),
            SelectableText(claim.sourceUrl, style: meta),
            if (maker != null)
              TextButton.icon(
                key: const Key('label-maker-page'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => ref.read(urlOpenerProvider)(Uri.parse(maker)),
                icon: const Icon(Icons.open_in_new),
                label: Text(t.labelInfoMakerPage),
              ),
          ],
        ),
      ),
    );
  }
}

/// A banned or crop-restricted label row: red, no dose.
class _BlockedCard extends StatelessWidget {
  const _BlockedCard({required this.row});

  final BlockedClaimOut row;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final banned = row.reason == BlockedClaimOutReason.banned;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: DecoratedBox(
        key: Key('label-blocked-${row.activeIngredient}'),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.08),
          border: Border.all(color: c.danger, width: 1.5),
          borderRadius: BorderRadius.circular(BmRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, color: c.danger),
                  const SizedBox(width: BmSpace.xs),
                  Expanded(
                    child: Text(
                      banned ? t.labelInfoBanned : t.labelInfoRestricted,
                      style: BmType.bodyStrong.copyWith(color: c.danger),
                    ),
                  ),
                ],
              ),
              Text(
                '${row.activeIngredient} ${row.formulation}',
                style: BmType.bodyStrong.copyWith(color: c.danger),
              ),
              Text(
                t.labelInfoTargetPrinted(row.target),
                style: BmType.meta.copyWith(color: c.danger),
              ),
              if (row.notification.isNotEmpty)
                Text(
                  row.notification,
                  style: BmType.meta.copyWith(color: c.danger),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Buttons that open the label screen for the given target keys (practice cards, scouting
/// records, look-alike cards). Nothing shown while the key list is empty.
class LabelInfoLinks extends ConsumerWidget {
  const LabelInfoLinks({
    required this.keys,
    this.plotId,
    this.idPrefix = 'label-link',
    super.key,
  });

  final List<String> keys;
  final String? plotId;
  final String idPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final targets = ref.watch(labelTargetsProvider).value;
    if (targets == null || keys.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: BmSpace.xs,
      runSpacing: BmSpace.xs,
      children: [
        for (final k in keys)
          if (targets.byKey(k) case final LabelTarget target)
            OutlinedButton.icon(
              key: Key('$idPrefix-$k'),
              onPressed: () =>
                  context.push(Routes.labelsFor(plotId: plotId, target: k)),
              icon: Icon(Icons.menu_book_outlined, color: c.brand),
              label: Text(t.labelInfoOpenFor(target.label(lang))),
            ),
      ],
    );
  }
}
