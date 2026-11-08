import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../theme/app_theme.dart';
import 'billing_admin_repository.dart';
import 'billing_strings.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'package_pages.dart' show packageDate, packageSay, rupeesToPaise;

String _rupees(int? paise) => paise == null ? '' : '${paise ~/ 100}';

/// The admin web's "Subscriptions" section (billing addendum §7): the switch (default
/// OFF) with an optional start date, Play's price-change rules shown before any amount is
/// saved, one monthly ₹ amount per role (written to Play; Play's price shown) and the
/// confirmed move of existing subscribers.
class BillingSettingsPage extends StatefulWidget {
  const BillingSettingsPage({required this.repo, super.key});
  final BillingAdminRepository repo;

  @override
  State<BillingSettingsPage> createState() => _BillingSettingsPageState();
}

class _BillingSettingsPageState extends State<BillingSettingsPage> {
  final _amounts = {for (final r in billingRoles) r: TextEditingController()};
  BillingSettingsOut? _settings;
  bool _enabled = false;
  DateTime? _start;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await widget.repo.settings();
      if (mounted) setState(() => _show(s));
    } on KbAdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _show(BillingSettingsOut s) {
    _settings = s;
    _enabled = s.enabled;
    _start = s.startsOn;
    for (final r in s.roles) {
      _amounts[r.role]?.text = _rupees(r.amountPaise);
    }
  }

  Future<void> _run(Future<BillingSettingsOut> Function() call) async {
    final s = BillingStrings.of(context);
    try {
      final saved = await call();
      if (!mounted) return;
      setState(() => _show(saved));
      packageSay(context, s['saved']);
    } on KbAdminException catch (e) {
      if (mounted) packageSay(context, s[e.message]);
    }
  }

  Future<void> _migrate(String role) async {
    final s = BillingStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s['migrate_confirm_title']),
        content: Text(s.fill('migrate_confirm_body', s[role])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s['cancel']),
          ),
          FilledButton(
            key: const Key('billing-migrate-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s['confirm']),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => widget.repo.migratePrices(role));
  }

  @override
  Widget build(BuildContext context) {
    final s = BillingStrings.of(context);
    final c = context.bm;
    if (_error case final e?) return Text(s[e], style: BmType.body);
    final settings = _settings;
    if (settings == null) return LoadingState(label: s['section']);
    Widget note(String key, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.xs),
      child: Text(s[key], style: BmType.body.copyWith(color: color)),
    );
    return ListView(
      padding: const EdgeInsets.only(top: BmSpace.xs),
      children: [
        BmCard(
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: s['switch_card']),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  key: const Key('billing-switch'),
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  title: Text(s['switch'], style: BmType.bodyStrong),
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ),
              note('switch_off_note', c.inkMuted),
              note('nothing_locked', c.inkMuted),
              note('gst_note', c.warnTitle),
              Row(
                children: [
                  TextButton.icon(
                    key: const Key('billing-start'),
                    icon: const Icon(Icons.event_rounded),
                    label: Text(
                      '${s['starts_on']}: '
                      '${_start == null ? '—' : packageDate(_start!)}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                  if (_start != null)
                    // Removes the date (saved as null with the switch; audit L2).
                    IconButton(
                      key: const Key('billing-start-clear'),
                      tooltip: s['clear_start'],
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _start = null),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 200,
                    child: FilledButton(
                      key: const Key('billing-save-switch'),
                      onPressed: () => _run(
                        () => widget.repo.saveSwitch(
                          enabled: _enabled,
                          startsOn: _start,
                        ),
                      ),
                      child: Text(s['save']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: BmSpace.md),
        BmCard(
          key: const Key('billing-rules'),
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: s['rules_card']),
              for (final (key, icon, color) in [
                ('rule_new', Icons.fiber_new_rounded, c.brandStrong),
                ('rule_down', Icons.south_rounded, c.brandStrong),
                ('rule_up_keep', Icons.north_rounded, c.warnTitle),
                ('rule_up_notice', Icons.campaign_rounded, c.warnTitle),
                ('rule_no_deal', Icons.handshake_rounded, c.inkMuted),
              ])
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: color),
                  title: Text(s[key], style: BmType.body),
                ),
            ],
          ),
        ),
        const SizedBox(height: BmSpace.md),
        BmCard(
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: s['roles_card']),
              for (final r in settings.roles) _roleRow(context, s, r),
            ],
          ),
        ),
      ],
    );
  }

  /// A role with no amount reads "free"; Play's last price, kept there, is a second line
  /// "in Play" (audit L1).
  Widget _priceText(
    BuildContext context,
    BillingStrings s,
    RolePriceOut r, {
    required bool free,
  }) {
    final c = context.bm;
    final play = r.playPricePaise;
    final synced = r.playSyncedAt;
    final price = play == null
        ? null
        : '${r.playCurrency ?? 'INR'} ${(play / 100).toStringAsFixed(2)}';
    final when = synced == null ? '' : ' · ${packageDate(synced)}';
    if (!free) {
      return Text(
        price == null ? '—' : '${s['play_price']}: $price$when',
        style: BmType.body.copyWith(color: c.brandStrong),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['free'], style: BmType.body.copyWith(color: c.inkMuted)),
        if (price != null)
          Text(
            s.fill('in_play', price) + when,
            style: BmType.meta.copyWith(color: c.inkMuted),
          ),
      ],
    );
  }

  Widget _roleRow(BuildContext context, BillingStrings s, RolePriceOut r) {
    final synced = r.playSyncedAt;
    final free = r.amountPaise == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
      child: Wrap(
        spacing: BmSpace.md,
        runSpacing: BmSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(s[r.role], style: BmType.bodyStrong),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              key: Key('billing-amount-${r.role}'),
              controller: _amounts[r.role],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: s['amount']),
            ),
          ),
          SizedBox(width: 240, child: _priceText(context, s, r, free: free)),
          SizedBox(
            width: 140,
            child: FilledButton(
              key: Key('billing-save-${r.role}'),
              onPressed: () => _run(
                () => widget.repo.saveAmount(
                  r.role,
                  rupeesToPaise(_amounts[r.role]!.text),
                ),
              ),
              child: Text(s['save']),
            ),
          ),
          SizedBox(
            width: 260,
            child: OutlinedButton(
              key: Key('billing-migrate-${r.role}'),
              // Nothing to move while the role is free (audit L1).
              onPressed: free || synced == null ? null : () => _migrate(r.role),
              child: Text(s['migrate']),
            ),
          ),
        ],
      ),
    );
  }
}
