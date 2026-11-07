import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/bottom_actions.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../design_system/glyphs.dart';
import '../design_system/info_note.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'market_link_admin_repository.dart';
import 'market_link_checks.dart';
import 'market_link_flags.dart';

/// Opens a signed document URL (a new browser tab on the admin web).
typedef OpenUrl = Future<void> Function(Uri url);

Future<void> _launch(Uri url) async {
  await launchUrl(url, webOnlyWindowName: '_blank');
}

String _date(DateTime d) => d.toLocal().toIso8601String().substring(0, 10);

String _typeLabel(AppLocalizations t, String type) => switch (type) {
  'buyer' => t.adminMlBuyer,
  'broker' => t.adminMlBroker,
  'provider' => t.adminMlProvider,
  _ => type,
};

String _statusLabel(AppLocalizations t, String status) => switch (status) {
  'pending' => t.adminMlStatusPending,
  'approved' => t.adminMlStatusApproved,
  'rejected' => t.adminMlStatusRejected,
  'draft' => t.adminMlTagDraft,
  'active' => t.adminMlTagActive,
  'retired' => t.adminMlTagRetired,
  _ => status,
};

String _fieldLabel(AppLocalizations t, String key) => switch (key) {
  'name' => t.adminMlFieldName,
  'firm' => t.adminMlFieldFirm,
  'phone' => t.adminMlFieldPhone,
  'markets' => t.adminMlFieldMarkets,
  'district' => t.adminMlFieldDistrict,
  'taluka' => t.adminMlFieldTaluka,
  'village' => t.adminMlFieldVillage,
  'crops' => t.adminMlFieldCrops,
  'service_areas' => t.adminMlFieldServiceAreas,
  'apmc_licence_no' => t.adminMlFieldApmc,
  'gst_no' => t.adminMlFieldGst,
  'kind' => t.adminMlFieldKind,
  'cert_valid_until' => t.adminMlFieldCertValidUntil,
  'vehicle_numbers' => t.adminMlFieldVehicles,
  'capacity_t' => t.adminMlFieldCapacity,
  'refrigerated' => t.adminMlFieldRefrigerated,
  'carrier_reg_no' => t.adminMlFieldCarrierReg,
  _ => key,
};

String _fieldValue(AppLocalizations t, Object? value) => switch (value) {
  'weighbridge' => t.adminMlKindWeighbridge,
  'transporter' => t.adminMlKindTransporter,
  'labour_gang' => t.adminMlKindLabourGang,
  'crate_supplier' => t.adminMlKindCrateSupplier,
  'yes' => t.adminMlYes,
  'no' => t.adminMlNo,
  _ => '$value',
};

/// Opens one subject's detail page (queue and re-check list).
Future<void> openVerificationDetail(
  BuildContext context, {
  required MarketLinkAdminRepository repo,
  required String type,
  required String id,
  OpenUrl? openUrl,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => VerificationDetailPage(
      repo: repo,
      type: type,
      id: id,
      openUrl: openUrl ?? _launch,
    ),
  ),
);

void _say(ScaffoldMessengerState messenger, String text) =>
    messenger.showSnackBar(SnackBar(content: Text(text)));

/// Colour by meaning: verified / active green, rejected red, waiting / draft neutral.
class _Status extends StatelessWidget {
  const _Status(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final colour = switch (status) {
      'approved' || 'active' => c.brandStrong,
      'rejected' || 'retired' => c.danger,
      _ => c.inkMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.xs,
        vertical: BmSpace.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BmSpace.xs),
        border: Border.all(color: colour),
      ),
      child: Text(
        _statusLabel(AppLocalizations.of(context), status),
        style: BmType.meta.copyWith(color: colour),
      ),
    );
  }
}

/// Traders, brokers and service providers waiting for a check, oldest first.
class VerificationQueuePage extends StatefulWidget {
  const VerificationQueuePage({required this.repo, this.openUrl, super.key});
  final MarketLinkAdminRepository repo;
  final OpenUrl? openUrl;

  @override
  State<VerificationQueuePage> createState() => _VerificationQueuePageState();
}

class _VerificationQueuePageState extends State<VerificationQueuePage> {
  String _type = '';
  late Future<List<SubjectOut>> _future = _load();

  Future<List<SubjectOut>> _load() =>
      widget.repo.queue(type: _type.isEmpty ? null : _type);

  Future<void> _open(SubjectOut s) async {
    await openVerificationDetail(
      context,
      repo: widget.repo,
      type: s.subjectType,
      id: s.subjectId,
      openUrl: widget.openUrl,
    );
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: '', label: Text(t.adminMlAll)),
            for (final type in const ['buyer', 'broker', 'provider'])
              ButtonSegment(value: type, label: Text(_typeLabel(t, type))),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() {
            _type = s.single;
            _future = _load();
          }),
        ),
        const SizedBox(height: BmSpace.md),
        Expanded(
          child: FutureBuilder<List<SubjectOut>>(
            future: _future,
            builder: (context, snap) => switch (snap) {
              AsyncSnapshot(:final error?) => Text('$error'),
              AsyncSnapshot(:final data?) when data.isEmpty => EmptyState(
                glyph: BmGlyph.ledger,
                message: t.adminMlQueueEmpty,
              ),
              AsyncSnapshot(:final data?) => ListView(
                children: [
                  for (final s in data)
                    ListTile(
                      key: ValueKey('subject-${s.subjectId}'),
                      onTap: () => _open(s),
                      title: Text(s.name, style: BmType.bodyStrong),
                      subtitle: Text(
                        [
                          _typeLabel(t, s.subjectType),
                          ?s.fields['district'] as String?,
                          t.adminMlDocumentCount(s.documentKeys.length),
                          for (final f in s.flags ?? const <String>[])
                            flagLabel(t, f),
                        ].join(' · '),
                        style: (s.flags ?? const []).isEmpty
                            ? null
                            : TextStyle(color: context.bm.danger),
                      ),
                      trailing: Text(
                        t.adminMlWaitingSince(_date(s.waitingSince)),
                        style: BmType.meta,
                      ),
                    ),
                ],
              ),
              _ => LoadingState(label: t.adminMlQueue),
            },
          ),
        ),
      ],
    );
  }
}

/// One subject: flags, submitted fields, documents, the per-check panel, every past
/// decision, and Approve / Reject.
class VerificationDetailPage extends StatefulWidget {
  const VerificationDetailPage({
    required this.repo,
    required this.type,
    required this.id,
    required this.openUrl,
    super.key,
  });
  final MarketLinkAdminRepository repo;
  final String type;
  final String id;
  final OpenUrl openUrl;

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  SubjectDetailOut? _detail;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.repo
        .subject(widget.type, widget.id)
        .then(
          (d) => mounted ? setState(() => _detail = d) : null,
          onError: (Object e) => mounted ? setState(() => _error = e) : null,
        );
  }

  Future<void> _decide({required bool approve}) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? reason;
    if (!approve) {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectDialog(),
      );
      if (reason == null) return;
    }
    try {
      final next = await widget.repo.decide(
        widget.type,
        widget.id,
        approve: approve,
        reason: reason,
      );
      if (mounted) setState(() => _detail = next);
      _say(messenger, t.adminDone);
    } on KbAdminException catch (e) {
      _say(messenger, e.message);
    }
  }

  Future<void> _record(String kind, String result, int? year) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final next = await widget.repo.recordCheck(
        widget.type,
        widget.id,
        kind: kind,
        result: result,
        registeredYear: year,
      );
      if (mounted) setState(() => _detail = next);
      _say(messenger, t.adminDone);
    } on KbAdminException catch (e) {
      _say(messenger, e.message);
    }
  }

  Future<void> _openDocument(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await widget.repo.documentUrl(widget.type, widget.id, index);
      await widget.openUrl(Uri.parse(url));
    } on KbAdminException catch (e) {
      _say(messenger, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        title: Text(
          detail?.subject.name ?? t.adminMlQueue,
          style: BmType.section.copyWith(color: c.onBrand),
        ),
      ),
      body: switch ((detail, _error)) {
        (_, final e?) => Padding(
          padding: const EdgeInsets.all(BmSpace.xl),
          child: Text('$e'),
        ),
        (final d?, _) => _body(t, c, d),
        _ => LoadingState(label: t.adminMlQueue),
      },
      bottomNavigationBar: detail == null
          ? null
          : BottomActions(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: c.danger),
                  onPressed: () => _decide(approve: false),
                  child: Text(t.adminMlReject),
                ),
                FilledButton(
                  onPressed: () => _decide(approve: true),
                  child: Text(t.adminApprove),
                ),
              ],
            ),
    );
  }

  Widget _body(AppLocalizations t, BmColors c, SubjectDetailOut d) {
    final s = d.subject;
    return ListView(
      padding: const EdgeInsets.all(BmSpace.xl),
      children: [
        Row(
          children: [
            Text(_typeLabel(t, s.subjectType), style: BmType.meta),
            const SizedBox(width: BmSpace.sm),
            _Status(s.status),
          ],
        ),
        const SizedBox(height: BmSpace.lg),
        FlagsSection(subject: s),
        SectionHeader(title: t.adminMlFields),
        BmCard(
          elevated: false,
          child: Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              for (final MapEntry(:key, :value) in s.fields.entries)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: BmSpace.lg,
                        bottom: BmSpace.xs,
                      ),
                      child: Text(
                        _fieldLabel(t, key),
                        style: BmType.meta.copyWith(color: c.inkMuted),
                      ),
                    ),
                    SelectableText(
                      _fieldValue(t, value),
                      style: BmType.bodyStrong,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: BmSpace.lg),
        SectionHeader(title: t.adminMlDocuments),
        if (s.documentKeys.isEmpty)
          EmptyNote(t.adminMlNoDocuments)
        else
          Wrap(
            spacing: BmSpace.sm,
            runSpacing: BmSpace.sm,
            children: [
              for (final (i, _) in s.documentKeys.indexed)
                OutlinedButton.icon(
                  key: ValueKey('document-$i'),
                  onPressed: () => _openDocument(i),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(t.adminMlDocument(i + 1)),
                ),
            ],
          ),
        const SizedBox(height: BmSpace.sm),
        InfoNote(t.adminMlBadgeNote),
        const SizedBox(height: BmSpace.lg),
        ChecksSection(detail: d, openUrl: widget.openUrl, onRecord: _record),
        const SizedBox(height: BmSpace.lg),
        SectionHeader(title: t.adminFeedHistory),
        for (final v in d.history)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: _Status(v.status),
            title: Text(
              [
                _date(v.checkedAt ?? v.createdAt),
                if (v.checkedBy case final who?) t.adminMlCheckedBy(who),
                ?v.reason,
              ].join(' · '),
              style: BmType.body,
            ),
          ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final reason = _reason.text.trim();
    return AlertDialog(
      title: Text(t.adminMlRejectTitle),
      content: SizedBox(
        width: 480,
        child: TextField(
          key: const Key('reject-reason'),
          controller: _reason,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: t.adminFeedReason),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.adminFeedCancel),
        ),
        FilledButton(
          onPressed: reason.isEmpty
              ? null
              : () => Navigator.of(context).pop(reason),
          child: Text(t.adminMlReject),
        ),
      ],
    );
  }
}

/// Every rating tag (drafts too) under its question; only admin edits them (spec §3A).
class RatingTagsPage extends StatefulWidget {
  const RatingTagsPage({required this.repo, super.key});
  final MarketLinkAdminRepository repo;

  @override
  State<RatingTagsPage> createState() => _RatingTagsPageState();
}

class _RatingTagsPageState extends State<RatingTagsPage> {
  late Future<List<RatingTagAdminOut>> _future = widget.repo.ratingTags();

  Future<void> _edit(RatingTagAdminOut tag) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final body = await showDialog<RatingTagIn>(
      context: context,
      builder: (_) => _TagDialog(tag: tag),
    );
    if (body == null) return;
    try {
      await widget.repo.saveRatingTag(tag.id, body);
      _say(messenger, t.adminDone);
      if (mounted) {
        setState(() {
          _future = widget.repo.ratingTags();
        });
      }
    } on KbAdminException catch (e) {
      _say(messenger, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return FutureBuilder<List<RatingTagAdminOut>>(
      future: _future,
      builder: (context, snap) => switch (snap) {
        AsyncSnapshot(:final error?) => Text('$error'),
        AsyncSnapshot(:final data?) when data.isEmpty => EmptyState(
          glyph: BmGlyph.ledger,
          message: t.adminMlTagsEmpty,
        ),
        AsyncSnapshot(:final data?) => ListView(
          children: [
            InfoNote(t.adminMlTagsNote),
            const SizedBox(height: BmSpace.sm),
            for (final (i, tag) in data.indexed) ...[
              if (i == 0 || data[i - 1].questionKey != tag.questionKey)
                Padding(
                  padding: const EdgeInsets.only(
                    top: BmSpace.md,
                    bottom: BmSpace.xs,
                  ),
                  child: SectionHeader(title: tag.questionKey),
                ),
              ListTile(
                key: ValueKey('tag-${tag.key}'),
                onTap: () => _edit(tag),
                leading: Icon(
                  tag.polarity == 'positive'
                      ? Icons.thumb_up_alt_outlined
                      : Icons.thumb_down_alt_outlined,
                  color: tag.polarity == 'positive' ? c.brandStrong : c.danger,
                  semanticLabel: tag.polarity == 'positive'
                      ? t.adminMlPositive
                      : t.adminMlNegative,
                ),
                title: Text(tag.labelMr, style: BmType.bodyStrong),
                subtitle: Text('${tag.labelEn} · ${tag.labelHi}'),
                trailing: Wrap(
                  spacing: BmSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Status(tag.status),
                    Icon(Icons.edit_rounded, semanticLabel: t.adminMlEditTag),
                  ],
                ),
              ),
            ],
          ],
        ),
        _ => LoadingState(label: t.adminMlTags),
      },
    );
  }
}

class _TagDialog extends StatefulWidget {
  const _TagDialog({required this.tag});
  final RatingTagAdminOut tag;

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late final _en = TextEditingController(text: widget.tag.labelEn);
  late final _mr = TextEditingController(text: widget.tag.labelMr);
  late final _hi = TextEditingController(text: widget.tag.labelHi);
  late String _status = widget.tag.status;

  @override
  void dispose() {
    for (final c in [_en, _mr, _hi]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filled = [_en, _mr, _hi].every((c) => c.text.trim().isNotEmpty);
    Widget field(String key, String label, TextEditingController c) =>
        TextField(
          key: Key('tag-$key'),
          controller: c,
          maxLength: 120,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: label),
        );
    return AlertDialog(
      title: Text(t.adminMlEditTag),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field('mr', t.adminMlLabelMr, _mr),
            field('hi', t.adminMlLabelHi, _hi),
            field('en', t.adminMlLabelEn, _en),
            SegmentedButton<String>(
              segments: [
                for (final s in const ['draft', 'active', 'retired'])
                  ButtonSegment(value: s, label: Text(_statusLabel(t, s))),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.single),
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
          onPressed: filled
              ? () => Navigator.of(context).pop(
                  RatingTagIn(
                    labelEn: _en.text.trim(),
                    labelMr: _mr.text.trim(),
                    labelHi: _hi.text.trim(),
                    status: RatingTagInStatus.values.byName(_status),
                  ),
                )
              : null,
          child: Text(t.adminFeedSave),
        ),
      ],
    );
  }
}
