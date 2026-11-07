// Season sale package, consumption-only (spec v1.5 §4D, §4E; research §7.1): the Android app
// shows no price, amount, ₹, pay button, UPI ID, QR, link or "pay at" text for this feature,
// including the representative screens. The admin web's package strings stay out of the app
// bundle (lib/admin/package_strings.dart is reachable from lib/main_admin.dart only).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Price / payment / UPI / QR / link words in English, Marathi and Hindi.
final _paymentWords = RegExp(
  r'₹|\brs\.?\s|rupee|price|amount|\bpay|payment|\bfee|\bcost|purchase|\bbuy|'
  r'\bupi\b|\bqr\b|\blink\b|https?:|www\.|@|'
  r'किंमत|रक्कम|रुपये|पैसे|भरा|भरणा|शुल्क|फी|यूपीआय|क्यूआर|लिंक|खरेदी|'
  r'कीमत|राशि|भुगतान|फीस|यूपीआई|खरीद',
  caseSensitive: false,
);

/// UPI / QR words: none anywhere in the app's strings or reachable code.
final _upiQr = RegExp(
  r'\bupi\b|\bvpa\b|\bqr\b|merchant|यूपीआय|यूपीआई|क्यूआर',
  caseSensitive: false,
);

Map<String, String> _arb(String lang) {
  final raw = jsonDecode(
    File('lib/l10n/app_$lang.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

/// Every Dart file the Android app (lib/main.dart) imports, directly or not.
Set<String> _reachable() {
  final seen = <String>{};
  final todo = ['lib/main.dart'];
  final directive = RegExp(
    r'''^(?:import|export|part)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  while (todo.isNotEmpty) {
    final path = todo.removeLast();
    if (!seen.add(path)) continue;
    final dir = File(path).parent.path;
    for (final m in directive.allMatches(File(path).readAsStringSync())) {
      final uri = m.group(1)!;
      final String target;
      if (uri.startsWith('package:bagmitra/')) {
        target = 'lib/${uri.substring('package:bagmitra/'.length)}';
      } else if (uri.contains(':')) {
        continue; // dart: and other packages
      } else {
        target = File('$dir/$uri').uri.normalizePath().toFilePath();
      }
      todo.add(target);
    }
  }
  return seen.map((p) => p.replaceFirst(RegExp(r'^\./'), '')).toSet();
}

/// The string literals of a Dart file (comments dropped).
Iterable<String> _literals(String source) {
  final code = source
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');
  final single = RegExp(r"'((?:[^'\\\n]|\\.)*)'");
  final double = RegExp(r'"((?:[^"\\\n]|\\.)*)"');
  return [
    for (final re in [single, double])
      ...re.allMatches(code).map((m) => m.group(1)!),
  ];
}

void main() {
  test('the package chip strings carry no price, payment, UPI or QR word', () {
    for (final lang in ['mr', 'hi', 'en']) {
      final keys = _arb(lang).entries
          .where((e) => e.key.startsWith('mlPackage'));
      expect(keys.length, 3, reason: lang);
      for (final e in keys) {
        expect(
          _paymentWords.hasMatch(e.value),
          isFalse,
          reason: '$lang ${e.key}',
        );
      }
    }
  });

  test('no UPI, VPA, QR or merchant text anywhere in the app strings', () {
    for (final lang in ['mr', 'hi', 'en']) {
      for (final e in _arb(lang).entries) {
        expect(_upiQr.hasMatch(e.value), isFalse, reason: '$lang ${e.key}');
      }
    }
  });

  test(
    'the Android app never reaches the admin web or its package strings',
    () {
      final files = _reachable();
      expect(
        files,
        contains('lib/features/market_link/presentation/package_chip.dart'),
      );
      expect(files.where((f) => f.startsWith('lib/admin/')), isEmpty);
      expect(files, isNot(contains('lib/main_admin.dart')));
    },
  );

  test('no reachable app code has a UPI / QR literal; the package files no payment word', () {
    for (final path in _reachable()) {
      // Generated API schemas: admin models are tree-shaken from the app build.
      if (path.startsWith('lib/api/generated/')) continue;
      final literals = _literals(File(path).readAsStringSync()).toList();
      for (final s in literals) {
        expect(_upiQr.hasMatch(s), isFalse, reason: '$path: $s');
      }
      if (path.contains('/package_')) {
        for (final s in literals) {
          expect(_paymentWords.hasMatch(s), isFalse, reason: '$path: $s');
        }
      }
    }
  });

  test('the checks catch the words they look for', () {
    for (final bad in [
      '₹1500',
      'Pay now',
      'UPI ID',
      'किंमत',
      'भुगतान करें',
      'QR',
    ]) {
      expect(_paymentWords.hasMatch(bad), isTrue, reason: bad);
    }
    expect(_upiQr.hasMatch('bagmitra@okaxis UPI'), isTrue);
    expect(_paymentWords.hasMatch('पॅकेज 31 डिसें 2026 पर्यंत चालू'), isFalse);
  });
}
