import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../scouting/data/scouting_photos.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/claim_kit.dart';
import 'share_claim_kit.dart';

/// The crop-loss claim kit: pick the plot and the date of loss, add photos (each stamped
/// with when and where it was added), a note, and tick a general checklist. Saved on this
/// phone only; "Share PDF" makes one PDF with plot, GPS, date, photos and note.
class ClaimKitScreen extends ConsumerStatefulWidget {
  const ClaimKitScreen({this.plotId, this.claimId, super.key});

  /// Plot to start with (from a plot screen or a storm alert).
  final String? plotId;

  /// An existing kit to reopen.
  final String? claimId;

  @override
  ConsumerState<ClaimKitScreen> createState() => _ClaimKitScreenState();
}

class _ClaimKitScreenState extends ConsumerState<ClaimKitScreen> {
  final _note = TextEditingController();
  late final String _id =
      widget.claimId ?? ref.read(claimKitRepositoryProvider).newId();
  String? _plot;
  DateTime? _date;
  final _done = <String>{};
  final _photos = <ClaimPhoto>[];
  bool _tried = false;
  bool _busy = false;
  late bool _loading = widget.claimId != null;

  @override
  void initState() {
    super.initState();
    _plot = widget.plotId;
    final id = widget.claimId;
    if (id != null) {
      ref.read(claimKitRepositoryProvider).find(id).then((k) {
        if (!mounted) return;
        if (k == null) return setState(() => _loading = false);
        setState(() {
          _loading = false;
          _plot = k.plotId;
          _date = k.lossOn;
          _note.text = k.note ?? '';
          _done
            ..clear()
            ..addAll(k.done);
          _photos
            ..clear()
            ..addAll(k.photos);
        });
      });
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  ClaimKit _kit() {
    final note = _note.text.trim();
    return ClaimKit(
      id: _id,
      plotId: _plot!,
      lossOn: _date ?? _today,
      note: note.isEmpty ? null : note,
      done: {..._done},
      photos: [..._photos],
    );
  }

  void _say(String Function(AppLocalizations) text) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text(AppLocalizations.of(context)))));
  }

  /// Takes or picks a photo, keeps it in the app's own folder and stamps it with the time
  /// and the phone's position (when the phone can read it).
  Future<void> _addPhoto(PhotoSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final photos = ref.read(claimPhotosProvider);
      final picked = await photos.pick(source);
      if (picked == null) return;
      final photoId = ref.read(claimKitRepositoryProvider).newId();
      final kept = await photos.keep(picked, photoId);
      final at = ref.read(clockProvider)();
      final reading = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      setState(
        () => _photos.add(
          ClaimPhoto(
            id: photoId,
            path: kept,
            takenAt: at,
            lat: reading.position?.lat,
            lon: reading.position?.lon,
            accuracyM: reading.accuracyM,
          ),
        ),
      );
    } on Object catch (e) {
      ref.read(appLogProvider).log('claim photo: $e');
      _say((t) => t.scoutingPhotoFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _save({bool leave = true}) async {
    setState(() => _tried = true);
    if (_plot == null) return false;
    await ref.read(claimKitRepositoryProvider).save(_kit());
    if (!leave) return true;
    _say((t) => t.plotSaved);
    if (mounted) {
      context.canPop() ? context.pop() : context.go(Routes.insurance(_plot!));
    }
    return true;
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await _save(leave: false) || !mounted) return;
      await shareClaimKit(context, ref, _kit());
    } on Object catch (e) {
      ref.read(appLogProvider).log('claim pdf: $e');
      _say((t) => t.claimKitShareFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(t.claimKitDelete),
        content: Text(t.claimKitDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(claimKitRepositoryProvider).delete(_id);
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plotsAsync = ref.watch(plotsProvider);
    if (_loading || !plotsAsync.hasValue) {
      return Scaffold(appBar: AppBar(title: Text(t.claimKitTitle)));
    }
    final plots = plotsAsync.value ?? const [];
    final today = _today;
    final date = _date ?? today;
    final label = BmType.formLabel.copyWith(color: c.ink);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.claimKitTitle),
        actions: [
          if (widget.claimId != null)
            IconButton(
              key: const Key('delete-claim'),
              tooltip: t.claimKitDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          DropdownButtonFormField<String>(
            key: const Key('claim-plot'),
            initialValue: plots.any((p) => p.id == _plot) ? _plot : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.claimKitPlot,
              errorText: _tried && _plot == null ? t.claimKitPickPlot : null,
            ),
            items: [
              for (final p in plots)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, style: BmType.body),
                ),
            ],
            onChanged: (v) => setState(() => _plot = v),
          ),
          ListTile(
            key: const Key('claim-date'),
            contentPadding: EdgeInsets.zero,
            minTileHeight: 48,
            title: Text(t.claimKitDate, style: BmType.body),
            trailing: Text(
              formatDate(date, lang),
              style: BmType.bodyStrong.copyWith(color: c.brandStrong),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(today.year - 1),
                lastDate: today,
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: BmSpace.sm),
          Text(t.claimKitPhotos, style: label),
          const SizedBox(height: BmSpace.xs),
          if (_photos.isEmpty)
            Text(
              t.claimKitNoPhotos,
              style: BmType.body.copyWith(color: c.inkMuted),
            ),
          for (final p in _photos)
            Padding(
              padding: const EdgeInsets.only(bottom: BmSpace.xs),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(BmRadius.chip),
                    child: Image.file(
                      File(p.path),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      cacheWidth: 192,
                      errorBuilder: (_, _, _) => SizedBox.square(
                        dimension: 64,
                        child: Icon(Icons.photo_outlined, color: c.inkMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: BmSpace.sm),
                  Expanded(
                    child: Text(
                      p.stamp(noGps: t.claimKitNoGps),
                      style: BmType.meta,
                    ),
                  ),
                  IconButton(
                    tooltip: t.claimKitRemovePhoto,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () async {
                      setState(() => _photos.remove(p));
                      // A photo never saved with the kit is not kept either.
                      final saved = await ref
                          .read(claimKitRepositoryProvider)
                          .find(_id);
                      if (saved?.photos.any((s) => s.id == p.id) != true) {
                        await ref.read(claimPhotosProvider).discard(p.path);
                      }
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.sm,
            runSpacing: BmSpace.xs,
            children: [
              OutlinedButton.icon(
                key: const Key('claim-camera'),
                onPressed: _busy ? null : () => _addPhoto(PhotoSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(t.scoutingCamera),
              ),
              OutlinedButton.icon(
                key: const Key('claim-gallery'),
                onPressed: _busy ? null : () => _addPhoto(PhotoSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(t.scoutingGallery),
              ),
            ],
          ),
          const SizedBox(height: BmSpace.md),
          TextField(
            key: const Key('claim-note'),
            controller: _note,
            maxLength: 500,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(
              counterText: '',
              labelText: t.claimKitNote,
              suffixIcon: VoiceMicButton(
                onResult: (text, {required isFinal}) => _note.text = text,
              ),
            ),
          ),
          const SizedBox(height: BmSpace.lg),
          Text(t.claimKitChecklist, style: label),
          const SizedBox(height: BmSpace.xs),
          BmCard(
            elevated: false,
            radius: BmRadius.card,
            padding: const EdgeInsets.all(BmSpace.md),
            child: Text(
              t.claimKitCheckPolicy,
              key: const Key('claim-check-policy'),
              style: BmType.body.copyWith(color: c.accentInk),
            ),
          ),
          for (final k in claimChecklist)
            CheckboxListTile(
              key: Key('check-$k'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _done.contains(k),
              title: Text(claimChecklistLabel(t, k), style: BmType.body),
              onChanged: (on) =>
                  setState(() => on == true ? _done.add(k) : _done.remove(k)),
            ),
          const SizedBox(height: BmSpace.sm),
          Text(
            t.claimKitLocalOnly,
            style: BmType.meta.copyWith(color: c.inkMuted),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton(
            key: const Key('claim-share'),
            onPressed: _busy ? null : _share,
            child: Text(t.claimKitShare),
          ),
          FilledButton(
            key: const Key('claim-save'),
            onPressed: _busy ? null : _save,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}
