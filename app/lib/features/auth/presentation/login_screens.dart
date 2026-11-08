import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../market_link/data/market_link_providers.dart';
import '../../market_link/presentation/role_label.dart';
import '../domain/auth.dart';

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.xl),
          children: [
            const SizedBox(height: BmSpace.xxl),
            Center(
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: c.headerGradient),
                ),
                child: const GlyphIcon(BmGlyph.orange),
              ),
            ),
            const SizedBox(height: BmSpace.xl),
            Text(
              title,
              style: BmType.title.copyWith(color: c.brand),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BmSpace.xl),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// What the grower is told for a failed sign-in step. Only an invalid number or code points
/// at what he typed; a network or service failure says what to do next.
String authFailureText(AppLocalizations t, AuthFailureKind kind) =>
    switch (kind) {
      AuthFailureKind.invalidPhone => t.loginInvalidPhone,
      AuthFailureKind.invalidOtp => t.loginInvalidOtp,
      AuthFailureKind.network => t.netOffline,
      AuthFailureKind.phoneUnavailable => t.loginPhoneUnavailable,
      AuthFailureKind.server ||
      AuthFailureKind.rateLimited ||
      AuthFailureKind.unknown => t.netServer,
    };

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phone = TextEditingController();
  String? _error;
  String? _googleError;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final e164 = normalizeIndianMobile(_phone.text);
    if (e164 == null) {
      setState(() => _error = t.loginInvalidPhone);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _googleError = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendOtp(e164);
      if (mounted) {
        await context.push(
          Uri(path: Routes.otp, queryParameters: {'phone': e164}).toString(),
        );
      }
    } on AuthFailure catch (f) {
      if (mounted) setState(() => _error = authFailureText(t, f.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _googleError = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthFailure catch (f) {
      if (mounted) {
        setState(
          () => _googleError = f.kind == AuthFailureKind.network
              ? t.netOffline
              : t.loginGoogleFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Offline test mode: a local-only account, nothing leaves the phone. Only offered when no
  /// backend is configured, so a build with Supabase keys goes straight to real login.
  Future<void> _tryWithoutAccount() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(localAccountPhone, localAccountCode);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final demo = config.demoMode;
    final phone = config.phoneLoginEnabled;
    final googleLabel = Text(t.loginGoogle);
    const googleIcon = Icon(Icons.account_circle_outlined);
    return _AuthScaffold(
      title: phone ? t.loginTitle : t.loginTitleGoogle,
      children: [
        if (phone) ...[
          TextField(
            key: const Key('phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            style: BmType.bigNumber.copyWith(fontSize: 26, letterSpacing: 1.5),
            decoration: InputDecoration(
              labelText: t.loginPhoneLabel,
              prefixText: '+91  ',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: BmSpace.lg),
          FilledButton(
            key: const Key('send-otp'),
            onPressed: _busy ? null : _submit,
            child: Text(t.loginSendOtp),
          ),
          const SizedBox(height: BmSpace.md),
          Text(t.loginOr, textAlign: TextAlign.center, style: BmType.meta),
          const SizedBox(height: BmSpace.md),
          OutlinedButton.icon(
            key: const Key('google-login'),
            onPressed: _busy ? null : _google,
            icon: googleIcon,
            label: googleLabel,
          ),
        ] else
          FilledButton.icon(
            key: const Key('google-login'),
            onPressed: _busy ? null : _google,
            icon: googleIcon,
            label: googleLabel,
          ),
        if (_googleError case final message?) ...[
          const SizedBox(height: BmSpace.sm),
          Text(
            message,
            key: const Key('google-error'),
            textAlign: TextAlign.center,
            style: BmType.meta.copyWith(color: context.bm.danger),
          ),
        ],
        // Market link (spec v1.5 §2.1): the picked role card, and the way back to the five.
        if (config.marketLink) ...[
          const SizedBox(height: BmSpace.lg),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: BmSpace.xs,
            children: [
              if (ref.watch(activeMarketRoleProvider).value case final role?)
                Text(
                  t.mlLoginRole(roleLabel(t, role)),
                  key: const Key('login-role'),
                  style: BmType.bodyStrong,
                ),
              TextButton.icon(
                key: const Key('login-switch-role'),
                onPressed: () => context.go(Routes.roles),
                icon: const Icon(Icons.swap_horiz),
                label: Text(t.mlSwitchRole),
              ),
            ],
          ),
        ],
        if (demo) ...[
          const SizedBox(height: BmSpace.md),
          OutlinedButton(
            key: const Key('try-without-account'),
            onPressed: _busy ? null : _tryWithoutAccount,
            child: Text(t.loginTryWithout),
          ),
          const SizedBox(height: BmSpace.md),
          Text(
            t.loginDemoNotice,
            textAlign: TextAlign.center,
            style: BmType.meta,
          ),
        ],
      ],
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  /// How long the grower waits before asking for a new OTP.
  static const resendAfter = Duration(seconds: 30);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  String? _error;
  String? _note;
  bool _busy = false;
  Timer? _timer;
  int _wait = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _wait = OtpScreen.resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _wait--);
      if (_wait <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    final t = AppLocalizations.of(context);
    if (!isValidOtp(_code.text)) {
      setState(() => _error = t.loginInvalidOtp);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _note = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(widget.phone, _code.text);
      // The router redirects home once the session stream reports the sign-in.
    } on AuthFailure catch (f) {
      if (mounted) setState(() => _error = authFailureText(t, f.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _note = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendOtp(widget.phone);
      if (mounted) {
        _code.clear();
        setState(() {
          _note = t.loginOtpResent;
          _startCountdown();
        });
      }
    } on AuthFailure catch (f) {
      if (mounted) setState(() => _error = authFailureText(t, f.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeNumber() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _AuthScaffold(
      title: t.loginOtpTitle(widget.phone),
      children: [
        TextField(
          key: const Key('otp'),
          controller: _code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: BmType.bigNumber.copyWith(fontSize: 30, letterSpacing: 10),
          decoration: InputDecoration(
            labelText: t.loginOtpLabel,
            errorText: _error,
            errorMaxLines: 3,
            helperText: _note,
            counterText: '',
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: BmSpace.lg),
        FilledButton(
          key: const Key('verify-otp'),
          onPressed: _busy ? null : _verify,
          child: Text(t.loginVerify),
        ),
        const SizedBox(height: BmSpace.md),
        if (_wait > 0)
          Text(
            t.loginResendIn(_wait),
            key: const Key('resend-countdown'),
            textAlign: TextAlign.center,
            style: BmType.meta,
          )
        else
          TextButton(
            key: const Key('resend-otp'),
            onPressed: _busy ? null : _resend,
            child: Text(t.loginResendOtp),
          ),
        TextButton(
          key: const Key('change-number'),
          onPressed: _busy ? null : _changeNumber,
          child: Text(t.loginChangeNumber),
        ),
      ],
    );
  }
}
