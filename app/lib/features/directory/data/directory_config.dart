import 'dart:convert';

import 'package:flutter/services.dart';

/// One institution, market or service in a directory: what it offers, where it is, and the
/// official page its details were read from. A phone or address is only ever what that page
/// says; [verified] is false when no official page could be checked.
class DirectoryEntry {
  const DirectoryEntry({
    required this.id,
    required this.kind,
    required this.district,
    required this.name,
    required this.offers,
    required this.url,
    required this.source,
    required this.verified,
    this.address,
    this.phone,
    this.checked,
  });

  static const kinds = {
    'research',
    'university',
    'kvk',
    'soil_lab',
    'portal',
    'apmc',
    'export',
    'processor',
  };

  final String id;
  final String kind;

  /// A key of [DirectoryData.districts].
  final String district;
  final Map<String, String> name;
  final Map<String, String> offers;

  /// The entry's own official web page.
  final String url;

  /// Where the name, address and phone were read.
  final String source;
  final bool verified;
  final String? address;
  final String? phone;

  /// The day the source was read.
  final DateTime? checked;

  String nameIn(String lang) => name[lang] ?? name['en'] ?? id;
  String offersIn(String lang) => offers[lang] ?? offers['en'] ?? '';
}

class DirectoryData {
  const DirectoryData({required this.districts, required this.entries});

  /// District slug → label per language, in the order the filter shows them.
  final Map<String, Map<String, String>> districts;
  final List<DirectoryEntry> entries;

  String districtLabel(String slug, String lang) =>
      districts[slug]?[lang] ?? districts[slug]?['en'] ?? slug;

  /// Districts that have at least one entry, in config order.
  List<String> get districtsInUse => [
    for (final d in districts.keys)
      if (entries.any((e) => e.district == d)) d,
  ];

  /// All entries ([district] null) or those of one district, in config order.
  List<DirectoryEntry> inDistrict(String? district) => [
    for (final e in entries)
      if (district == null || e.district == district) e,
  ];
}

/// A directory from a config asset (labs and experts, markets and buyers), so a reviewer
/// can correct an entry without a release.
class DirectoryConfig {
  DirectoryConfig(this.asset, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const labs = 'assets/config/lab_directory.json';
  static const markets = 'assets/config/market_directory.json';

  final String asset;
  final AssetBundle _bundle;

  Future<DirectoryData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    return DirectoryData(
      districts: (json['districts'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, strings(v)),
      ),
      entries: [
        for (final e
            in (json['entries'] as List<dynamic>).cast<Map<String, dynamic>>())
          DirectoryEntry(
            id: e['id'] as String,
            kind: e['kind'] as String,
            district: e['district'] as String,
            name: strings(e['name']),
            offers: strings(e['offers']),
            url: e['url'] as String,
            source: e['source'] as String,
            verified: e['verified'] == true,
            address: e['address'] as String?,
            phone: e['phone'] as String?,
            checked: switch (e['checked']) {
              final String d => DateTime.parse(d),
              _ => null,
            },
          ),
      ],
    );
  }
}
