import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _read(String name) =>
    jsonDecode(File('assets/config/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Every `label_target` a practice profile links to is a key the label screen knows, so the
/// label button opens a named target (WP2 profiles x WP4 label screen).
void main() {
  test('practice label targets are known label target keys', () {
    final keys = {
      for (final t in _read('label_targets.json')['targets'] as List)
        (t as Map<String, dynamic>)['key'] as String,
    };
    final used = <String>{};
    void walk(Object? node) {
      if (node is Map) {
        if (node['label_target'] case final String k) used.add(k);
        node.values.forEach(walk);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    walk(_read('practice_cards.json'));
    expect(used, isNotEmpty);
    expect(used.difference(keys), isEmpty);
  });
}
