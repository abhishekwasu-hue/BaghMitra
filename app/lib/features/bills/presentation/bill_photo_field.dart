import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/sync_engine.dart';
import '../../../theme/app_theme.dart';
import '../../photo_analysis/data/photo_analysis_api.dart';
import '../../photo_analysis/domain/photo_analysis.dart';
import '../../scouting/data/scouting_photos.dart';
import '../data/bill_photos.dart';
import '../data/bill_read_api.dart';
import '../domain/bill_reading.dart';

// "बिलाचा फोटो" on the spray record and Add expense forms (OPEN_QUESTIONS Q136): take or pick
// the shop bill's photo, keep it with the record on the phone, and "बिलावरून भरा" fills the
// empty fields from it. Consent is the privacy policy accepted at signup: no prompt per photo.

/// The calm limit line for bill reading, as for the photo check: the reset in local time.
String billLimitText(
  AppLocalizations t,
  PhotoLimitException e,
  String lang,
  DateTime now,
) {
  final at = e.resetsAt?.toLocal();
  final local = now.toLocal();
  final tomorrow = DateTime(local.year, local.month, local.day + 1);
  final isTomorrow = at == null || at == tomorrow;
  final midnight = at != null && at.hour == 0 && at.minute == 0;
  final when = at == null
      ? ''
      : midnight
      ? formatDate(at, lang)
      : formatDateTime(at, lang);
  final count = e.max == null ? '' : formatInt(e.max!, lang);
  return switch (e.kind) {
    PhotoLimitKind.daily =>
      isTomorrow ? t.billLimitDaily(count) : t.billLimitDailyAt(count, when),
    PhotoLimitKind.monthly => t.billLimitMonthly(count, when),
    PhotoLimitKind.total =>
      isTomorrow ? t.billLimitTotal : t.billLimitTotalAt(when),
  };
}

/// `shop बिल #no`, or null when the bill shows neither.
String? billLabel(AppLocalizations t, BillReading b) =>
    switch ((b.shopName, b.billNo)) {
      (final shop?, final no?) => t.billLabelShopNo(shop, no),
      (final shop?, null) => t.billLabelShop(shop),
      (null, final no?) => t.billLabelNo(no),
      (null, null) => null,
    };

String billFieldName(AppLocalizations t, BillField f) => switch (f) {
  BillField.product => t.billFieldProduct,
  BillField.active => t.billFieldActive,
  BillField.dose => t.billFieldDose,
  BillField.cost => t.billFieldCost,
  BillField.amount => t.billFieldAmount,
  BillField.date => t.billFieldDate,
  BillField.note => t.billFieldNote,
};

int _paise(double rs) => (rs * 100).round();

/// The bill photo full screen, pinch to zoom.
Future<void> openBillPhoto(BuildContext context, String path) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          key: const Key('bill-photo-full'),
          appBar: AppBar(
            title: AppBarTitle(AppLocalizations.of(context).billPhoto),
          ),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: context.bm.inkMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );

/// A kept bill photo; a tap opens it full screen.
class BillThumb extends StatelessWidget {
  const BillThumb(this.path, {this.size = 56, super.key});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppLocalizations.of(context).billPhotoOpen,
    child: InkWell(
      onTap: () => openBillPhoto(context, path),
      borderRadius: BorderRadius.circular(BmRadius.chip),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BmRadius.chip),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, _, _) => SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.receipt_long_outlined,
              color: context.bm.inkMuted,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A saved record's bill photo on a list: the file on this phone, or a backed-up one
/// fetched once; nothing while there is neither.
class RecordBillThumb extends ConsumerWidget {
  const RecordBillThumb({
    required this.kind,
    required this.recordId,
    required this.path,
    super.key,
  });

  final BillKind kind;
  final String recordId;
  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file =
        path ?? ref.watch(billPhotoFileProvider((kind, recordId))).value;
    return file == null
        ? const SizedBox.shrink()
        : BillThumb(file, size: 48, key: Key('bill-thumb-$recordId'));
  }
}

/// What the form shows under the bill photo: calm, small lines.
enum BillNoteKind { filled, nothingFilled, unsure, offline, limit, problem }

typedef BillNote = ({BillNoteKind kind, String text});

/// The bill photo part of a form: the picked photo, taking / removing it, and reading it.
/// The form keeps the photo with its record when saved ([keepBill]) and fills its own
/// fields from what [readBill] returns.
mixin BillPhotoForm<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The picked photo (a temporary file until the record is saved).
  String? billPicked;
  bool billBusy = false;
  List<BillNote> billNotes = const [];

  ScoutingPhotos get _photos => ref.read(billPhotosProvider);

  void _log(String line) => ref.read(appLogProvider).log('bill photo: $line');

  Future<void> pickBill(PhotoSource source) async {
    try {
      final path = await _photos.pick(source);
      if (path != null && mounted) {
        setState(() {
          billPicked = path;
          billNotes = const [];
        });
      }
    } on Object catch (e) {
      _log('pick $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).scoutingPhotoFailed),
        ),
      );
    }
  }

  void removeBill() => setState(() {
    billPicked = null;
    billNotes = const [];
  });

  /// Keeps the picked photo for record [id]; the kept path, or null without a photo.
  /// Throws when the file cannot be kept (the form then saves nothing, as scouting does).
  Future<String?> keepBill(String id) async {
    final picked = billPicked;
    if (picked == null) return null;
    try {
      return await _photos.keep(picked, id);
    } on Object catch (e) {
      _log('keep $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).scoutingPhotoFailed),
          ),
        );
      }
      rethrow;
    }
  }

  /// The phone knows it has no network (last sync run): reading is not offered.
  bool get billOffline =>
      ref.watch(syncStatusProvider).value?.connectivity == Connectivity.offline;

  /// Sends the photo once; null (with a calm note shown) when there is no answer.
  Future<BillReading?> readBill() async {
    final path = billPicked;
    if (path == null || billBusy) return null;
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      billBusy = true;
      billNotes = const [];
    });
    BillNote? note;
    try {
      final bytes = await ref.read(photoPreparerProvider)(path);
      return await ref.read(billReadApiProvider).read(bytes);
    } on PhotoLimitException catch (e) {
      _log('$e');
      note = (
        kind: BillNoteKind.limit,
        text: billLimitText(t, e, lang, ref.read(clockProvider)()),
      );
    } on PhotoProblemException catch (e) {
      _log('$e');
      note = switch (e.problem) {
        PhotoProblem.offline => (
          kind: BillNoteKind.offline,
          text: t.billOffline,
        ),
        PhotoProblem.unavailable => (
          kind: BillNoteKind.problem,
          text: t.billUnavailable,
        ),
        PhotoProblem.refused => (
          kind: BillNoteKind.problem,
          text: t.billRefused,
        ),
        PhotoProblem.signedOut => (
          kind: BillNoteKind.problem,
          text: t.billSignedOut,
        ),
        PhotoProblem.failed => (kind: BillNoteKind.problem, text: t.billFailed),
      };
    } on PhotoUnreadableException catch (e) {
      _log('$e');
      note = (kind: BillNoteKind.problem, text: t.billRefused);
    } on Object catch (e) {
      _log('$e');
      note = (kind: BillNoteKind.problem, text: t.billFailed);
    } finally {
      if (mounted) {
        setState(() {
          billBusy = false;
          if (note != null) billNotes = [note];
        });
      }
    }
    return null;
  }

  /// After a pick: which fields were filled (muted), with the unsure line first.
  void showBillFilled(BillReading bill, Iterable<BillField> filled) {
    final t = AppLocalizations.of(context);
    setState(
      () => billNotes = [
        if (bill.unsure) (kind: BillNoteKind.unsure, text: t.billUnsure),
        if (filled.isEmpty)
          (kind: BillNoteKind.nothingFilled, text: t.billNothingFilled)
        else
          (
            kind: BillNoteKind.filled,
            text: t.billFilled(
              [for (final f in filled) billFieldName(t, f)].join(', '),
            ),
          ),
      ],
    );
  }

  void showBillUnsure() => setState(
    () => billNotes = [
      (
        kind: BillNoteKind.unsure,
        text: AppLocalizations.of(context).billUnsure,
      ),
    ],
  );

  Widget billField({required VoidCallback onFill}) => _BillPhotoField(
    path: billPicked,
    busy: billBusy,
    offline: billOffline,
    notes: billNotes,
    onPick: pickBill,
    onRemove: removeBill,
    onFill: onFill,
  );
}

class _BillPhotoField extends StatelessWidget {
  const _BillPhotoField({
    required this.path,
    required this.busy,
    required this.offline,
    required this.notes,
    required this.onPick,
    required this.onRemove,
    required this.onFill,
  });

  final String? path;
  final bool busy;
  final bool offline;
  final List<BillNote> notes;
  final void Function(PhotoSource) onPick;
  final VoidCallback onRemove;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final photo = path;
    final shown = [
      ...notes,
      // Known offline: say so once, calmly; never "will be sent".
      if (photo != null &&
          offline &&
          !notes.any((n) => n.kind == BillNoteKind.offline))
        (kind: BillNoteKind.offline, text: t.billOffline),
    ];
    return Column(
      key: const Key('bill-photo'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.billPhoto, style: BmType.formLabel.copyWith(color: c.ink)),
        const SizedBox(height: BmSpace.xs),
        if (photo == null) ...[
          Wrap(
            spacing: BmSpace.sm,
            runSpacing: BmSpace.xs,
            children: [
              OutlinedButton.icon(
                key: const Key('bill-photo-camera'),
                onPressed: () => onPick(PhotoSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(t.scoutingCamera),
              ),
              OutlinedButton.icon(
                key: const Key('bill-photo-gallery'),
                onPressed: () => onPick(PhotoSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(t.scoutingGallery),
              ),
            ],
          ),
          const SizedBox(height: BmSpace.xs),
          InfoNote(t.billPhotoHint),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BillThumb(photo, size: 96, key: const Key('bill-photo-thumb')),
              const SizedBox(width: BmSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (busy)
                      Padding(
                        key: const Key('bill-reading'),
                        padding: const EdgeInsets.symmetric(
                          vertical: BmSpace.sm,
                        ),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: c.brand,
                              ),
                            ),
                            const SizedBox(width: BmSpace.sm),
                            Expanded(
                              child: Text(
                                t.billReading,
                                style: BmType.body.copyWith(color: c.inkMuted),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!offline)
                      OutlinedButton.icon(
                        key: const Key('bill-fill'),
                        onPressed: onFill,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(t.billFill),
                      ),
                    TextButton.icon(
                      key: const Key('bill-photo-remove'),
                      onPressed: busy ? null : onRemove,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(t.scoutingRemovePhoto),
                    ),
                  ],
                ),
              ),
            ],
          ),
        for (final n in shown) ...[
          const SizedBox(height: BmSpace.xs),
          n.kind == BillNoteKind.unsure
              ? Text(
                  n.text,
                  key: const Key('bill-note-unsure'),
                  style: BmType.body.copyWith(color: c.info),
                )
              : InfoNote(n.text, key: Key('bill-note-${n.kind.name}')),
        ],
      ],
    );
  }
}

/// The line the farmer picked; [item] is null for the bill total (expense form only).
class BillPick {
  const BillPick(this.item);
  final BillItem? item;
}

/// The lines read from the bill, amounts first on the right, to pick one. With
/// [withTotal], the bill total is offered first (the expense form).
Future<BillPick?> showBillPickSheet(
  BuildContext context,
  BillReading bill, {
  bool withTotal = false,
}) => showModalBottomSheet<BillPick>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => BillPickSheet(bill: bill, withTotal: withTotal),
);

class BillPickSheet extends StatelessWidget {
  const BillPickSheet({required this.bill, this.withTotal = false, super.key});

  final BillReading bill;
  final bool withTotal;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final head = [
      ?billLabel(t, bill),
      if (bill.billDate case final d?) formatDate(d, lang),
    ].join(' · ');
    Widget amount(double? rs) => Text(
      rs == null ? '—' : formatPaise(_paise(rs), lang),
      style: BmType.section.copyWith(color: c.ink),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          key: const Key('bill-pick-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            BmSpace.lg,
            0,
            BmSpace.lg,
            BmSpace.lg,
          ),
          children: [
            Text(t.billPickTitle, style: BmType.section.copyWith(color: c.ink)),
            if (head.isNotEmpty) InfoNote(head),
            if (bill.unsure) ...[
              const SizedBox(height: BmSpace.xs),
              Text(t.billUnsure, style: BmType.body.copyWith(color: c.info)),
            ],
            const SizedBox(height: BmSpace.sm),
            if (withTotal && bill.totalRs != null) ...[
              ListTile(
                key: const Key('bill-pick-total'),
                contentPadding: EdgeInsets.zero,
                title: Text(t.billTotal, style: BmType.bodyStrong),
                trailing: amount(bill.totalRs),
                onTap: () => Navigator.of(context).pop(const BillPick(null)),
              ),
              Divider(color: c.line, height: 1),
            ],
            for (final (i, item) in bill.items.indexed)
              ListTile(
                key: Key('bill-pick-$i'),
                contentPadding: EdgeInsets.zero,
                title: Text(item.name, style: BmType.bodyStrong),
                subtitle: [?item.activeIngredient, ?item.quantityText].isEmpty
                    ? null
                    : Text(
                        [
                          ?item.activeIngredient,
                          ?item.quantityText,
                        ].join(' · '),
                        style: BmType.meta.copyWith(color: c.inkMuted),
                      ),
                trailing: amount(item.amountRs),
                onTap: () => Navigator.of(context).pop(BillPick(item)),
              ),
          ],
        ),
      ),
    );
  }
}
