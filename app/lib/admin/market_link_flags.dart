import 'package:flutter/material.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Market linkage L7 admin (spec v1.5 §4C): what the admin must look at before approving.
/// Flags only inform; nothing is blocked or hidden.

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
