/// Market-link registration (spec v1.5 §2, §4; L2): the phone side of
/// `/v1/market-link/{traders,exporters,brokers,providers}`. Grower profiles are never public,
/// so there is no grower here.
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
