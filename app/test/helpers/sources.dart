import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens every folded "Sources (n)" header that is built (on screen or not), so a test can
/// check the source text that sits one tap away (SourcesDisclosure).
Future<void> openAllSources(WidgetTester tester, {Finder? within}) async {
  Finder toggles() {
    final all = find.byKey(const Key('sources-toggle'), skipOffstage: false);
    return within == null
        ? all
        : find.descendant(of: within, matching: all, skipOffstage: false);
  }

  // Opening one can push later lines out of the list's build area, so look again each time.
  for (var guard = 0; guard < 200; guard++) {
    final closed = toggles().evaluate().where(
      (e) => (e.widget as Semantics).properties.expanded != true,
    );
    if (closed.isEmpty) return;
    (closed.first.widget as Semantics).properties.onTap!();
    await tester.pump();
  }
}
