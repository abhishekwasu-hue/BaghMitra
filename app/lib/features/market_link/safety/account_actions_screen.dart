import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'safety_labels.dart';
import 'safety_repository.dart';
import 'safety_screens.dart';

String _date(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}-${two(l.month)}-${l.year}';
}

class AppealScreen extends ConsumerWidget {
  const AppealScreen({super.key, required this.actionId});
  final String actionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ReasonForm(
      title: t.mlAppealTitle,
      note: t.mlAppealNote,
      reasons: appealReasons,
      label: appealReasonLabel,
      action: t.mlAppealSend,
      done: t.mlAppealSent,
      send: (reason, photo) => ref
          .read(safetyRepositoryProvider)
          .appeal(actionId, reason, photo: photo),
    );
  }
}

final myActionsProvider = FutureProvider.autoDispose<List<AccountActionOut>>(
  (ref) => ref.watch(safetyRepositoryProvider).myActions(),
);

/// "My account actions": every warn / hide / suspend (and verify / restore) with its reason
/// code, the appeal state, an Appeal button while the one appeal is open, and the
/// grievance officer (spec §4C).
class AccountActionsScreen extends ConsumerWidget {
  const AccountActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final actions = ref.watch(myActionsProvider);
    final officer = ref.watch(grievanceOfficerProvider).value;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlActionsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          BmCard(
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.mlGrievanceTitle, style: BmType.meta),
                Text(
                  officer?.name ?? t.mlGrievanceDefault,
                  style: BmType.bodyStrong,
                ),
                if (officer?.contact case final contact?)
                  SelectableText(contact, style: BmType.body),
                const SizedBox(height: BmSpace.xs),
                InfoNote(t.mlAppealNote),
              ],
            ),
          ),
          const SizedBox(height: BmSpace.lg),
          ...switch (actions) {
            AsyncData(:final value) when value.isEmpty => [
              EmptyState(glyph: BmGlyph.ledger, message: t.mlActionsEmpty),
            ],
            AsyncData(:final value) => [
              for (final a in value) ...[
                _ActionCard(
                  a,
                  onAppealed: () => ref.invalidate(myActionsProvider),
                ),
                const SizedBox(height: BmSpace.sm),
              ],
            ],
            AsyncError() => [EmptyNote(t.mlSafetyRetry)],
            _ => [LoadingState(label: t.mlActionsTitle)],
          },
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(this.a, {required this.onAppealed});
  final AccountActionOut a;
  final VoidCallback onAppealed;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    // Colour by meaning: hide / suspend red, a warning in the warm colour, others green.
    final colour = switch (a.action) {
      'hide' || 'suspend' => c.danger,
      'warn' => c.caution,
      _ => c.brandStrong,
    };
    return BmCard(
      key: ValueKey('action-${a.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            actionLabel(t, a.action),
            style: BmType.section.copyWith(color: colour),
          ),
          Text(
            t.mlActionReason(reasonLabel(t, a.reasonCode)),
            style: BmType.bodyStrong,
          ),
          Text(t.mlActionDate(_date(a.actedAt)), style: BmType.meta),
          if (a.appealState != 'none') ...[
            const SizedBox(height: BmSpace.xs),
            Text(
              [
                appealStateLabel(t, a.appealState),
                if (a.appealReason case final r?) appealReasonLabel(t, r),
              ].join(' · '),
              style: BmType.body,
            ),
          ],
          if (a.canAppeal) ...[
            const SizedBox(height: BmSpace.sm),
            OutlinedButton(
              key: ValueKey('appeal-${a.id}'),
              onPressed: () async {
                final done = await context.push<bool>(Routes.mlAppeal(a.id));
                if (done ?? false) onAppealed();
              },
              child: Text(t.mlAppeal),
            ),
          ],
        ],
      ),
    );
  }
}
