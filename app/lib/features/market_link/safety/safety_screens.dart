import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'safety_labels.dart';
import 'safety_photo.dart';
import 'safety_repository.dart';

/// Report button for a profile or lot (spec v1.5 §4). Other milestones place it; it opens
/// the report screen for [subjectType] (buyer / broker / provider / lot / rating / user).
class ReportButton extends StatelessWidget {
  const ReportButton({
    super.key,
    required this.subjectType,
    required this.subjectId,
  });
  final String subjectType;
  final String subjectId;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.push(Routes.mlReport(subjectType, subjectId)),
    icon: const Icon(Icons.flag_outlined),
    label: Text(AppLocalizations.of(context).mlSafetyReport),
  );
}

/// The ⋮ menu on another person's profile: report, block / unblock (Google Play UGC).
class ProfileSafetyMenu extends ConsumerWidget {
  const ProfileSafetyMenu({
    super.key,
    required this.subjectType,
    required this.subjectId,
    required this.userId,
    required this.blocked,
    this.onChanged,
  });
  final String subjectType;
  final String subjectId;
  final String userId;
  final bool blocked;
  final VoidCallback? onChanged;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!blocked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(t.mlBlockTitle),
          content: Text(t.mlBlockNote, style: BmType.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text(t.mlBlock),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref
          .read(safetyRepositoryProvider)
          .setBlocked(userId, blocked: !blocked);
      messenger.showSnackBar(
        SnackBar(content: Text(blocked ? t.mlUnblocked : t.mlBlocked)),
      );
      onChanged?.call();
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(t.mlSafetyRetry)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: t.mlMoreOptions,
      onSelected: (v) => v == 'report'
          ? context.push(Routes.mlReport(subjectType, subjectId))
          : _toggle(context, ref),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'report', child: Text(t.mlSafetyReport)),
        PopupMenuItem(
          value: 'block',
          child: Text(blocked ? t.mlUnblock : t.mlBlock),
        ),
      ],
    );
  }
}

/// Big reason chips + one optional camera photo + one main action; no text field anywhere
/// (spec §4: predefined reasons only).
class ReasonForm extends ConsumerStatefulWidget {
  const ReasonForm({
    super.key,
    required this.title,
    required this.note,
    required this.reasons,
    required this.label,
    required this.action,
    required this.done,
    required this.send,
  });
  final String title;
  final String note;
  final List<String> reasons;
  final String Function(AppLocalizations, String) label;
  final String action;
  final String done;
  final Future<void> Function(String reason, List<int>? photo) send;

  @override
  ConsumerState<ReasonForm> createState() => ReasonFormState();
}

class ReasonFormState extends ConsumerState<ReasonForm> {
  String? _reason;
  List<int>? _photo;
  bool _sending = false;

  Future<void> _takePhoto() async {
    final bytes = await ref.read(safetyPhotoProvider)();
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _send() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _sending = true);
    try {
      await widget.send(_reason!, _photo);
      messenger.showSnackBar(SnackBar(content: Text(widget.done)));
      if (router.canPop()) router.pop(true);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(t.mlSafetyRetry)));
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          SectionHeader(title: t.mlSafetyReportWhy),
          Wrap(
            spacing: BmSpace.sm,
            runSpacing: BmSpace.sm,
            children: [
              for (final r in widget.reasons)
                ChoiceChip(
                  key: ValueKey('reason-$r'),
                  label: Text(widget.label(t, r), style: BmType.bodyStrong),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.lg),
          if (_photo == null)
            OutlinedButton.icon(
              key: const ValueKey('safety-photo'),
              onPressed: _takePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(t.mlSafetyPhoto),
            )
          else
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: c.brandStrong),
                const SizedBox(width: BmSpace.xs),
                Text(t.mlSafetyPhotoAdded, style: BmType.bodyStrong),
              ],
            ),
          const SizedBox(height: BmSpace.lg),
          InfoNote(widget.note),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const ValueKey('safety-send'),
            onPressed: _reason == null || _sending ? null : _send,
            child: Text(widget.action),
          ),
        ],
      ),
    );
  }
}

class ReportScreen extends ConsumerWidget {
  const ReportScreen({
    super.key,
    required this.subjectType,
    required this.subjectId,
  });
  final String subjectType;
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ReasonForm(
      title: t.mlSafetyReportTitle,
      note: t.mlSafetyReportNote,
      reasons: reportReasons,
      label: reasonLabel,
      action: t.mlSafetySend,
      done: t.mlSafetySent,
      send: (reason, photo) => ref
          .read(safetyRepositoryProvider)
          .report(subjectType, subjectId, reason, photo: photo),
    );
  }
}
