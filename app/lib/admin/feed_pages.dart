import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'document_picker.dart';
import 'feed_admin_repository.dart';

/// Supabase app_metadata role that may review the government feed (runbook govt-feed §1).
const feedAdminRole = 'feed_admin';

const _statuses = ['in_review', 'draft', 'published', 'withdrawn'];
const _langs = ['en', 'mr', 'hi'];
const _types = ['gr', 'circular', 'scheme', 'alert', 'news'];

String _date(DateTime? d) =>
    d == null ? '—' : d.toIso8601String().substring(0, 10);

DateTime? _parseDate(String text) {
  final s = text.trim();
  if (s.isEmpty) return null;
  final d = DateTime.tryParse(s);
  if (d == null) throw FormatException(s);
  return d;
}

String? _blankToNull(String text) => text.trim().isEmpty ? null : text.trim();

String _statusLabel(AppLocalizations t, String status) => switch (status) {
  'in_review' => t.adminFeedStatusInReview,
  'draft' => t.adminFeedStatusDraft,
  'published' => t.adminFeedStatusPublished,
  'withdrawn' => t.adminFeedStatusWithdrawn,
  _ => status,
};

void _say(ScaffoldMessengerState messenger, String text) =>
    messenger.showSnackBar(SnackBar(content: Text(text)));

/// One admin section with the review queue, manual upload and the source registry.
class FeedAdminSection extends StatelessWidget {
  const FeedAdminSection({required this.feed, this.documents, super.key});
  final FeedAdminRepository feed;
  final DocumentPicker? documents;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: t.adminFeedQueue),
              Tab(text: t.adminFeedUpload),
              Tab(text: t.adminFeedSources),
            ],
          ),
          const SizedBox(height: BmSpace.sm),
          Expanded(
            child: TabBarView(
              children: [
                FeedQueuePage(feed: feed),
                FeedUploadPage(feed: feed, documents: documents),
                FeedSourcesPage(feed: feed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.warn = false});
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.xs,
        vertical: BmSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: warn ? c.accentSoft : c.brandSoft,
        borderRadius: BorderRadius.circular(BmSpace.xs),
        border: Border.all(color: warn ? c.danger : c.line),
      ),
      child: Text(
        text,
        style: BmType.meta.copyWith(color: warn ? c.danger : c.ink),
      ),
    );
  }
}

/// Items by status (default in review) with type / trust badges and the check-issue count.
class FeedQueuePage extends StatefulWidget {
  const FeedQueuePage({required this.feed, super.key});
  final FeedAdminRepository feed;

  @override
  State<FeedQueuePage> createState() => _FeedQueuePageState();
}

class _FeedQueuePageState extends State<FeedQueuePage> {
  String _status = 'in_review';
  late Future<List<FeedAdminItemSummaryOut>> _future = _load();

  Future<List<FeedAdminItemSummaryOut>> _load() =>
      widget.feed.items(status: _status);

  void _reload() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedItemPage(feed: widget.feed, itemId: id),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            for (final s in _statuses)
              ButtonSegment(value: s, label: Text(_statusLabel(t, s))),
          ],
          selected: {_status},
          onSelectionChanged: (s) {
            _status = s.single;
            _reload();
          },
        ),
        const SizedBox(height: BmSpace.sm),
        Expanded(
          child: FutureBuilder<List<FeedAdminItemSummaryOut>>(
            future: _future,
            builder: (context, snap) => switch (snap) {
              AsyncSnapshot(:final error?) => Text('$error'),
              AsyncSnapshot(:final data?) when data.isEmpty => Text(
                t.adminFeedNoItems,
              ),
              AsyncSnapshot(:final data?) => ListView(
                children: [
                  for (final item in data)
                    ListTile(
                      key: ValueKey('feed-item-${item.id}'),
                      onTap: () => _open(item.id),
                      title: Text(
                        item.title ?? item.grNumber ?? item.id,
                        style: BmType.bodyStrong,
                      ),
                      subtitle: Text(
                        [
                          ?item.department,
                          ?item.grNumber,
                          _date(item.publishedAt),
                          if (item.approved) t.adminFeedApproved,
                        ].join(' · '),
                      ),
                      trailing: Wrap(
                        spacing: BmSpace.xs,
                        children: [
                          _Badge(item.type),
                          _Badge(item.trust),
                          _Badge(
                            t.adminFeedIssueCount(item.checkIssues.length),
                            warn: item.checkIssues.isNotEmpty,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ],
    );
  }
}

/// One item: source link, text preview, check issues, texts, dates, targets and actions.
class FeedItemPage extends StatefulWidget {
  const FeedItemPage({required this.feed, required this.itemId, super.key});
  final FeedAdminRepository feed;
  final String itemId;

  @override
  State<FeedItemPage> createState() => _FeedItemPageState();
}

class _FeedItemPageState extends State<FeedItemPage> {
  FeedAdminItemOut? _item;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.feed
        .item(widget.itemId)
        .then(
          (i) => mounted ? setState(() => _item = i) : null,
          onError: (Object e) => mounted ? setState(() => _error = e) : null,
        );
  }

  Future<void> _act(Future<FeedAdminItemOut> Function() call) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final next = await call();
      if (mounted) setState(() => _item = next);
      _say(messenger, t.adminDone);
    } on FeedAdminException catch (e) {
      _say(messenger, e.aiUnavailable ? t.adminFeedAiOff : e.message);
    }
  }

  Future<void> _approve(FeedAdminItemOut item) async {
    if (item.checkIssues.isEmpty) {
      return _act(() => widget.feed.approve(item.id));
    }
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => _AcceptIssuesDialog(count: item.checkIssues.length),
    );
    if (comment == null) return;
    await _act(
      () => widget.feed.approve(
        item.id,
        acceptCheckIssues: true,
        comment: comment,
      ),
    );
  }

  Future<void> _withdraw(FeedAdminItemOut item) async {
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (_) => _WithdrawDialog(feed: widget.feed, itemId: item.id),
    );
    if (result case (final reason, final replacedBy)) {
      await _act(() => widget.feed.withdraw(item.id, reason, replacedBy));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final item = _item;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        title: Text(
          item?.title ?? t.adminFeedQueue,
          style: BmType.section.copyWith(color: c.onBrand),
        ),
      ),
      body: switch ((item, _error)) {
        (_, final e?) => Padding(
          padding: const EdgeInsets.all(BmSpace.xl),
          child: Text('$e'),
        ),
        (final i?, _) => _body(context, i),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _body(BuildContext context, FeedAdminItemOut item) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.lg, bottom: BmSpace.xs),
      child: Text(text, style: BmType.section.copyWith(color: c.brand)),
    );
    const buttonSize = Size(0, 44);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BmSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Badge(_statusLabel(t, item.status)),
              _Badge(item.type),
              _Badge(item.trust),
              if (item.approved) _Badge(t.adminFeedApproved),
              Text(
                [
                  item.sourceKey,
                  ?item.department,
                  ?item.grNumber,
                  _date(item.publishedAt),
                ].join(' · '),
                style: BmType.meta,
              ),
            ],
          ),
          const SizedBox(height: BmSpace.xs),
          SelectableText('${t.adminFeedSourceLink}: ${item.url}'),
          if (item.replacedById case final r?)
            Text(t.adminFeedReplacedByValue(r), style: BmType.meta),
          const SizedBox(height: BmSpace.md),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                onPressed: () => _approve(item),
                child: Text(t.adminApprove),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.brand,
                  minimumSize: buttonSize,
                ),
                onPressed: () => _act(() => widget.feed.publish(item.id)),
                child: Text(t.adminPublish),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                onPressed: () => _withdraw(item),
                child: Text(t.adminFeedWithdraw),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                onPressed: () => _act(() => widget.feed.aiDraft(item.id)),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(t.adminFeedAiDraft),
              ),
            ],
          ),
          heading(t.adminFeedCheckIssues),
          if (item.checkIssues.isEmpty)
            Text(t.adminFeedNoIssues, style: BmType.body)
          else
            for (final issue in item.checkIssues)
              ListTile(
                dense: true,
                leading: Icon(Icons.warning_amber_rounded, color: c.danger),
                title: Text(issue.text, style: BmType.body),
                subtitle: Text('${issue.kind} · ${issue.where}'),
              ),
          heading(t.adminFeedTextPreview),
          _TextPreview(item: item),
          heading(t.adminFeedTexts),
          for (final lang in _langs)
            _TextEditor(
              key: ValueKey('text-$lang'),
              lang: lang,
              initial: switch (item.texts[lang]) {
                final Map<String, dynamic> m => FeedAdminItemTextOut.fromJson(
                  m,
                ),
                _ => null,
              },
              onSave: (title, summary) => _act(
                () => widget.feed.setText(item.id, lang, title, summary),
              ),
            ),
          heading(t.adminFeedDates),
          Text(
            [
              '${t.adminFeedDeadline}: ${_date(item.deadline)}',
              '${t.adminFeedPayment}: ${_date(item.paymentDate)}',
              '${t.adminFeedValidFrom}: ${_date(item.validFrom)}',
              '${t.adminFeedValidTo}: ${_date(item.validTo)}',
            ].join('   '),
            style: BmType.body,
          ),
          Text(t.adminFeedDatesNote, style: BmType.meta),
          if (item.card case final card?) ...[
            heading(t.adminFeedCard(card.version)),
            for (final MapEntry(:key, :value) in card.fields.entries)
              Text(
                '$key: ${switch (value) {
                  {'value': final Object v, 'page': final Object p} => '$v ($p)',
                  {'value': final Object v} => '$v',
                  _ => '$value',
                }}',
                style: BmType.body,
              ),
          ],
          heading(t.adminFeedTargets),
          _TargetsEditor(
            initial: item.targets,
            onSave: (targets) =>
                _act(() => widget.feed.setTargets(item.id, targets)),
          ),
          heading(t.adminFeedHistory),
          for (final e in item.events)
            Text('${_date(e.createdAt)} · ${e.kind}', style: BmType.meta),
        ],
      ),
    );
  }
}

/// What the server read from the document: the stored-text flag and, from the latest
/// `extracted` event, method / quality and the text that was not used (broken layer, OCR).
class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.item});
  final FeedAdminItemOut item;

  static const _previewChars = 1200;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final extracted = item.events.lastWhere(
      (e) => e.kind == 'extracted',
      orElse: () => FeedAdminEventOut(
        kind: '',
        actorId: null,
        detail: const {},
        createdAt: item.publishedAt,
      ),
    );
    final d = extracted.detail;
    final unused = switch (d) {
      {'text_layer': final String s} => s,
      {'ocr': {'text': final String s}} => s,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.hasText ? t.adminFeedHasText : t.adminFeedNoText,
          style: BmType.body,
        ),
        if (extracted.kind.isNotEmpty)
          Text(
            [
              for (final k in ['method', 'quality', 'used', 'pages', 'chars'])
                if (d[k] != null) '$k: ${d[k]}',
            ].join(' · '),
            style: BmType.meta,
          ),
        if (unused != null) ...[
          const SizedBox(height: BmSpace.xs),
          Text(t.adminFeedUnusedText, style: BmType.meta),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BmSpace.sm),
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(BmSpace.xs),
            ),
            child: SelectableText(
              unused.length > _previewChars
                  ? '${unused.substring(0, _previewChars)}…'
                  : unused,
            ),
          ),
        ],
      ],
    );
  }
}

class _TextEditor extends StatefulWidget {
  const _TextEditor({
    required this.lang,
    required this.initial,
    required this.onSave,
    super.key,
  });
  final String lang;
  final FeedAdminItemTextOut? initial;
  final Future<void> Function(String title, String? summary) onSave;

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _summary = TextEditingController(text: widget.initial?.summary);

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = widget.lang;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: BmSpace.sm,
        children: [
          SizedBox(
            width: 32,
            child: Text(lang.toUpperCase(), style: BmType.bodyStrong),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('title-$lang'),
              controller: _title,
              decoration: InputDecoration(labelText: t.adminFeedTitle),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              key: Key('summary-$lang'),
              controller: _summary,
              minLines: 2,
              maxLines: 2,
              decoration: InputDecoration(labelText: t.adminFeedSummary),
            ),
          ),
          TextButton(
            key: Key('save-$lang'),
            onPressed: () =>
                widget.onSave(_title.text.trim(), _blankToNull(_summary.text)),
            child: Text(t.adminFeedSave),
          ),
        ],
      ),
    );
  }
}

class _TargetsEditor extends StatefulWidget {
  const _TargetsEditor({required this.initial, required this.onSave});
  final List<FeedAdminTargetOut> initial;
  final Future<void> Function(List<FeedAdminTargetIn>) onSave;

  @override
  State<_TargetsEditor> createState() => _TargetsEditorState();
}

typedef _Row = ({
  TextEditingController district,
  TextEditingController crop,
  TextEditingController minHa,
  TextEditingController maxHa,
});

class _TargetsEditorState extends State<_TargetsEditor> {
  late final List<_Row> _rows = [
    for (final t in widget.initial)
      _row(t.district, t.crop, t.minHa?.toString(), t.maxHa?.toString()),
  ];
  String? _error;

  static _Row _row([String? d, String? c, String? min, String? max]) => (
    district: TextEditingController(text: d),
    crop: TextEditingController(text: c),
    minHa: TextEditingController(text: min),
    maxHa: TextEditingController(text: max),
  );

  @override
  void dispose() {
    for (final r in _rows) {
      for (final c in [r.district, r.crop, r.minHa, r.maxHa]) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _save() {
    final t = AppLocalizations.of(context);
    double? ha(TextEditingController c) =>
        c.text.trim().isEmpty ? null : double.parse(c.text.trim());
    try {
      final targets = [
        for (final r in _rows)
          FeedAdminTargetIn(
            district: _blankToNull(r.district.text),
            crop: _blankToNull(r.crop.text),
            minHa: ha(r.minHa),
            maxHa: ha(r.maxHa),
          ),
      ];
      setState(() => _error = null);
      widget.onSave(targets);
    } on FormatException {
      setState(() => _error = t.adminFeedBadNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.adminFeedTargetsNote, style: BmType.meta),
        for (final (i, r) in _rows.indexed)
          Row(
            spacing: BmSpace.sm,
            children: [
              for (final (key, label, c) in [
                ('district', t.adminFeedDistrict, r.district),
                ('crop', t.adminFeedCrop, r.crop),
                ('min', t.adminFeedMinHa, r.minHa),
                ('max', t.adminFeedMaxHa, r.maxHa),
              ])
                Expanded(
                  child: TextField(
                    key: Key('target-$i-$key'),
                    controller: c,
                    decoration: InputDecoration(labelText: label),
                  ),
                ),
              IconButton(
                tooltip: t.adminFeedRemove,
                onPressed: () => setState(() => _rows.removeAt(i)),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        if (_error case final e?) Text(e, style: BmType.meta),
        const SizedBox(height: BmSpace.xs),
        Wrap(
          spacing: BmSpace.xs,
          children: [
            TextButton(
              onPressed: () => setState(() => _rows.add(_row())),
              child: Text(t.adminFeedAddTarget),
            ),
            TextButton(onPressed: _save, child: Text(t.adminFeedSaveTargets)),
          ],
        ),
      ],
    );
  }
}

/// Approving with open check issues needs an explicit accept and a comment (runbook §4).
class _AcceptIssuesDialog extends StatefulWidget {
  const _AcceptIssuesDialog({required this.count});
  final int count;

  @override
  State<_AcceptIssuesDialog> createState() => _AcceptIssuesDialogState();
}

class _AcceptIssuesDialogState extends State<_AcceptIssuesDialog> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.adminFeedAcceptTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminFeedAcceptBody(widget.count)),
          TextField(
            key: const Key('accept-comment'),
            controller: _comment,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: t.adminFeedComment),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.adminFeedCancel),
        ),
        FilledButton(
          onPressed: _comment.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_comment.text.trim()),
          child: Text(t.adminFeedAcceptApprove),
        ),
      ],
    );
  }
}

/// Reason plus an optional replacement chosen from the published / in-review items.
class _WithdrawDialog extends StatefulWidget {
  const _WithdrawDialog({required this.feed, required this.itemId});
  final FeedAdminRepository feed;
  final String itemId;

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  final _reason = TextEditingController();
  String? _replacement;
  late final Future<List<FeedAdminItemSummaryOut>> _candidates = () async {
    final lists = await Future.wait([
      widget.feed.items(status: 'published'),
      widget.feed.items(),
    ]);
    return [
      for (final list in lists)
        for (final i in list)
          if (i.id != widget.itemId) i,
    ];
  }();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.adminFeedWithdrawTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('withdraw-reason'),
              controller: _reason,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: t.adminFeedReason),
            ),
            const SizedBox(height: BmSpace.sm),
            FutureBuilder<List<FeedAdminItemSummaryOut>>(
              future: _candidates,
              builder: (context, snap) => DropdownButtonFormField<String?>(
                key: const Key('withdraw-replacement'),
                initialValue: _replacement,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.adminFeedReplacedBy),
                items: [
                  DropdownMenuItem(child: Text(t.adminFeedNoReplacement)),
                  for (final i
                      in snap.data ?? const <FeedAdminItemSummaryOut>[])
                    DropdownMenuItem(
                      value: i.id,
                      child: Text(
                        '${i.title ?? i.grNumber ?? i.id} · '
                        '${_statusLabel(t, i.status)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _replacement = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.adminFeedCancel),
        ),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () =>
                    Navigator.of(context)
                        .pop((_reason.text.trim(), _replacement)),
          child: Text(t.adminFeedWithdraw),
        ),
      ],
    );
  }
}

/// Manual GR upload: the document (PDF / HTML, base64; the server keeps its hash and
/// extracts the text) and / or text pasted from it (pasted text wins), plus metadata.
class FeedUploadPage extends StatefulWidget {
  const FeedUploadPage({required this.feed, this.documents, super.key});
  final FeedAdminRepository feed;

  /// Defaults to the `file_picker` adapter; tests pass a fake.
  final DocumentPicker? documents;

  @override
  State<FeedUploadPage> createState() => _FeedUploadPageState();
}

class _FeedUploadPageState extends State<FeedUploadPage> {
  final _c = <String, TextEditingController>{
    for (final k in [
      'source',
      'url',
      'published',
      'external',
      'gr',
      'department',
      'deadline',
      'payment',
      'validFrom',
      'validTo',
      'title',
      'summary',
      'text',
    ])
      k: TextEditingController(),
  };
  String _type = 'gr';
  String? _result;
  FeedAdminItemOut? _created;
  PickedDocument? _document;

  Future<void> _pick() async {
    final t = AppLocalizations.of(context);
    try {
      final doc = await (widget.documents ?? const FilePickerDocuments())
          .pick();
      if (doc != null) setState(() => _document = doc);
    } on DocumentTooLarge {
      setState(
        () => _result = t.adminFeedTooLarge(maxDocumentBytes ~/ (1024 * 1024)),
      );
    } on DocumentTypeNotAllowed {
      setState(() => _result = t.adminFeedBadType);
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String k) => _c[k]!.text.trim();

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final FeedAdminItemIn body;
    try {
      final published = _parseDate(_v('published'));
      if (_v('source').isEmpty || _v('url').isEmpty || published == null) {
        setState(() => _result = t.adminFeedRequiredMissing);
        return;
      }
      body = FeedAdminItemIn(
        sourceKey: _v('source'),
        type: FeedAdminItemInType.values.byName(_type),
        url: _v('url'),
        publishedAt: DateTime.utc(
          published.year,
          published.month,
          published.day,
        ),
        externalId: _blankToNull(_v('external')),
        grNumber: _blankToNull(_v('gr')),
        department: _blankToNull(_v('department')),
        deadline: _parseDate(_v('deadline')),
        paymentDate: _parseDate(_v('payment')),
        validFrom: _parseDate(_v('validFrom')),
        validTo: _parseDate(_v('validTo')),
        extractedText: _blankToNull(_c['text']!.text),
        documentBase64: switch (_document) {
          final d? => base64Encode(d.bytes),
          _ => null,
        },
        documentType: _document?.type,
        texts: _v('title').isEmpty
            ? null
            : {
                'en': {
                  'title': _v('title'),
                  'summary': ?_blankToNull(_v('summary')),
                },
              },
      );
    } on FormatException {
      setState(() => _result = t.adminFeedBadDate);
      return;
    }
    try {
      final item = await widget.feed.create(body);
      setState(() {
        _created = item;
        _result = t.adminFeedCreated(
          _statusLabel(t, item.status),
          item.checkIssues.length,
        );
      });
    } on FeedAdminException catch (e) {
      setState(() => _result = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget field(String k, String label, {int lines = 1}) => TextField(
      key: Key('upload-$k'),
      controller: _c[k],
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines * 2,
      decoration: InputDecoration(labelText: label),
    );
    Widget pair(Widget a, Widget b) => Row(
      spacing: BmSpace.md,
      children: [
        Expanded(child: a),
        Expanded(child: b),
      ],
    );
    final dateHint = t.adminFeedDateHint;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminFeedUploadNote, style: BmType.meta),
          const SizedBox(height: BmSpace.sm),
          SegmentedButton<String>(
            segments: [
              for (final type in _types)
                ButtonSegment(value: type, label: Text(type)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.single),
          ),
          pair(
            field('source', t.adminFeedSourceKey),
            field('published', '${t.adminFeedPublishedAt} ($dateHint)'),
          ),
          field('url', t.adminFeedUrl),
          pair(
            field('external', t.adminFeedExternalId),
            field('gr', t.adminFeedGrNumber),
          ),
          field('department', t.adminFeedDepartment),
          pair(
            field('deadline', '${t.adminFeedDeadline} ($dateHint)'),
            field('payment', '${t.adminFeedPayment} ($dateHint)'),
          ),
          pair(
            field('validFrom', '${t.adminFeedValidFrom} ($dateHint)'),
            field('validTo', '${t.adminFeedValidTo} ($dateHint)'),
          ),
          pair(
            field('title', 'EN · ${t.adminFeedTitle}'),
            field('summary', 'EN · ${t.adminFeedSummary}'),
          ),
          const SizedBox(height: BmSpace.sm),
          Row(
            spacing: BmSpace.sm,
            children: [
              OutlinedButton.icon(
                key: const Key('upload-pick'),
                onPressed: _pick,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(t.adminFeedPickDocument),
              ),
              Expanded(
                child: Text(switch (_document) {
                  final d? => t.adminFeedDocument(
                    d.name,
                    (d.bytes.length / 1024).ceil(),
                  ),
                  _ => t.adminFeedNoDocument,
                }, style: BmType.body),
              ),
              if (_document != null)
                IconButton(
                  tooltip: t.adminFeedRemove,
                  onPressed: () => setState(() => _document = null),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          field('text', t.adminFeedPastedText, lines: 6),
          const SizedBox(height: BmSpace.md),
          Wrap(
            spacing: BmSpace.sm,
            children: [
              FilledButton(onPressed: _submit, child: Text(t.adminFeedSubmit)),
              if (_created case final item?)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          FeedItemPage(feed: widget.feed, itemId: item.id),
                    ),
                  ),
                  child: Text(t.adminFeedOpen),
                ),
            ],
          ),
          if (_result case final r?) ...[
            const SizedBox(height: BmSpace.md),
            SelectableText(r, style: BmType.body),
          ],
          if (_created case final item?) ...[
            const SizedBox(height: BmSpace.sm),
            Text(t.adminFeedExtraction, style: BmType.bodyStrong),
            _TextPreview(item: item),
            for (final issue in item.checkIssues)
              Text('• ${issue.kind}: ${issue.text}', style: BmType.body),
          ],
        ],
      ),
    );
  }
}

/// The source registry: terms status per source, set to allowed / disallowed with a note.
class FeedSourcesPage extends StatefulWidget {
  const FeedSourcesPage({required this.feed, super.key});
  final FeedAdminRepository feed;

  @override
  State<FeedSourcesPage> createState() => _FeedSourcesPageState();
}

class _FeedSourcesPageState extends State<FeedSourcesPage> {
  late final Future<List<FeedAdminSourceOut>> _future = widget.feed.sources();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FeedAdminSourceOut>>(
    future: _future,
    builder: (context, snap) => switch (snap) {
      AsyncSnapshot(:final error?) => Text('$error'),
      AsyncSnapshot(:final data?) => ListView(
        children: [
          for (final s in data)
            _SourceTile(key: ValueKey(s.key), feed: widget.feed, source: s),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    },
  );
}

class _SourceTile extends StatefulWidget {
  const _SourceTile({required this.feed, required this.source, super.key});
  final FeedAdminRepository feed;
  final FeedAdminSourceOut source;

  @override
  State<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<_SourceTile> {
  late FeedAdminSourceOut _source = widget.source;
  late String _terms = widget.source.termsStatus;
  late final _note = TextEditingController(text: widget.source.notes);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final next = await widget.feed.setTerms(
        _source.key,
        _terms,
        _blankToNull(_note.text),
      );
      if (mounted) setState(() => _source = next);
      _say(messenger, t.adminDone);
    } on FeedAdminException catch (e) {
      _say(messenger, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = _source;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.name, style: BmType.bodyStrong),
          SelectableText(
            '${s.key} · ${s.tier} · ${t.adminFeedTerms}: ${s.termsStatus} · '
            '${s.fetchMethod} · ${s.fetchStatus}'
            '${s.lastError == null ? '' : ' (${s.lastError})'} · ${s.url}',
            style: BmType.meta,
          ),
          const SizedBox(height: BmSpace.xs),
          Row(
            spacing: BmSpace.sm,
            children: [
              SegmentedButton<String>(
                key: Key('terms-${s.key}'),
                segments: [
                  ButtonSegment(
                    value: 'unknown',
                    label: Text(t.adminFeedTermsUnknown),
                  ),
                  ButtonSegment(
                    value: 'allowed',
                    label: Text(t.adminFeedTermsAllowed),
                  ),
                  ButtonSegment(
                    value: 'disallowed',
                    label: Text(t.adminFeedTermsDisallowed),
                  ),
                ],
                selected: {_terms},
                onSelectionChanged: (v) => setState(() => _terms = v.single),
              ),
              Expanded(
                child: TextField(
                  key: Key('terms-note-${s.key}'),
                  controller: _note,
                  decoration: InputDecoration(labelText: t.adminFeedTermsNote),
                ),
              ),
              TextButton(
                key: Key('terms-save-${s.key}'),
                onPressed: _save,
                child: Text(t.adminFeedSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
