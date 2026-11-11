import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../design_system/info_note.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'market_link_admin_repository.dart';

/// Whole rupees typed by the admin to paise; empty (or not a number) is null = default.
int? rupeesToPaise(String text) {
  final v = int.tryParse(text.trim());
  return v == null ? null : v * 100;
}

/// The lot form settings (owner 2026-11-11, Q138): the asking-rate range per quintal and
/// per crate and the harvest window length. Empty = the default shown in grey; the server
/// refuses a minimum that is not below its maximum.
class LotSettingsPage extends StatefulWidget {
  const LotSettingsPage({required this.repo, super.key});
  final MarketLinkAdminRepository repo;

  @override
  State<LotSettingsPage> createState() => _LotSettingsPageState();
}

const _paiseFields = [
  'per_quintal_min_paise',
  'per_quintal_max_paise',
  'per_crate_min_paise',
  'per_crate_max_paise',
];

class _LotSettingsPageState extends State<LotSettingsPage> {
  final _text = {
    for (final f in [..._paiseFields, 'harvest_window_days'])
      f: TextEditingController(),
  };
  AdminLotSettingsOut? _settings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(widget.repo.lotSettings);
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, int?> _stored(AdminLotSettingsOut s) => {
    'per_quintal_min_paise': s.perQuintalMinPaise,
    'per_quintal_max_paise': s.perQuintalMaxPaise,
    'per_crate_min_paise': s.perCrateMinPaise,
    'per_crate_max_paise': s.perCrateMaxPaise,
    'harvest_window_days': s.harvestWindowDays,
  };

  Future<void> _run(Future<AdminLotSettingsOut> Function() call) async {
    // The first load runs from initState: no inherited lookups then.
    final first = _settings == null;
    final messenger = first ? null : ScaffoldMessenger.of(context);
    final done = first ? '' : AppLocalizations.of(context).adminDone;
    try {
      final s = await call();
      if (!mounted) return;
      setState(() {
        _settings = s;
        _error = null;
        for (final MapEntry(:key, :value) in _stored(s).entries) {
          _text[key]!.text = value == null
              ? ''
              : key == 'harvest_window_days'
              ? '$value'
              : '${value ~/ 100}';
        }
      });
      messenger?.showSnackBar(SnackBar(content: Text(done)));
    } on KbAdminException catch (e) {
      if (!mounted) return;
      if (first) {
        setState(() => _error = e.message);
      } else {
        messenger?.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<AdminLotSettingsOut> _save() => widget.repo.saveLotSettings(
    AdminLotSettingsIn(
      perQuintalMinPaise: rupeesToPaise(_text['per_quintal_min_paise']!.text),
      perQuintalMaxPaise: rupeesToPaise(_text['per_quintal_max_paise']!.text),
      perCrateMinPaise: rupeesToPaise(_text['per_crate_min_paise']!.text),
      perCrateMaxPaise: rupeesToPaise(_text['per_crate_max_paise']!.text),
      harvestWindowDays: int.tryParse(_text['harvest_window_days']!.text),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final s = _settings;
    if (s == null) {
      return _error == null
          ? LoadingState(label: t.adminMlLotSettings)
          : Text(_error!, style: BmType.body.copyWith(color: c.danger));
    }
    final labels = {
      'per_quintal_min_paise': t.adminMlQuintalMin,
      'per_quintal_max_paise': t.adminMlQuintalMax,
      'per_crate_min_paise': t.adminMlCrateMin,
      'per_crate_max_paise': t.adminMlCrateMax,
      'harvest_window_days': t.adminMlHarvestDays,
    };
    String hint(String f) {
      final v = (s.defaults[f] as num?)?.toInt() ?? 0;
      return f == 'harvest_window_days' ? '$v' : '${v ~/ 100}';
    }

    return ListView(
      children: [
        InfoNote(t.adminMlLotSettingsNote),
        const SizedBox(height: BmSpace.sm),
        BmCard(
          key: const Key('admin-lot-settings'),
          elevated: false,
          child: Wrap(
            spacing: BmSpace.md,
            runSpacing: BmSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final MapEntry(key: f, value: label) in labels.entries)
                SizedBox(
                  width: 220,
                  child: TextField(
                    key: Key('admin-lot-$f'),
                    controller: _text[f],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint(f),
                    ),
                  ),
                ),
              FilledButton(
                key: const Key('admin-lot-save'),
                onPressed: () => _run(_save),
                child: Text(t.save),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
