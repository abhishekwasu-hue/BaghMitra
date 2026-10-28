import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/presentation/cycle_chips.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../data/scouting_photos.dart';
import '../domain/scouting_record.dart';

String scoutingItemLabel(AppLocalizations t, String item) => switch (item) {
  'psylla' => t.scoutingItemPsylla,
  'leaf_miner' => t.scoutingItemLeafMiner,
  'mites_thrips' => t.scoutingItemMitesThrips,
  'fruit_drop' => t.scoutingItemFruitDrop,
  'gummosis_bark' => t.scoutingItemGummosis,
  'die_back' => t.scoutingItemDieBack,
  _ => t.scoutingItemOther,
};

String scoutingSeverityLabel(AppLocalizations t, String severity) =>
    switch (severity) {
      'low' => t.scoutingSeverityLow,
      'medium' => t.scoutingSeverityMedium,
      'high' => t.scoutingSeverityHigh,
      _ => t.scoutingSeverityNone,
    };

/// A kept photo from this phone, or a plain icon when the file is gone.
class _Thumb extends StatelessWidget {
  const _Thumb(this.path, {this.size = 56});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(BmRadius.chip),
    child: Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * 3).round(),
      errorBuilder: (_, _, _) => SizedBox.square(
        dimension: size,
        child: Icon(Icons.photo_outlined, color: context.bm.inkMuted),
      ),
    ),
  );
}

/// A record's photo: the file on this phone, or a backed-up one fetched once from the
/// server; a small cloud mark when it is backed up.
class _RecordPhoto extends ConsumerWidget {
  const _RecordPhoto(this.record);
  final ScoutingRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final path =
        record.photoPath ??
        ref.watch(scoutingPhotoFileProvider(record.id)).value;
    return Column(
      children: [
        path != null
            ? _Thumb(path)
            : SizedBox.square(
                dimension: 56,
                child: Icon(Icons.photo_outlined, color: context.bm.inkMuted),
              ),
        if (record.backedUp)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.xs),
            child: Icon(
              Icons.cloud_done_outlined,
              key: const Key('photo-backed-up'),
              size: 16,
              color: context.bm.brand,
              semanticLabel: t.scoutingPhotoBackedUp,
            ),
          ),
      ],
    );
  }
}

/// The scouting log of one block ("पाहणी नोंद"), newest first.
class ScoutingScreen extends ConsumerWidget {
  const ScoutingScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final loaded = ref.watch(scoutingRecordsProvider(plotId));
    final records = loaded.value ?? const [];
    Color tone(String severity) => switch (severity) {
      'high' => c.danger,
      'medium' => c.soil,
      'low' => c.brand,
      _ => c.inkMuted,
    };
    return Scaffold(
      appBar: AppBar(title: Text(t.scoutingTitle)),
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : records.isEmpty
          ? EmptyState(glyph: BmGlyph.camera, message: t.scoutingEmpty)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                120,
              ),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: BmSpace.sm),
              itemBuilder: (_, i) {
                final r = records[i];
                return BmCard(
                  elevated: false,
                  radius: BmRadius.card,
                  padding: const EdgeInsets.all(BmSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scoutingItemLabel(t, r.item),
                              style: BmType.bodyStrong,
                            ),
                            const SizedBox(height: BmSpace.xs),
                            Text(
                              '${scoutingSeverityLabel(t, r.severity)} · '
                              '${formatDate(r.observedOn, lang)}',
                              style: BmType.body.copyWith(
                                color: tone(r.severity),
                              ),
                            ),
                            if (r.note != null) ...[
                              const SizedBox(height: BmSpace.xs),
                              Text(
                                r.note!,
                                style: BmType.body.copyWith(color: c.inkMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (r.photoPath != null || r.backedUp) ...[
                        const SizedBox(width: BmSpace.sm),
                        _RecordPhoto(r),
                      ],
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: () => context.push(Routes.addScouting(plotId)),
            child: Text(t.scoutingAdd),
          ),
        ],
      ),
    );
  }
}

/// Records one scouting observation: what was looked at and how much of it there was are
/// required; a note (typed or spoken) and one photo are optional. Names only, no advice.
class AddScoutingScreen extends ConsumerStatefulWidget {
  const AddScoutingScreen({required this.plotId, super.key});
  final String plotId;

  @override
  ConsumerState<AddScoutingScreen> createState() => _AddScoutingScreenState();
}

class _AddScoutingScreenState extends ConsumerState<AddScoutingScreen> {
  final _note = TextEditingController();
  DateTime? _date;
  String? _item;
  String? _severity;
  String? _cycle;
  String? _picked;
  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pick(PhotoSource source) async {
    try {
      final path = await ref.read(scoutingPhotosProvider).pick(source);
      if (path != null && mounted) setState(() => _picked = path);
    } on Object catch (e) {
      ref.read(appLogProvider).log('scouting photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).scoutingPhotoFailed),
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_item == null || _severity == null || _saving) return;
    _saving = true;
    final repo = ref.read(scoutingRepositoryProvider);
    final id = repo.newId();
    final note = _note.text.trim();
    String? photo;
    try {
      if (_picked != null) {
        photo = await ref.read(scoutingPhotosProvider).keep(_picked!, id);
      }
    } on Object catch (e) {
      // The photo could not be kept (storage full?): nothing is saved; the grower can retry
      // or remove the photo and save the observation alone.
      _saving = false;
      ref.read(appLogProvider).log('scouting photo keep: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).scoutingPhotoFailed),
        ),
      );
      return;
    }
    await repo.save(
      ScoutingRecord(
        id: id,
        plotId: widget.plotId,
        baharCycleId: _cycle,
        observedOn: _date ?? _today,
        item: _item!,
        severity: _severity!,
        note: note.isEmpty ? null : note,
        photoPath: photo,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.canPop()
        ? context.pop()
        : context.go(Routes.scouting(widget.plotId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final today = _today;
    final date = _date ?? today;
    final label = BmType.formLabel.copyWith(color: c.ink);
    Widget choice(
      String title,
      List<String> slugs,
      String Function(String) name,
      String? value,
      ValueChanged<String> set,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BmSpace.md),
        Text(title, style: label),
        const SizedBox(height: BmSpace.xs),
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            for (final s in slugs)
              ChoiceChip(
                label: Text(name(s), style: BmType.bodyStrong),
                selected: value == s,
                onSelected: (_) => setState(() => set(s)),
              ),
          ],
        ),
        if (_tried && value == null)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.xs),
            child: Text(
              t.scoutingPickOne,
              style: BmType.label.copyWith(color: c.danger),
            ),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.scoutingAdd)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          ListTile(
            key: const Key('scouting-date'),
            contentPadding: EdgeInsets.zero,
            title: Text(t.scoutingDate, style: BmType.body),
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
          choice(
            t.scoutingWhat,
            scoutingItems,
            (s) => scoutingItemLabel(t, s),
            _item,
            (v) => _item = v,
          ),
          choice(
            t.scoutingSeverity,
            scoutingSeverities,
            (s) => scoutingSeverityLabel(t, s),
            _severity,
            (v) => _severity = v,
          ),
          const SizedBox(height: BmSpace.md),
          TextField(
            key: const Key('scouting-note'),
            controller: _note,
            maxLength: 500,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              counterText: '',
              labelText: t.scoutingNote,
              suffixIcon: VoiceMicButton(
                onResult: (text, {required isFinal}) => _note.text = text,
              ),
            ),
          ),
          const SizedBox(height: BmSpace.sm),
          Text(t.scoutingPhoto, style: label),
          const SizedBox(height: BmSpace.xs),
          if (_picked != null)
            Row(
              children: [
                _Thumb(_picked!, size: 96),
                const SizedBox(width: BmSpace.sm),
                TextButton.icon(
                  onPressed: () => setState(() => _picked = null),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(t.scoutingRemovePhoto),
                ),
              ],
            )
          else
            Wrap(
              spacing: BmSpace.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pick(PhotoSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t.scoutingCamera),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(PhotoSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t.scoutingGallery),
                ),
              ],
            ),
          CycleChips(
            plotId: widget.plotId,
            selected: _cycle,
            onChanged: (v) => setState(() => _cycle = v),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [FilledButton(onPressed: _save, child: Text(t.save))],
      ),
    );
  }
}
