import 'package:bagmitra/features/auth/domain/auth.dart';
import 'package:bagmitra/features/auth/infra/supabase_auth_repository.dart';
import 'package:bagmitra/features/auth/presentation/login_screens.dart';
import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  AuthFailureKind send(sb.AuthException e) =>
      authFailureKindFor(e, verifying: false);
  AuthFailureKind verify(sb.AuthException e) =>
      authFailureKindFor(e, verifying: true);

  test('a failed fetch without a status is the network, never the number', () {
    final offline = sb.AuthRetryableFetchException(message: 'SocketException');
    expect(send(offline), AuthFailureKind.network);
    expect(verify(offline), AuthFailureKind.network);
  });

  test('5xx and SMS provider failures are the service', () {
    expect(
      send(sb.AuthRetryableFetchException(message: 'x', statusCode: '503')),
      AuthFailureKind.server,
    );
    expect(
      send(
        const sb.AuthApiException(
          'x',
          statusCode: '500',
          code: 'unexpected_failure',
        ),
      ),
      AuthFailureKind.server,
    );
    expect(
      send(
        const sb.AuthApiException(
          'x',
          statusCode: '500',
          code: 'sms_send_failed',
        ),
      ),
      AuthFailureKind.server,
    );
  });

  test('no SMS provider on the project points the grower to Google', () {
    expect(
      send(
        const sb.AuthApiException(
          'Unsupported phone provider',
          statusCode: '400',
          code: 'phone_provider_disabled',
        ),
      ),
      AuthFailureKind.phoneUnavailable,
    );
  });

  test('rate limits, wrong codes and invalid numbers', () {
    expect(
      send(
        const sb.AuthApiException(
          'x',
          statusCode: '429',
          code: 'over_sms_send_rate_limit',
        ),
      ),
      AuthFailureKind.rateLimited,
    );
    expect(
      verify(
        const sb.AuthApiException('x', statusCode: '403', code: 'otp_expired'),
      ),
      AuthFailureKind.invalidOtp,
    );
    expect(
      send(
        const sb.AuthApiException(
          'x',
          statusCode: '422',
          code: 'validation_failed',
        ),
      ),
      AuthFailureKind.invalidPhone,
    );
    expect(
      verify(
        const sb.AuthApiException(
          'x',
          statusCode: '422',
          code: 'validation_failed',
        ),
      ),
      AuthFailureKind.invalidOtp,
    );
    expect(
      send(
        const sb.AuthApiException(
          'x',
          statusCode: '400',
          code: 'something_new',
        ),
      ),
      AuthFailureKind.unknown,
    );
  });

  test('only typing mistakes mention the number or the code', () {
    final t = AppLocalizationsEn();
    expect(
      authFailureText(t, AuthFailureKind.network),
      'Check the internet and try again',
    );
    expect(authFailureText(t, AuthFailureKind.server), t.netServer);
    expect(authFailureText(t, AuthFailureKind.rateLimited), t.netServer);
    expect(authFailureText(t, AuthFailureKind.unknown), t.netServer);
    expect(
      authFailureText(t, AuthFailureKind.phoneUnavailable),
      t.loginPhoneUnavailable,
    );
    expect(
      authFailureText(t, AuthFailureKind.invalidPhone),
      t.loginInvalidPhone,
    );
    expect(authFailureText(t, AuthFailureKind.invalidOtp), t.loginInvalidOtp);
  });
}
