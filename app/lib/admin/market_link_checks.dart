import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../design_system/info_note.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'market_link_pages.dart';

/// Market linkage L7 admin widgets (spec v1.5 §4, §4C): the per-check panel and the flags
/// an admin must look at before approving. Every check is done by hand on the official
/// public page; nothing is fetched.

String adminDate(DateTime d) => d.toLocal().toIso8601String().substring(0, 10);

String checkKindLabel(AppLocalizations t, String kind) => switch (kind) {
  'gstin' => 'GSTIN',
  'apmc' => t.adminMlCheckApmc,
  'fssai' => 'FSSAI',
  'iec' => 'IEC',
  'apeda' => 'APEDA',
  'phone_call' => t.adminMlCheckPhoneCall,
  'place_photo' => t.adminMlCheckPlacePhoto,
  _ => kind,
};

String _resultLabel(AppLocalizations t, String result) => switch (result) {
  'passed' => t.adminMlResultPassed,
  'failed' => t.adminMlResultFailed,
  'cancelled' => t.adminMlResultCancelled,
  _ => result,
};

String flagLabel(AppLocalizations t, String flag) => switch (flag) {
  'duplicate_number' => t.adminMlFlagDuplicate,
  'returning_suspended' => t.adminMlFlagReturning,
  'mock_location' => t.adminMlFlagMock,
  'outside_stated_district' => t.adminMlFlagOtherDistrict,
  'place_not_named' => t.adminMlFlagNoPlace,
  _ => flag,
};

String _whyLabel(AppLocalizations t, String why) => switch (why) {
  'name' => t.adminMlWhyName,
  'gps' => t.adminMlWhyGps,
  'account' => t.adminMlWhyAccount,
  'gst_no' => 'GSTIN',
  'apmc_licence_no' => t.adminMlCheckApmc,
  'iec_no' => 'IEC',
  'fssai_no' => 'FSSAI',
  'apeda_no' => 'APEDA',
  _ => why,
};

/// Records one check: the result, and the GST registration year for a GSTIN check.
typedef RecordCheck = Future<void> Function(
  String kind,
  String result,
  int? registeredYear,
);

/// What the admin must look at before approving: fix flags, duplicate numbers, returning
/// suspended users, each with the other profile it matches. Red: look first.
class FlagsSection extends StatelessWidget {
  const FlagsSection({required this.subject, super.key});
  final SubjectOut subject;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final flags = subject.flags ?? const [];
    if (flags.isEmpty) return const SizedBox.shrink();
    final related = subject.related ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.adminMlFlags),
        BmCard(
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final flag in flags) ...[
                Text(
                  flagLabel(t, flag),
                  key: ValueKey('flag-$flag'),
                  style: BmType.bodyStrong.copyWith(color: c.danger),
                ),
                for (final r in related)
                  if (r.flag == flag)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: BmSpace.md,
                        top: BmSpace.xxs,
                      ),
                      child: Text(
                        '${r.name} · ${_whyLabel(t, r.why)}',
                        style: BmType.body,
                      ),
                    ),
                const SizedBox(height: BmSpace.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: BmSpace.lg),
      ],
    );
  }
}

/// One row per check that applies: the number, a button to the official page (the number
/// is copied to paste there) and Record result; then every check record, newest first.
class ChecksSection extends StatelessWidget {
  const ChecksSection({
    required this.detail,
    required this.openUrl,
    required this.onRecord,
    super.key,
  });
  final SubjectDetailOut detail;
  final OpenUrl openUrl;
  final RecordCheck onRecord;

  Future<void> _open(BuildContext context, OfficialLinkOut link) async {
    final url = link.url;
    if (url == null) return;
    final number = link.number;
    if (link.kind != 'phone_call' && number != null) {
      final t = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);
      await Clipboard.setData(ClipboardData(text: number));
      messenger.showSnackBar(
        SnackBar(content: Text(t.adminMlNumberCopied(number))),
      );
    }
    await openUrl(Uri.parse(url));
  }

  Future<void> _record(BuildContext context, String kind) async {
    final out = await showDialog<(String, int?)>(
      context: context,
      builder: (_) => _CheckDialog(kind: kind),
    );
    if (out != null) await onRecord(kind, out.$1, out.$2);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final checks = detail.checks ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.adminMlChecks),
        InfoNote(t.adminMlChecksNote),
        const SizedBox(height: BmSpace.sm),
        for (final link in detail.links ?? const <OfficialLinkOut>[])
          Padding(
            padding: const EdgeInsets.only(bottom: BmSpace.sm),
            child: Wrap(
              spacing: BmSpace.sm,
              runSpacing: BmSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(checkKindLabel(t, link.kind), style: BmType.bodyStrong),
                if (link.number case final n?)
                  SelectableText(n, style: BmType.body),
                if (link.url != null)
                  OutlinedButton.icon(
                    key: ValueKey('open-${link.kind}'),
                    onPressed: () => _open(context, link),
                    icon: Icon(
                      link.kind == 'phone_call'
                          ? Icons.call_rounded
                          : Icons.open_in_new_rounded,
                    ),
                    label: Text(
                      link.kind == 'phone_call'
                          ? t.adminMlCallNow
                          : t.adminMlOpenPage,
                    ),
                  ),
                OutlinedButton.icon(
                  key: ValueKey('record-${link.kind}'),
                  onPressed: () => _record(context, link.kind),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(t.adminMlRecordResult),
                ),
              ],
            ),
          ),
        if (checks.isEmpty) EmptyNote(t.adminMlNoChecks),
        for (final k in checks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              k.result == 'passed'
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: k.result == 'passed' ? c.brandStrong : c.danger,
            ),
            title: Text(
              [
                checkKindLabel(t, k.kind),
                _resultLabel(t, k.result),
                if (k.registeredYear case final y?)
                  t.adminMlRegisteredSince('$y'),
              ].join(' · '),
              style: BmType.body,
            ),
            subtitle: Text(
              [
                adminDate(k.checkedAt),
                t.adminMlCheckedBy(k.checkedBy),
                ?k.number,
              ].join(' · '),
              style: BmType.meta,
            ),
          ),
      ],
    );
  }
}

class _CheckDialog extends StatefulWidget {
  const _CheckDialog({required this.kind});
  final String kind;

  @override
  State<_CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends State<_CheckDialog> {
  String _result = 'passed';
  final _year = TextEditingController();

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final gst = widget.kind == 'gstin' && _result == 'passed';
    return AlertDialog(
      title: Text(checkKindLabel(t, widget.kind)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: [
              for (final r in const ['passed', 'failed', 'cancelled'])
                ButtonSegment(value: r, label: Text(_resultLabel(t, r))),
            ],
            selected: {_result},
            onSelectionChanged: (s) => setState(() => _result = s.single),
          ),
          if (gst) ...[
            const SizedBox(height: BmSpace.md),
            TextField(
              key: const Key('registered-year'),
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: t.adminMlRegisteredYear),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context)
                  .pop((_result, gst ? int.tryParse(_year.text) : null)),
          child: Text(t.adminMlRecordResult),
        ),
      ],
    );
  }
}
