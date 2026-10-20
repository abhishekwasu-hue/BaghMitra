import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/farm_task.dart';

/// Adds one task for the whole orchard: what, which kind, and when.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  String _kind = 'other';
  int _inDays = 0;
  DateTime? _picked;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime _due(DateTime now) =>
      _picked ?? dateOnly(now).add(Duration(days: _inDays));

  Future<void> _pick(DateTime now) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due(now),
      firstDate: dateOnly(now),
      lastDate: dateOnly(now).add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _picked = picked);
  }

  Future<void> _save(DateTime now) async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(tasksRepositoryProvider);
    await repo.save(
      FarmTask(
        id: repo.newId(),
        title: _title.text.trim(),
        kind: _kind,
        dueOn: _due(now),
        source: 'manual',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.canPop() ? context.pop() : context.go(Routes.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final kinds = ref.watch(taskKindsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(
        title: Text(t.addTask, style: BmType.section.copyWith(color: c.brand)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            TextFormField(
              key: const Key('task-title'),
              controller: _title,
              maxLength: 200,
              decoration: InputDecoration(labelText: t.taskWhat),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.fieldRequired : null,
            ),
            const SizedBox(height: BmSpace.sm),
            Text(t.taskKind, style: BmType.label),
            Wrap(
              spacing: BmSpace.xs,
              children: [
                for (final k in kinds)
                  ChoiceChip(
                    key: Key('kind-${k.slug}'),
                    label: Text(k.label(lang)),
                    selected: _kind == k.slug,
                    selectedColor: c.nowTint,
                    onSelected: (_) => setState(() => _kind = k.slug),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.md),
            Text(t.taskDue, style: BmType.label),
            Wrap(
              spacing: BmSpace.xs,
              children: [
                for (final (days, label) in [
                  (0, t.dueToday),
                  (1, t.dueTomorrow),
                  (3, t.dueInDays(3)),
                  (7, t.dueInDays(7)),
                ])
                  ChoiceChip(
                    key: Key('due-$days'),
                    label: Text(label),
                    selected: _picked == null && _inDays == days,
                    selectedColor: c.nowTint,
                    onSelected: (_) => setState(() {
                      _picked = null;
                      _inDays = days;
                    }),
                  ),
                ActionChip(
                  key: const Key('due-pick'),
                  avatar: const Icon(Icons.event, size: 18),
                  label: Text(t.pickDate),
                  onPressed: () => _pick(now),
                ),
              ],
            ),
            const SizedBox(height: BmSpace.lg),
            FilledButton(onPressed: () => _save(now), child: Text(t.save)),
          ],
        ),
      ),
    );
  }
}
