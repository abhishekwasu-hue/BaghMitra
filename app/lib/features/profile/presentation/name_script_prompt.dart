import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/name_script_flag.dart';
import '../domain/farmer_profile.dart';

/// A small card on home: in Marathi or Hindi, a name saved in Latin letters ("Abhishek जी")
/// is offered to be written once in the language's script. Save updates the profile name
/// (synced as any profile change); "no" hides it for this language on this phone.
class NameScriptPrompt extends ConsumerStatefulWidget {
  const NameScriptPrompt({super.key});

  @override
  ConsumerState<NameScriptPrompt> createState() => _NameScriptPromptState();
}

class _NameScriptPromptState extends ConsumerState<NameScriptPrompt> {
  final _name = TextEditingController();

  /// Dismissed languages as read from the phone (null: not read yet).
  final _dismissed = <String, bool>{};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _readDismissed(String lang) async {
    final v = await NameScriptFlag(ref.read(databaseProvider)).dismissed(lang);
    if (mounted) setState(() => _dismissed[lang] = v);
  }

  Future<void> _dismiss(String lang) async {
    setState(() => _dismissed[lang] = true);
    await NameScriptFlag(ref.read(databaseProvider)).dismiss(lang);
  }

  Future<void> _save(FarmerProfile p) async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    await ref
        .read(profileRepositoryProvider)
        .save(
          FarmerProfile(
            id: p.id,
            language: p.language,
            displayName: name,
            village: p.village,
            taluka: p.taluka,
            district: p.district,
            phone: p.phone,
            consentDataProcessing: p.consentDataProcessing,
            consentWhatsapp: p.consentWhatsapp,
          ),
        );
    if (!mounted) return;
    _name.clear();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final profile = ref.watch(profileProvider).value;
    final name = profile?.displayName?.trim() ?? '';
    if (profile == null ||
        !devanagariLanguages.contains(lang) ||
        !nameNeedsScript(name)) {
      return const SizedBox.shrink();
    }
    final dismissed = _dismissed[lang];
    if (dismissed == null) {
      _dismissed[lang] = true; // hidden while it is read
      _readDismissed(lang);
      return const SizedBox.shrink();
    }
    if (dismissed) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: BmCard(
        key: const Key('name-script-prompt'),
        radius: BmRadius.card,
        padding: const EdgeInsets.all(BmSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.nameScriptPromptTitle, style: BmType.bodyStrong),
            const SizedBox(height: BmSpace.xs),
            TextField(
              key: const Key('name-script-field'),
              controller: _name,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.nameScriptFieldLabel,
              ),
              onSubmitted: (_) => _save(profile),
            ),
            const SizedBox(height: BmSpace.xs),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('name-script-later'),
                    onPressed: () => _dismiss(lang),
                    child: Text(
                      t.nameScriptLater,
                      style: TextStyle(color: c.inkMuted),
                    ),
                  ),
                ),
                const SizedBox(width: BmSpace.xs),
                Expanded(
                  child: FilledButton(
                    key: const Key('name-script-save'),
                    onPressed: _saving ? null : () => _save(profile),
                    child: Text(t.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
