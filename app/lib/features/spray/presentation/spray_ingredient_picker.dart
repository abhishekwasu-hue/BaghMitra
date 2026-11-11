import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/spray_ingredients.dart';

/// The spray form's active ingredient in two steps (owner Q137): a type, then a compound from
/// our bundled list for that type, so the grower neither types nor searches. "Other", and a
/// type with no official list, show a free-text box instead.
///
/// [controller] holds the value that is saved (the compound's name), so the ban check and
/// sync read it as before. Setting its text from outside (an old record, a bill photo) picks
/// the matching entry, or "Other" with that text when nothing matches.
class SprayIngredientPicker extends ConsumerStatefulWidget {
  const SprayIngredientPicker({required this.controller, super.key});

  final TextEditingController controller;

  /// The type key for "Other": not in the asset, always offered last.
  static const other = 'other';

  @override
  ConsumerState<SprayIngredientPicker> createState() =>
      _SprayIngredientPickerState();
}

class _SprayIngredientPickerState extends ConsumerState<SprayIngredientPicker> {
  final _typing = FocusNode();
  SprayIngredients? _data;
  String? _type;

  /// The last text this widget has matched, so its own writes are not matched again.
  String? _seen;

  TextEditingController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onText);
  }

  @override
  void didUpdateWidget(SprayIngredientPicker old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
      _seen = null;
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onText);
    _typing.dispose();
    super.dispose();
  }

  bool _hasList(String? type) =>
      type != null &&
      type != SprayIngredientPicker.other &&
      (_data?.entries.any((e) => e.type == type) ?? false);

  void _onText() {
    final text = _c.text;
    if (text == _seen) return;
    // The grower typing in the free-text box: keep the box, do not jump to a list entry.
    if (_typing.hasFocus) {
      _seen = text;
      return;
    }
    _match(text);
  }

  /// Picks the type and entry [text] names; writes the entry's own name back when the text
  /// named it another way ("Captan 75% WP" is saved as "Captan").
  void _match(String text) {
    final data = _data;
    if (data == null) return;
    _seen = text;
    final e = data.match(text);
    String? type = _type;
    if (e != null) {
      type = e.type;
    } else if (text.trim().isNotEmpty && _hasList(_type)) {
      type = SprayIngredientPicker.other;
    } else if (text.trim().isNotEmpty && _type == null) {
      type = SprayIngredientPicker.other;
    }
    if (type != _type) setState(() => _type = type);
    if (e != null && e.name != text) {
      _seen = e.name;
      _c.text = e.name;
    }
  }

  void _chooseType(String? type) {
    if (type == null || type == _type) return;
    final current = _data?.match(_c.text);
    final keep = current == null
        ? !_hasList(type) // free text moves between free-text types
        : current.type == type;
    setState(() => _type = type);
    if (!keep) {
      _seen = '';
      _c.clear();
    }
  }

  Future<void> _openList(String lang, String type) async {
    final data = _data!;
    final picked = await showModalBottomSheet<SprayIngredient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _IngredientList(
        title: data.types.firstWhere((t) => t.key == type).label(lang),
        entries: data.ofType(type),
        selected: data.match(_c.text),
      ),
    );
    if (picked == null || !mounted) return;
    _seen = picked.name;
    _c.text = picked.name;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final async = ref.watch(sprayIngredientsProvider);
    final data = async.value;
    if (data == null) {
      // The asset ships with the app; until it is read (or if it cannot be), the plain box.
      return async.hasError ? _freeText(t, help: false) : const SizedBox();
    }
    if (_data == null) {
      _data = data;
      final e = data.match(_c.text);
      _type =
          e?.type ??
          (_c.text.trim().isEmpty ? null : SprayIngredientPicker.other);
      _seen = _c.text;
      if (e != null && e.name != _c.text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _match(_c.text);
        });
      }
    }
    final type = _type;
    final chosen = data.match(_c.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: const Key('spray-active-type'),
          // Keyed by the type so a value set from outside shows in the field.
          child: DropdownButtonFormField<String>(
            key: ValueKey(type),
            initialValue: type,
            isExpanded: true,
            style: BmType.body.copyWith(color: c.ink),
            dropdownColor: c.card,
            decoration: InputDecoration(labelText: t.sprayActiveType),
            items: [
              for (final ty in data.types)
                DropdownMenuItem(
                  value: ty.key,
                  child: Text(ty.label(lang), overflow: TextOverflow.ellipsis),
                ),
              DropdownMenuItem(
                value: SprayIngredientPicker.other,
                child: Text(t.sprayActiveOther),
              ),
            ],
            onChanged: _chooseType,
          ),
        ),
        if (type != null) ...[
          const SizedBox(height: BmSpace.md),
          if (_hasList(type))
            InkWell(
              key: const Key('spray-active-pick'),
              borderRadius: BorderRadius.circular(BmRadius.chip),
              onTap: () => _openList(lang, type),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t.sprayActive,
                  suffixIcon: Icon(Icons.expand_more, color: c.inkMuted),
                ),
                child: Text(
                  chosen?.display ?? t.sprayActivePick,
                  style: BmType.body.copyWith(
                    color: chosen == null ? c.inkMuted : c.ink,
                  ),
                ),
              ),
            )
          else
            _freeText(t, help: type == SprayIngredientPicker.other),
        ],
      ],
    );
  }

  Widget _freeText(AppLocalizations t, {required bool help}) => TextFormField(
    key: const Key('spray-active'),
    controller: _c,
    focusNode: _typing,
    decoration: InputDecoration(
      labelText: t.sprayActive,
      helperText: help ? t.sprayActiveOtherHelp : null,
      helperMaxLines: 2,
    ),
  );
}

/// Step 2: the compounds of one type, with a search box when the list is long.
class _IngredientList extends StatefulWidget {
  const _IngredientList({
    required this.title,
    required this.entries,
    required this.selected,
  });

  final String title;
  final List<SprayIngredient> entries;
  final SprayIngredient? selected;

  /// Longer lists than this get a search box (owner Q137: "about 8").
  static const searchFrom = 9;

  @override
  State<_IngredientList> createState() => _IngredientListState();
}

class _IngredientListState extends State<_IngredientList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final e in widget.entries)
        if (q.isEmpty || e.display.toLowerCase().contains(q)) e,
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xs,
              ),
              child: Text(
                widget.title,
                style: BmType.section.copyWith(color: c.brand),
              ),
            ),
            if (widget.entries.length >= _IngredientList.searchFrom)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BmSpace.lg,
                  0,
                  BmSpace.lg,
                  BmSpace.xs,
                ),
                child: TextField(
                  key: const Key('spray-active-search'),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: t.sprayActiveSearch,
                    prefixIcon: Icon(Icons.search, color: c.inkMuted),
                  ),
                ),
              ),
            Flexible(
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(BmSpace.lg),
                      child: Text(
                        t.sprayActiveNoMatch,
                        style: BmType.body.copyWith(color: c.inkMuted),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: BmSpace.lg),
                      children: [
                        for (final e in shown)
                          ListTile(
                            key: Key('spray-active-option-${e.name}'),
                            minTileHeight: BmSpace.tapTarget,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: BmSpace.lg,
                            ),
                            title: Text(
                              e.display,
                              style: BmType.body.copyWith(color: c.ink),
                            ),
                            trailing: e.name == widget.selected?.name
                                ? Icon(Icons.check, color: c.brand)
                                : null,
                            onTap: () => Navigator.of(context).pop(e),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
