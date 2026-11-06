import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/auth.dart';

/// Turns a Supabase auth error into what the grower is told. A failed fetch with no HTTP
/// status is the phone's network; 5xx is the service; only a validation or token error is
/// about the number or code he typed ([verifying] says which step it was).
AuthFailureKind authFailureKindFor(
  sb.AuthException e, {
  required bool verifying,
}) {
  if (e is sb.AuthRetryableFetchException) {
    return e.statusCode == null
        ? AuthFailureKind.network
        : AuthFailureKind.server;
  }
  switch (e.code) {
    case 'phone_provider_disabled':
      return AuthFailureKind.phoneUnavailable;
    case 'sms_send_failed':
      return AuthFailureKind.server;
    case 'over_sms_send_rate_limit' ||
        'over_request_rate_limit' ||
        'over_email_send_rate_limit':
      return AuthFailureKind.rateLimited;
    case 'otp_expired' || 'invalid_credentials':
      return AuthFailureKind.invalidOtp;
    case 'validation_failed':
      return verifying
          ? AuthFailureKind.invalidOtp
          : AuthFailureKind.invalidPhone;
  }
  final status = int.tryParse(e.statusCode ?? '');
  if (status != null && status >= 500) return AuthFailureKind.server;
  return verifying ? AuthFailureKind.invalidOtp : AuthFailureKind.unknown;
}

/// Phone-OTP and Google auth via Supabase. Thin adapter; behaviour is covered by the
/// [AuthRepository] contract tests run against the demo implementation, and the error
/// mapping by [authFailureKindFor]'s tests.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, {void Function(String)? log})
    : _log = log ?? _noLog;

  final sb.SupabaseClient _client;
  final void Function(String) _log;

  static void _noLog(String _) {}

  static AuthSession? _map(sb.Session? s) => s == null
      ? null
      : AuthSession(
          userId: s.user.id,
          phone: s.user.phone ?? '',
          accessToken: s.accessToken,
        );

  @override
  AuthSession? get current => _map(_client.auth.currentSession);

  @override
  Stream<AuthSession?> sessions() =>
      _client.auth.onAuthStateChange.map((e) => _map(e.session));

  @override
  Future<void> sendOtp(String phoneE164) async {
    try {
      await _client.auth.signInWithOtp(phone: phoneE164);
    } on sb.AuthException catch (e) {
      throw AuthFailure(authFailureKindFor(e, verifying: false));
    } on Exception {
      throw const AuthFailure(AuthFailureKind.network);
    }
  }

  @override
  Future<AuthSession> verifyOtp(String phoneE164, String code) async {
    try {
      final res = await _client.auth.verifyOTP(
        type: sb.OtpType.sms,
        phone: phoneE164,
        token: code,
      );
      return _map(res.session) ??
          (throw const AuthFailure(AuthFailureKind.invalidOtp));
    } on sb.AuthException catch (e) {
      throw AuthFailure(authFailureKindFor(e, verifying: true));
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure(AuthFailureKind.network);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final opened = await _client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: googleRedirectUri,
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );
      if (!opened) throw const AuthFailure(AuthFailureKind.network);
    } on sb.AuthException catch (e) {
      throw AuthFailure(
        e is sb.AuthRetryableFetchException && e.statusCode == null
            ? AuthFailureKind.network
            : AuthFailureKind.unknown,
      );
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure(AuthFailureKind.network);
    }
  }

  /// Never throws. Supabase drops the phone's session first and only then tells the server;
  /// offline that second step fails, which is fine: the server's session simply expires.
  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Object catch (e) {
      _log('auth: sign-out kept local only (${e.runtimeType})');
    }
  }
}
