import 'package:bagmitra/design_system/app_bar_title.dart';
import 'package:bagmitra/design_system/glyphs.dart';
import 'package:bagmitra/design_system/navigation.dart';
import 'package:bagmitra/design_system/price_card.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpIn(
  WidgetTester tester,
  Widget child, {
  double scale = 1.0,
  PreferredSizeWidget? appBar,
}) async {
  tester.view.physicalSize = const Size(393, 851) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: BmTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 851),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(appBar: appBar, body: child),
      ),
    ),
  );
}

RenderParagraph paragraphOf(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  const long = 'पीएम-किसान सन्मान निधी आणि आणखी एक लांब नाव';

  testWidgets('a long title wraps to two lines at 1.3x instead of being cut', (
    tester,
  ) async {
    await pumpIn(
      tester,
      const SizedBox(),
      scale: 1.3,
      appBar: AppBar(
        title: const AppBarTitle(long),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),
    );
    final p = paragraphOf(tester, long);
    expect(p.maxLines, 2);
    expect(p.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
    // Both lines sit inside the standard bar.
    final bar = tester.getRect(find.byType(AppBar));
    final title = tester.getRect(find.text(long));
    expect(title.bottom, lessThanOrEqualTo(bar.bottom));
  });

  testWidgets('a short title stays one line in the bar style', (tester) async {
    await pumpIn(
      tester,
      const SizedBox(),
      scale: 1.3,
      appBar: AppBar(title: const AppBarTitle('योजना')),
    );
    final p = paragraphOf(tester, 'योजना');
    expect(p.maxLines, 1);
    expect(p.text.style?.fontSize, BmType.section.fontSize);
  });

  testWidgets('TalkBack reads the camera label once', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpIn(
      tester,
      BmBottomBar(
        items: const [
          BmNavItem(BmGlyph.home, 'घर'),
          BmNavItem(BmGlyph.orchard, 'बाग'),
          BmNavItem(BmGlyph.ledger, 'हिशोब'),
          BmNavItem(BmGlyph.mic, 'विचारा'),
        ],
        selected: 0,
        cameraLabel: 'फोटो काढा',
        onCamera: () {},
      ),
    );
    expect(find.bySemanticsLabel('फोटो काढा'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the bottom bar fits at 1.3x and 1.5x text', (tester) async {
    for (final scale in [1.3, 1.5]) {
      await pumpIn(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: BmBottomBar(
            items: const [
              BmNavItem(BmGlyph.home, 'घर'),
              BmNavItem(BmGlyph.orchard, 'बाग'),
              BmNavItem(BmGlyph.ledger, 'हिशोब'),
              BmNavItem(BmGlyph.mic, 'विचारा'),
            ],
            selected: 0,
            cameraLabel: 'फोटो काढा',
            onCamera: _noop,
          ),
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull, reason: 'scale $scale');
      for (final label in ['घर', 'बाग', 'हिशोब', 'विचारा']) {
        expect(paragraphOf(tester, label).didExceedMaxLines, isFalse);
      }
    }
  });

  testWidgets('the price change is read as words, not the arrow symbol', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpIn(
      tester,
      const PriceHeroCard(
        price: '₹३,२००',
        caption: 'प्रति क्विंटल',
        change: '८%',
        changeCaption: 'गेल्या आठवड्यापेक्षा',
        changeLabel: 'गेल्या आठवड्यापेक्षा ८% वाढ',
      ),
    );
    expect(
      find.bySemanticsLabel('गेल्या आठवड्यापेक्षा ८% वाढ'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('▲')), findsNothing);
    semantics.dispose();
  });
}

void _noop() {}
