import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/interest_api.dart';
import '../data/registration_api.dart';
import '../domain/deal_rating.dart';
import '../domain/market_link_role.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';
import 'profile_widgets.dart';

/// Rating after a completed deal (spec §3A, Q66): for each person the caller rates, 1-5
/// stars on every question and optional ticks from the admin's list. No text field and no
/// mic anywhere. Changeable until the window closes (7 days from completion), then shown
/// read-only.
class RatingScreen extends StatelessWidget {
  const RatingScreen({required this.dealId, required this.role, super.key});

  final String dealId;
  final MarketLinkRole role;

  @override
  Widget build(BuildContext context) =>
      MarketLinkEntry(role: role, child: _Rating(dealId));
}

class _Rating extends ConsumerStatefulWidget {
  const _Rating(this.dealId);

  final String dealId;

  @override
  ConsumerState<_Rating> createState() => _RatingState();
}

class _RatingState extends ConsumerState<_Rating> {
  // Rated role -> question -> stars / ticked tag ids; filled from the saved rating once.
  final _stars = <DealRole, Map<String, int>>{};
  final _ticks = <DealRole, Map<String, Set<String>>>{};
  bool _filled = false;
  bool _busy = false;

  void _fill(DealRatings r) {
    if (_filled) return;
    _filled = true;
    for (final MapEntry(key: role, value: answers) in r.given.entries) {
      for (final a in answers) {
        (_stars[role] ??= {})[a.questionKey] = a.stars;
        (_ticks[role] ??= {})[a.questionKey] = {...a.tagIds};
      }
    }
  }

  bool _complete(DealRatings r) => r.state.rates.every(
    (role) =>
        (r.questions[role] ?? const []).every((q) => _stars[role]?[q] != null),
  );

  Future<void> _save(DealRatings r) async {
    final t = AppLocalizations.of(context);
    setState(() => _busy = true);
    String? say = t.mlRateSaved;
    try {
      for (final role in r.state.rates) {
        await ref.read(interestApiProvider).rate(widget.dealId, role, [
          for (final q in r.questions[role] ?? const <String>[])
            RatingAnswer(q, _stars[role]![q]!, [...?_ticks[role]?[q]]),
        ]);
      }
    } on MarketCallException catch (e) {
      say = switch (e.problem) {
        MarketCallProblem.offline => t.mlOffline,
        MarketCallProblem.refused when e.code == 'same_device' =>
          t.mlRateSameDevice,
        MarketCallProblem.refused => t.mlRateRefused,
        MarketCallProblem.server => t.mlServerBusy,
      };
    }
    ref.invalidate(dealRatingsProvider(widget.dealId));
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(say)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final loaded = ref.watch(dealRatingsProvider(widget.dealId));
    final intro = ref.watch(introductionProvider(widget.dealId)).value;
    final tags = ref.watch(ratingTagsProvider).value ?? const [];
    final r = loaded.value;
    if (r != null) _fill(r);
    final open = r != null && r.state.completed && !r.state.ratingLocked;
    String name(DealRole role) => switch (role) {
      DealRole.grower => intro?.grower.name ?? '',
      DealRole.trader => intro?.trader.name ?? '',
      DealRole.broker => intro?.broker?.name ?? '',
    };
    String roleLabel(DealRole role) => switch (role) {
      DealRole.grower => t.mlIntroGrower,
      DealRole.trader => t.mlRoleTrader,
      DealRole.broker => t.mlRoleBroker,
    };
    Widget question(DealRole role, String q) {
      final stars = _stars[role]?[q] ?? 0;
      final ticked = _ticks[role]?[q] ?? const <String>{};
      return BmCard(
        key: Key('ml-rate-${role.name}-$q'),
        elevated: false,
        radius: BmRadius.card,
        padding: const EdgeInsets.all(BmSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(questionLabel(t, q), style: BmType.bodyStrong),
            Wrap(
              children: [
                for (var n = 1; n <= 5; n++)
                  IconButton(
                    key: Key('ml-star-${role.name}-$q-$n'),
                    tooltip: t.mlRateStarsOf(n),
                    constraints: const BoxConstraints(
                      minWidth: BmSpace.tapTarget,
                      minHeight: BmSpace.tapTarget,
                    ),
                    color: n <= stars ? c.brandStrong : c.inkMuted,
                    icon: Icon(
                      n <= stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                    ),
                    onPressed: open
                        ? () => setState(() => (_stars[role] ??= {})[q] = n)
                        : null,
                  ),
              ],
            ),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final tag in tags.where((g) => g.questionKey == q))
                  FilterChip(
                    key: Key('ml-tag-${tag.id}'),
                    label: Text(tag.label(lang)),
                    selected: ticked.contains(tag.id),
                    onSelected: open
                        ? (on) => setState(() {
                            final set = (_ticks[role] ??= {})[q] ??= {};
                            on ? set.add(tag.id) : set.remove(tag.id);
                          })
                        : null,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final until = r?.state.ratingUntil == null
        ? ''
        : formatDate(r!.state.ratingUntil!.toLocal(), lang);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlRatingsTitle)),
      body: switch (r) {
        null when loaded.error != null => ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            MarketCallBanner(
              loaded.error!,
              onRetry: () => ref.invalidate(dealRatingsProvider(widget.dealId)),
            ),
          ],
        ),
        null => LoadingState(label: t.loadingLabel),
        final r when !r.state.completed => EmptyState(
          glyph: BmGlyph.orange,
          message: t.mlDealWaitBoth,
        ),
        final r => ListView(
          padding: const EdgeInsets.fromLTRB(
            BmSpace.lg,
            BmSpace.xs,
            BmSpace.lg,
            BmSpace.xxl,
          ),
          children: [
            const LotDisclaimerNote(),
            InfoNote(
              r.state.ratingLocked
                  ? t.mlRateLocked(until)
                  : t.mlRateUntil(until),
            ),
            InfoNote(t.mlRateNoText),
            for (final role in r.state.rates) ...[
              const SizedBox(height: BmSpace.md),
              Text(
                [
                  roleLabel(role),
                  name(role),
                ].where((s) => s.isNotEmpty).join(' · '),
                style: BmType.cardTitle,
              ),
              for (final q in r.questions[role] ?? const <String>[]) ...[
                const SizedBox(height: BmSpace.sm),
                question(role, q),
              ],
            ],
          ],
        ),
      },
      bottomNavigationBar: !open
          ? null
          : BottomActions(
              children: [
                FilledButton(
                  key: const Key('ml-rate-save'),
                  onPressed: _busy || !_complete(r) ? null : () => _save(r),
                  child: Text(_complete(r) ? t.mlRateSave : t.mlRateAnswerAll),
                ),
              ],
            ),
    );
  }
}
