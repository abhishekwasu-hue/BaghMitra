import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/sync_status_banner.dart';
import '../../../theme/app_theme.dart';
import '../../bahar/data/bahar_catalog.dart';
import '../../bahar/data/stage_templates.dart';
import '../../bahar/presentation/cycle_chips.dart';
import '../../plots/domain/plot.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/lot_form_rules.dart';
import '../domain/market_link_role.dart';
import '../domain/market_lot.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';

/// One lot of produce for sale (spec v1.5 §3 step 1): orchard and bahar as big choices,
/// crop and variety from the orchard, tonnes, size / quality (typed or spoken), harvest
/// window (from the bahar's harvest stage by default), basis, an optional asking rate with
/// today's mandi price beside it. Saved as a draft on the phone. A published lot is read
/// only. (Photos and "show to traders" come in the next part, L3-7.)
class LotFormScreen extends StatelessWidget {
  const LotFormScreen({this.lotId, this.plotId, super.key});

  final String? lotId;
  final String? plotId;

  @override
  Widget build(BuildContext context) => MarketLinkEntry(
    role: MarketLinkRole.grower,
    child: _LotForm(lotId: lotId, plotId: plotId),
  );
}

class _LotForm extends ConsumerStatefulWidget {
  const _LotForm({this.lotId, this.plotId});

  final String? lotId;
  final String? plotId;

  @override
  ConsumerState<_LotForm> createState() => _LotFormState();
}

/// Between the size, the grade and the short line in the lot text.
const qualitySeparator = ' · ';

class _LotFormState extends ConsumerState<_LotForm> {
  final _form = GlobalKey<FormState>();
  final _tonnes = TextEditingController();
  final _quality = TextEditingController();
  final _rate = TextEditingController();
  late final String _id =
      widget.lotId ?? ref.read(marketLotRepositoryProvider).newId();
  String? _plot;
  String? _cycle;
  String? _basis;
  String? _size;
  String? _grade;
  StageWindow? _custom;
  String _status = 'draft';
  bool _awaitingCheck = false;
  bool _tried = false;
  bool _busy = false;
  late bool _loading = widget.lotId != null;

  @override
  void initState() {
    super.initState();
    _plot = widget.plotId;
    final id = widget.lotId;
    if (id == null) return;
    final repo = ref.read(marketLotRepositoryProvider);
    // The chip options are needed to read the size / grade back from the lot text.
    Future.wait([repo.find(id), ref.read(fieldWorkOptionsProvider.future)])
        .then((r) {
          if (!mounted) return;
          final lot = r[0] as MarketLot?;
          setState(() {
            _loading = false;
            if (lot == null) return;
            _plot = lot.plotId;
            _cycle = lot.baharCycleId;
            _basis = lot.basis;
            _status = lot.status;
            _awaitingCheck = lot.awaitingCheck;
            final q = lot.quantityT;
            _tonnes.text = q == q.roundToDouble() ? '${q.round()}' : '$q';
            _quality.text = _readQuality(lot.quality);
            _rate.text = lot.askingRatePaise == null
                ? ''
                : plainRupees(lot.askingRatePaise!).replaceAll('.00', '');
            _custom = StageWindow(lot.harvestFrom, lot.harvestTo);
          });
        });
  }

  @override
  void dispose() {
    for (final c in [_tonnes, _quality, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  void _say(String Function(AppLocalizations) text) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text(AppLocalizations.of(context)))));
  }

  Plot? _plotOf(List<Plot> plots) =>
      plots.where((p) => p.id == _plot).firstOrNull;

  StageWindow? _baharWindow(String? crop) {
    final cycles = _plot == null
        ? null
        : ref.watch(baharCyclesProvider(_plot!)).value;
    final cycle = cycles?.where((c) => c.id == _cycle).firstOrNull;
    if (cycle == null || crop == null) return null;
    final templates = ref.watch(stageTemplatesProvider).value;
    return harvestWindowFor(cycle, templates?[templateKey(crop, cycle.bahar)]);
  }

  /// Size and grade chips go into the lot text with the short line, in the grower's
  /// language: "मोठी · ए ग्रेड · line". (Separate columns are asked for in migration 0030.)
  String _composeQuality() {
    final lang = Localizations.localeOf(context).languageCode;
    final options = ref.read(fieldWorkOptionsProvider).value;
    String? label(List<LabeledOption>? all, String? slug) =>
        all?.where((o) => o.slug == slug).firstOrNull?.label(lang);
    return [
      ?label(options?.sizeClasses, _size),
      ?label(options?.grades, _grade),
      if (_quality.text.trim().isNotEmpty) _quality.text.trim(),
    ].join(qualitySeparator);
  }

  /// The chips and the short line back from a saved lot text.
  String _readQuality(String? text) {
    final options = ref.read(fieldWorkOptionsProvider).value;
    final rest = <String>[];
    for (final part in (text ?? '').split(qualitySeparator)) {
      bool named(LabeledOption o) => o.labels.values.contains(part);
      final size = options?.sizeClasses.where(named).firstOrNull;
      final grade = options?.grades.where(named).firstOrNull;
      if (size != null && _size == null) {
        _size = size.slug;
      } else if (grade != null && _grade == null) {
        _grade = grade.slug;
      } else if (part.isNotEmpty) {
        rest.add(part);
      }
    }
    return rest.join(qualitySeparator);
  }

  /// Tonnes as typed, Devanagari digits too.
  double? get _quantity {
    const devanagari = '०१२३४५६७८९';
    final ascii = _tonnes.text.trim().split('').map((ch) {
      final i = devanagari.indexOf(ch);
      return i < 0 ? ch : '$i';
    }).join();
    return double.tryParse(ascii);
  }

  Future<void> _pickWindow(StageWindow? start) async {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 31)),
      lastDate: DateTime(today.year + 2, today.month, today.day),
      initialDateRange: start == null
          ? null
          : DateTimeRange(start: start.from, end: start.to),
    );
    if (range != null && mounted) {
      setState(() => _custom = StageWindow(range.start, range.end));
    }
  }

  /// Saves the draft and its photo changes; false when something required is missing.
  Future<bool> _save(Plot? plot, StageWindow? window) async {
    setState(() => _tried = true);
    final quantity = _quantity;
    if (!_form.currentState!.validate() ||
        plot == null ||
        window == null ||
        _basis == null ||
        quantity == null) {
      return false;
    }
    final repo = ref.read(marketLotRepositoryProvider);
    final quality = _composeQuality();
    final rate = parseRupeesToPaise(_rate.text);
    await repo.save(
      MarketLot(
        id: _id,
        plotId: plot.id,
        baharCycleId: _cycle,
        crop: plot.crop,
        variety: plot.variety,
        quantityT: quantity,
        quality: quality.isEmpty ? null : quality,
        harvestFrom: window.from,
        harvestTo: window.to,
        basis: _basis!,
        askingRatePaise: rate == null || rate == 0 ? null : rate,
      ),
    );
    return true;
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(Routes.marketLots);

  Future<void> _saveDraft(Plot? plot, StageWindow? window) async {
    if (_busy) return;
    _busy = true;
    try {
      if (!await _save(plot, window)) return;
      _say((t) => t.plotSaved);
      if (mounted) _back();
    } finally {
      _busy = false;
    }
  }

  Future<void> _delete() async {
    await ref.read(marketLotRepositoryProvider).delete(_id);
    if (mounted) _back();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plots = ref.watch(plotsProvider).value;
    if (_loading || plots == null) {
      return Scaffold(body: LoadingState(label: t.loadingLabel));
    }
    if (plots.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: AppBarTitle(t.mlLotFormTitle)),
        body: EmptyState(
          glyph: BmGlyph.orange,
          message: t.mlNoPlot,
          action: FilledButton(
            onPressed: () => context.push(Routes.addPlot),
            child: Text(t.addPlot),
          ),
        ),
      );
    }
    if (_plot == null && plots.length == 1) _plot = plots.single.id;
    final plot = _plotOf(plots);
    final crops = ref.watch(cropsProvider).value ?? const [];
    final cropName = plot == null
        ? null
        : crops.where((x) => x.slug == plot.crop).firstOrNull?.label(lang) ??
              plot.crop;
    final options = ref.watch(fieldWorkOptionsProvider).value;
    final sizes = options?.sizeClasses ?? const <LabeledOption>[];
    // Graded produce for sale: fallen / rejected fruit is not a sale grade.
    final grades = [
      for (final g in options?.grades ?? const <LabeledOption>[])
        if (g.slug != 'rejected') g,
    ];
    final baharWindow = _baharWindow(plot?.crop);
    final window = _custom ?? baharWindow;
    final draft = _status == 'draft';
    final label = BmType.formLabel.copyWith(color: c.ink);
    final error = BmType.meta.copyWith(color: c.danger);
    const gap = SizedBox(height: BmSpace.md);

    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.md, bottom: BmSpace.xs),
      child: Text(text, style: label),
    );
    Widget missing(bool show) => show && _tried
        ? Padding(
            padding: const EdgeInsets.only(top: BmSpace.xxs),
            child: Text(t.mlChooseOne, style: error),
          )
        : const SizedBox.shrink();

    final banner = buildSyncStatusBanner(context, ref);
    final children = <Widget>[
      ?banner,
      const LotDisclaimerNote(),
      title(t.mlPlot),
      Wrap(
        spacing: BmSpace.xs,
        runSpacing: BmSpace.xs,
        children: [
          for (final p in plots)
            ChoiceChip(
              key: Key('lot-plot-${p.id}'),
              label: Text(p.name),
              selected: _plot == p.id,
              onSelected: draft
                  ? (_) => setState(() {
                      _plot = p.id;
                      _cycle = null;
                    })
                  : null,
            ),
        ],
      ),
      missing(plot == null),
      if (cropName != null)
        Padding(
          padding: const EdgeInsets.only(top: BmSpace.xs),
          child: Text(
            [cropName, ?plot?.variety].join(' · '),
            key: const Key('lot-crop'),
            style: BmType.bodyStrong.copyWith(color: c.brand),
          ),
        ),
      // The bahar choice shows only when the orchard has bahars recorded.
      if (plot != null &&
          (ref.watch(baharCyclesProvider(plot.id)).value?.isNotEmpty ??
              false)) ...[
        title(t.mlBahar),
        CycleChips(
          plotId: plot.id,
          selected: _cycle,
          onChanged: (id) {
            if (draft) setState(() => _cycle = id);
          },
        ),
      ],
      gap,
      TextFormField(
        key: const Key('lot-tonnes'),
        controller: _tonnes,
        enabled: draft,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.०-९]')),
        ],
        decoration: InputDecoration(labelText: t.mlQuantity),
        validator: (_) => (_quantity ?? 0) > 0 ? null : t.invalidNumber,
      ),
      title(t.mlQuality),
      for (final (key, label, options, value, set) in [
        ('size', t.mlSize, sizes, _size, (String? v) => _size = v),
        ('grade', t.mlGrade, grades, _grade, (String? v) => _grade = v),
      ]) ...[
        Text(label, style: BmType.meta),
        const SizedBox(height: BmSpace.xxs),
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            for (final o in options)
              ChoiceChip(
                key: Key('lot-$key-${o.slug}'),
                label: Text(o.label(lang)),
                selected: value == o.slug,
                onSelected: draft
                    ? (on) => setState(() => set(on ? o.slug : null))
                    : null,
              ),
          ],
        ),
        const SizedBox(height: BmSpace.xs),
      ],
      TextFormField(
        key: const Key('lot-quality'),
        controller: _quality,
        enabled: draft,
        maxLength: 200,
        decoration: InputDecoration(
          labelText: t.mlQualityLine,
          counterText: '',
          helperText: draft ? t.mlNoContacts : null,
          helperMaxLines: 3,
          suffixIcon: draft
              ? VoiceMicButton(
                  onResult: (text, {required isFinal}) => _quality.text = text,
                )
              : null,
        ),
        validator: (v) => hasContactDetails(v ?? '') ? t.mlNoContacts : null,
      ),
      title(t.mlHarvestWindow),
      Wrap(
        spacing: BmSpace.xs,
        runSpacing: BmSpace.xs,
        children: [
          if (baharWindow != null)
            ChoiceChip(
              key: const Key('lot-window-bahar'),
              label: Text(
                t.mlWindowFromBahar(
                  formatDate(baharWindow.from, lang),
                  formatDate(baharWindow.to, lang),
                ),
              ),
              selected: _custom == null,
              onSelected: draft ? (_) => setState(() => _custom = null) : null,
            ),
          ChoiceChip(
            key: const Key('lot-window-pick'),
            avatar: const Icon(Icons.date_range_rounded),
            label: Text(
              _custom == null
                  ? t.mlWindowPick
                  : windowLabel(t, _custom!.from, _custom!.to, lang),
            ),
            selected: _custom != null,
            onSelected: draft ? (_) => _pickWindow(window) : null,
          ),
        ],
      ),
      missing(window == null),
      title(t.mlBasis),
      Wrap(
        spacing: BmSpace.xs,
        runSpacing: BmSpace.xs,
        children: [
          for (final b in lotBases)
            ChoiceChip(
              key: Key('lot-basis-$b'),
              label: Text(basisLabel(t, b)),
              selected: _basis == b,
              onSelected: draft ? (_) => setState(() => _basis = b) : null,
            ),
        ],
      ),
      missing(_basis == null),
      gap,
      TextFormField(
        key: const Key('lot-rate'),
        controller: _rate,
        enabled: draft,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: t.mlAskingRate),
        validator: (v) =>
            (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
            ? null
            : t.invalidNumber,
        onChanged: (_) => setState(() {}),
      ),
      if (plot != null)
        LotMandiNote(
          crop: plot.crop,
          basis: _basis,
          ratePaise: parseRupeesToPaise(_rate.text) ?? 0,
        ),
      gap,
      InfoNote(t.mlPrivacy),
      if (draft && widget.lotId != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const Key('lot-delete'),
            onPressed: _busy ? null : _delete,
            child: Text(t.mlDeleteDraft, style: TextStyle(color: c.danger)),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(t.mlLotFormTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: BmSpace.md),
            child: Center(
              child: LotStatusChip(_status, awaitingCheck: _awaitingCheck),
            ),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BmSpace.lg,
            BmSpace.xs,
            BmSpace.lg,
            BmSpace.xxl,
          ),
          children: children,
        ),
      ),
      bottomNavigationBar: _status == 'draft'
          ? BottomActions(
              children: [
                FilledButton(
                  key: const Key('lot-save'),
                  onPressed: _busy ? null : () => _saveDraft(plot, window),
                  child: Text(t.mlSaveDraft),
                ),
              ],
            )
          : null,
    );
  }
}
