import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../domain/qa_text.dart';

/// One stored question with its checked answer (owner 2026-11-12, Q144).
class QaEntry {
  const QaEntry({
    required this.id,
    required this.questions,
    required this.answers,
    required this.sources,
    required this.keys,
    this.section,
  });

  final String id;

  /// The question per language (mr, hi, en).
  final Map<String, String> questions;

  /// The answer per language: 4-10 short lines (seed: the card texts).
  final Map<String, List<String>> answers;

  /// Source keys into [QaKb.sources].
  final List<String> sources;

  /// The practice-card section the answer comes from, when there is one.
  final String? section;

  /// Search keys: normalised words and "~" sound keys.
  final List<String> keys;

  String question(String lang) =>
      questions[lang] ?? questions['mr'] ?? questions['en'] ?? '';

  List<String> answer(String lang) =>
      answers[lang] ?? answers['mr'] ?? answers['en'] ?? const [];
}

/// A source an answer comes from: its title and link (empty for the app's own screens).
class QaSource {
  const QaSource(this.title, this.url);
  final String title;
  final String url;
}

class QaHit {
  const QaHit(this.entry, this.score);
  final QaEntry entry;

  /// 0 (nothing in common) to 1 (every word of the question found).
  final double score;
}

/// The bundled questions and answers with their search index. Matching works on Marathi,
/// Hindi, English and romanised text: a word of the farmer's question counts fully when the
/// same word is stored, nearly when one word starts with the other ("फळगळ" / "फळगळी"), and
/// partly when only its sound key matches ("falgal" / "फळगळ"). Rare words weigh more.
class QaKb {
  QaKb({required this.kind, required this.sources, required this.entries}) {
    for (final (i, e) in entries.indexed) {
      for (final k in e.keys) {
        (k.startsWith('~') ? _sounds : _words)
            .putIfAbsent(k.startsWith('~') ? k.substring(1) : k, () => [])
            .add(i);
      }
    }
  }

  factory QaKb.fromJson(Map<String, dynamic> json) {
    final src = (json['src'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(
        k,
        QaSource(
          (v as Map<String, dynamic>)['t'] as String? ?? k,
          v['u'] as String? ?? '',
        ),
      ),
    );
    final entries = [
      for (final raw in json['entries'] as List<dynamic>? ?? const [])
        _entry(raw as Map<String, dynamic>),
    ];
    return QaKb(
      kind: json['kind'] as String? ?? 'seed',
      sources: src,
      entries: entries,
    );
  }

  static QaEntry _entry(Map<String, dynamic> e) {
    final q = (e['q'] as Map<String, dynamic>).cast<String, String>();
    final paraphrases = [
      for (final p in e['p'] as List<dynamic>? ?? const []) p as String,
    ];
    final keys = e['k'] is List
        ? [for (final k in e['k'] as List<dynamic>) k as String]
        : qaIndexKeys([
            for (final l in const ['mr', 'hi', 'en']) ?q[l],
            ...paraphrases,
          ]);
    return QaEntry(
      id: e['id'] as String,
      questions: q,
      answers: {
        for (final MapEntry(:key, :value)
            in (e['a'] as Map<String, dynamic>).entries)
          key: [for (final line in value as List<dynamic>) line as String],
      },
      sources: [
        for (final s in e['s'] as List<dynamic>? ?? const []) s as String,
      ],
      section: e['sec'] as String?,
      keys: keys,
    );
  }

  /// "seed" (hand-assembled from card texts) or "generated".
  final String kind;
  final Map<String, QaSource> sources;
  final List<QaEntry> entries;
  final _words = <String, List<int>>{};
  final _sounds = <String, List<int>>{};

  static const _exact = 1.0;
  static const _prefix = 0.85;
  static const _sound = 0.8;
  static const _soundPrefix = 0.65;
  static const _minPrefix = 3;

  Map<int, double> _matches(String word) {
    final best = <int, double>{};
    void mark(List<int>? ids, double sim) {
      for (final i in ids ?? const <int>[]) {
        if ((best[i] ?? 0) < sim) best[i] = sim;
      }
    }

    mark(_words[word], _exact);
    if (word.length >= _minPrefix) {
      for (final MapEntry(:key, :value) in _words.entries) {
        if (key != word &&
            key.length >= _minPrefix &&
            (key.startsWith(word) || word.startsWith(key))) {
          mark(value, _prefix);
        }
      }
    }
    final s = qaSkeleton(word);
    if (s.length >= 2) {
      mark(_sounds[s], _sound);
      if (s.length >= _minPrefix) {
        for (final MapEntry(:key, :value) in _sounds.entries) {
          if (key != s &&
              key.length >= _minPrefix &&
              (key.startsWith(s) || s.startsWith(key))) {
            mark(value, _soundPrefix);
          }
        }
      }
    }
    return best;
  }

  /// Entries for [query], best first, with a score above zero.
  List<QaHit> search(String query, {int limit = 6}) {
    final words = qaWords(query);
    if (words.isEmpty || entries.isEmpty) return const [];
    final n = entries.length;
    final scores = <int, double>{};
    var total = 0.0;
    for (final w in words) {
      final found = _matches(w);
      final weight = math.log(1 + n / (1 + found.length));
      total += weight;
      for (final MapEntry(:key, :value) in found.entries) {
        scores[key] = (scores[key] ?? 0) + weight * value;
      }
    }
    final hits =
        [
          for (final MapEntry(:key, :value) in scores.entries)
            QaHit(entries[key], value / total),
        ]..sort((a, b) {
          // Ties (a word every one of them has) go to the shorter, more specific question.
          final byScore = b.score.compareTo(a.score);
          return byScore != 0
              ? byScore
              : a.entry.keys.length.compareTo(b.entry.keys.length);
        });
    return hits.take(limit).toList();
  }

  /// Other questions of the same topic area as [entry] (same card section), for "related".
  List<QaEntry> sameSection(QaEntry entry, {int limit = 3}) => [
    for (final e in entries)
      if (e.id != entry.id &&
          entry.section != null &&
          e.section == entry.section)
        e,
  ].take(limit).toList();
}

/// A hit at or above this score is shown as the answer.
const qaAnswerScore = 0.45;

/// Hits at or above this score (and below [qaAnswerScore]) are offered as close questions.
const qaCloseScore = 0.2;

/// Loads `assets/config/qa_kb.json.gz` (gzipped JSON; written by `kb/qa_build.py`).
class QaKbConfig {
  QaKbConfig({AssetBundle? bundle, this.path = assetPath})
    : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/config/qa_kb.json.gz';

  /// The asset to read; widget tests give a small fixture (the seed).
  final String path;
  final AssetBundle _bundle;

  Future<QaKb> load() async {
    final data = await _bundle.load(path);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final json = jsonDecode(utf8.decode(gzip.decode(bytes)));
    return QaKb.fromJson(json as Map<String, dynamic>);
  }
}
