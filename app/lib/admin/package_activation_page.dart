import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'package_admin_repository.dart';
import 'package_pages.dart';
import 'package_strings.dart';

/// Admin activation (§4E): find the grower by phone, choose a lot or all lots, enter the
/// payment received outside the app, save. Lists the grower's recorded payments.
class PackageActivationPage extends StatefulWidget {
  const PackageActivationPage({required this.repo, super.key});
  final PackageAdminRepository repo;

  @override
  State<PackageActivationPage> createState() => _PackageActivationPageState();
}

class _PackageActivationPageState extends State<PackageActivationPage> {
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _ref = TextEditingController();
  List<PackageGrowerOut>? _found;
  PackageGrowerOut? _grower;
  String _lot = '';
  String _method = 'upi';
  DateTime? _paidOn;
  List<PackageGrantOut> _grants = const [];

  @override
  void dispose() {
    for (final c in [_phone, _amount, _ref]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() call) async {
    final s = PackageStrings.of(context);
    try {
      await call();
    } on PackageAdminException catch (e) {
      final code = e.code == 'duplicate_payment_ref' ? e.code! : e.message;
      if (mounted) packageSay(context, packageErrorText(s, code));
    } on KbAdminException catch (e) {
      if (mounted) packageSay(context, e.message);
    }
  }

  Future<void> _find() => _guard(() async {
    final found = await widget.repo.findGrower(_phone.text);
    setState(() {
      _found = found;
      _grower = found.firstOrNull;
      _lot = '';
    });
    await _loadGrants();
  });

  Future<void> _loadGrants() async {
    final g = _grower;
    final grants = g == null
        ? <PackageGrantOut>[]
        : await widget.repo.grants(g.id);
    if (mounted) setState(() => _grants = grants);
  }

  bool get _ready =>
      _grower != null &&
      rupeesToPaise(_amount.text) != null &&
      _ref.text.trim().length >= 4 &&
      _paidOn != null;

  Future<void> _save() => _guard(() async {
    final s = PackageStrings.of(context);
    final g = await widget.repo.recordGrant(
      PackageGrantIn(
        growerId: _grower!.id,
        lotId: _lot.isEmpty ? null : _lot,
        amountPaise: rupeesToPaise(_amount.text)!,
        method: PackageGrantInMethod.values.byName(_method),
        paymentRef: _ref.text.trim(),
        paidOn: _paidOn!,
      ),
    );
    if (!mounted) return;
    packageSay(
      context,
      '${s['receipt_no']} ${g.receiptNo} · '
      '${s['valid_until']} ${packageDate(g.validUntil)}',
    );
    _amount.clear();
    _ref.clear();
    await _loadGrants();
  });

  Future<void> _revoke(PackageGrantOut g) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RevokeDialog(receiptNo: g.receiptNo),
    );
    if (reason == null) return;
    await _guard(() async {
      await widget.repo.revoke(g.id, reason);
      await _loadGrants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = PackageStrings.of(context);
    final c = context.bm;
    final g = _grower;
    return ListView(
      padding: const EdgeInsets.only(top: BmSpace.xs),
      children: [
        Row(
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                key: const Key('pkg-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s['phone']),
                onSubmitted: (_) => _find(),
              ),
            ),
            const SizedBox(width: BmSpace.sm),
            SizedBox(
              width: 160,
              child: FilledButton(
                key: const Key('pkg-find'),
                onPressed: _find,
                child: Text(s['find']),
              ),
            ),
          ],
        ),
        const SizedBox(height: BmSpace.md),
        if (_found case final f? when f.isEmpty)
          Text(s['no_grower'], style: BmType.body.copyWith(color: c.danger)),
        if (g != null)
          BmCard(
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text([?g.name, ?g.phone].join(' · '), style: BmType.cardTitle),
                Text(
                  [?g.village, ?g.district].join(', '),
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: BmSpace.sm),
                DropdownButtonFormField<String>(
                  key: const Key('pkg-lot'),
                  initialValue: _lot,
                  decoration: InputDecoration(labelText: s['lot']),
                  items: [
                    DropdownMenuItem(value: '', child: Text(s['all_lots'])),
                    for (final l in g.lots)
                      DropdownMenuItem(
                        value: l.id,
                        child: Text([l.crop, ?l.variety, l.status].join(' · ')),
                      ),
                  ],
                  onChanged: (v) => setState(() => _lot = v ?? ''),
                ),
                const SizedBox(height: BmSpace.sm),
                Wrap(
                  spacing: BmSpace.md,
                  runSpacing: BmSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        key: const Key('pkg-amount'),
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: s['amount']),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: [
                        for (final m in const ['upi', 'cash', 'bank'])
                          ButtonSegment(value: m, label: Text(s[m])),
                      ],
                      selected: {_method},
                      onSelectionChanged: (v) =>
                          setState(() => _method = v.single),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        key: const Key('pkg-ref'),
                        controller: _ref,
                        maxLength: 40,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: s['payment_ref'],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('pkg-paid-on'),
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        '${s['paid_on']}: '
                        '${_paidOn == null ? s['pick_date'] : packageDate(_paidOn!)}',
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final d = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(2026),
                          lastDate: now,
                        );
                        if (d != null) setState(() => _paidOn = d);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: BmSpace.sm),
                FilledButton(
                  key: const Key('pkg-activate'),
                  onPressed: _ready ? _save : null,
                  child: Text(s['activate']),
                ),
              ],
            ),
          ),
        if (_grants.isNotEmpty) ...[
          const SizedBox(height: BmSpace.md),
          SectionHeader(title: s['grants']),
          for (final x in _grants) _GrantTile(x, onRevoke: () => _revoke(x)),
        ],
      ],
    );
  }
}

class _GrantTile extends StatelessWidget {
  const _GrantTile(this.grant, {required this.onRevoke});
  final PackageGrantOut grant;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final s = PackageStrings.of(context);
    final c = context.bm;
    final g = grant;
    final active = g.revokedAt == null && g.validUntil.isAfter(DateTime.now());
    final (label, colour) = g.revokedAt != null
        ? (s['revoked'], c.danger)
        : active
        ? (s['active'], c.brandStrong)
        : (s['ended'], c.inkMuted);
    return ListTile(
      key: ValueKey('grant-${g.id}'),
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${g.receiptNo} · ₹${g.amountPaise ~/ 100} · ${s[g.method]}',
        style: BmType.bodyStrong,
      ),
      subtitle: Text(
        'UTR ${g.paymentRef} · ${s['paid_on']} ${packageDate(g.paidOn)} · '
        '${s['valid_until']} ${packageDate(g.validUntil)}',
      ),
      trailing: Wrap(
        spacing: BmSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: BmType.meta.copyWith(color: colour)),
          if (active) TextButton(onPressed: onRevoke, child: Text(s['revoke'])),
        ],
      ),
    );
  }
}

/// Asks for the revoke reason (logged with the revoke, §4E); pops it or null.
class _RevokeDialog extends StatefulWidget {
  const _RevokeDialog({required this.receiptNo});
  final String receiptNo;

  @override
  State<_RevokeDialog> createState() => _RevokeDialogState();
}

class _RevokeDialogState extends State<_RevokeDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = PackageStrings.of(context);
    final text = _reason.text.trim();
    return AlertDialog(
      title: Text('${s['revoke']} · ${widget.receiptNo}'),
      content: TextField(
        key: const Key('pkg-revoke-reason'),
        controller: _reason,
        maxLength: 200,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: s['reason']),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s['back']),
        ),
        FilledButton(
          onPressed: text.length < 3
              ? null
              : () => Navigator.of(context).pop(text),
          child: Text(s['revoke']),
        ),
      ],
    );
  }
}
