/// The five market-link roles behind the role cards (spec v1.5 §2.1). One account may hold
/// several; the grower role is the existing grower app.
enum MarketRole {
  grower,
  trader,
  broker,
  exporter,
  provider;

  /// The role name the API stores (`terms_acceptances.role`).
  String get api => name;

  static MarketRole? fromName(String? name) =>
      values.where((r) => r.name == name).firstOrNull;
}

/// The current document versions the user accepts before a role is used, and the grievance
/// officer (spec v1.5 §4C). [grievanceName] null: the owner.
class MarketTerms {
  const MarketTerms({
    required this.versions,
    this.termsUrl,
    this.privacyUrl,
    this.grievanceName,
    this.grievanceContact,
  });

  factory MarketTerms.fromJson(Map<String, Object?> json) {
    final docs = [
      for (final d in json['documents']! as List)
        (d as Map).cast<String, Object?>(),
    ];
    final officer = (json['grievance_officer'] as Map?)
        ?.cast<String, Object?>();
    String? url(String kind) =>
        docs.where((d) => d['kind'] == kind).firstOrNull?['url'] as String?;
    return MarketTerms(
      versions: {
        for (final d in docs) d['kind']! as String: d['version']! as String,
      },
      termsUrl: url('terms'),
      privacyUrl: url('privacy'),
      grievanceName: officer?['name'] as String?,
      grievanceContact: officer?['contact'] as String?,
    );
  }

  /// Used until the server has been reached once: the versions this build's text matches.
  static const bundled = MarketTerms(
    versions: {'terms': '1', 'privacy': '1', 'disclaimer': '1'},
    privacyUrl: '/privacy',
  );

  final Map<String, String> versions;
  final String? termsUrl;
  final String? privacyUrl;
  final String? grievanceName;
  final String? grievanceContact;
}
