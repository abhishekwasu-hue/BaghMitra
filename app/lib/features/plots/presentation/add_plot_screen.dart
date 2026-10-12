import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/plot.dart';

/// Adds an orchard block. Saves locally at once; sync happens in the background.
class AddPlotScreen extends ConsumerStatefulWidget {
  const AddPlotScreen({super.key});

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

  @override
  void dispose() {
    for (final c in [_name, _variety, _acres, _trees, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(plotRepositoryProvider);
    await repo.save(
      Plot(
        id: repo.newId(),
        name: _name.text.trim(),
        crop: _crop!,
        areaSqM: double.parse(_acres.text.trim()) * Plot.sqMPerAcre,
        variety: _optional(_variety.text),
        treeCount: int.tryParse(_trees.text.trim()),
        plantingYear: int.tryParse(_year.text.trim()),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final crops = ref.watch(cropsProvider).value ?? const [];
    _crop ??= crops.isEmpty ? null : crops.first.slug;

    String? required(String? v) =>
        _optional(v) == null ? t.fieldRequired : null;
    String? positive(String? v) =>
        (double.tryParse(v?.trim() ?? '') ?? 0) <= 0 ? t.invalidNumber : null;

    String? optionalInt(String? v) =>
        _optional(v) == null || int.tryParse(v!.trim()) != null
        ? null
        : t.invalidNumber;

    const gap = SizedBox(height: BmSpace.md);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        title: Text(t.addPlot, style: BmType.section.copyWith(color: c.brand)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('plot-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.plotName,
                hintText: t.plotNameHint,
              ),
              validator: required,
            ),
            gap,
            Text(
              t.plotCrop,
              style: BmType.label.copyWith(color: c.inkMuted, fontSize: 14),
            ),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final crop in crops)
                  ChoiceChip(
                    label: Text(crop.label(lang), style: BmType.bodyStrong),
                    selected: _crop == crop.slug,
                    selectedColor: c.nowTint,
                    side: BorderSide(
                      color: _crop == crop.slug ? c.accent : c.line,
                    ),
                    onSelected: (_) => setState(() => _crop = crop.slug),
                  ),
              ],
            ),
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
            gap,
            TextFormField(
              key: const Key('plot-variety'),
              controller: _variety,
              decoration: InputDecoration(labelText: t.plotVariety),
            ),
            gap,
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: t.plotPlantingYear),
              validator: optionalInt,
            ),
            const SizedBox(height: BmSpace.xl),
            FilledButton(
              onPressed: _crop == null ? null : _save,
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}
