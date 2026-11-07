import 'package:flutter/material.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/empty_state.dart';
import '../design_system/glyphs.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'market_link_admin_repository.dart';
import 'market_link_checks.dart';
import 'market_link_pages.dart';

/// Passed checks older than a year (nightly job), oldest first; a new check on the
/// subject takes it off the list.
class RecheckListPage extends StatefulWidget {
  const RecheckListPage({required this.repo, this.openUrl, super.key});
  final MarketLinkAdminRepository repo;
  final OpenUrl? openUrl;

  @override
  State<RecheckListPage> createState() => _RecheckListPageState();
}

class _RecheckListPageState extends State<RecheckListPage> {
  late Future<List<RecheckItemOut>> _future = widget.repo.rechecks();

  Future<void> _open(RecheckItemOut item) async {
    await openVerificationDetail(
      context,
      repo: widget.repo,
      type: item.subjectType,
      id: item.subjectId,
      openUrl: widget.openUrl,
    );
    if (mounted) {
      setState(() {
        _future = widget.repo.rechecks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<RecheckItemOut>>(
      future: _future,
      builder: (context, snap) => switch (snap) {
        AsyncSnapshot(:final error?) => Text('$error'),
        AsyncSnapshot(:final data?) when data.isEmpty => EmptyState(
          glyph: BmGlyph.ledger,
          message: t.adminMlRechecksEmpty,
        ),
        AsyncSnapshot(:final data?) => ListView(
          children: [
            for (final item in data)
              ListTile(
                key: ValueKey('recheck-${item.checkId}'),
                onTap: () => _open(item),
                title: Text(item.name, style: BmType.bodyStrong),
                subtitle: Text(
                  [checkKindLabel(t, item.kind), ?item.number].join(' · '),
                ),
                trailing: Text(
                  t.adminMlLastChecked(adminDate(item.checkedAt)),
                  style: BmType.meta,
                ),
              ),
          ],
        ),
        _ => LoadingState(label: t.adminMlRechecks),
      },
    );
  }
}
