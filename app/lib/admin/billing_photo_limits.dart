import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../theme/app_theme.dart';
import 'billing_admin_repository.dart';
import 'billing_strings.dart';

/// Digits to a whole number; empty (or not a number) is null = "use the default".
int? photoLimit(String text) => int.tryParse(text.trim());

String _text(int? value) => value == null ? '' : '$value';

/// Which per-farmer AI limits a [PhotoLimitsCard] edits: crop photo analysis (Q135) or
/// reading a shop bill photo (Q136). Both have the same shape on the API.
enum LimitsKind {
  photo('photo'),
  bill('bill');

  const LimitsKind(this.prefix);

  /// Key prefix of the card's widgets (`billing-<prefix>-…`) and of its own strings.
  final String prefix;
}

/// One kind's values from the settings, so the card reads both kinds the same way.
typedef _Limits = ({
  int? freeDaily,
  int? freeMonthly,
  int? dailyTotal,
  int? defaultDaily,
  int? defaultMonthly,
});

_Limits _limits(BillingSettingsOut s, LimitsKind kind) => switch (kind) {
  LimitsKind.photo => (
    freeDaily: s.photoLimits.freeDaily,
    freeMonthly: s.photoLimits.freeMonthly,
    dailyTotal: s.photoLimits.dailyTotal,
    defaultDaily: s.photoLimits.defaultDaily,
    defaultMonthly: s.photoLimits.defaultMonthly,
  ),
  LimitsKind.bill => (
    freeDaily: s.billLimits.freeDaily,
    freeMonthly: s.billLimits.freeMonthly,
    dailyTotal: s.billLimits.dailyTotal,
    defaultDaily: s.billLimits.defaultDaily,
    defaultMonthly: s.billLimits.defaultMonthly,
  ),
};

(int?, int?) _roleLimits(RolePriceOut r, LimitsKind kind) => switch (kind) {
  LimitsKind.photo => (r.photoAiDaily, r.photoAiMonthly),
  LimitsKind.bill => (r.billReadDaily, r.billReadMonthly),
};

/// Per-farmer AI limits on the Subscriptions page (owner 2026-11-11): photos analysed
/// (Q135, [LimitsKind.photo]) or bills read (Q136, [LimitsKind.bill]) per farmer per day /
/// month for farmers without a plan and for each role's plan, and the optional overall daily
/// cap. Empty = the default the API reports (5 / 50); empty overall cap = no cap. [run] saves
/// through the page (snack bar, refreshed settings).
class PhotoLimitsCard extends StatefulWidget {
  const PhotoLimitsCard({
    required this.settings,
    required this.repo,
    required this.run,
    this.kind = LimitsKind.photo,
    super.key,
  });

  final BillingSettingsOut settings;
  final BillingAdminRepository repo;
  final Future<void> Function(Future<BillingSettingsOut> Function() call) run;
  final LimitsKind kind;

  @override
  State<PhotoLimitsCard> createState() => _PhotoLimitsCardState();
}

class _PhotoLimitsCardState extends State<PhotoLimitsCard> {
  final _freeDaily = TextEditingController();
  final _freeMonthly = TextEditingController();
  final _total = TextEditingController();
  final _daily = {for (final r in billingRoles) r: TextEditingController()};
  final _monthly = {for (final r in billingRoles) r: TextEditingController()};

  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void didUpdateWidget(PhotoLimitsCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.settings, widget.settings)) _fill();
  }

  void _fill() {
    final p = _limits(widget.settings, widget.kind);
    _freeDaily.text = _text(p.freeDaily);
    _freeMonthly.text = _text(p.freeMonthly);
    _total.text = _text(p.dailyTotal);
    for (final r in widget.settings.roles) {
      final (daily, monthly) = _roleLimits(r, widget.kind);
      _daily[r.role]?.text = _text(daily);
      _monthly[r.role]?.text = _text(monthly);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _freeDaily,
      _freeMonthly,
      _total,
      ..._daily.values,
      ..._monthly.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<BillingSettingsOut> _saveFree() {
    final freeDaily = photoLimit(_freeDaily.text);
    final freeMonthly = photoLimit(_freeMonthly.text);
    final dailyTotal = photoLimit(_total.text);
    return switch (widget.kind) {
      LimitsKind.photo => widget.repo.savePhotoLimits(
        freeDaily: freeDaily,
        freeMonthly: freeMonthly,
        dailyTotal: dailyTotal,
      ),
      LimitsKind.bill => widget.repo.saveBillLimits(
        freeDaily: freeDaily,
        freeMonthly: freeMonthly,
        dailyTotal: dailyTotal,
      ),
    };
  }

  Future<BillingSettingsOut> _saveRole(String role) {
    final daily = photoLimit(_daily[role]!.text);
    final monthly = photoLimit(_monthly[role]!.text);
    return switch (widget.kind) {
      LimitsKind.photo => widget.repo.saveRolePhotoLimits(
        role,
        daily: daily,
        monthly: monthly,
      ),
      LimitsKind.bill => widget.repo.saveRoleBillLimits(
        role,
        daily: daily,
        monthly: monthly,
      ),
    };
  }

  Widget _field(Key key, TextEditingController c, String label, String hint) =>
      SizedBox(
        width: 170,
        child: TextField(
          key: key,
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  Widget _save(
    Key key,
    BillingStrings s,
    Future<BillingSettingsOut> Function() call,
  ) => SizedBox(
    width: 140,
    child: FilledButton(
      key: key,
      onPressed: () => widget.run(call),
      child: Text(s['save']),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = BillingStrings.of(context);
    final c = context.bm;
    final k = widget.kind.prefix;
    final p = _limits(widget.settings, widget.kind);
    final day = '${p.defaultDaily ?? 5}';
    final month = '${p.defaultMonthly ?? 50}';
    Widget row(List<Widget> children) => Padding(
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
      child: Wrap(
        spacing: BmSpace.md,
        runSpacing: BmSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
    Widget label(String text) =>
        SizedBox(width: 220, child: Text(text, style: BmType.bodyStrong));
    return BmCard(
      key: Key('billing-$k-limits'),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: s['${k}_card']),
          Text(
            s.fill('photo_empty', '$day / $month'),
            style: BmType.body.copyWith(color: c.inkMuted),
          ),
          Text(s['photo_ist'], style: BmType.meta.copyWith(color: c.inkMuted)),
          row([
            label(s['photo_no_plan']),
            _field(
              Key('billing-$k-free-daily'),
              _freeDaily,
              s['${k}_daily'],
              day,
            ),
            _field(
              Key('billing-$k-free-monthly'),
              _freeMonthly,
              s['${k}_monthly'],
              month,
            ),
          ]),
          row([
            label(s['photo_total']),
            _field(
              Key('billing-$k-total'),
              _total,
              s['photo_total'],
              s['photo_total_empty'],
            ),
            _save(Key('billing-$k-save'), s, _saveFree),
          ]),
          const Divider(),
          for (final r in widget.settings.roles)
            row([
              label(s[r.role]),
              _field(
                Key('billing-$k-daily-${r.role}'),
                _daily[r.role]!,
                s['${k}_daily'],
                day,
              ),
              _field(
                Key('billing-$k-monthly-${r.role}'),
                _monthly[r.role]!,
                s['${k}_monthly'],
                month,
              ),
              _save(
                Key('billing-$k-save-${r.role}'),
                s,
                () => _saveRole(r.role),
              ),
            ]),
        ],
      ),
    );
  }
}
