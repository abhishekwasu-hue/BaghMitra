import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../theme/app_theme.dart';

/// Optional "which bahar was this for?" choice shared by the record entry screens.
class CycleChips extends ConsumerWidget {
  const CycleChips({
    required this.plotId,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String plotId;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final cycles = ref.watch(baharCyclesProvider(plotId)).value ?? const [];
    final bahars = ref.watch(baharOptionsProvider).value;
    if (cycles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: BmSpace.md),
      child: Wrap(
        spacing: BmSpace.xs,
        children: [
          for (final cy in cycles)
            ChoiceChip(
              label: Text(
                '${bahars?.baharLabel(cy.bahar, lang) ?? cy.bahar} '
                '${formatYear(cy.seasonYear, lang)}',
              ),
              selected: selected == cy.id,
              onSelected: (on) => onChanged(on ? cy.id : null),
            ),
        ],
      ),
    );
  }
}
