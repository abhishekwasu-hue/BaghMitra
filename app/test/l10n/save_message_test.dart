import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner 2026-11-10: with the internet on, every save said "will be sent when the net comes
/// back". The save message is shown whatever the connection, so it says only that the entry
/// was saved; being offline is told by the offline banner, not by every save.
void main() {
  test('the save message claims nothing about the network', () {
    final words = {
      'en': RegExp('online|sync|internet|network', caseSensitive: false),
      'mr': RegExp('नेट|पाठव|इंटरनेट'),
      'hi': RegExp('नेटवर्क|भेज|इंटरनेट'),
    };
    for (final MapEntry(key: lang, value: banned) in words.entries) {
      final text = File('lib/l10n/app_$lang.arb').readAsStringSync();
      final arb = jsonDecode(text) as Map;
      final saved = arb['plotSaved'] as String;
      expect(saved, isNot(matches(banned)), reason: '$lang: $saved');
    }
  });
}
