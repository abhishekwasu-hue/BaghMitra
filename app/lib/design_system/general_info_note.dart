import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'info_note.dart';
import 'sources_disclosure.dart';

/// The one shared mark for content gathered from public sources before an expert review
/// (owner decision Q57): one short "General information · confirm with your KVK first" line,
/// always visible. The source and the date it was checked, when given, fold into a
/// [SourcesDisclosure] under it (owner: sources stay one tap away, out of the reading flow).
/// Built on [InfoNote], so it uses the info colour, never the action orange.
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
    final mark = InfoNote(t.generalInfoMark);
    if (src == null || src.isEmpty) return mark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SourcesDisclosure(
          notes: [
            t.generalInfoSource(
              src,
              checked == null || checked!.isEmpty ? '–' : checked!,
            ),
          ],
        ),
      ],
    );
  }
}
