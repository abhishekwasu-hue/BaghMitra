import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../data/crop_catalog.dart';
import '../data/place_geocoder.dart';
import '../domain/geo.dart';
import '../domain/plot.dart';
import 'crop_picker.dart';
import 'plot_point.dart';

/// Adds an orchard block, or edits one when [plotId] is given. The grower stands in the block
/// and takes its location first; walking the boundary is optional. Saves locally at once; sync
/// happens in the background.
class AddPlotScreen extends ConsumerStatefulWidget {
  const AddPlotScreen({this.plotId, super.key});

  final String? plotId;

  @override
  ConsumerState<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends ConsumerState<AddPlotScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _variety = TextEditingController();
  final _acres = TextEditingController();
  final _trees = TextEditingController();
  final _year = TextEditingController();
  String? _crop;
  List<LatLon>? _boundary;

  /// The block's location: the fix taken in the block, the walked centre, or the saved one.
  /// The latest of the first two wins.
  LatLon? _centre;
  Plot? _editing;
  bool _filled = false;

  /// The nearby place of [_placeFor], looked up after each new fix or walk. Shown only,
  /// never saved or synced (Q53, Q59).
  LatLon? _placeFor;
  PlaceLine? _place;

  @override
  void dispose() {
    for (final c in [_name, _variety, _acres, _trees, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Fills the form once from the block being edited.
  void _fill(Plot p) {
    _filled = true;
    _editing = p;
    _name.text = p.name;
    _crop = p.crop;
    _variety.text = p.variety ?? '';
    _acres.text = sqMToAcres(p.areaSqM).toStringAsFixed(2);
    _trees.text = p.treeCount?.toString() ?? '';
    _year.text = p.plantingYear?.toString() ?? '';
    _boundary = cornersFromGeoJson(p.boundary);
    _centre = p.centroidLat != null && p.centroidLon != null
        ? LatLon(p.centroidLat!, p.centroidLon!)
        : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(plotRepositoryProvider);
    final id = _editing?.id ?? repo.newId();
    await repo.save(
      Plot(
        id: id,
        // What the form does not show (water, soil, irrigation) is kept as it was.
        irrigationType: _editing?.irrigationType,
        waterSource: _editing?.waterSource,
        soilType: _editing?.soilType,
        rowSpacingM: _editing?.rowSpacingM,
        plantSpacingM: _editing?.plantSpacingM,
        name: _name.text.trim(),
        crop: _crop!,
        areaSqM: _boundary != null
            ? polygonAreaSqM(_boundary!)
            : double.parse(_acres.text.trim()) * Plot.sqMPerAcre,
        variety: _optional(_variety.text),
        treeCount: int.tryParse(_trees.text.trim()),
        plantingYear: int.tryParse(_year.text.trim()),
        centroidLat: _centre?.lat,
        centroidLon: _centre?.lon,
        boundary: _boundary == null ? null : toGeoJsonPolygon(_boundary!),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    // The block's id goes back to the page that opened the form, so an action started
    // with no block yet can open for it (see openForPlot). Opened directly (e.g. from a
    // notification) there is nothing to pop.
    context.canPop() ? context.pop(id) : context.go(Routes.plots);
  }

  /// Deleting a block, from its edit screen: asks first, then returns to the block list
  /// (the block's own screens are gone with it).
  Future<void> _confirmDelete() async {
    final t = AppLocalizations.of(context);
    final plot = _editing;
    if (plot == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deletePlot),
        content: Text(t.deletePlotConfirm(plot.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            style: BmButtonStyle.destructive(context.bm),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await ref.read(plotRepositoryProvider).delete(plot.id);
    if (mounted) context.go(Routes.plots);
  }

  /// Asks the phone's geocoder for the place at [point]; a later point wins. Any failure
  /// ends as "not found" and never stops the form.
  Future<void> _lookUpPlace(LatLon point) async {
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _placeFor = point;
      _place = const PlaceLooking();
    });
    PlaceAddress? address;
    try {
      address = await ref
          .read(placeGeocoderProvider)
          .addressOf(point, languageCode: lang);
    } on Object {
      address = null;
    }
    if (!mounted || _placeFor != point) return;
    setState(
      () =>
          _place = address == null ? const PlaceMissing() : PlaceFound(address),
    );
  }

  Future<void> _walkBoundary() async {
    final corners = await context.push<List<LatLon>>(Routes.walkBoundary);
    if (corners == null || !mounted) return;
    setState(() {
      _boundary = corners;
      _centre = centroidOf(corners);
      // The walked area fills the field; the grower can still see and correct it.
      _acres.text = sqMToAcres(polygonAreaSqM(corners)).toStringAsFixed(2);
    });
    await _lookUpPlace(_centre!);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final catalog = ref.watch(cropCatalogDataProvider).value;
    final crops = catalog?.crops ?? const <CropOption>[];
    if (widget.plotId != null && !_filled) {
      final plots = ref.watch(plotsProvider).value;
      final existing = plots?.where((p) => p.id == widget.plotId).firstOrNull;
      if (existing == null) {
        // L5: while the block loads, the page keeps its title and a loading sign; a block
        // that is gone (deleted, or another phone's) returns to the list.
        if (plots != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.canPop() ? context.pop() : context.go(Routes.plots);
          });
        }
        return Scaffold(
          appBar: AppBar(title: AppBarTitle(t.editPlot)),
          body: LoadingState(label: t.loadingLabel),
        );
      }
      _fill(existing);
    }
    _crop ??= crops.isEmpty ? null : crops.first.slug;
    // Vegetables, flowers and other: the grower types the crop's name, kept as the variety.
    final nameTyped =
        crops.where((o) => o.slug == _crop).firstOrNull?.nameTyped ?? false;

    String? required(String? v) =>
        _optional(v) == null ? t.requiredPlotName : null;
    String? positive(String? v) =>
        (double.tryParse(v?.trim() ?? '') ?? 0) <= 0 ? t.invalidNumber : null;

    String? optionalInt(String? v) =>
        _optional(v) == null || int.tryParse(v!.trim()) != null
        ? null
        : t.invalidNumber;

    const gap = SizedBox(height: BmSpace.md);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(widget.plotId == null ? t.addPlot : t.editPlot),
        actions: [
          if (widget.plotId != null)
            IconButton(
              key: const Key('delete-plot'),
              tooltip: t.deletePlot,
              onPressed: _confirmDelete,
              icon: Icon(Icons.delete_outline_rounded, color: c.inkMuted),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            PointCaptureCard(
              point: _centre,
              place: _centre != null && _centre == _placeFor ? _place : null,
              onCaptured: (fix) {
                setState(() => _centre = fix.position);
                _lookUpPlace(fix.position!);
              },
            ),
            gap,
            TextFormField(
              key: const Key('plot-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.plotName,
                hintText: t.plotNameHint,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _name.text = text,
                ),
              ),
              validator: required,
            ),
            gap,
            Text(t.plotCrop, style: BmType.formLabel.copyWith(color: c.ink)),
            const SizedBox(height: BmSpace.xs),
            if (catalog != null)
              CropPicker(
                catalog: catalog,
                selected: _crop,
                onSelected: (slug) => setState(() {
                  final typed = crops
                      .where((o) => o.slug == slug)
                      .firstOrNull
                      ?.nameTyped;
                  // A variety and a typed crop name are not the same thing.
                  if (typed != nameTyped) _variety.clear();
                  _crop = slug;
                }),
              ),
            if (nameTyped) ...[
              gap,
              TextFormField(
                key: const Key('plot-crop-name'),
                controller: _variety,
                // The server keeps a variety of up to 60 characters.
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: t.plotCropName,
                  hintText: t.plotCropNameHint,
                  suffixIcon: VoiceMicButton(
                    onResult: (text, {required isFinal}) =>
                        _variety.text = text,
                  ),
                ),
                validator: (v) =>
                    _optional(v) == null ? t.requiredCropName : null,
              ),
            ],
            gap,
            TextFormField(
              key: const Key('plot-acres'),
              controller: _acres,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(labelText: t.plotAreaAcres),
              validator: positive,
              // Typing a new area replaces the walked one: the two would disagree. The
              // location stays: it is still where the block is.
              onChanged: (_) => setState(() => _boundary = null),
            ),
            const SizedBox(height: BmSpace.xs),
            OutlinedButton.icon(
              key: const Key('walk-boundary'),
              onPressed: _walkBoundary,
              icon: const Icon(Icons.timeline_rounded),
              label: Text(t.boundaryWalkOptional),
            ),
            if (_boundary != null)
              Padding(
                padding: const EdgeInsets.only(top: BmSpace.xs),
                child: Text(
                  t.boundaryMarked(_boundary!.length),
                  style: BmType.label.copyWith(color: c.brand),
                ),
              ),
            gap,
            TextFormField(
              key: const Key('plot-trees'),
              controller: _trees,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.plotTreeCount),
              validator: optionalInt,
            ),
            if (!nameTyped) ...[
              gap,
              TextFormField(
                key: const Key('plot-variety'),
                controller: _variety,
                decoration: InputDecoration(labelText: t.plotVariety),
              ),
            ],
            gap,
            TextFormField(
              key: const Key('plot-year'),
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: t.plotPlantingYear),
              validator: optionalInt,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: _crop == null ? null : _save,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}
