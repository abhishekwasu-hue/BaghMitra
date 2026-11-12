// Empty feed filters (owner 2026-11-12, Q145) at phone width, Marathi, 1.3x text, light and
// dark: online, the "योजना" filter with no scheme says calmly that schemes appear here; offline
// with nothing saved, the list keeps "फोन ऑनलाइन असताना संदेश येतील.".
//   flutter test --update-goldens test/goldens/feed_empty_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/feed/feed_data_test.dart'
    show FakeFeedRepository, feedBody, feedJson;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final online in [true, false]) {
      final name =
          'feed_empty_scheme_${online ? 'online' : 'offline'}_mr_${mode.name}';
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: '/feed',
          size: _phone,
          overrides: [
            feedRepositoryProvider.overrideWithValue(
              FakeFeedRepository(
                online
                    ? feedBody([
                        {
                          ...feedJson(
                            'news1',
                            type: 'news',
                            trust: 'news',
                            grNumber: null,
                            department: null,
                            level: 'state',
                            publishedAt: '2026-10-11T06:00:00Z',
                          ),
                          'title': 'संत्रा बागेसाठी पाणी व्यवस्थापन',
                        },
                      ])
                    : null,
              ),
            ),
          ],
        );
        await settle(tester);
        await tester.tap(find.byKey(const Key('feed-filter-scheme')));
        await settle(tester);
        await tester.pump(const Duration(seconds: 1)); // the chip's animation
        expect(
          find.text(
            online
                ? 'नवीन योजना आल्यावर इथे दिसतील.'
                : 'फोन ऑनलाइन असताना संदेश येतील.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$name.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
