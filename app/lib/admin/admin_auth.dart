import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AdminSignInError implements Exception {
  const AdminSignInError();
}

/// Staff sign-in for the admin web (email + password accounts created in Supabase).
/// Roles are not read here: the API decides from server-set app_metadata.
abstract interface class AdminAuth {
  String? get accessToken;
  Stream<void> get changes;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

/// Thin Supabase adapter; the flow is covered by widget tests with a fake.
class SupabaseAdminAuth implements AdminAuth {
  SupabaseAdminAuth(this._client);
  final sb.SupabaseClient _client;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  Stream<void> get changes => _client.auth.onAuthStateChange;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException {
      throw const AdminSignInError();
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
