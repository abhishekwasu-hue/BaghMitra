import 'package:flutter/material.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../features/reactions/domain/reaction.dart';
import '../features/reactions/presentation/reaction_bar.dart'
    show reactionEmojiFonts;
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'feed_admin_repository.dart';

/// "👍 2 · 😟 1": the reactions someone chose, in the app's order; null when none.
String? reactionLine(List<ReactionCountOut>? counts) {
  final parts = [
    for (final r in Reaction.values)
      for (final c in counts ?? const <ReactionCountOut>[])
        if (c.reaction.value == r.value && c.count > 0) '${r.emoji} ${c.count}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Readers' reactions (Q146) as counts only, never who reacted: the totals, then the most
/// helpful and the least helpful feed items and answers, each with every emoji's count.
class FeedReactionsPage extends StatefulWidget {
  const FeedReactionsPage({required this.feed, super.key});
  final FeedAdminRepository feed;

  @override
  State<FeedReactionsPage> createState() => _FeedReactionsPageState();
}

class _FeedReactionsPageState extends State<FeedReactionsPage> {
  late final Future<FeedAdminReactionsResponse> _future = widget.feed
      .reactions();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<FeedAdminReactionsResponse>(
      future: _future,
      builder: (context, snap) => switch (snap) {
        AsyncSnapshot(:final error?) => Text('$error'),
        AsyncSnapshot(:final data?) when data.total == 0 => Text(
          t.adminReactionsNone,
          key: const Key('reactions-none'),
        ),
        AsyncSnapshot(:final data?) => ListView(
          key: const Key('reactions-lists'),
          children: [
            Text(
              t.adminReactionsTotals(data.targets, data.total),
              style: BmType.bodyStrong,
            ),
            const SizedBox(height: BmSpace.sm),
            _RowsCard(
              keyName: 'most',
              title: t.adminReactionsMost,
              rows: data.mostHelpful,
            ),
            const SizedBox(height: BmSpace.md),
            _RowsCard(
              keyName: 'least',
              title: t.adminReactionsLeast,
              rows: data.leastHelpful,
            ),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _RowsCard extends StatelessWidget {
  const _RowsCard({
    required this.keyName,
    required this.title,
    required this.rows,
  });

  final String keyName;
  final String title;
  final List<FeedAdminReactionRowOut> rows;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Card(
      key: Key('reactions-$keyName'),
      child: Padding(
        padding: const EdgeInsets.all(BmSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: BmType.section),
            const SizedBox(height: BmSpace.xs),
            for (final (i, row) in rows.indexed)
              ListTile(
                key: Key('reactions-$keyName-${row.target}'),
                contentPadding: EdgeInsets.zero,
                leading: Text('${i + 1}', style: BmType.bodyStrong),
                title: Text(row.title ?? row.target, style: BmType.bodyStrong),
                subtitle: Text(
                  [
                    if (row.kind == 'qa') t.adminReactionsQa,
                    ?row.itemType,
                    reactionLine(row.counts) ?? '',
                  ].join(' · '),
                  style: const TextStyle(
                    fontFamilyFallback: reactionEmojiFonts,
                  ),
                ),
                trailing: Wrap(
                  spacing: BmSpace.xs,
                  children: [
                    _Count('👍', row.helpful, c.brandStrong),
                    _Count('😟', row.unclear, c.danger),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A number first, coloured by meaning (helpful green, unclear red).
class _Count extends StatelessWidget {
  const _Count(this.emoji, this.value, this.color);
  final String emoji;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    '$emoji $value',
    style: BmType.bodyStrong.copyWith(
      color: color,
      fontFamilyFallback: reactionEmojiFonts,
    ),
  );
}
