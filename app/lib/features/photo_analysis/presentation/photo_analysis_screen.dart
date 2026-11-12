import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../scouting/data/scouting_photos.dart';
import '../../scouting/domain/scouting_record.dart';
import '../data/offline_leaf_model.dart';
import '../data/photo_analysis_api.dart';
import '../domain/offline_check.dart';
import '../domain/photo_analysis.dart';

String photoPartLabel(AppLocalizations t, PhotoPart p) => switch (p) {
  PhotoPart.leaf => t.photoCheckPartLeaf,
  PhotoPart.fruit => t.photoCheckPartFruit,
  PhotoPart.trunk => t.photoCheckPartTrunk,
  PhotoPart.wholeTree => t.photoCheckPartWholeTree,
};

String likelihoodLabel(AppLocalizations t, Likelihood l) => switch (l) {
  Likelihood.high => t.photoCheckLikelyHigh,
  Likelihood.medium => t.photoCheckLikelyMedium,
  Likelihood.low => t.photoCheckLikelyLow,
};

/// The calm limit line (owner 2026-11-11: small, light, never an error), with the reset in
/// the phone's local time: "tomorrow" when it is the coming midnight.
String photoLimitText(
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
      isTomorrow
          ? t.photoCheckLimitDaily(count)
          : t.photoCheckLimitDailyAt(count, when),
    PhotoLimitKind.monthly => t.photoCheckLimitMonthly(count, when),
    PhotoLimitKind.total =>
      isTomorrow ? t.photoCheckLimitTotal : t.photoCheckLimitTotalAt(when),
  };
}

/// "फोटोवरून ओळखा" (OPEN_QUESTIONS Q135, stage 3): one photo of the block goes to the server,
/// which names up to three problems from the practice cards with a calm explanation. Opened
/// from the scouting log (the screen picks the photo) or from the pest / disease photo form
/// with its photo ([photoPath], kept by that form). Consent is the privacy policy accepted at
/// signup: no question here; the system camera needs no permission of the app. Online first:
/// nothing is queued; the photo stays on screen for a one-tap retry. One call per photo.
/// Without network the phone's own leaf model gives a first estimate ([OfflineLeafCheck]),
/// said to be an estimate; it never reaches the server, so it never counts against limits.
class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  const PhotoAnalysisScreen({
    required this.plotId,
    this.photoPath,
    this.scoutingItem,
    super.key,
  });

  final String plotId;
  final String? photoPath;

  /// What the grower chose on the scouting form; sent as `scouting_item`.
  final String? scoutingItem;

  @override
  ConsumerState<PhotoAnalysisScreen> createState() =>
      _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  late String? _path = widget.photoPath;

  /// A photo this screen picked (a temporary file): removed when it is replaced or left.
  String? _ownPick;
  Uint8List? _bytes;
  bool _preparing = false;
  PhotoPart? _part;
  bool _busy = false;
  PhotoAnalysisResult? _result;
  PhotoLimitException? _limit;
  PhotoProblem? _problem;

  /// The phone's own estimate, made when the online check found no network.
  OfflineReading? _offline;
  bool _deleting = false;
  bool _deleted = false;
  bool _deleteFailed = false;
  late final ScoutingPhotos _photos;

  bool get _fromForm => widget.photoPath != null;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(scoutingPhotosProvider);
    if (_path != null) _prepare(_path!);
  }

  @override
  void dispose() {
    if (_ownPick != null) _photos.discard(_ownPick!);
    super.dispose();
  }

  void _log(String line) => ref.read(appLogProvider).log('photo check: $line');

  Future<void> _pick(PhotoSource source) async {
    try {
      final path = await _photos.pick(source);
      if (path == null || !mounted) return;
      setState(() {
        _path = _ownPick = path;
        _problem = null;
        _offline = null;
      });
      await _prepare(path);
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

  Future<void> _prepare(String path) async {
    setState(() => _preparing = true);
    try {
      final bytes = await ref.read(photoPreparerProvider)(path);
      if (!mounted || _path != path) return;
      setState(() => _bytes = bytes);
    } on Object catch (e) {
      _log('prepare $e');
      if (mounted) setState(() => _problem = PhotoProblem.refused);
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  /// Back to choosing a photo; the old answer and photo go.
  void _reset() {
    if (_ownPick != null) _photos.discard(_ownPick!);
    setState(() {
      _path = _ownPick = null;
      _bytes = null;
      _result = null;
      _limit = null;
      _problem = null;
      _offline = null;
      _deleted = _deleteFailed = false;
    });
  }

  Future<void> _analyse() async {
    final bytes = _bytes;
    if (bytes == null || _busy || _result != null) return;
    setState(() {
      _busy = true;
      _problem = null;
      _offline = null;
    });
    try {
      final item = widget.scoutingItem;
      final result = await ref
          .read(photoAnalysisApiProvider)
          .analyse(
            plotId: widget.plotId,
            photo: bytes,
            part: _part,
            scoutingItem: scoutingItems.contains(item) ? item : null,
          );
      if (mounted) setState(() => _result = result);
    } on PhotoLimitException catch (e) {
      _log('$e');
      if (mounted) setState(() => _limit = e);
    } on PhotoProblemException catch (e) {
      _log('$e');
      // The estimate first, so the plain offline line never flashes before it.
      if (e.problem == PhotoProblem.offline) await _checkOnPhone(bytes);
      if (mounted) setState(() => _problem = e.problem);
    } on Object catch (e) {
      _log('$e');
      if (mounted) setState(() => _problem = PhotoProblem.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// No network: the phone's leaf model looks at the same photo. The model knows only
  /// leaves, so a photo marked fruit / trunk / whole tree reads "not clear". When the model
  /// cannot run, the plain "internet needed" line stays.
  Future<void> _checkOnPhone(Uint8List bytes) async {
    final check = ref.read(offlineLeafCheckProvider);
    if (check == null || !mounted) return;
    if (_part != null && _part != PhotoPart.leaf) {
      setState(() => _offline = OfflineReading.notALeaf);
      return;
    }
    try {
      final reading = await check.check(bytes);
      _log('on phone: ${reading.verdict.name} ${reading.best}');
      if (mounted && identical(_bytes, bytes)) {
        setState(() => _offline = reading);
      }
    } on Object catch (e) {
      _log('on phone $e');
    }
  }

  Future<void> _delete() async {
    final id = _result?.photoId;
    if (id == null || _deleting) return;
    setState(() {
      _deleting = true;
      _deleteFailed = false;
    });
    try {
      await ref.read(photoAnalysisApiProvider).delete(id);
      if (mounted) setState(() => _deleted = true);
    } on Object catch (e) {
      _log('delete $e');
      if (mounted) setState(() => _deleteFailed = true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final sections = {
      for (final s
          in ref.watch(practiceCardsProvider).value?.sections ??
              const <Never>[])
        s.key,
    };
    final calm = BmType.body.copyWith(color: c.inkMuted);
    final result = _result;
    final limit = _limit;
    final chosen = _result == null && _limit == null;

    Widget preview() => ClipRRect(
      key: const Key('photo-check-preview'),
      borderRadius: BorderRadius.circular(BmRadius.tile),
      child: SizedBox(
        // Smaller once there is an answer, so the answer is what the grower sees first.
        height: chosen ? 200 : 120,
        width: double.infinity,
        child: switch (_bytes) {
          final b? => Image.memory(
            b,
            fit: BoxFit.cover,
            cacheWidth: 900,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _PhotoPlaceholder(c.inkMuted),
          ),
          null => _PhotoPlaceholder(c.inkMuted, busy: _preparing),
        },
      ),
    );

    final offline = _problem == PhotoProblem.offline ? _offline : null;
    final problemText = switch (_problem) {
      PhotoProblem.offline when offline != null => null,
      PhotoProblem.offline => (t.photoCheckOffline, 'photo-check-offline'),
      PhotoProblem.failed => (t.photoCheckFailed, 'photo-check-failed'),
      PhotoProblem.unavailable => (
        t.photoCheckUnavailable,
        'photo-check-unavailable',
      ),
      PhotoProblem.refused => (t.photoCheckRefused, 'photo-check-refused'),
      PhotoProblem.signedOut => (
        t.photoCheckSignedOut,
        'photo-check-signed-out',
      ),
      null => null,
    };

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.photoCheckOpen)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.xs,
          BmSpace.lg,
          BmSpace.xl,
        ),
        children: [
          if (_path == null) ...[
            Text(t.photoCheckHint, style: calm),
          ] else ...[
            preview(),
            if (!_fromForm && !_busy && chosen)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  key: const Key('photo-check-change'),
                  onPressed: _reset,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t.photoCheckChange),
                ),
              ),
          ],
          if (chosen) ...[
            const SizedBox(height: BmSpace.md),
            Text(
              t.photoCheckPart,
              style: BmType.formLabel.copyWith(color: c.ink),
            ),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final p in PhotoPart.values)
                  ChoiceChip(
                    key: Key('photo-part-${p.wire}'),
                    label: Text(photoPartLabel(t, p), style: BmType.bodyStrong),
                    selected: _part == p,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _part = _part == p ? null : p),
                  ),
              ],
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: BmSpace.lg),
            Row(
              key: const Key('photo-check-busy'),
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: c.brand,
                  ),
                ),
                const SizedBox(width: BmSpace.sm),
                Expanded(child: Text(t.photoCheckBusy, style: calm)),
              ],
            ),
          ],
          if (problemText case (final text, final key)) ...[
            const SizedBox(height: BmSpace.md),
            Text(text, key: Key(key), style: calm),
          ],
          if (offline != null && !_busy) ...[
            const SizedBox(height: BmSpace.md),
            _OfflineResult(reading: offline, sections: sections),
          ],
          if (limit != null) ...[
            const SizedBox(height: BmSpace.md),
            Text(
              photoLimitText(t, limit, lang, ref.read(clockProvider)()),
              key: const Key('photo-check-limit'),
              style: calm,
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: BmSpace.md),
            if (result.healthy)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.sm),
                child: Row(
                  key: const Key('photo-check-healthy'),
                  children: [
                    Icon(Icons.eco_outlined, color: c.brand),
                    const SizedBox(width: BmSpace.xs),
                    Expanded(
                      child: Text(
                        t.photoCheckHealthy,
                        style: BmType.bodyStrong.copyWith(color: c.brand),
                      ),
                    ),
                  ],
                ),
              ),
            if (result.unsure)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.sm),
                child: Text(
                  t.photoCheckUnsure,
                  key: const Key('photo-check-unsure'),
                  style: BmType.body.copyWith(color: c.info),
                ),
              ),
            for (final cand in result.candidates.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.sm),
                child: _CandidateCard(
                  candidate: cand,
                  lang: lang,
                  hasCard: sections.contains(cand.key),
                ),
              ),
            InfoNote(t.photoCheckNote, key: const Key('photo-check-note')),
            const SizedBox(height: BmSpace.xs),
            if (_deleted)
              Text(
                t.photoCheckDeleted,
                key: const Key('photo-check-deleted'),
                style: BmType.meta.copyWith(color: c.inkMuted),
              )
            else ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('photo-check-delete'),
                  style: BmButtonStyle.destructive(c),
                  onPressed: _deleting ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: Text(t.photoCheckDelete),
                ),
              ),
              if (_deleteFailed)
                Text(
                  t.photoCheckDeleteFailed,
                  key: const Key('photo-check-delete-failed'),
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          if (limit != null || (result != null && result.unsure))
            OutlinedButton(
              key: const Key('photo-check-cards'),
              onPressed: () => context.push(Routes.practices),
              child: Text(t.photoCheckSeeCards),
            ),
          if (limit == null && result != null)
            _fromForm
                ? FilledButton(
                    key: const Key('photo-check-back'),
                    onPressed: () => context.pop(),
                    child: Text(t.photoCheckBack),
                  )
                : FilledButton(
                    key: const Key('photo-check-another'),
                    onPressed: _reset,
                    child: Text(t.photoCheckChange),
                  ),
          if (chosen && _path == null) ...[
            OutlinedButton.icon(
              key: const Key('photo-check-gallery'),
              onPressed: () => _pick(PhotoSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(t.scoutingGallery),
            ),
            FilledButton.icon(
              key: const Key('photo-check-camera'),
              onPressed: () => _pick(PhotoSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(t.scoutingCamera),
            ),
          ],
          if (chosen && _path != null)
            FilledButton(
              key: const Key('photo-check-run'),
              onPressed: _bytes == null || _busy ? null : _analyse,
              child: Text(
                _problem == null || _problem == PhotoProblem.refused
                    ? t.photoCheckOpen
                    : t.photoCheckRetry,
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder(this.color, {this.busy = false});
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.bm.background,
    child: Center(
      child: busy
          ? SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            )
          : Icon(Icons.photo_outlined, color: color, size: 40),
    ),
  );
}

/// One possible problem: the card's name, the calm likelihood with its percentage, the
/// explanation in the app language, what was seen, and the card.
class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.lang,
    required this.hasCard,
  });

  final PhotoCandidate candidate;
  final String lang;
  final bool hasCard;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final cand = candidate;
    final healthy = cand.key == PhotoCandidate.healthy;
    final (:signs, :english) = cand.signsIn(lang);
    final signList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in signs)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.xxs),
            child: Text('• $s', style: BmType.meta.copyWith(color: c.inkMuted)),
          ),
      ],
    );
    return BmCard(
      key: Key('photo-candidate-${cand.key}'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (healthy) ...[
                Icon(Icons.eco_outlined, color: c.brand, size: 22),
                const SizedBox(width: BmSpace.xs),
              ],
              Expanded(
                child: Text(
                  cand.nameIn(lang),
                  style: BmType.bodyStrong.copyWith(
                    color: healthy ? c.brand : c.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BmSpace.xxs),
          Text(
            '${likelihoodLabel(t, Likelihood.of(cand.confidence))} · '
            '${formatPercent(cand.percent, lang)}',
            style: BmType.meta.copyWith(color: c.brandStrong),
          ),
          if (cand.explanationIn(lang) case final text
              when text.isNotEmpty) ...[
            const SizedBox(height: BmSpace.xs),
            Text(text, style: BmType.body),
          ],
          if (signs.isNotEmpty)
            // In Marathi and Hindi the signs fold away behind one quiet line (the explanation
            // above already says what was seen); "(in English)" only when that language had
            // none and the English ones are shown.
            lang == 'en'
                ? Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.photoCheckSigns, style: BmType.label),
                        signList,
                      ],
                    ),
                  )
                // Its own transparent Material, so the tile's ink shows on the card.
                : Material(
                    type: MaterialType.transparency,
                    child: ExpansionTile(
                      key: Key('photo-signs-${cand.key}'),
                      tilePadding: EdgeInsets.zero,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      childrenPadding: const EdgeInsets.only(
                        bottom: BmSpace.xs,
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      expandedAlignment: AlignmentDirectional.centerStart,
                      title: Text(
                        english ? t.photoCheckSignsEnglish : t.photoCheckSigns,
                        style: BmType.meta.copyWith(color: c.inkMuted),
                      ),
                      children: [signList],
                    ),
                  ),
          if (hasCard)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xs),
              child: FilledButton.icon(
                key: Key('photo-card-${cand.key}'),
                style: BmButtonStyle.primary(c),
                onPressed: () =>
                    context.push(Routes.practicesSection(cand.key)),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(t.photoCheckOpenCard),
              ),
            ),
        ],
      ),
    );
  }
}

/// The phone's own estimate, offline: calm, never certain. A disease line ("signs like
/// canker (possible)") with its card, at most two; a healthy line in green; or "not clear,
/// the full check runs online". Greening carries the PCR line, as online. One muted line
/// says it is the phone's estimate.
class _OfflineResult extends StatelessWidget {
  const _OfflineResult({required this.reading, required this.sections});

  final OfflineReading reading;
  final Set<String> sections;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    if (reading.verdict == OfflineVerdict.unclear) {
      return Text(
        t.photoOfflineUnclear,
        key: const Key('photo-offline-unclear'),
        style: BmType.body.copyWith(color: c.info),
      );
    }
    String what(String key) => switch (key) {
      'canker' => t.photoOfflineCanker,
      'greening' => t.photoOfflineGreening,
      _ => key,
    };
    final shown = reading.shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BmCard(
          key: const Key('photo-offline-result'),
          elevated: false,
          radius: BmRadius.card,
          padding: const EdgeInsets.all(BmSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reading.verdict == OfflineVerdict.healthy)
                Row(
                  key: const Key('photo-offline-healthy'),
                  children: [
                    Icon(Icons.eco_outlined, color: c.brand, size: 22),
                    const SizedBox(width: BmSpace.xs),
                    Expanded(
                      child: Text(
                        t.photoOfflineHealthy,
                        style: BmType.bodyStrong.copyWith(color: c.brand),
                      ),
                    ),
                  ],
                )
              else
                for (final (i, g) in shown.indexed) ...[
                  if (i > 0) const SizedBox(height: BmSpace.sm),
                  Text(
                    (i == 0 ? t.photoOfflineLead : t.photoOfflineAlso)(
                      what(g.key),
                      likelihoodLabel(t, Likelihood.of(g.probability)),
                    ),
                    key: Key('photo-offline-${g.key}'),
                    style: i == 0
                        ? BmType.bodyStrong.copyWith(color: c.ink)
                        : BmType.body.copyWith(color: c.ink),
                  ),
                  if (g.key == 'greening') ...[
                    const SizedBox(height: BmSpace.xxs),
                    Text(
                      t.photoOfflinePcr,
                      key: const Key('photo-offline-pcr'),
                      style: BmType.body,
                    ),
                  ],
                  if (sections.contains(g.key))
                    Padding(
                      padding: const EdgeInsets.only(top: BmSpace.xs),
                      child: FilledButton.icon(
                        key: Key('photo-offline-card-${g.key}'),
                        style: BmButtonStyle.primary(c),
                        onPressed: () =>
                            context.push(Routes.practicesSection(g.key)),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: Text(t.photoCheckOpenCard),
                      ),
                    ),
                ],
            ],
          ),
        ),
        const SizedBox(height: BmSpace.xs),
        Text(
          t.photoOfflineNote,
          key: const Key('photo-offline-note'),
          style: BmType.meta.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}
