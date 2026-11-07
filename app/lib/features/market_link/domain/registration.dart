/// Market-link registration and public profiles (spec v1.5 §2, §3A, §4; L2). The phone side
/// of `/v1/market-link/{traders,exporters,brokers,providers}` and `/me/profiles`. Grower profiles are never public, so there is no grower here.
library;

/// The four roles that register (the grower role is the existing grower app).
enum RegistrationRole {
  trader('traders'),
  exporter('exporters'),
  broker('brokers'),
  provider('providers');

  const RegistrationRole(this.path);

  /// The registration endpoint under `/v1/market-link/`.
  final String path;

  static RegistrationRole? fromName(String? name) =>
      values.where((r) => r.name == name).firstOrNull;
}

/// Service-provider kinds (spec §4), with the API names.
enum ProviderKind {
  weighbridge('weighbridge'),
  transporter('transporter'),
  labourGang('labour_gang'),
  crateSupplier('crate_supplier');

  const ProviderKind(this.api);
  final String api;

  static ProviderKind? fromApi(String? api) =>
      values.where((k) => k.api == api).firstOrNull;
}

/// Document photos a registrant may add for the admin's check (brokers have none).
enum DocKind { gst, apmc, fssai, iec, apeda, certificate }

/// The one foreground GPS fix taken at registration (addendum 3): exact point, accuracy,
/// time, the phone geocoder's names and the mock-location flag.
class RegistrationFix {
  const RegistrationFix({
    required this.lat,
    required this.lon,
    required this.accuracyM,
    required this.capturedAt,
    this.place,
    this.district,
    this.state,
    this.pin,
    this.isMocked = false,
  });

  final double lat;
  final double lon;
  final double accuracyM;
  final DateTime capturedAt;
  final String? place;
  final String? district;
  final String? state;
  final String? pin;
  final bool isMocked;

  Map<String, Object?> toJson() => {
    'lat': lat,
    'lon': lon,
    'accuracy_m': accuracyM,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'place': place,
    'district': district,
    'state': state,
    // The server takes a six-digit PIN only.
    'pin': pin != null && RegExp(r'^\d{6}$').hasMatch(pin!) ? pin : null,
    'is_mocked': isMocked,
  };
}

/// A badge from a stored record, with its date: [kind] `checked` (admin approval),
/// `registered_from` (the registration fix's place), `place_photo` (a BagMitra
/// representative's visit) or a per-check badge (L7: `gst_checked` with [sinceYear],
/// `apmc_seen`, `fssai_checked`, `iec_active`, `apeda_listed`). Never a guarantee.
class ProfileBadge {
  const ProfileBadge(this.kind, this.on, {this.place, this.sinceYear});

  factory ProfileBadge.fromJson(Map<String, Object?> j) => ProfileBadge(
    j['kind']! as String,
    DateTime.parse(j['on']! as String),
    place: j['place'] as String?,
    sinceYear: j['since_year'] as int?,
  );

  final String kind;
  final DateTime on;
  final String? place;
  final int? sinceYear;
}

class QuestionStars {
  const QuestionStars(this.questionKey, this.average, this.count);

  factory QuestionStars.fromJson(Map<String, Object?> j) => QuestionStars(
    j['question_key']! as String,
    (j['average']! as num).toDouble(),
    j['count']! as int,
  );

  final String questionKey;
  final double average;
  final int count;
}

class TagCount {
  const TagCount(this.labels, this.polarity, this.count);

  factory TagCount.fromJson(Map<String, Object?> j) => TagCount(
    {
      for (final l in ['mr', 'hi', 'en']) l: j['label_$l']! as String,
    },
    j['polarity']! as String,
    j['count']! as int,
  );

  final Map<String, String> labels;
  final String polarity;
  final int count;

  String label(String lang) => labels[lang] ?? labels['en']!;
}

List<String> _strings(Object? v) => [
  for (final s in (v as List?) ?? const []) s as String,
];

List<Map<String, Object?>> _maps(Object? v) => [
  for (final m in (v as List?) ?? const []) (m as Map).cast<String, Object?>(),
];

/// A public profile (verified only), or the registrant's own view when [status] is set.
class MarketProfile {
  const MarketProfile({
    required this.subjectType,
    required this.id,
    required this.kind,
    required this.name,
    required this.phone,
    required this.district,
    this.firm,
    this.village,
    this.taluka,
    this.markets = const [],
    this.crops = const [],
    this.areas = const [],
    this.address,
    this.dealsCompleted = 0,
    this.stars = const [],
    this.tags = const [],
    this.badges = const [],
    this.certValidUntil,
    this.certificateExpired = false,
    this.vehicleNumbers = const [],
    this.capacityT,
    this.refrigerated,
    this.distanceKm,
    this.status,
    this.reason,
    this.documents = 0,
    this.hasCertificatePhoto = false,
  });

  factory MarketProfile.fromJson(Map<String, Object?> j) {
    final provider = (j['provider'] as Map?)?.cast<String, Object?>();
    final until = provider?['cert_valid_until'] as String?;
    return MarketProfile(
      subjectType: j['subject_type']! as String,
      id: j['id']! as String,
      kind: j['kind']! as String,
      name: j['name']! as String,
      phone: j['phone']! as String,
      district: j['district']! as String,
      firm: j['firm'] as String?,
      village: j['village'] as String?,
      taluka: j['taluka'] as String?,
      markets: _strings(j['markets']),
      crops: _strings(j['crops']),
      areas: _strings(j['areas']),
      address: j['address'] as String?,
      dealsCompleted: (j['deals_completed'] as int?) ?? 0,
      stars: [for (final m in _maps(j['stars'])) QuestionStars.fromJson(m)],
      tags: [for (final m in _maps(j['tags'])) TagCount.fromJson(m)],
      badges: [for (final m in _maps(j['badges'])) ProfileBadge.fromJson(m)],
      certValidUntil: until == null ? null : DateTime.parse(until),
      certificateExpired: provider?['certificate_expired'] == true,
      vehicleNumbers: _strings(provider?['vehicle_numbers']),
      capacityT: (provider?['capacity_t'] as num?)?.toDouble(),
      refrigerated: provider?['refrigerated'] as bool?,
      distanceKm: j['distance_km'] as int?,
      status: j['status'] as String?,
      reason: j['reason'] as String?,
      documents: (j['documents'] as int?) ?? 0,
      hasCertificatePhoto: j['has_certificate_photo'] == true,
    );
  }

  /// `buyer`, `broker` or `provider` (the API's subject type).
  final String subjectType;
  final String id;

  /// trader / exporter, broker, or the provider kind's API name.
  final String kind;
  final String name;
  final String phone;
  final String district;
  final String? firm;
  final String? village;
  final String? taluka;
  final List<String> markets;
  final List<String> crops;
  final List<String> areas;
  final String? address;
  final int dealsCompleted;
  final List<QuestionStars> stars;
  final List<TagCount> tags;
  final List<ProfileBadge> badges;
  final DateTime? certValidUntil;
  final bool certificateExpired;
  final List<String> vehicleNumbers;
  final double? capacityT;
  final bool? refrigerated;
  final int? distanceKm;

  /// Own view only: pending / approved / rejected, and the admin's reason.
  final String? status;
  final String? reason;
  final int documents;
  final bool hasCertificatePhoto;

  /// Mean of the per-question averages, to one decimal; null while nobody has rated.
  double? get overallStars => stars.isEmpty
      ? null
      : (stars.map((s) => s.average).reduce((a, b) => a + b) /
                    stars.length *
                    10)
                .round() /
            10;

  /// Village, taluka, district, each named once (a village is often its taluka town).
  String get place => {
    for (final s in [?village, ?taluka, district])
      if (s.trim().isNotEmpty) s.trim(),
  }.join(', ');

  /// Documents the owner may photograph for this profile (spec §4).
  List<DocKind> get documentKinds => switch (subjectType) {
    'buyer' => const [
      DocKind.gst,
      DocKind.apmc,
      DocKind.fssai,
      DocKind.iec,
      DocKind.apeda,
    ],
    'provider' when kind == 'weighbridge' => const [DocKind.certificate],
    _ => const [],
  };
}

/// A ten-digit Indian mobile number as the API takes it (+91…); null when it is not one.
String? normalisePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  final ten = digits.length == 12 && digits.startsWith('91')
      ? digits.substring(2)
      : digits;
  return RegExp(r'^[6-9]\d{9}$').hasMatch(ten) ? '+91$ten' : null;
}

final gstinPattern = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
final iecPattern = RegExp(r'^[A-Z0-9]{10}$');
final fssaiPattern = RegExp(r'^\d{14}$');

/// Comma- or newline-separated words as a list (markets, areas, vehicle numbers).
List<String> splitList(String raw) => [
  for (final s in raw.split(RegExp(r'[,\n]')))
    if (s.trim().isNotEmpty) s.trim(),
];
