import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.enums.swagger.dart' as enums;
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

/// One end of one range: crop, basis, "min" / "max".
typedef _End = (String crop, String basis, String end);

/// The lot form settings (owner 2026-11-11, Q138): a santra block and a mosambi block, each
/// with the rate range per quintal and per crate (for the grower's asking rate and a trader's
/// offer), and the harvest window length for both. Empty = the default shown in grey; the
/// server refuses a minimum that is not below its maximum.
class LotSettingsPage extends StatefulWidget {
  const LotSettingsPage({required this.repo, super.key});
  final MarketLinkAdminRepository repo;

  @override
  State<LotSettingsPage> createState() => _LotSettingsPageState();
}

const _crops = ['santra', 'mosambi'];
const _bases = ['per_quintal', 'per_crate'];

class _LotSettingsPageState extends State<LotSettingsPage> {
  final _ends = {
    for (final c in _crops)
      for (final b in _bases)
        for (final e in ['min', 'max']) (c, b, e): TextEditingController(),
  };
  final _days = TextEditingController();
  AdminLotSettingsOut? _settings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(widget.repo.lotSettings);
  }

  @override
  void dispose() {
    for (final c in [..._ends.values, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  AdminRangeOut? _range(AdminLotSettingsOut s, String crop, String basis) => s
      .rateRanges
      .where((r) => r.crop.value == crop && r.basis.value == basis)
      .firstOrNull;

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
        for (final MapEntry(key: (crop, basis, end), :value) in _ends.entries) {
          final r = _range(s, crop, basis);
          final paise = end == 'min' ? r?.minPaise : r?.maxPaise;
          value.text = paise == null ? '' : '${paise ~/ 100}';
        }
        _days.text = s.harvestWindowDays == null
            ? ''
            : '${s.harvestWindowDays}';
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
      rateRanges: [
        for (final c in _crops)
          for (final b in _bases)
            AdminRangeIn(
              crop: enums.AdminRangeInCrop.values.byName(c),
              basis: enums.AdminRangeInBasis.values.firstWhere(
                (x) => x.value == b,
              ),
              minPaise: rupeesToPaise(_ends[(c, b, 'min')]!.text),
              maxPaise: rupeesToPaise(_ends[(c, b, 'max')]!.text),
            ),
      ],
      harvestWindowDays: int.tryParse(_days.text.trim()),
    ),
  );

  Widget _field(Key key, TextEditingController c, String label, String hint) =>
      SizedBox(
        width: 200,
        child: TextField(
          key: key,
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, hintText: hint),
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
    String label(_End k) => switch (k) {
      (_, 'per_quintal', 'min') => t.adminMlQuintalMin,
      (_, 'per_quintal', _) => t.adminMlQuintalMax,
      (_, _, 'min') => t.adminMlCrateMin,
      _ => t.adminMlCrateMax,
    };
    String hint(_End k) {
      final r = _range(s, k.$1, k.$2);
      final v = (k.$3 == 'min' ? r?.defaultMinPaise : r?.defaultMaxPaise) ?? 0;
      return '${v ~/ 100}';
    }

    Widget block(String crop) => BmCard(
      key: Key('admin-lot-$crop'),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: crop == 'santra'
                ? t.adminMlCropSantra
                : t.adminMlCropMosambi,
          ),
          Wrap(
            spacing: BmSpace.md,
            runSpacing: BmSpace.sm,
            children: [
              for (final b in _bases)
                for (final e in ['min', 'max'])
                  _field(
                    Key('admin-lot-$crop-$b-$e'),
                    _ends[(crop, b, e)]!,
                    label((crop, b, e)),
                    hint((crop, b, e)),
                  ),
            ],
          ),
        ],
      ),
    );

    return ListView(
      children: [
        InfoNote(t.adminMlLotSettingsNote),
        const SizedBox(height: BmSpace.sm),
        for (final crop in _crops) ...[
          block(crop),
          const SizedBox(height: BmSpace.sm),
        ],
        Wrap(
          spacing: BmSpace.md,
          runSpacing: BmSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _field(
              const Key('admin-lot-harvest_window_days'),
              _days,
              t.adminMlHarvestDays,
              '${s.harvestWindowDaysDefault}',
            ),
            FilledButton(
              key: const Key('admin-lot-save'),
              onPressed: () => _run(_save),
              child: Text(t.save),
            ),
          ],
        ),
      ],
    );
  }
}
