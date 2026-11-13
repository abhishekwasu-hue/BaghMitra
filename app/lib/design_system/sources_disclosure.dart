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
/// flow (owner: "hide the sources; whoever wants them taps and sees them"; 2026-11-13: an
/// on / off button for the source links, everywhere in the app). Collapsed it is one 48 dp
/// header, "स्रोत (३)" in green bold with a chevron; one tap shows every source: [notes]
/// (free-text citations such as page references), each [sources] entry with its publisher,
/// date read and link, the screen's own [links] (link cards that keep their tap action) and
/// the evidence [kinds]; a second tap folds them again. Nothing is removed, only folded.
/// Open or closed is per view: it starts closed each time the screen is built.
class SourcesDisclosure extends StatefulWidget {
  const SourcesDisclosure({
    super.key,
    this.sources = const [],
    this.notes = const [],
    this.links = const [],
    this.kinds = const [],
    this.initiallyExpanded = false,
  });

  final List<SourceRef> sources;
  final List<String> notes;

  /// Link cards built by the screen (e.g. a chip that copies its link), each one source.
  final List<Widget> links;

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
    final count = w.sources.length + w.links.length;
    if (count == 0 && w.notes.isEmpty && w.kinds.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final quiet = BmType.meta.copyWith(color: c.inkMuted);
    final label = count == 0
        ? t.sourcesTitle
        : t.sourcesTitleCount(
            formatInt(count, Localizations.localeOf(context).languageCode),
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
          hint: _open ? t.sourcesHide : t.sourcesShow,
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
                  Icon(Icons.link_rounded, size: 20, color: c.link),
                  const SizedBox(width: BmSpace.xxs),
                  Flexible(
                    child: Text(
                      label,
                      style: BmType.bodyStrong.copyWith(
                        color: c.link,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: BmSpace.xxs),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 26,
                    color: c.link,
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
                for (final link in w.links)
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xs),
                    child: link,
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
