import 'package:flutter/material.dart';

import '../core/kb_terms.dart';
import '../theme/app_theme.dart';

/// Article reading (owner 2026-11-12: "multi colour, highlight the important words, not
/// just text dumped on the page"): every section is a card with a coloured header strip and
/// a round icon chip chosen from the heading's meaning; numbers with units and the names of
/// crops, pests, diseases and stages are marked in the app, so existing articles read the
/// same way; a long paragraph that splits cleanly becomes a bullet list. The server text is
/// never changed: only how it is drawn.

/// What a section heading is about. The keyword map decides the icon and the tone.
enum ArticleSectionKind { see, when, check, act, caution, sources, other }

// Checked in this order: "KVK ला केव्हा विचारावे" is a caution / ask line, not a date.
final _kindWords = <(ArticleSectionKind, RegExp)>[
  (
    ArticleSectionKind.sources,
    RegExp(r'स्रोत|संदर्भ|source', caseSensitive: false),
  ),
  (
    ArticleSectionKind.caution,
    RegExp(
      r'सावध|काळजी|विचार|तज्ज्ञ|KVK|सावधानी|सतर्क|विशेषज्ञ|पूछ|caution|careful|'
      r'\bcare\b|warning|expert|\bask\b',
      caseSensitive: false,
    ),
  ),
  (
    ArticleSectionKind.check,
    RegExp(
      r'तपास|पाहणी|जाँच|निगरानी|check|scout|monitor',
      caseSensitive: false,
    ),
  ),
  (
    ArticleSectionKind.act,
    RegExp(
      r'करावे|उपाय|व्यवस्थापन|नियंत्रण|करें|प्रबंधन|what to do|\bdo\b|manage|'
      r'control|action|steps',
      caseSensitive: false,
    ),
  ),
  (
    ArticleSectionKind.see,
    RegExp(
      r'दिसते|दिसतात|लक्षण|ओळख|दिखता|दिखते|पहचान|what you see|symptom|\bsigns?\b',
      caseSensitive: false,
    ),
  ),
  (
    ArticleSectionKind.when,
    RegExp(
      r'कधी|केव्हा|हंगाम|कब|मौसम|\bwhen\b|season|timing',
      caseSensitive: false,
    ),
  ),
];

ArticleSectionKind sectionKindFor(String heading) {
  for (final (kind, words) in _kindWords) {
    if (words.hasMatch(heading)) return kind;
  }
  return ArticleSectionKind.other;
}

IconData sectionIcon(ArticleSectionKind kind) => switch (kind) {
  ArticleSectionKind.see => Icons.visibility_rounded,
  ArticleSectionKind.when => Icons.event_rounded,
  ArticleSectionKind.check => Icons.search_rounded,
  ArticleSectionKind.act => Icons.check_circle_rounded,
  ArticleSectionKind.caution => Icons.info_rounded,
  ArticleSectionKind.sources => Icons.link_rounded,
  ArticleSectionKind.other => Icons.lightbulb_rounded,
};

/// The tone of a section: by meaning, or for an unknown heading the [otherIndex]-th colour
/// of a rotating palette, so neighbouring cards still differ.
BmTone sectionTone(BmColors c, ArticleSectionKind kind, {int otherIndex = 0}) =>
    switch (kind) {
      ArticleSectionKind.see => c.toneAmber,
      ArticleSectionKind.when => c.toneBlue,
      ArticleSectionKind.check => c.toneTeal,
      ArticleSectionKind.act => c.toneGreen,
      ArticleSectionKind.caution => c.toneViolet,
      ArticleSectionKind.sources => c.toneGrey,
      ArticleSectionKind.other => [
        c.toneBlue,
        c.toneTeal,
        c.toneViolet,
        c.toneAmber,
        c.toneGreen,
      ][otherIndex % 5],
    };

/// Highlights per paragraph: enough to guide the eye, few enough to stay readable.
const maxMarksPerParagraph = 4;

enum ReadingMarkKind { number, term }

typedef ReadingMark = ({int start, int end, ReadingMarkKind kind});

const _digit = '[0-9०-९]';
const _devanagariUnits =
    'मीटर|सेमी|मिमी|किमी|किलो|किग्रॅ|किग्रा|ग्रॅम|ग्राम|लिटर|लीटर|मिली|दिवस|दिन|'
    'आठवड|हफ्त|सप्ताह|महिन|महीन|तास|घंट|फूट|फुट|हेक्टर|एकर|टक्के|प्रतिशत|झाड|पेड़';
const _latinUnits =
    'cm|mm|km|kg|ml|m|g|l|litres?|days?|weeks?|months?|hours?|hectares?|ha|'
    'acres?|trees?|farmers?|per ?cent';

const _months =
    'जानेवारी|फेब्रुवारी|मार्च|एप्रिल|मे|जून|जुलै|ऑगस्ट|सप्टेंबर|ऑक्टोबर|'
    'नोव्हेंबर|डिसेंबर|जनवरी|फ़रवरी|फरवरी|अप्रैल|मई|जुलाई|अगस्त|सितंबर|'
    'अक्टूबर|नवंबर|दिसंबर|January|February|March|April|May|June|July|August|'
    'September|October|November|December';

/// A number, a range or a rupee amount, with the unit that follows it; a date
/// ("३० नोव्हेंबर २०२६") is one mark.
final _numberPattern = RegExp(
  '(?:₹\\s?)?$_digit+(?:[.,]$_digit+)*(?:\\s?[–-]\\s?$_digit+(?:[.,]$_digit+)*)?'
  '(?:\\s(?:$_months)(?![\\p{L}\\p{M}])(?:,?\\s$_digit{4})?|'
  '\\s?(?:%|°\\s?C|(?:$_devanagariUnits)[\\p{L}\\p{M}]*|'
  '(?:$_latinUnits)(?![\\p{L}])))?',
  unicode: true,
  caseSensitive: false,
);

final _termPattern = () {
  final terms = [...kbTerms]..sort((a, b) => b.length.compareTo(a.length));
  final alternatives = terms.map(RegExp.escape).join('|');
  // A term at the start of a word, with its Marathi / Hindi ending (सायलाच्या).
  return RegExp(
    '(?<![\\p{L}\\p{M}])($alternatives)[\\p{L}\\p{M}]*',
    unicode: true,
    caseSensitive: false,
  );
}();

/// The marks of one paragraph, in reading order: numbers with units and KB names, each
/// name only the first time, at most [cap].
List<ReadingMark> findMarks(String text, {int cap = maxMarksPerParagraph}) {
  // Each candidate with the key that makes it "the same name" (the term without ending).
  final all = <(ReadingMark, String)>[
    for (final m in _numberPattern.allMatches(text))
      ((start: m.start, end: m.end, kind: ReadingMarkKind.number), ''),
    for (final m in _termPattern.allMatches(text))
      (
        (start: m.start, end: m.end, kind: ReadingMarkKind.term),
        m.group(1)!.toLowerCase(),
      ),
  ]..sort((a, b) => a.$1.start.compareTo(b.$1.start));
  final marks = <ReadingMark>[];
  final seen = <String>{};
  for (final (m, name) in all) {
    if (marks.length == cap) break;
    if (marks.isNotEmpty && m.start < marks.last.end) continue;
    if (m.kind == ReadingMarkKind.term && !seen.add(name)) continue;
    // Trailing spaces (a number before a word that is not a unit) stay plain text.
    final end = m.start + text.substring(m.start, m.end).trimRight().length;
    marks.add((start: m.start, end: end, kind: m.kind));
  }
  return marks;
}

/// Sentences are split after "." , ";" or "।" followed by a space; not after a decimal
/// point or a short abbreviation (Dr., डॉ., उदा.).
final _sentenceEnd = RegExp(r'(?<=[.;।])\s+');
final _abbreviation = RegExp(
  r'(?:^|\s)(?:Dr|Mr|Mrs|No|e\.g|i\.e|डॉ|उदा|इ|क्र|सं)\.$',
  caseSensitive: false,
);

/// A paragraph of more than two sentences, as bullets; any other paragraph unchanged
/// (one item). A clean split only: every piece is a real sentence. The text is kept as
/// written, but a ";" that ended a piece is dropped.
List<String> splitBullets(String paragraph) {
  final text = paragraph.trim();
  final raw = text.split(_sentenceEnd);
  final pieces = <String>[];
  for (final part in raw) {
    if (pieces.isNotEmpty && _abbreviation.hasMatch(pieces.last)) {
      pieces[pieces.length - 1] = '${pieces.last} $part';
    } else {
      pieces.add(part);
    }
  }
  if (pieces.length < 3) return [text];
  final cleaned = [
    for (final p in pieces) p.endsWith(';') ? p.substring(0, p.length - 1) : p,
  ];
  if (cleaned.any((p) => p.trim().length < 8)) return [text];
  return cleaned;
}

/// A paragraph with its marks: numbers bold on a soft tinted pill, KB names bold in the
/// [tone] ink. [text] is the plain text, for tests and screen readers.
class HighlightedText extends StatelessWidget {
  const HighlightedText(this.text, {super.key, required this.tone, this.style});

  final String text;
  final BmTone tone;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final base = (style ?? BmType.body).copyWith(color: style?.color ?? c.ink);
    final marks = findMarks(text);
    if (marks.isEmpty) return Text(text, style: base);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in marks) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      final part = text.substring(m.start, m.end);
      spans.add(switch (m.kind) {
        ReadingMarkKind.term => TextSpan(
          text: part,
          style: TextStyle(color: tone.ink, fontWeight: FontWeight.w700),
        ),
        ReadingMarkKind.number => WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: tone.tint,
              border: Border.all(color: tone.ink.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(BmRadius.pill),
            ),
            // The span already scales with the text size: no second scaling here.
            child: Text(
              part,
              textScaler: TextScaler.noScaling,
              style: base.copyWith(fontWeight: FontWeight.w700, height: 1.2),
            ),
          ),
        ),
      });
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text.rich(TextSpan(style: base, children: spans)),
    );
  }
}

/// A paragraph as bullets when it splits cleanly ([splitBullets]), each highlighted.
class ReadingParagraph extends StatelessWidget {
  const ReadingParagraph(this.text, {super.key, required this.tone});

  final String text;
  final BmTone tone;

  @override
  Widget build(BuildContext context) {
    final pieces = splitBullets(text);
    if (pieces.length == 1) return HighlightedText(text, tone: tone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, p) in pieces.indexed)
          ReadingBullet(
            key: key == null ? null : ValueKey('$key-$i'),
            text: p,
            tone: tone,
          ),
      ],
    );
  }
}

/// One bullet line: a dot in the tone ink and the highlighted text.
class ReadingBullet extends StatelessWidget {
  const ReadingBullet({super.key, required this.text, required this.tone});

  final String text;
  final BmTone tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BmSpace.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: BmSpace.xs),
          child: Icon(Icons.circle, size: 8, color: tone.ink),
        ),
        Expanded(child: HighlightedText(text, tone: tone)),
      ],
    ),
  );
}

/// A round icon chip: the tone ink filled circle with the icon in the card colour.
class ToneIconChip extends StatelessWidget {
  const ToneIconChip({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 36,
  });

  final IconData icon;
  final BmTone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: tone.ink, shape: BoxShape.circle),
    child: Icon(icon, size: size * 0.58, color: context.bm.card),
  );
}

/// A card for one part of an article: a tinted header strip with the icon chip and a
/// medium-size heading in the tone ink, then [child] on the card.
class ReadingCard extends StatelessWidget {
  const ReadingCard({
    super.key,
    required this.heading,
    required this.icon,
    required this.tone,
    required this.child,
  });

  final String heading;
  final IconData icon;
  final BmTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: tone.ink.withValues(alpha: 0.45), width: 1.5),
        borderRadius: BorderRadius.circular(BmRadius.tile),
        boxShadow: BmElevation.tile(c),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tone.tint,
            padding: const EdgeInsets.symmetric(
              horizontal: BmSpace.sm,
              vertical: BmSpace.xs,
            ),
            child: Row(
              children: [
                ToneIconChip(icon: icon, tone: tone),
                const SizedBox(width: BmSpace.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      heading,
                      style: BmType.alertTitle.copyWith(
                        fontSize: 19,
                        color: tone.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(BmSpace.md), child: child),
        ],
      ),
    );
  }
}

/// One article section ([heading] and [body]) as a [ReadingCard] chosen by meaning.
class ArticleSectionCard extends StatelessWidget {
  const ArticleSectionCard({
    super.key,
    required this.heading,
    required this.body,
    this.otherIndex = 0,
  });

  final String heading;
  final String body;

  /// The place of this section among the ones with no known meaning (rotating colour).
  final int otherIndex;

  @override
  Widget build(BuildContext context) {
    final kind = sectionKindFor(heading);
    final tone = sectionTone(context.bm, kind, otherIndex: otherIndex);
    return ReadingCard(
      heading: heading,
      icon: sectionIcon(kind),
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, para) in body.split(RegExp(r'\n\s*\n')).indexed)
            if (para.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : BmSpace.xs),
                child: ReadingParagraph(para.trim(), tone: tone),
              ),
        ],
      ),
    );
  }
}

/// A small rounded badge: an icon and a short line in a tone (the "written from checked
/// sources" line of an article).
class ReadingBadge extends StatelessWidget {
  const ReadingBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final BmTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: BmSpace.sm,
      vertical: BmSpace.xxs,
    ),
    decoration: BoxDecoration(
      color: tone.tint,
      border: Border.all(color: tone.ink.withValues(alpha: 0.45)),
      borderRadius: BorderRadius.circular(BmRadius.chip),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: tone.ink),
        ),
        const SizedBox(width: BmSpace.xxs),
        Expanded(
          child: Text(text, style: BmType.meta.copyWith(color: tone.ink)),
        ),
      ],
    ),
  );
}

/// A compact source chip: link icon, title and site, at least 48 dp tall. [onTap] copies
/// the link where the screen allows it; without it the chip is plain (selectable) text.
class SourceChip extends StatelessWidget {
  const SourceChip({
    super.key,
    required this.title,
    required this.url,
    this.onTap,
    this.hint,
  });

  final String title;
  final String url;
  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final tone = c.toneGrey;
    final host = Uri.tryParse(url)?.host;
    final label = '$title\n${host == null || host.isEmpty ? url : host}';
    final linked = onTap != null;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BmSpace.sm,
          vertical: BmSpace.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.link_rounded,
              size: 18,
              color: linked ? c.link : tone.ink,
            ),
            const SizedBox(width: BmSpace.xs),
            Expanded(
              child: linked
                  ? Text(
                      label,
                      style: BmType.meta.copyWith(
                        color: c.link,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: c.link,
                      ),
                    )
                  : SelectableText(
                      label,
                      style: BmType.meta.copyWith(color: c.ink),
                    ),
            ),
          ],
        ),
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BmRadius.chip),
      side: BorderSide(color: tone.ink.withValues(alpha: 0.35)),
    );
    return Material(
      color: tone.tint,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: linked
          ? Semantics(
              button: true,
              hint: hint,
              child: InkWell(onTap: onTap, child: body),
            )
          : body,
    );
  }
}
