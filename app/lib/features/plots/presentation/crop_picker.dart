import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/crop_catalog.dart';

/// The block form's crop choice (owner 2026-11-14): santra and mosambi as the two big
/// choices; below them the green "other crops" button opens the list of every other crop,
/// in its sections (fruit, field crops, vegetables, flowers, other).
class CropPicker extends StatefulWidget {
  const CropPicker({
    required this.catalog,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CropCatalogData catalog;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  State<CropPicker> createState() => _CropPickerState();
}

class _CropPickerState extends State<CropPicker> {
  bool? _open;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final crops = widget.catalog.crops;
    final primary = [
      for (final o in crops)
        if (o.primary) o,
    ];
    final picked = crops.where((o) => o.slug == widget.selected).firstOrNull;
    final otherPicked = picked != null && !picked.primary;
    // A block already on another crop opens with the list shown.
    final open = _open ?? otherPicked;
    final sections = [
      for (final g in widget.catalog.categories)
        (
          g,
          [
            for (final o in crops)
              if (!o.primary && o.category == g.key) o,
          ],
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, o) in primary.indexed) ...[
                if (i > 0) const SizedBox(width: BmSpace.sm),
                Expanded(
                  child: _BigChoice(
                    key: Key('crop-${o.slug}'),
                    label: o.label(lang),
                    selected: o.slug == widget.selected,
                    onTap: () => widget.onSelected(o.slug),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: BmSpace.sm),
        FilledButton.icon(
          key: const Key('other-crops'),
          style: BmButtonStyle.primary(c),
          onPressed: () => setState(() => _open = !open),
          icon: Icon(
            open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          label: Text(
            otherPicked
                ? '${t.plotOtherCrops}: ${picked.label(lang)}'
                : t.plotOtherCrops,
            textAlign: TextAlign.center,
          ),
        ),
        if (open)
          for (final (g, list) in sections)
            if (list.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: BmSpace.md,
                  bottom: BmSpace.xs,
                ),
                child: Text(
                  g.label(lang),
                  style: BmType.label.copyWith(color: c.brandStrong),
                ),
              ),
              Wrap(
                spacing: BmSpace.xs,
                runSpacing: BmSpace.xs,
                children: [
                  for (final o in list)
                    ChoiceChip(
                      key: Key('crop-${o.slug}'),
                      label: Text(o.label(lang), style: BmType.bodyStrong),
                      selected: o.slug == widget.selected,
                      onSelected: (_) => widget.onSelected(o.slug),
                    ),
                ],
              ),
            ],
      ],
    );
  }
}

/// One of the two big crop choices: filled when picked, with a tick.
class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final fg = selected ? c.onAccent : c.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.accent : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BmRadius.tile),
          side: BorderSide(color: selected ? c.accent : c.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BmSpace.tapTarget + 16,
            ),
            child: Padding(
              padding: const EdgeInsets.all(BmSpace.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_circle_rounded, color: fg, size: 22),
                    const SizedBox(width: BmSpace.xs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: BmType.section.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
