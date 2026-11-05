import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Content checks over every bundled config (audit C3, C6):
// 1. Every number in an English text is also in the Marathi and Hindi text of the same item,
//    so a translation never drops a fact, a range or a caveat.
// 2. Marathi texts use the one term per concept chosen in docs/agronomy/GLOSSARY_mr.md.

const _devanagariDigits = '०१२३४५६७८९';

String _asciiDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final i = _devanagariDigits.indexOf(String.fromCharCode(r));
    b.write(i >= 0 ? '$i' : String.fromCharCode(r));
  }
  return b.toString();
}

Set<String> _numbers(String s) => {
  for (final m in RegExp(r'\d+(?:\.\d+)?').allMatches(_asciiDigits(s)))
    m.group(0)!,
};

/// Every `{en, mr?, hi?}` text map in [node], with a readable path.
Iterable<(String, Map<String, dynamic>)> _texts(
  Object? node,
  String path,
) sync* {
  if (node is Map<String, dynamic>) {
    if (node['en'] is String) yield (path, node);
    final id = node['id'] ?? node['key'] ?? node['slug'];
    for (final e in node.entries) {
      if (e.key == 'en' || e.key == 'mr' || e.key == 'hi') continue;
      yield* _texts(
        e.value,
        id == null ? '$path.${e.key}' : '$path[$id].${e.key}',
      );
    }
  } else if (node is List) {
    for (final (i, v) in node.indexed) {
      yield* _texts(v, '$path[$i]');
    }
  }
}

/// Variant -> the glossary term to use instead (docs/agronomy/GLOSSARY_mr.md).
const _mrVariants = {
  'काढणी': 'तोडणी',
  'प्लॉट': 'बाग',
  'सिल्ला': 'सायला',
  'पालवी': 'नवती',
  'शेंडेमर': 'फांदीमर',
  'फांदी करपा': 'काडी करपा',
  'खंग': 'ऱ्हास',
  'कॅन्कर': 'कँकर',
  'साल पोखरणारी': 'साल खाणारी अळी',
  'मुळकुज': 'मूळकूज',
  'मुळकूज': 'मूळकूज',
  'सेंमी': 'सें.मी.',
  'मिमी': 'मि.मी.',
  'आळ्याऐवजी खोडापासून दूर गोल': 'दुहेरी आळे',
};

void main() {
  final files =
      Directory('assets/config')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('there are config files to check', () {
    expect(files, isNotEmpty);
  });

  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final json = jsonDecode(f.readAsStringSync());

    test('$name: every English number is in the Marathi and Hindi text', () {
      final misses = <String>[];
      for (final (path, t) in _texts(json, name)) {
        final en = _numbers(t['en'] as String);
        for (final lang in ['mr', 'hi']) {
          if (t[lang] case final String other) {
            final missing = en.difference(_numbers(other));
            if (missing.isNotEmpty) misses.add('$path $lang lacks $missing');
          }
        }
      }
      expect(misses, isEmpty);
    });

    test('$name: Marathi texts use the glossary terms', () {
      final misses = <String>[];
      for (final (path, t) in _texts(json, name)) {
        if (t['mr'] case final String mr) {
          for (final v in _mrVariants.entries) {
            if (mr.contains(v.key)) {
              misses.add('$path: "${v.key}" -> "${v.value}"');
            }
          }
        }
      }
      expect(misses, isEmpty);
    });
  }

  test('the number check catches a dropped number', () {
    final t = {'en': 'About 5–15 litres', 'mr': 'सुमारे ५ लिटर'};
    expect(_numbers(t['en']!).difference(_numbers(t['mr']!)), {'15'});
  });
}
