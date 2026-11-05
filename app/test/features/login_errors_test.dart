import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/features/auth/data/demo_auth_repository.dart';
import 'package:bagmitra/features/auth/domain/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Demo auth whose next send / verify fails with a chosen kind.
class FailingAuth extends DemoAuthRepository {
  AuthFailureKind? sendFails;
  AuthFailureKind? verifyFails;
  int sends = 0;

  @override
  Future<void> sendOtp(String phoneE164) async {
    sends++;
    if (sendFails case final kind?) throw AuthFailure(kind);
    return super.sendOtp(phoneE164);
  }

  @override
  Future<AuthSession> verifyOtp(String phoneE164, String code) async {
    if (verifyFails case final kind?) throw AuthFailure(kind);
    return super.verifyOtp(phoneE164, code);
  }
}

const _backendConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: 'https://project.supabase.test',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
);

const _backendWithPhone = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: 'https://project.supabase.test',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
  phoneLogin: true,
);

Future<void> _openOtp(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('phone')), '98765 43210');
  await tester.tap(find.byKey(const Key('send-otp')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('a network failure on send asks to check the internet', (
    tester,
  ) async {
    final auth = FailingAuth()..sendFails = AuthFailureKind.network;
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      auth: auth,
    );
    await _openOtp(tester);
    expect(find.text('Check the internet and try again'), findsOneWidget);
    expect(find.text('Enter a valid 10-digit mobile number'), findsNothing);

    auth.sendFails = AuthFailureKind.server;
    await tester.tap(find.byKey(const Key('send-otp')));
    await tester.pump();
    expect(
      find.text('The server is busy; try again in a little while'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('Marathi network failure text on the OTP screen', (tester) async {
    final auth = FailingAuth();
    await pumpApp(tester, session: null, auth: auth);
    await _openOtp(tester);
    auth.verifyFails = AuthFailureKind.network;
    await tester.enterText(find.byKey(const Key('otp')), '123456');
    await tester.tap(find.byKey(const Key('verify-otp')));
    await tester.pump();
    expect(find.text('इंटरनेट तपासा आणि पुन्हा प्रयत्न करा'), findsOneWidget);
    expect(find.text('SMS मधील नवीन ६ अंकी OTP टाका'), findsNothing);

    auth.verifyFails = AuthFailureKind.invalidOtp;
    await tester.tap(find.byKey(const Key('verify-otp')));
    await tester.pump();
    expect(find.text('SMS मधील नवीन ६ अंकी OTP टाका'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('resend OTP waits 30 s, then sends again and restarts the wait', (
    tester,
  ) async {
    final auth = FailingAuth();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      auth: auth,
    );
    await _openOtp(tester);
    expect(auth.sends, 1);
    expect(find.text('Resend OTP in 30 s'), findsOneWidget);
    expect(find.byKey(const Key('resend-otp')), findsNothing);

    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Resend OTP in 20 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    expect(find.byKey(const Key('resend-countdown')), findsNothing);

    await tester.tap(find.byKey(const Key('resend-otp')));
    await tester.pump();
    expect(auth.sends, 2);
    expect(find.text('A new OTP has been sent'), findsOneWidget);
    expect(find.text('Resend OTP in 30 s'), findsOneWidget);

    // A failed resend says why, and the code typed so far is kept for another try.
    await tester.pump(const Duration(seconds: 30));
    auth.sendFails = AuthFailureKind.network;
    await tester.tap(find.byKey(const Key('resend-otp')));
    await tester.pump();
    expect(find.text('Check the internet and try again'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('change number goes back to the phone field', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      auth: FailingAuth(),
    );
    await _openOtp(tester);
    await tester.tap(find.byKey(const Key('change-number')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('phone')), findsOneWidget);
    expect(find.byKey(const Key('otp')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('without PHONE_LOGIN the login page offers Google only', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      config: _backendConfig,
      auth: FailingAuth(),
    );
    expect(find.text('Start with your Google account'), findsOneWidget);
    expect(find.byKey(const Key('phone')), findsNothing);
    expect(find.byKey(const Key('send-otp')), findsNothing);
    expect(find.byKey(const Key('google-login')), findsOneWidget);
    expect(find.byKey(const Key('try-without-account')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('with PHONE_LOGIN=true the phone path is back', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      config: _backendWithPhone,
      auth: FailingAuth(),
    );
    expect(find.text('Sign in with your mobile number'), findsOneWidget);
    expect(find.byKey(const Key('phone')), findsOneWidget);
    expect(find.byKey(const Key('google-login')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Google sign-in offline asks to check the internet', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      session: null,
      config: _backendConfig,
      auth: _GoogleOffline(),
    );
    await tester.tap(find.byKey(const Key('google-login')));
    await tester.pump();
    expect(find.byKey(const Key('google-error')), findsOneWidget);
    expect(find.text('Check the internet and try again'), findsOneWidget);
    await unmountApp(tester);
  });
}

class _GoogleOffline extends DemoAuthRepository {
  @override
  Future<void> signInWithGoogle() async =>
      throw const AuthFailure(AuthFailureKind.network);
}
