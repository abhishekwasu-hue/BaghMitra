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

/// Photo analysis limits on the Subscriptions page (owner 2026-11-11, Q135): photos per
/// farmer per day / month for farmers without a plan and for each role's plan, and the
/// optional overall daily cap. Empty = the default the API reports (5 / 50); empty overall
/// cap = no cap. [run] saves through the page (snack bar, refreshed settings).
class PhotoLimitsCard extends StatefulWidget {
  const PhotoLimitsCard({
    required this.settings,
    required this.repo,
    required this.run,
    super.key,
  });

  final BillingSettingsOut settings;
  final BillingAdminRepository repo;
  final Future<void> Function(Future<BillingSettingsOut> Function() call) run;

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
    final p = widget.settings.photoLimits;
    _freeDaily.text = _text(p.freeDaily);
    _freeMonthly.text = _text(p.freeMonthly);
    _total.text = _text(p.dailyTotal);
    for (final r in widget.settings.roles) {
      _daily[r.role]?.text = _text(r.photoAiDaily);
      _monthly[r.role]?.text = _text(r.photoAiMonthly);
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
    final p = widget.settings.photoLimits;
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
      key: const Key('billing-photo-limits'),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: s['photo_card']),
          Text(
            s.fill('photo_empty', '$day / $month'),
            style: BmType.body.copyWith(color: c.inkMuted),
          ),
          Text(s['photo_ist'], style: BmType.meta.copyWith(color: c.inkMuted)),
          row([
            label(s['photo_no_plan']),
            _field(
              const Key('billing-photo-free-daily'),
              _freeDaily,
              s['photo_daily'],
              day,
            ),
            _field(
              const Key('billing-photo-free-monthly'),
              _freeMonthly,
              s['photo_monthly'],
              month,
            ),
          ]),
          row([
            label(s['photo_total']),
            _field(
              const Key('billing-photo-total'),
              _total,
              s['photo_total'],
              s['photo_total_empty'],
            ),
            _save(
              const Key('billing-photo-save'),
              s,
              () => widget.repo.savePhotoLimits(
                freeDaily: photoLimit(_freeDaily.text),
                freeMonthly: photoLimit(_freeMonthly.text),
                dailyTotal: photoLimit(_total.text),
              ),
            ),
          ]),
          const Divider(),
          for (final r in widget.settings.roles)
            row([
              label(s[r.role]),
              _field(
                Key('billing-photo-daily-${r.role}'),
                _daily[r.role]!,
                s['photo_daily'],
                day,
              ),
              _field(
                Key('billing-photo-monthly-${r.role}'),
                _monthly[r.role]!,
                s['photo_monthly'],
                month,
              ),
              _save(
                Key('billing-photo-save-${r.role}'),
                s,
                () => widget.repo.saveRolePhotoLimits(
                  r.role,
                  daily: photoLimit(_daily[r.role]!.text),
                  monthly: photoLimit(_monthly[r.role]!.text),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}
