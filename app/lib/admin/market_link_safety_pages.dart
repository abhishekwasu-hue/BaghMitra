import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../design_system/glyphs.dart';
import '../design_system/info_note.dart';
import '../features/market_link/safety/safety_labels.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'market_link_safety_admin.dart';

/// Opens a signed photo URL (a new browser tab on the admin web).
typedef OpenPhoto = Future<void> Function(Uri url);

Future<void> launchPhoto(Uri url) async {
  await launchUrl(url, webOnlyWindowName: '_blank');
}

String adminDate(DateTime d) => d.toLocal().toIso8601String().substring(0, 10);

String targetLabel(AppLocalizations t, String type) => switch (type) {
  'buyer' => t.adminMlBuyer,
  'broker' => t.adminMlBroker,
  'provider' => t.adminMlProvider,
  'lot' => t.adminMlTargetLot,
  'rating' => t.adminMlTargetRating,
  'user' => t.adminMlTargetUser,
  _ => type,
};

void sayAdmin(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Red badges for the grievance timeline (IT Rules 2021: acknowledge within 24 h, close
/// within 15 days).
class OverdueBadges extends StatelessWidget {
  const OverdueBadges({super.key, required this.ack, required this.close});
  final bool ack;
  final bool close;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    Widget badge(String text) => Container(
      margin: const EdgeInsets.only(right: BmSpace.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.xs,
        vertical: BmSpace.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BmSpace.xs),
        border: Border.all(color: c.danger),
      ),
      child: Text(text, style: BmType.meta.copyWith(color: c.danger)),
    );
    return Wrap(
      children: [
        if (ack) badge(t.adminMlAckOverdue),
        if (close) badge(t.adminMlCloseOverdue),
      ],
    );
  }
}

Widget photoButtons(
  BuildContext context,
  int count,
  Future<String> Function(int) url,
  OpenPhoto open,
) => Wrap(
  spacing: BmSpace.sm,
  children: [
    for (var i = 0; i < count; i++)
      OutlinedButton.icon(
        key: ValueKey('photo-$i'),
        onPressed: () async {
          try {
            await open(Uri.parse(await url(i)));
          } on KbAdminException catch (e) {
            if (context.mounted) sayAdmin(context, e.message);
          }
        },
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text(AppLocalizations.of(context).adminMlPhoto(i + 1)),
      ),
  ],
);

/// Reports to the admin, oldest first, with the grievance timeline and the decision.
class ReportsPage extends StatefulWidget {
  const ReportsPage({required this.repo, this.openPhoto, super.key});
  final MarketLinkSafetyAdmin repo;
  final OpenPhoto? openPhoto;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _status = 'open';
  late Future<List<ReportAdminOut>> _future = widget.repo.reports(_status);

  void _reload() => setState(() {
    _future = widget.repo.reports(_status);
  });

  Future<void> _run(Future<void> Function() call) async {
    final t = AppLocalizations.of(context);
    try {
      await call();
      if (mounted) sayAdmin(context, t.adminDone);
      _reload();
    } on KbAdminException catch (e) {
      if (mounted) sayAdmin(context, e.message);
    }
  }

  Future<void> _act(ReportAdminOut r) async {
    final choice = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const ActionDialog(),
    );
    if (choice == null) return;
    await _run(() => widget.repo.actOnReport(r.id, choice.$1, choice.$2));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'open', label: Text(t.adminMlStatusOpen)),
            ButtonSegment(
              value: 'actioned',
              label: Text(t.adminMlStatusActioned),
            ),
            ButtonSegment(
              value: 'dismissed',
              label: Text(t.adminMlStatusDismissed),
            ),
          ],
          selected: {_status},
          onSelectionChanged: (s) {
            _status = s.single;
            _reload();
          },
        ),
        const SizedBox(height: BmSpace.sm),
        InfoNote(t.adminMlActionNote),
        const SizedBox(height: BmSpace.sm),
        Expanded(
          child: FutureBuilder<List<ReportAdminOut>>(
            future: _future,
            builder: (context, snap) => switch (snap) {
              AsyncSnapshot(:final error?) => Text('$error'),
              AsyncSnapshot(:final data?) when data.isEmpty => EmptyState(
                glyph: BmGlyph.ledger,
                message: t.adminMlReportsEmpty,
              ),
              AsyncSnapshot(:final data?) => ListView(
                children: [
                  for (final r in data) ...[
                    _card(t, r),
                    const SizedBox(height: BmSpace.sm),
                  ],
                ],
              ),
              _ => LoadingState(label: t.adminMlReports),
            },
          ),
        ),
      ],
    );
  }

  Widget _card(AppLocalizations t, ReportAdminOut r) => BmCard(
    elevated: false,
    padding: EdgeInsets.zero,
    key: ValueKey('report-${r.id}'),
    child: Padding(
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reasonLabel(t, r.reason), style: BmType.bodyStrong),
          Text(
            [
              targetLabel(t, r.subjectType),
              r.subjectId,
              t.adminMlReceived(adminDate(r.createdAt)),
            ].join(' · '),
            style: BmType.meta,
          ),
          OverdueBadges(ack: r.ackOverdue, close: r.closeOverdue),
          photoButtons(
            context,
            r.photoCount,
            (i) => widget.repo.reportPhotoUrl(r.id, i),
            widget.openPhoto ?? launchPhoto,
          ),
          if (r.status == 'open')
            Wrap(
              spacing: BmSpace.sm,
              children: [
                if (r.acknowledgedAt == null)
                  TextButton(
                    onPressed: () =>
                        _run(() => widget.repo.acknowledgeReport(r.id)),
                    child: Text(t.adminMlAcknowledge),
                  ),
                TextButton(
                  onPressed: () => _run(() => widget.repo.dismissReport(r.id)),
                  child: Text(t.adminMlDismiss),
                ),
                FilledButton(
                  key: ValueKey('act-${r.id}'),
                  onPressed: () => _act(r),
                  child: Text(t.adminMlAct),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

/// warn / hide / suspend and a platform-rule reason code; returns (action, reason code).
class ActionDialog extends StatefulWidget {
  const ActionDialog({super.key});

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  String _action = 'warn';
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.adminMlActionTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: [
                for (final a in const ['warn', 'hide', 'suspend'])
                  ButtonSegment(value: a, label: Text(actionLabel(t, a))),
              ],
              selected: {_action},
              onSelectionChanged: (s) => setState(() => _action = s.single),
            ),
            const SizedBox(height: BmSpace.md),
            Wrap(
              spacing: BmSpace.sm,
              runSpacing: BmSpace.sm,
              children: [
                for (final r in platformReasons)
                  ChoiceChip(
                    key: ValueKey('code-$r'),
                    label: Text(reasonLabel(t, r)),
                    selected: _reason == r,
                    onSelected: (_) => setState(() => _reason = r),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.md),
            InfoNote(t.adminMlActionNote),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.adminFeedCancel),
        ),
        FilledButton(
          key: const ValueKey('action-confirm'),
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop((_action, _reason!)),
          child: Text(t.adminMlAct),
        ),
      ],
    );
  }
}
