import 'dart:convert';

import 'package:flutter/services.dart';

/// A published page a card's statements come from.
class LookalikeSource {
  const LookalikeSource({
    required this.title,
    required this.url,
    required this.verified,
  });

  final String title;
  final String url;

  /// False until the page itself has been read; cards citing it show as drafts.
  final bool verified;
}

/// One "looks alike" card: what the grower may see, what it can be confused with, and who
/// can confirm it. Never a diagnosis, a chemical or a treatment.
class LookalikeCard {
  const LookalikeCard({
    required this.id,
    required this.scoutingItem,
    required this.title,
    required this.see,
    required this.confusedWith,
    required this.confirm,
    required this.sourceKeys,
  });

  final String id;

  /// The scouting log item "Log this" opens with (`scoutingItems`).
  final String scoutingItem;
  final Map<String, String> title;
  final Map<String, String> see;
  final Map<String, String> confusedWith;
  final Map<String, String> confirm;
  final List<String> sourceKeys;

  String text(Map<String, String> field, String lang) =>
      field[lang] ?? field['en'] ?? '';

  /// A card is a draft while any source it cites is unknown or not yet read.
  bool isDraftIn(Map<String, LookalikeSource> sources) =>
      sourceKeys.any((k) => !(sources[k]?.verified ?? false));
}

class LookalikeCardsData {
  const LookalikeCardsData({
    required this.sources,
    required this.cards,
    required this.isDraft,
  });

  final Map<String, LookalikeSource> sources;
  final List<LookalikeCard> cards;

  /// Not expert-reviewed yet; kept for the reviewer (no banner, as Q30).
  final bool isDraft;
}

/// The look-alike cards from config, so a reviewer can correct them without a release.
class LookalikeCardsConfig {
  LookalikeCardsConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/lookalike_cards.json';
  final AssetBundle _bundle;

  Future<LookalikeCardsData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    return LookalikeCardsData(
      sources: (json['sources'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          LookalikeSource(
            title: (v as Map<String, dynamic>)['title'] as String,
            url: v['url'] as String,
            verified: v['verified'] == true,
          ),
        ),
      ),
      cards: [
        for (final c
            in (json['cards'] as List<dynamic>).cast<Map<String, dynamic>>())
          LookalikeCard(
            id: c['id'] as String,
            scoutingItem: c['scouting_item'] as String,
            title: strings(c['title']),
            see: strings(c['see']),
            confusedWith: strings(c['confused_with']),
            confirm: strings(c['confirm']),
            sourceKeys: (c['sources'] as List<dynamic>).cast<String>(),
          ),
      ],
      isDraft: json['status'] != 'reviewed',
    );
  }
}
