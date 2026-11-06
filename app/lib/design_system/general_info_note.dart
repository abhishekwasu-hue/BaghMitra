import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'info_note.dart';

/// The one shared mark for content gathered from public sources before an expert review
/// (owner decision Q57): "General information from public sources…", plus the source and the
/// date it was checked when known. Built on [InfoNote], so it uses the info colour, never the
/// action orange.
class GeneralInfoNote extends StatelessWidget {
  const GeneralInfoNote({super.key, this.source, this.checked});

  /// A short source name, e.g. "ICAR-CCRI Nagpur".
  final String? source;

  /// When the source was last read, already formatted for the reader's language.
  final String? checked;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final src = source;
    final lines = [
      t.generalInfoNote,
      if (src != null && src.isNotEmpty)
        t.generalInfoSource(
          src,
          checked == null || checked!.isEmpty ? '–' : checked!,
        ),
    ];
    return InfoNote(lines.join('\n'));
  }
}
