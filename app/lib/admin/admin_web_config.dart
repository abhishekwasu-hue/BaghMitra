import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Runtime configuration for the admin web served by the API at `/admin/` (OPS-02).
///
/// The CI build carries no environment values. When the build has no Supabase defines and
/// runs in a browser, the page asks the API for `config.json` next to `index.html`; the API
/// answers with the Supabase project URL and its public anon key. The API is then the page's
/// own origin, so the browser needs no CORS. Any failure keeps [base] (demo mode, where the
/// sections explain that admin sign-in needs Supabase).
Future<AppConfig> resolveAdminConfig(
  AppConfig base, {
  required bool isWeb,
  required Uri pageUri,
  required http.Client client,
}) async {
  if (!isWeb || !base.demoMode) return base;
  try {
    final res = await client
        .get(pageUri.resolve('config.json'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return base;
    final body = jsonDecode(res.body);
    if (body is! Map<String, Object?>) return base;
    final url = body['supabase_url'];
    final key = body['supabase_anon_key'];
    if (url is! String || key is! String || url.isEmpty || key.isEmpty) {
      return base;
    }
    return AppConfig(
      productName: base.productName,
      apiBaseUrl: pageUri.origin,
      supabaseUrl: url,
      supabaseAnonKey: key,
      devGallery: base.devGallery,
      testBuild: base.testBuild,
      speechEngine: base.speechEngine,
      sarkariSandesh: base.sarkariSandesh,
      marketLink: base.marketLink,
    );
  } on Object {
    return base;
  }
}
