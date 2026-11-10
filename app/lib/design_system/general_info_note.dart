import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'sources_disclosure.dart';

/// The sources of content gathered from public sources, folded into one [SourcesDisclosure]
/// line (owner: sources stay one tap away, out of the reading flow).
///
/// Owner decision 2026-11-10 replaces Q57's mark: the AI checks the content against the
/// official sources (Q128) and every practice card has been checked, so the old "General
/// information · confirm with your KVK first" line is no longer shown anywhere. With a
/// [source] this shows only the folded sources; without one it shows nothing.
class GeneralInfoNote extends StatelessWidget {
  const GeneralInfoNote({super.key, this.source, this.checked});

  /// A short source name, e.g. "ICAR-CCRI Nagpur".
  final String? source;

  /// When the source was last read, already formatted for the reader's language.
  final String? checked;

  @override
  Widget build(BuildContext context) {
    final src = source;
    if (src == null || src.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final date = checked;
    return SourcesDisclosure(
      notes: [
        t.generalInfoSource(src, date == null || date.isEmpty ? '–' : date),
      ],
    );
  }
}
