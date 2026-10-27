/// Build-time configuration. Pass with `--dart-define-from-file=../product.env` plus
/// `--dart-define=API_BASE_URL=...` etc. Nothing secret lives here (anon key is public).
class AppConfig {
  const AppConfig({
    required this.productName,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.devGallery,
    required this.testBuild,
    required this.speechEngine,
    this.sarkariSandesh = '',
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    productName: String.fromEnvironment(
      'PRODUCT_NAME',
      defaultValue: 'BagMitra',
    ),
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    devGallery: bool.fromEnvironment('DEV_GALLERY'),
    testBuild: String.fromEnvironment('TEST_BUILD'),
    speechEngine: String.fromEnvironment(
      'SPEECH_ENGINE',
      defaultValue: 'on_device',
    ),
    // Empty unless defined at build time; the analyzer only sees the empty default.
    // ignore: avoid_redundant_argument_values
    sarkariSandesh: String.fromEnvironment('SARKARI_SANDESH'),
  );

  final String productName;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool devGallery;

  /// Short commit id of a CI test build (`--dart-define=TEST_BUILD=<sha>`); empty in real builds.
  final String testBuild;

  /// `on_device` (default) or `cloud`. Bhashini / Sarvam can be added as further engines.
  final String speechEngine;

  /// Feature flag for the Sarkari Sandesh feed (`--dart-define=SARKARI_SANDESH=on|off`).
  /// Unset: on in demo and test builds (they use the built-in sample feed), off otherwise
  /// until the server feed is live.
  final String sarkariSandesh;

  bool get sarkariSandeshEnabled => switch (sarkariSandesh) {
    'on' => true,
    'off' => false,
    _ => demoMode || isTestBuild,
  };

  bool get isTestBuild => testBuild.isNotEmpty;

  /// Without Supabase credentials the app runs in demo mode (local-only auth).
  bool get demoMode => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
}
