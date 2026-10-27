import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AdminSignInError implements Exception {
  const AdminSignInError();
}

/// Staff sign-in for the admin web (email + password accounts created in Supabase).
/// The API decides access from server-set app_metadata; [roles] (the same app_metadata
/// `roles`) only decides which sections the shell shows (e.g. `feed_admin`).
abstract interface class AdminAuth {
  String? get accessToken;
  Set<String> get roles;
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
  Set<String> get roles =>
      switch (_client.auth.currentUser?.appMetadata['roles']) {
        final List<Object?> list => {...list.whereType<String>()},
        _ => const {},
      };

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
