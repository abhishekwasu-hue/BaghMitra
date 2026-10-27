class FarmerProfile {
  const FarmerProfile({
    required this.id,
    required this.language,
    this.displayName,
    this.village,
    this.taluka,
    this.district,
    this.phone,
    this.consentDataProcessing = false,
    this.consentWhatsapp = false,
  });

  final String id;
  final String language;
  final String? displayName;
  final String? village;
  final String? taluka;
  final String? district;

  /// Contact number only (E.164), never a login. Google users may add one on the profile.
  final String? phone;
  final bool consentDataProcessing;
  final bool consentWhatsapp;

  /// Payload for the `farmer_profile` sync entity (see api sync/registry.py).
  Map<String, Object?> toPayload() => {
    'display_name': displayName,
    'language': language,
    'village': village,
    'taluka': taluka,
    'district': district,
    'phone': phone,
    'consent_data_processing': consentDataProcessing,
    'consent_whatsapp': consentWhatsapp,
  };

  static FarmerProfile fromPayload(String id, Map<String, Object?> p) =>
      FarmerProfile(
        id: id,
        language: p['language']! as String,
        displayName: p['display_name'] as String?,
        village: p['village'] as String?,
        taluka: p['taluka'] as String?,
        district: p['district'] as String?,
        phone: p['phone'] as String?,
        consentDataProcessing: p['consent_data_processing'] as bool? ?? false,
        consentWhatsapp: p['consent_whatsapp'] as bool? ?? false,
      );
}
