import 'dart:io';

import 'package:bagmitra/core/kb_terms.dart';
import 'package:bagmitra/design_system/article_reading.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../architecture/ui_guidelines_test.dart' show contrast;

List<String> _marked(String text, {int cap = maxMarksPerParagraph}) => [
  for (final m in findMarks(text, cap: cap)) text.substring(m.start, m.end),
];

void main() {
  group('highlighter', () {
    test('marks numbers with their units, in Marathi and English digits', () {
      expect(
        _marked('सुमारे २ मीटर उंचीवर सापळे लावा (स्रोतानुसार एकरी ३०).'),
        ['२ मीटर', '३०'],
      );
      expect(_marked('Spray within 10 days; ₹6,000 per hectare; 60 %.'), [
        '10 days',
        '₹6,000',
        '60 %',
      ]);
      expect(_marked('१५-२० दिवसांनी पुन्हा तपासा'), ['१५-२० दिवसांनी']);
      // A date is one mark, not a day pill and a year pill.
      expect(_marked('अर्जाची अंतिम मुदत ३० नोव्हेंबर २०२६'), [
        '३० नोव्हेंबर २०२६',
      ]);
    });

    test('marks KB names with their Marathi endings, once each', () {
      expect(
        _marked('सायलाच्या पिल्लांमुळे ग्रीनिंग पसरतो; सायला नवतीवर दिसतो.'),
        ['सायलाच्या', 'ग्रीनिंग', 'नवतीवर'],
      );
      expect(_marked('आंबिया बहार व मृग बहार'), ['आंबिया', 'मृग बहार']);
      // An everyday word is not a stage name.
      expect(_marked('हस्तक्षेप करू नये'), isEmpty);
    });

    test('keeps at most four marks per paragraph', () {
      const text =
          'सायला, कँकर, ग्रीनिंग, डिंक्या आणि फळगळ: ५ झाडे, ३ दिवस, २ मीटर.';
      expect(_marked(text), hasLength(maxMarksPerParagraph));
      expect(_marked(text), ['सायला', 'कँकर', 'ग्रीनिंग', 'डिंक्या']);
      expect(_marked(text, cap: 2), ['सायला', 'कँकर']);
    });

    test('every KB term is a name used in the app cards and config', () {
      final config = [
        for (final f in Directory('assets/config').listSync())
          if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
      ].join('\n').toLowerCase();
      expect([
        for (final term in kbTerms)
          if (!config.contains(term.toLowerCase())) term,
      ], isEmpty);
    });
  });

  group('section icons', () {
    test('the heading meaning picks the icon and the tone', () {
      const c = BmColors.light;
      for (final (heading, kind, icon, tone) in [
        (
          'काय दिसते',
          ArticleSectionKind.see,
          Icons.visibility_rounded,
          c.toneAmber,
        ),
        (
          'लक्षणे',
          ArticleSectionKind.see,
          Icons.visibility_rounded,
          c.toneAmber,
        ),
        ('कधी येतो', ArticleSectionKind.when, Icons.event_rounded, c.toneBlue),
        ('हंगाम', ArticleSectionKind.when, Icons.event_rounded, c.toneBlue),
        (
          'बागेत काय तपासावे',
          ArticleSectionKind.check,
          Icons.search_rounded,
          c.toneTeal,
        ),
        (
          'काय करावे',
          ArticleSectionKind.act,
          Icons.check_circle_rounded,
          c.toneGreen,
        ),
        (
          'उपाय',
          ArticleSectionKind.act,
          Icons.check_circle_rounded,
          c.toneGreen,
        ),
        (
          'सावधगिरी',
          ArticleSectionKind.caution,
          Icons.info_rounded,
          c.toneViolet,
        ),
        (
          'KVK ला केव्हा विचारावे',
          ArticleSectionKind.caution,
          Icons.info_rounded,
          c.toneViolet,
        ),
        ('स्रोत', ArticleSectionKind.sources, Icons.link_rounded, c.toneGrey),
        (
          'What you see',
          ArticleSectionKind.see,
          Icons.visibility_rounded,
          c.toneAmber,
        ),
        (
          'What to check',
          ArticleSectionKind.check,
          Icons.search_rounded,
          c.toneTeal,
        ),
        (
          'What to do',
          ArticleSectionKind.act,
          Icons.check_circle_rounded,
          c.toneGreen,
        ),
      ]) {
        final k = sectionKindFor(heading);
        expect(k, kind, reason: heading);
        expect(sectionIcon(k), icon, reason: heading);
        expect(sectionTone(c, k), tone, reason: heading);
      }
    });

    test('unknown headings rotate through the palette', () {
      const c = BmColors.dark;
      expect(sectionKindFor('मित्रकीटकांचे जतन'), ArticleSectionKind.other);
      final tones = [
        for (var i = 0; i < 5; i++)
          sectionTone(c, ArticleSectionKind.other, otherIndex: i),
      ];
      expect(tones.toSet(), hasLength(5));
      expect(
        sectionTone(c, ArticleSectionKind.other, otherIndex: 5),
        tones.first,
      );
    });

    for (final (name, c) in [
      ('light', BmColors.light),
      ('dark', BmColors.dark),
    ]) {
      test('every reading tone is readable ($name)', () {
        for (final tone in [
          c.toneGreen,
          c.toneBlue,
          c.toneTeal,
          c.toneAmber,
          c.toneViolet,
          c.toneGrey,
        ]) {
          expect(contrast(tone.ink, tone.tint), greaterThanOrEqualTo(4.5));
          expect(contrast(tone.ink, c.card), greaterThanOrEqualTo(4.5));
          // Body text on the pill and the summary box.
          expect(contrast(c.ink, tone.tint), greaterThanOrEqualTo(4.5));
          // The icon in a chip: card colour on the tone ink.
          expect(contrast(c.card, tone.ink), greaterThanOrEqualTo(4.5));
        }
      });
    }
  });

  group('bullets', () {
    test('more than two sentences become bullets, text kept', () {
      expect(
        splitBullets(
          'शेंडे तपासा. कोवळी पाने पाहा; पिवळे सापळे लावा. दर महिन्याला बदला.',
        ),
        [
          'शेंडे तपासा.',
          'कोवळी पाने पाहा',
          'पिवळे सापळे लावा.',
          'दर महिन्याला बदला.',
        ],
      );
    });

    test('two sentences or a short piece stay one paragraph', () {
      const two = 'चपटी पिल्ले गर्दी करतात; नवीन पाने वळतात व गळतात.';
      expect(splitBullets(two), [two]);
      const shortPiece = 'हे पहा. ठीक. नंतर पुन्हा सर्व शेंडे तपासा.';
      expect(splitBullets(shortPiece), [shortPiece]);
    });

    test('decimals and abbreviations do not split', () {
      const text =
          'Dr. PDKV advises 2.5 m spacing for new plantings. Check every flush '
          'twice a week. Ask the KVK when unsure about it.';
      expect(splitBullets(text), [
        'Dr. PDKV advises 2.5 m spacing for new plantings.',
        'Check every flush twice a week.',
        'Ask the KVK when unsure about it.',
      ]);
    });
  });

  testWidgets(
    'a highlighted paragraph keeps its plain text for screen readers',
    (tester) async {
      final handle = tester.ensureSemantics();
      const text = 'सुमारे २ मीटर उंचीवर सायलासाठी सापळे लावा.';
      await tester.pumpWidget(
        MaterialApp(
          theme: BmTheme.light(),
          home: const Scaffold(
            body: HighlightedText(
              text,
              tone: BmTone(BmPalette.leaf, BmPalette.leafReadTint),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel(text), findsOneWidget);
      expect(find.text('२ मीटर'), findsOneWidget); // the pill
      handle.dispose();
    },
  );
}
