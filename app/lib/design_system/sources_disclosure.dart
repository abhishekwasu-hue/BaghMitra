import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// One source behind a piece of content: its title, and when known its link, publisher and
/// the date it was read (already formatted for the reader's language).
class SourceRef {
  const SourceRef(this.title, {this.url, this.publisher, this.checked});

  final String title;
  final String? url;
  final String? publisher;
  final String? checked;
}

/// The sources behind a piece of content, folded away so they do not break the reading
/// flow (owner request: "hide the sources; whoever wants them taps and sees them"). Collapsed
/// it is one quiet 48 dp line, "Sources (3)"; one tap shows every source as before: [notes]
/// (free-text citations such as page references), each [sources] entry with its publisher,
/// date read and link, and the evidence [kinds]. Nothing is removed, only folded.
class SourcesDisclosure extends StatefulWidget {
  const SourcesDisclosure({
    super.key,
    this.sources = const [],
    this.notes = const [],
    this.kinds = const [],
    this.initiallyExpanded = false,
  });

  final List<SourceRef> sources;
  final List<String> notes;

  /// Evidence levels already in the reader's language ("Official", "University" …).
  final List<String> kinds;

  final bool initiallyExpanded;

  @override
  State<SourcesDisclosure> createState() => _SourcesDisclosureState();
}

class _SourcesDisclosureState extends State<SourcesDisclosure> {
  late bool _open = widget.initiallyExpanded;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final w = widget;
    if (w.sources.isEmpty && w.notes.isEmpty && w.kinds.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final quiet = BmType.meta.copyWith(color: c.inkMuted);
    final label = _open
        ? t.sourcesHide
        : w.sources.isEmpty
        ? t.sourcesShow
        : t.sourcesShowCount(
            formatInt(
              w.sources.length,
              Localizations.localeOf(context).languageCode,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          key: const Key('sources-toggle'),
          button: true,
          expanded: _open,
          label: label,
          excludeSemantics: true,
          onTap: _toggle,
          child: InkWell(
            borderRadius: BorderRadius.circular(BmRadius.chip),
            onTap: _toggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: BmSpace.tapTarget,
                minWidth: BmSpace.tapTarget,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: BmSpace.md,
                    color: c.inkMuted,
                  ),
                  const SizedBox(width: BmSpace.xxs),
                  Flexible(child: Text(label, style: quiet)),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: BmSpace.lg,
                    color: c.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            key: const Key('sources-list'),
            padding: const EdgeInsets.only(bottom: BmSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in w.notes) Text(n, style: quiet),
                for (final s in w.sources)
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xxs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: BmType.meta),
                        if ([
                              ?s.publisher,
                              if (s.checked case final d?) t.sourcesChecked(d),
                            ]
                            case final meta when meta.isNotEmpty)
                          Text(meta.join(' · '), style: quiet),
                        if (s.url case final url? when url.isNotEmpty)
                          Text(
                            url,
                            style: BmType.meta.copyWith(color: c.brandStrong),
                          ),
                      ],
                    ),
                  ),
                if (w.kinds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xxs),
                    child: Wrap(
                      spacing: BmSpace.xs,
                      children: [
                        for (final k in w.kinds)
                          Text(k, style: BmType.meta.copyWith(color: c.brand)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
