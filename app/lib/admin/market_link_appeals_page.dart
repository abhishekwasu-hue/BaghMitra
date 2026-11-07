import 'package:flutter/material.dart';

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
import 'market_link_safety_pages.dart';

/// Appeals waiting for the grievance officer, oldest first, with the timeline badges.
class AppealsPage extends StatefulWidget {
  const AppealsPage({required this.repo, this.openPhoto, super.key});
  final MarketLinkSafetyAdmin repo;
  final OpenPhoto? openPhoto;

  @override
  State<AppealsPage> createState() => _AppealsPageState();
}

class _AppealsPageState extends State<AppealsPage> {
  late Future<List<ActionOut>> _future = widget.repo.appeals();

  Future<void> _run(Future<void> Function() call) async {
    final t = AppLocalizations.of(context);
    try {
      await call();
      if (mounted) sayAdmin(context, t.adminDone);
      setState(() {
        _future = widget.repo.appeals();
      });
    } on KbAdminException catch (e) {
      if (mounted) sayAdmin(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<ActionOut>>(
      future: _future,
      builder: (context, snap) => switch (snap) {
        AsyncSnapshot(:final error?) => Text('$error'),
        AsyncSnapshot(:final data?) when data.isEmpty => EmptyState(
          glyph: BmGlyph.ledger,
          message: t.adminMlAppealsEmpty,
        ),
        AsyncSnapshot(:final data?) => ListView(
          children: [
            InfoNote(t.mlAppealNote),
            for (final a in data)
              BmCard(
                elevated: false,
                padding: EdgeInsets.zero,
                key: ValueKey('appeal-${a.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(BmSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${actionLabel(t, a.action)} · '
                        '${reasonLabel(t, a.reasonCode)}',
                        style: BmType.bodyStrong,
                      ),
                      Text(
                        t.adminMlAppealReason(
                          appealReasonLabel(t, a.appealReason ?? ''),
                        ),
                        style: BmType.body,
                      ),
                      Text(
                        [
                          targetLabel(t, a.subjectType),
                          a.subjectId,
                          if (a.appealedAt case final at?)
                            t.adminMlReceived(adminDate(at)),
                        ].join(' · '),
                        style: BmType.meta,
                      ),
                      OverdueBadges(ack: a.ackOverdue, close: a.closeOverdue),
                      photoButtons(
                        context,
                        a.appealPhotoCount,
                        (i) => widget.repo.appealPhotoUrl(a.id, i),
                        widget.openPhoto ?? launchPhoto,
                      ),
                      Wrap(
                        spacing: BmSpace.sm,
                        children: [
                          if (a.appealAcknowledgedAt == null)
                            TextButton(
                              onPressed: () => _run(
                                () => widget.repo.acknowledgeAppeal(a.id),
                              ),
                              child: Text(t.adminMlAcknowledge),
                            ),
                          OutlinedButton(
                            onPressed: () => _run(
                              () =>
                                  widget.repo.decideAppeal(a.id, upheld: false),
                            ),
                            child: Text(t.adminMlKeepDecision),
                          ),
                          FilledButton(
                            key: ValueKey('uphold-${a.id}'),
                            onPressed: () => _run(
                              () =>
                                  widget.repo.decideAppeal(a.id, upheld: true),
                            ),
                            child: Text(t.adminMlUphold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        _ => LoadingState(label: t.adminMlAppeals),
      },
    );
  }
}
