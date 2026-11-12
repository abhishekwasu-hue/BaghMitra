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
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart';
import '../data/label_targets.dart';

/// What CIB&RC registered labels say for a crop, grouped by pest / disease, chemical and
/// 🌿 bio apart (owner decision Q57). Label information only, never a recommendation: one
/// notice at the top (not a recommendation, read the pack label, the source documents), then
/// a compact tile per row (product, dose in bold, PHI); a tap opens every field exactly as
/// the API gives it (dose and dilution in bold) in a sheet. Brand names are a plain
/// alphabetical list, banned or restricted rows are red and carry no dose, and nothing is
/// added by the app.
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.xs,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          _LabelNotice(sources: sources),
          if (widget.plotId == null)
            _CropChoice(crop: crop, onPick: (v) => setState(() => _picked = v)),
          if (cached != null)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xs),
              child: Text(
                t.labelInfoUpdated(formatDate(cached.savedAt.toLocal(), lang)),
                style: BmType.meta,
              ),
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
                _ClaimTile(id: claims.indexOf(cl), claim: cl, lang: lang),
            ],
            if (g.bio.isNotEmpty) ...[
              _SubHeading(t.labelInfoBio, key: Key('label-bio-${g.key}')),
              for (final cl in g.bio)
                _ClaimTile(id: claims.indexOf(cl), claim: cl, lang: lang),
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

/// A dilution cell that is only a number or a range ("750", "750-1000").
final _bareLitres = RegExp(r'^\d+(\.\d+)?(\s*[-–]\s*\d+(\.\d+)?)?$');

/// The one notice on the screen (owner, label UX): what CIB&RC label information is (not a
/// recommendation, check with the KVK), read the pack label, and the source documents once.
/// Owner 2026-11-10: small, muted text, with no coloured box, border or icons.
class _LabelNotice extends StatelessWidget {
  const _LabelNotice({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final note = BmType.meta.copyWith(color: c.inkMuted);
    return Column(
      key: const Key('label-banner'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.labelInfoBanner, style: note),
        const SizedBox(height: BmSpace.xxs),
        Text(t.labelReadNote, key: const Key('label-read-note'), style: note),
        if (sources.isNotEmpty)
          ExpansionTile(
            key: const Key('label-sources'),
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: BmSpace.xs),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            iconColor: c.inkMuted,
            collapsedIconColor: c.inkMuted,
            title: Text(
              t.labelInfoSources(
                formatInt(
                  sources.length,
                  Localizations.localeOf(context).languageCode,
                ),
              ),
              style: note,
            ),
            children: [
              for (final s in sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: BmSpace.xxs),
                  child: Text('• $s', style: note),
                ),
            ],
          )
        else
          const SizedBox(height: BmSpace.xs),
      ],
    );
  }
}

/// One label row in the list: product large, the dose in bold right below, PHI as a chip.
/// Tapping it opens every field of the row in [showLabelClaimDetails].
class _ClaimTile extends StatelessWidget {
  const _ClaimTile({required this.id, required this.claim, required this.lang});

  final int id;
  final LabelClaimOut claim;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final phi = claim.phiDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: BmCard(
        elevated: false,
        radius: BmRadius.card,
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: Semantics(
            button: true,
            hint: t.labelInfoOpenDetails,
            child: InkWell(
              key: Key('label-row-$id'),
              borderRadius: BorderRadius.circular(BmRadius.card),
              onTap: () => showLabelClaimDetails(context, id, claim, lang),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BmSpace.md,
                    BmSpace.sm,
                    BmSpace.xs,
                    BmSpace.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product(claim),
                              style: BmType.alertTitle.copyWith(color: c.ink),
                            ),
                            const SizedBox(height: BmSpace.xxs),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${t.labelInfoDose} ',
                                    style: BmType.meta.copyWith(
                                      color: c.inkMuted,
                                    ),
                                  ),
                                  TextSpan(text: claim.dose, style: _strong(c)),
                                ],
                              ),
                              key: Key('label-row-dose-$id'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (phi != null) ...[
                              const SizedBox(height: BmSpace.xs),
                              _Chip(t.labelInfoPhi(formatInt(phi, lang))),
                            ],
                          ],
                        ),
                      ),
                      Tooltip(
                        message: t.labelInfoOpenDetails,
                        child: Icon(Icons.chevron_right, color: c.brand),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _product(LabelClaimOut claim) =>
    '${claim.activeIngredient} ${claim.formulation}';

TextStyle _strong(BmColors c) =>
    BmType.bodyStrong.copyWith(color: c.ink, fontWeight: FontWeight.w700);

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.doneTint,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BmSpace.xs,
          vertical: BmSpace.xxs,
        ),
        child: Text(text, style: BmType.label.copyWith(color: c.brandStrong)),
      ),
    );
  }
}

/// Every field of one label row as the API gives it, in a scrollable bottom sheet.
Future<void> showLabelClaimDetails(
  BuildContext context,
  int id,
  LabelClaimOut claim,
  String lang,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    builder: (context, controller) =>
        _ClaimDetails(id: id, claim: claim, lang: lang, controller: controller),
  ),
);

class _ClaimDetails extends ConsumerWidget {
  const _ClaimDetails({
    required this.id,
    required this.claim,
    required this.lang,
    required this.controller,
  });

  final int id;
  final LabelClaimOut claim;
  final String lang;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final meta = BmType.meta.copyWith(color: c.inkMuted);
    final strong = _strong(c);
    String n(int v) => formatInt(v, lang);
    final maker = claim.makerUrl;
    final brands = claim.brandNames ?? const <String>[];
    final photo = claim.photoUrl;
    return ListView(
      key: Key('label-detail-$id'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(BmSpace.lg, 0, BmSpace.lg, BmSpace.xl),
      children: [
        Text(t.labelInfoDetailsTitle, style: BmType.label),
        const SizedBox(height: BmSpace.xxs),
        Text(_product(claim), style: BmType.section.copyWith(color: c.brand)),
        const SizedBox(height: BmSpace.sm),
        Text(t.labelInfoDose, style: meta),
        Text(claim.dose, key: const Key('label-dose'), style: strong),
        if (claim.dilution case final d?) ...[
          const SizedBox(height: BmSpace.xs),
          Text(
            // A bare number sits under the printed heading "Dilution in water (L)" of
            // "Dosage per ha"; a cell with its own unit (per tree, '**') is shown as printed.
            _bareLitres.hasMatch(d)
                ? t.labelInfoDilution(d)
                : t.labelInfoDilutionPrinted(d),
            key: const Key('label-dilution'),
            style: strong,
          ),
        ],
        const SizedBox(height: BmSpace.xs),
        if (claim.phiDays != null)
          Text(t.labelInfoPhi(n(claim.phiDays!)), style: BmType.body),
        if (claim.intervalDays != null)
          Text(t.labelInfoInterval(n(claim.intervalDays!)), style: BmType.body),
        if (claim.maxSprays != null)
          Text(t.labelInfoMaxSprays(n(claim.maxSprays!)), style: BmType.body),
        if (claim.description case final d?) ...[
          const SizedBox(height: BmSpace.xs),
          Text(d, style: BmType.body),
        ],
        if (brands.isNotEmpty) ...[
          const SizedBox(height: BmSpace.xs),
          Text(
            t.labelInfoBrands(brands.join(', ')),
            key: const Key('label-brands'),
            style: BmType.body,
          ),
        ],
        if (photo != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
            child: Image.network(
              photo,
              height: 120,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        if (maker != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('label-maker-page'),
              style: BmButtonStyle.link(c),
              onPressed: () => ref.read(urlOpenerProvider)(Uri.parse(maker)),
              icon: const Icon(Icons.open_in_new),
              label: Text(t.labelInfoMakerPage),
            ),
          ),
        const Divider(height: BmSpace.xl),
        Text(t.labelInfoTargetPrinted(claim.target), style: meta),
        Text(t.labelInfoCrop(claim.labelCrop), style: meta),
        Text(t.labelInfoSource(claim.sourceTitle), style: meta),
        if (claim.pageRef case final p?) Text(t.labelInfoPage(p), style: meta),
        SelectableText(claim.sourceUrl, style: meta),
      ],
    );
  }
}

/// A banned or crop-restricted label row, with no dose. Owner 2026-11-10: calm and factual,
/// in muted text with no red box or block icon.
class _BlockedCard extends StatelessWidget {
  const _BlockedCard({required this.row});

  final BlockedClaimOut row;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final banned = row.reason == BlockedClaimOutReason.banned;
    final meta = BmType.meta.copyWith(color: c.inkMuted);
    return Padding(
      key: Key('label-blocked-${row.activeIngredient}'),
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            banned ? t.labelInfoBanned : t.labelInfoRestricted,
            style: BmType.label.copyWith(color: c.inkMuted),
          ),
          Text(
            '${row.activeIngredient} ${row.formulation}',
            style: BmType.body.copyWith(color: c.inkMuted),
          ),
          Text(t.labelInfoTargetPrinted(row.target), style: meta),
          if (row.notification.isNotEmpty) Text(row.notification, style: meta),
        ],
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
