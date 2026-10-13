import 'package:flutter/material.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart';

/// Loads a list, shows a spinner, and reloads after an action. Errors are shown, not hidden.
class _Loader<T> extends StatefulWidget {
  const _Loader({required this.load, required this.builder});

  final Future<List<T>> Function() load;
  final Widget Function(BuildContext, List<T>, VoidCallback reload) builder;

  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<_Loader<T>> {
  late Future<List<T>> _future = widget.load();

  void _reload() {
    final next = widget.load();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<T>>(
    future: _future,
    builder: (context, snap) => switch (snap) {
      AsyncSnapshot(:final error?) => Text('$error'),
      AsyncSnapshot(:final data?) => widget.builder(context, data, _reload),
      _ => const Center(child: CircularProgressIndicator()),
    },
  );
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = AppLocalizations.of(context).adminDone;
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  } on KbAdminException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class KbCardsPage extends StatelessWidget {
  const KbCardsPage({required this.kb, super.key});
  final KbAdminRepository kb;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return _Loader<CardOut>(
      load: kb.cards,
      builder: (context, cards, reload) => cards.isEmpty
          ? Text(t.adminNoCards)
          : ListView(
              children: [
                for (final card in cards)
                  ListTile(
                    title: Text(card.title, style: BmType.bodyStrong),
                    subtitle: Text(
                      '${card.topic} · ${card.crop} · v${card.version} · '
                      '${card.status}',
                    ),
                    leading: card.hasChemicalOptions
                        ? Chip(label: Text(t.adminChemical))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: BmSpace.xs,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () => _run(context, () async {
                            await kb.review(
                              card.id,
                              ReviewInDecision.approve,
                              null,
                            );
                            reload();
                          }),
                          child: Text(t.adminApprove),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: c.brand,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () => _run(context, () async {
                            await kb.publish(card.id);
                            reload();
                          }),
                          child: Text(t.adminPublish),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class KbImportPage extends StatefulWidget {
  const KbImportPage({required this.kb, super.key});
  final KbAdminRepository kb;

  @override
  State<KbImportPage> createState() => _KbImportPageState();
}

class _KbImportPageState extends State<KbImportPage> {
  final _source = TextEditingController();
  final _csv = TextEditingController();
  String _kind = 'claims';
  String? _result;

  @override
  void dispose() {
    _source.dispose();
    _csv.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    try {
      final d = await widget.kb.import(_kind, _source.text.trim(), _csv.text);
      setState(
        () => _result = t.adminImportResult(
          d.added,
          d.changed,
          d.removed,
          d.unchanged,
          d.cardsPulled,
        ),
      );
    } on KbAdminException catch (e) {
      setState(() => _result = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'claims', label: Text(t.adminImportClaims)),
            ButtonSegment(
              value: 'restrictions',
              label: Text(t.adminImportRestrictions),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() => _kind = s.single),
        ),
        const SizedBox(height: BmSpace.md),
        TextField(
          key: const Key('import-source'),
          controller: _source,
          decoration: InputDecoration(labelText: t.adminImportSource),
        ),
        const SizedBox(height: BmSpace.md),
        TextField(
          key: const Key('import-csv'),
          controller: _csv,
          minLines: 8,
          maxLines: 16,
          decoration: InputDecoration(labelText: t.adminImportCsv),
        ),
        const SizedBox(height: BmSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: _submit, child: Text(t.adminImport)),
        ),
        if (_result case final r?) ...[
          const SizedBox(height: BmSpace.md),
          SelectableText(r, style: BmType.body),
        ],
      ],
    );
  }
}

class KbAlertsPage extends StatelessWidget {
  const KbAlertsPage({required this.kb, super.key});
  final KbAdminRepository kb;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _Loader<AlertOut>(
      load: kb.alerts,
      builder: (context, alerts, reload) => alerts.isEmpty
          ? Text(t.adminNoAlerts)
          : ListView(
              children: [
                for (final a in alerts)
                  ListTile(
                    title: Text(a.kind, style: BmType.bodyStrong),
                    subtitle: Text(a.detail),
                    trailing: TextButton(
                      onPressed: () => _run(context, () async {
                        await kb.resolve(a.id);
                        reload();
                      }),
                      child: Text(t.adminResolve),
                    ),
                  ),
              ],
            ),
    );
  }
}

class KbSourcesPage extends StatelessWidget {
  const KbSourcesPage({required this.kb, super.key});
  final KbAdminRepository kb;

  @override
  Widget build(BuildContext context) => _Loader<SourceOut>(
    load: kb.sources,
    builder: (context, sources, _) => ListView(
      children: [
        for (final s in sources)
          ListTile(
            title: Text(s.title, style: BmType.bodyStrong),
            subtitle: SelectableText(
              '${s.publisher} · ${s.tier} · ${s.allowedUse} · '
              '${s.verification} · ${s.url}',
            ),
          ),
      ],
    ),
  );
}
