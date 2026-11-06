import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../auth/domain/auth.dart';
import '../data/account_deletion.dart';
import '../domain/farmer_profile.dart';

/// The grower's own details after setup: name, place, app language, consents, contact number,
/// signing out, the privacy policy link and deleting the account (S-10). Saved offline
/// through the same repository as onboarding.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _village = TextEditingController();
  final _taluka = TextEditingController();
  final _district = TextEditingController();
  final _phone = TextEditingController();
  FarmerProfile? _profile;
  String? _language;
  var _consentWhatsapp = false;
  String? _phoneError;
  var _saving = false;
  var _deleting = false;

  @override
  void initState() {
    super.initState();
    // Fill the form once, from the saved profile (already loaded when home is showing).
    ref.listenManual<AsyncValue<FarmerProfile?>>(profileProvider, (_, next) {
      final p = next.value;
      if (p == null || _profile != null) return;
      _profile = p;
      _name.text = p.displayName ?? '';
      _village.text = p.village ?? '';
      _taluka.text = p.taluka ?? '';
      _district.text = p.district ?? '';
      _phone.text = p.phone ?? '';
      _language = p.language;
      _consentWhatsapp = p.consentWhatsapp;
      if (mounted) setState(() {});
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    for (final c in [_name, _village, _taluka, _district, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  /// Google sign-ins carry no phone number; they may add one as a contact.
  bool get _signedInWithPhone =>
      ref.read(authRepositoryProvider).current?.phone.isNotEmpty ?? false;

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final p = _profile;
    if (p == null || _saving) return;
    var phone = p.phone;
    if (!_signedInWithPhone) {
      final typed = _text(_phone);
      phone = typed == null ? null : normalizeIndianMobile(typed);
      if (typed != null && phone == null) {
        setState(() => _phoneError = t.loginInvalidPhone);
        return;
      }
    }
    setState(() {
      _saving = true;
      _phoneError = null;
    });
    final saved = FarmerProfile(
      id: p.id,
      language: _language ?? p.language,
      displayName: _text(_name),
      village: _text(_village),
      taluka: _text(_taluka),
      district: _text(_district),
      phone: phone,
      consentDataProcessing: p.consentDataProcessing,
      consentWhatsapp: _consentWhatsapp,
    );
    await ref.read(profileRepositoryProvider).save(saved);
    _profile = saved;
    // The saved profile now decides the language.
    ref.read(languagePreviewProvider.notifier).set(null);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.profileSaved)));
  }

  Future<void> _signOut() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.profileSignOutTitle),
        content: Text(t.profileSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            key: const Key('sign-out-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.profileSignOut),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(languagePreviewProvider.notifier).set(null);
    // Only the session ends: the records stay on this phone, as before.
    // Push alerts for this account stop on this phone (no-op with push off).
    await ref.read(pushRegistrarProvider).beforeSignOut();
    await ref.read(authRepositoryProvider).signOut();
  }

  String get _privacyUrl {
    final base = ref.read(appConfigProvider).apiBaseUrl;
    return '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/privacy';
  }

  /// No browser plugin in the app: the link is copied for the grower to open.
  Future<void> _copyPrivacyLink() async {
    final t = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _privacyUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.feedLinkCopied)));
  }

  Future<void> _deleteAccount() async {
    final t = AppLocalizations.of(context);
    if (_deleting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      ref.read(languagePreviewProvider.notifier).set(null);
      // Server first, then this phone, then sign-out (the router then shows login).
      await ref.read(accountDeletionProvider).run();
    } on AccountDeletionException catch (e) {
      ref.read(appLogProvider).log('account deletion: ${e.reason}');
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.profileDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final languages = ref.watch(languagesProvider).value ?? const [];
    final session = ref.watch(sessionProvider).value;
    final p = _profile;
    Widget field(String key, TextEditingController controller, String label) =>
        Padding(
          padding: const EdgeInsets.only(bottom: BmSpace.sm),
          child: TextField(
            key: Key(key),
            controller: controller,
            maxLength: 120,
            decoration: InputDecoration(counterText: '', labelText: label),
          ),
        );
    return PopScope(
      // Leaving without saving puts back the saved language.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(languagePreviewProvider.notifier).set(null);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t.profileTitle)),
        body: p == null
            ? const SizedBox.shrink()
            : ListView(
                key: const Key('profile-list'),
                padding: const EdgeInsets.all(BmSpace.lg),
                children: [
                  field('profile-name', _name, t.onboardingName),
                  field('profile-village', _village, t.onboardingVillage),
                  field('profile-taluka', _taluka, t.onboardingTaluka),
                  field('profile-district', _district, t.onboardingDistrict),
                  if (session != null && session.phone.isNotEmpty)
                    ListTile(
                      key: const Key('profile-phone-readonly'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.loginPhoneLabel, style: BmType.meta),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.phone, style: BmType.bodyStrong),
                          Text(
                            t.profilePhoneSignedIn,
                            style: BmType.meta.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: BmSpace.sm),
                      child: TextField(
                        key: const Key('profile-phone'),
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 16,
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: t.profileAddPhone,
                          helperText: t.profilePhoneContactOnly,
                          helperMaxLines: 3,
                          errorText: _phoneError,
                        ),
                      ),
                    ),
                  const SizedBox(height: BmSpace.md),
                  Text(t.onboardingLanguage, style: BmType.section),
                  const SizedBox(height: BmSpace.xs),
                  Wrap(
                    spacing: BmSpace.xs,
                    children: [
                      for (final l in languages)
                        ChoiceChip(
                          label: Text(l.label('en'), style: BmType.bodyStrong),
                          selected: _language == l.slug,
                          onSelected: (_) {
                            setState(() => _language = l.slug);
                            // The whole app switches at once, like on setup.
                            ref
                                .read(languagePreviewProvider.notifier)
                                .set(l.slug);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: BmSpace.md),
                  CheckboxListTile(
                    key: const Key('consent-data'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(t.onboardingConsentData, style: BmType.body),
                    subtitle: Text(
                      t.profileConsentDataNote,
                      style: BmType.meta.copyWith(color: c.inkMuted),
                    ),
                    value: p.consentDataProcessing,
                    onChanged: null,
                  ),
                  CheckboxListTile(
                    key: const Key('consent-whatsapp'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      t.onboardingConsentWhatsapp,
                      style: BmType.body,
                    ),
                    value: _consentWhatsapp,
                    onChanged: (v) =>
                        setState(() => _consentWhatsapp = v ?? false),
                  ),
                  const SizedBox(height: BmSpace.lg),
                  FilledButton(
                    key: const Key('profile-save'),
                    onPressed: _saving ? null : _save,
                    child: Text(t.save),
                  ),
                  const SizedBox(height: BmSpace.md),
                  // The way to Settings in every build (audit R2): photo backup on mobile
                  // data, the introduction, sending the log, the app version.
                  OutlinedButton.icon(
                    key: const Key('profile-settings'),
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => context.push(Routes.settings),
                    label: Text(t.settingsTitle),
                  ),
                  const SizedBox(height: BmSpace.xl),
                  OutlinedButton(
                    key: const Key('sign-out'),
                    onPressed: _signOut,
                    child: Text(t.profileSignOut),
                  ),
                  const SizedBox(height: BmSpace.lg),
                  ListTile(
                    key: const Key('profile-privacy'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(t.profilePrivacy, style: BmType.bodyStrong),
                    subtitle: Text(
                      '${t.profilePrivacyHint}\n$_privacyUrl',
                      style: BmType.meta.copyWith(color: c.inkMuted),
                    ),
                    trailing: const Icon(Icons.copy),
                    onTap: _copyPrivacyLink,
                  ),
                  const SizedBox(height: BmSpace.md),
                  TextButton.icon(
                    key: const Key('delete-account'),
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    onPressed: _deleting ? null : _deleteAccount,
                    icon: _deleting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(t.profileDeleteAccount),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Asks the grower to type the confirmation word before anything is deleted.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  /// The word in the app's language, or the English one, in any case.
  bool _confirmed(AppLocalizations t) {
    final typed = _typed.text.trim().toLowerCase();
    return typed == t.profileDeleteWord.toLowerCase() || typed == 'delete';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return AlertDialog(
      title: Text(t.profileDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.profileDeleteBody(t.profileDeleteWord)),
          const SizedBox(height: BmSpace.sm),
          TextField(
            key: const Key('delete-account-word'),
            controller: _typed,
            autofocus: true,
            decoration: InputDecoration(hintText: t.profileDeleteWord),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const Key('delete-account-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: c.onBrand,
          ),
          onPressed: _confirmed(t)
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(t.profileDeleteConfirm),
        ),
      ],
    );
  }
}
