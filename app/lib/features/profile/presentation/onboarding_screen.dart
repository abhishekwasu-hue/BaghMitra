import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/farmer_profile.dart';

/// First-run setup: language (Marathi first), optional name and place, and the consent the app
/// needs to store the grower's records. Saved offline like any other record.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _defaultLanguage = 'mr';

  final _name = TextEditingController();
  final _village = TextEditingController();
  final _taluka = TextEditingController();
  final _district = TextEditingController();
  var _language = _defaultLanguage;
  var _consentData = false;
  var _consentWhatsapp = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    // Show the screen in the preselected language straight away.
    Future.microtask(
      () => ref.read(languagePreviewProvider.notifier).set(_language),
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _village, _taluka, _district]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final userId = ref.read(authRepositoryProvider).current?.userId;
    if (userId == null || !_consentData || _saving) return;
    setState(() => _saving = true);
    await ref
        .read(profileRepositoryProvider)
        .save(
          FarmerProfile(
            id: userId,
            language: _language,
            displayName: _text(_name),
            village: _text(_village),
            taluka: _text(_taluka),
            district: _text(_district),
            consentDataProcessing: true,
            consentWhatsapp: _consentWhatsapp,
          ),
        );
    // The saved profile now decides the language, and the router moves on to home.
    ref.read(languagePreviewProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final languages = ref.watch(languagesProvider).value ?? const [];
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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.xl),
          children: [
            Text(
              t.onboardingWelcome,
              style: BmType.title.copyWith(color: c.brand),
            ),
            const SizedBox(height: BmSpace.lg),
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
                      ref.read(languagePreviewProvider.notifier).set(l.slug);
                    },
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.lg),
            field('profile-name', _name, t.onboardingName),
            field('profile-village', _village, t.onboardingVillage),
            field('profile-taluka', _taluka, t.onboardingTaluka),
            field('profile-district', _district, t.onboardingDistrict),
            CheckboxListTile(
              key: const Key('consent-data'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(t.onboardingConsentData, style: BmType.body),
              value: _consentData,
              onChanged: (v) => setState(() => _consentData = v ?? false),
            ),
            CheckboxListTile(
              key: const Key('consent-whatsapp'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(t.onboardingConsentWhatsapp, style: BmType.body),
              value: _consentWhatsapp,
              onChanged: (v) => setState(() => _consentWhatsapp = v ?? false),
            ),
            const SizedBox(height: BmSpace.lg),
            FilledButton(
              onPressed: _consentData && !_saving ? _save : null,
              child: Text(t.onboardingContinue),
            ),
          ],
        ),
      ),
    );
  }
}
