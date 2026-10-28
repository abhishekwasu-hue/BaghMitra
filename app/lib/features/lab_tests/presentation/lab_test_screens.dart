import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../scouting/data/scouting_photos.dart';
import '../../tasks/domain/farm_task.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../data/lab_parameters.dart';
import '../domain/lab_test.dart';

String labTestTypeLabel(AppLocalizations t, String type) => switch (type) {
  'water' => t.labTestTypeWater,
  'leaf' => t.labTestTypeLeaf,
  _ => t.labTestTypeSoil,
};

String labTestTitle(AppLocalizations t, String type) => switch (type) {
  'water' => t.labTestTitleWater,
  'leaf' => t.labTestTitleLeaf,
  _ => t.labTestTitleSoil,
};

String labTestReminderTitle(AppLocalizations t, String type) => switch (type) {
  'water' => t.labTestReminderWater,
  'leaf' => t.labTestReminderLeaf,
  _ => t.labTestReminderSoil,
};

/// The record as text for the share sheet and read-aloud: what was typed, the "ask an
/// expert" line, and where it came from. Never a rating of a value.
String labTestShareText(
  AppLocalizations t,
  LabTest test,
  String lang,
  String productName,
) => [
  '${labTestTitle(t, test.testType)} · '
      '${t.labTestSampledLine(formatDate(test.sampledOn, lang))}',
  if (test.reportedOn != null)
    t.labTestReportedLine(formatDate(test.reportedOn!, lang)),
  if (test.labName != null) t.labTestLabLine(test.labName!),
  for (final r in test.readings) '${r.parameter}: ${r.valueWithUnit}',
  if (test.note != null) test.note!,
  t.labTestAskExpert,
  shareFooter(t, productName),
].join('\n');

/// The open "next test due" task of [test], if the grower set one.
Future<FarmTask?> _openReminder(WidgetRef ref, String testId) async {
  final task = await ref
      .read(tasksRepositoryProvider)
      .findBySource(labTestReminderSource(testId));
  return task == null || task.isDone ? null : task;
}

/// The "ask an expert" line every lab test screen shows: the app never reads the values.
class _AskExpertNote extends StatelessWidget {
  const _AskExpertNote();

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return BmCard(
      key: const Key('lab-ask-expert'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent_rounded, color: c.brand),
          const SizedBox(width: BmSpace.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context).labTestAskExpert,
              style: BmType.bodyStrong.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A kept report picture, or a file icon with its name (a PDF the app does not open).
class _ReportPreview extends StatelessWidget {
  const _ReportPreview(this.path, {required this.isImage});

  final String path;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final icon = SizedBox.square(
      dimension: 72,
      child: Icon(
        isImage ? Icons.photo_outlined : Icons.description_outlined,
        color: c.inkMuted,
        size: 36,
      ),
    );
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(BmRadius.chip),
          child: isImage
              ? Image.file(
                  File(path),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  cacheWidth: 216,
                  errorBuilder: (_, _, _) => icon,
                )
              : icon,
        ),
        const SizedBox(width: BmSpace.sm),
        Expanded(
          child: Text(
            p.basename(path),
            style: BmType.meta.copyWith(color: c.inkMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// One plot's soil, water and leaf tests, newest sample first.
class LabTestsScreen extends ConsumerWidget {
  const LabTestsScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final tests = ref.watch(labTestsProvider(plotId));
    return Scaffold(
      appBar: AppBar(title: Text(t.labTestsTitle)),
      body: switch (tests) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          glyph: BmGlyph.drop,
          message: t.labTestsEmpty,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(
            BmSpace.lg,
            BmSpace.sm,
            BmSpace.lg,
            BmSpace.xxl,
          ),
          children: [
            for (final test in value)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.sm),
                child: InkWell(
                  key: Key('lab-test-${test.id}'),
                  borderRadius: BorderRadius.circular(BmRadius.card),
                  onTap: () => context.push(Routes.labTest(plotId, test.id)),
                  child: BmCard(
                    elevated: false,
                    radius: BmRadius.card,
                    padding: const EdgeInsets.all(BmSpace.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labTestTitle(t, test.testType),
                                style: BmType.bodyStrong,
                              ),
                              const SizedBox(height: BmSpace.xxs),
                              Text(
                                [
                                  t.labTestSampledLine(
                                    formatDate(test.sampledOn, lang),
                                  ),
                                  t.labTestValuesCount(test.readings.length),
                                ].join(' · '),
                                style: BmType.body.copyWith(color: c.inkMuted),
                              ),
                              if (test.labName != null)
                                Text(
                                  test.labName!,
                                  style: BmType.meta.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (test.reportPath != null)
                          Padding(
                            padding: const EdgeInsets.only(left: BmSpace.xs),
                            child: Icon(
                              Icons.attach_file_rounded,
                              color: c.inkMuted,
                            ),
                          ),
                        Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        _ => LoadingState(label: t.loadingLabel),
      },
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('add-lab-test'),
            onPressed: () => context.push(Routes.addLabTest(plotId)),
            child: Text(t.labTestAdd),
          ),
        ],
      ),
    );
  }
}

/// One test as the grower recorded it: dates, lab, the typed values, the report, and the
/// "ask an expert" line. No value is rated, coloured or explained.
class LabTestDetailScreen extends ConsumerWidget {
  const LabTestDetailScreen({
    required this.plotId,
    required this.testId,
    super.key,
  });

  final String plotId;
  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final tests = ref.watch(labTestsProvider(plotId));
    if (!tests.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(t.labTestsTitle)),
        body: LoadingState(label: t.loadingLabel),
      );
    }
    LabTest? test;
    for (final x in tests.value!) {
      if (x.id == testId) test = x;
    }
    if (test == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.labTestsTitle)),
        body: EmptyState(glyph: BmGlyph.drop, message: t.labTestsEmpty),
      );
    }
    final record = test;
    final shareText = labTestShareText(
      t,
      record,
      lang,
      ref.watch(appConfigProvider).productName,
    );
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: BmType.body.copyWith(color: c.inkMuted)),
          ),
          const SizedBox(width: BmSpace.sm),
          Flexible(child: Text(value, style: BmType.bodyStrong)),
        ],
      ),
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.lg, bottom: BmSpace.xs),
      child: Text(title, style: BmType.section.copyWith(color: c.brand)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(labTestTitle(t, record.testType)),
        actions: [
          ShareSpeakButtons(shareText: shareText, keyPrefix: 'lab-test'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.sm,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          const _AskExpertNote(),
          const SizedBox(height: BmSpace.sm),
          row(t.labTestSampledOn, formatDate(record.sampledOn, lang)),
          if (record.reportedOn != null)
            row(t.labTestReportedOn, formatDate(record.reportedOn!, lang)),
          if (record.labName != null) row(t.labTestLab, record.labName!),
          section(t.labTestReadings),
          if (record.readings.isEmpty) EmptyNote(t.labTestNoValues),
          for (final (i, r) in record.readings.indexed)
            Container(
              key: Key('lab-reading-$i'),
              padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(r.parameter, style: BmType.body)),
                  const SizedBox(width: BmSpace.sm),
                  Text(r.valueWithUnit, style: BmType.bodyStrong),
                ],
              ),
            ),
          if (record.note != null) ...[
            section(t.labTestNote),
            Text(record.note!, style: BmType.body),
          ],
          if (record.reportPath != null) ...[
            section(t.labTestReport),
            _ReportPreview(record.reportPath!, isImage: record.reportIsImage),
            const SizedBox(height: BmSpace.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('lab-share-report'),
                onPressed: () => _shareReport(context, ref, record),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(t.labTestShareReport),
              ),
            ),
            Text(
              t.labTestReportLocal,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton.icon(
            key: const Key('edit-lab-test'),
            onPressed: () =>
                context.push(Routes.editLabTest(plotId, record.id)),
            icon: const Icon(Icons.edit_outlined),
            label: Text(t.labTestEditAction),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReport(
    BuildContext context,
    WidgetRef ref,
    LabTest test,
  ) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final path = test.reportPath!;
    // The same "read a kept file, null when gone" reader the claim kit uses.
    final bytes = await ref.read(claimPhotoBytesProvider)(path);
    if (bytes == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.labTestReportMissing)));
      return;
    }
    final ext = p.extension(path).toLowerCase();
    await ref
        .read(fileSharerProvider)
        .share(
          fileName: p.basename(path),
          bytes: bytes,
          mimeType: switch (ext) {
            '.pdf' => 'application/pdf',
            '.png' => 'image/png',
            _ => 'image/jpeg',
          },
        );
  }
}

/// Controllers of one typed value row.
class _ReadingFields {
  _ReadingFields({String parameter = '', String value = '', String? unit})
    : parameter = TextEditingController(text: parameter),
      value = TextEditingController(text: value),
      unit = TextEditingController(text: unit ?? '');

  final TextEditingController parameter;
  final TextEditingController value;
  final TextEditingController unit;

  bool get isBlank =>
      parameter.text.trim().isEmpty &&
      value.text.trim().isEmpty &&
      unit.text.trim().isEmpty;

  bool get isComplete =>
      parameter.text.trim().isNotEmpty && value.text.trim().isNotEmpty;

  LabReading toReading() {
    final u = unit.text.trim();
    return LabReading(
      parameter: parameter.text.trim(),
      value: value.text.trim(),
      unit: u.isEmpty ? null : u,
    );
  }

  void dispose() {
    parameter.dispose();
    value.dispose();
    unit.dispose();
  }
}

/// Adds or edits one test. Type and sample date are required; the rest stays empty unless
/// the grower types it. Values are kept as typed text. A "next test due" task is made only
/// when the grower picks that date.
class LabTestFormScreen extends ConsumerStatefulWidget {
  const LabTestFormScreen({required this.plotId, this.testId, super.key});
  final String plotId;
  final String? testId;

  @override
  ConsumerState<LabTestFormScreen> createState() => _LabTestFormScreenState();
}

class _LabTestFormScreenState extends ConsumerState<LabTestFormScreen> {
  static const maxReadings = 40;

  final _form = GlobalKey<FormState>();
  final _lab = TextEditingController();
  final _note = TextEditingController();
  final _readings = <_ReadingFields>[];
  String? _type;
  late DateTime _sampled;
  DateTime? _reported;
  DateTime? _nextDue;

  /// The kept report of the saved record (edit), and a newly picked one (temporary path).
  String? _keptReport;
  String? _pickedReport;
  bool _reportRemoved = false;
  bool _tried = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _sampled = DateTime(now.year, now.month, now.day);
    final id = widget.testId;
    if (id != null) _load(id);
  }

  Future<void> _load(String id) async {
    final test = await ref.read(labTestRepositoryProvider).find(id);
    final reminder = await _openReminder(ref, id);
    if (test == null || !mounted) return;
    setState(() {
      _type = test.testType;
      _sampled = test.sampledOn;
      _reported = test.reportedOn;
      _lab.text = test.labName ?? '';
      _note.text = test.note ?? '';
      _keptReport = test.reportPath;
      _nextDue = reminder?.dueOn;
      _readings
        ..clear()
        ..addAll([
          for (final r in test.readings)
            _ReadingFields(
              parameter: r.parameter,
              value: r.value,
              unit: r.unit,
            ),
        ]);
    });
  }

  @override
  void dispose() {
    _lab.dispose();
    _note.dispose();
    for (final r in _readings) {
      r.dispose();
    }
    super.dispose();
  }

  String? get _shownReport =>
      _pickedReport ?? (_reportRemoved ? null : _keptReport);

  void _addReading({String parameter = '', String? unit}) {
    if (_readings.length >= maxReadings) return;
    setState(
      () => _readings.add(_ReadingFields(parameter: parameter, unit: unit)),
    );
  }

  Future<void> _pickReport(Future<String?> Function() pick) async {
    try {
      final path = await pick();
      if (path != null && mounted) setState(() => _pickedReport = path);
    } on Object catch (e) {
      ref.read(appLogProvider).log('lab report: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).labTestReportFailed),
        ),
      );
    }
  }

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    final valid = _form.currentState?.validate() ?? false;
    if (!valid || _type == null || _saving) return;
    _saving = true;
    final t = AppLocalizations.of(context);
    final repo = ref.read(labTestRepositoryProvider);
    final id = widget.testId ?? repo.newId();
    String? report = _reportRemoved ? null : _keptReport;
    try {
      if (_pickedReport != null) {
        report = await ref
            .read(labReportFilesProvider)
            .keep(_pickedReport!, id);
      }
    } on Object catch (e) {
      // The report could not be kept (storage full?): nothing is saved; the grower can
      // retry or remove the report and save the values alone.
      _saving = false;
      ref.read(appLogProvider).log('lab report keep: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.labTestReportFailed)));
      return;
    }
    final test = LabTest(
      id: id,
      plotId: widget.plotId,
      testType: _type!,
      sampledOn: _sampled,
      labName: _text(_lab),
      reportedOn: _reported,
      readings: [
        for (final r in _readings)
          if (!r.isBlank) r.toReading(),
      ],
      note: _text(_note),
      reportPath: report,
    );
    await repo.save(test);
    await _saveReminder(t, test);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.plotSaved)));
    context.canPop()
        ? context.pop()
        : context.go(Routes.labTests(widget.plotId));
  }

  /// Only a date the grower picked makes (or moves) the reminder; clearing it removes the
  /// open reminder of this test.
  Future<void> _saveReminder(AppLocalizations t, LabTest test) async {
    final tasks = ref.read(tasksRepositoryProvider);
    final existing = await _openReminder(ref, test.id);
    final due = _nextDue;
    if (due == null) {
      if (existing != null) await tasks.delete(existing.id);
      return;
    }
    await tasks.save(
      FarmTask(
        id: existing?.id ?? tasks.newId(),
        title: labTestReminderTitle(t, test.testType),
        kind: 'other',
        dueOn: due,
        plotId: test.plotId,
        source: labTestReminderSource(test.id),
        note: test.labName,
      ),
    );
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(t.labTestDelete),
        content: Text(t.labTestDeleteConfirm),
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
    final id = widget.testId!;
    final reminder = await _openReminder(ref, id);
    if (reminder != null) {
      await ref.read(tasksRepositoryProvider).delete(reminder.id);
    }
    await ref.read(labTestRepositoryProvider).delete(id);
    if (!mounted) return;
    context.go(Routes.labTests(widget.plotId));
  }

  Future<DateTime?> _pickDate(
    DateTime? initial,
    DateTime first,
    DateTime last,
  ) => showDatePicker(
    context: context,
    initialDate: initial ?? (ref.read(clockProvider)()),
    firstDate: first,
    lastDate: last,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.read(clockProvider)();
    final label = BmType.formLabel.copyWith(color: c.ink);
    const gap = SizedBox(height: BmSpace.md);
    final suggestions =
        ref.watch(labParametersProvider).value?[_type] ??
        const <LabParameter>[];
    final typed = {
      for (final r in _readings) r.parameter.text.trim().toLowerCase(),
    };
    Widget dateTile(
      Key key,
      String title,
      DateTime? value,
      VoidCallback onTap, {
      Key? clearKey,
      VoidCallback? onClear,
    }) => ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: BmType.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value == null ? t.insuranceNotSet : formatDate(value, lang),
            style: BmType.bodyStrong.copyWith(color: c.brandStrong),
          ),
          if (onClear != null && value != null)
            IconButton(
              key: clearKey,
              tooltip: t.labTestNextDueClear,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            ),
        ],
      ),
      onTap: onTap,
    );
    final report = _shownReport;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testId == null ? t.labTestAdd : t.labTestEdit),
        actions: [
          if (widget.testId != null)
            IconButton(
              key: const Key('delete-lab-test'),
              tooltip: t.labTestDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            Text(t.labTestType, style: label),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final type in labTestTypes)
                  ChoiceChip(
                    key: Key('lab-type-$type'),
                    label: Text(
                      labTestTypeLabel(t, type),
                      style: BmType.bodyStrong,
                    ),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            if (_tried && _type == null)
              Padding(
                padding: const EdgeInsets.only(top: BmSpace.xs),
                child: Text(
                  t.scoutingPickOne,
                  style: BmType.label.copyWith(color: c.danger),
                ),
              ),
            const SizedBox(height: BmSpace.sm),
            dateTile(
              const Key('lab-sampled'),
              t.labTestSampledOn,
              _sampled,
              () async {
                final d = await _pickDate(
                  _sampled,
                  DateTime(today.year - 10),
                  today,
                );
                if (d != null) setState(() => _sampled = d);
              },
            ),
            dateTile(
              const Key('lab-reported'),
              t.labTestReportedOn,
              _reported,
              () async {
                final d = await _pickDate(
                  _reported,
                  DateTime(today.year - 10),
                  today,
                );
                if (d != null) setState(() => _reported = d);
              },
            ),
            gap,
            TextFormField(
              key: const Key('lab-name'),
              controller: _lab,
              maxLength: 120,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.labTestLab,
              ),
            ),
            const SizedBox(height: BmSpace.lg),
            Text(t.labTestReadings, style: label),
            const SizedBox(height: BmSpace.xxs),
            Text(
              t.labTestReadingsHint,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
            for (final (i, r) in _readings.indexed)
              _ReadingRow(
                key: ObjectKey(r),
                index: i,
                fields: r,
                onRemove: () => setState(() {
                  _readings.remove(r);
                  r.dispose();
                }),
                onChanged: () => setState(() {}),
              ),
            const SizedBox(height: BmSpace.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('lab-add-reading'),
                onPressed: _readings.length >= maxReadings ? null : _addReading,
                icon: const Icon(Icons.add_rounded),
                label: Text(t.labTestAddReading),
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: BmSpace.xs),
              Text(
                t.labTestSuggestions,
                style: BmType.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: BmSpace.xs),
              Wrap(
                spacing: BmSpace.xs,
                runSpacing: BmSpace.xs,
                children: [
                  for (final s in suggestions)
                    if (!typed.contains(s.label(lang).toLowerCase()))
                      ActionChip(
                        key: Key('lab-suggest-${s.key}'),
                        label: Text(s.label(lang), style: BmType.body),
                        onPressed: () =>
                            _addReading(parameter: s.label(lang), unit: s.unit),
                      ),
                ],
              ),
            ],
            const SizedBox(height: BmSpace.lg),
            Text(t.labTestReport, style: label),
            const SizedBox(height: BmSpace.xs),
            if (report != null)
              Row(
                children: [
                  Expanded(
                    child: _ReportPreview(report, isImage: isImagePath(report)),
                  ),
                  TextButton.icon(
                    key: const Key('lab-remove-report'),
                    onPressed: () => setState(() {
                      _pickedReport = null;
                      _reportRemoved = true;
                    }),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(t.labTestReportRemove),
                  ),
                ],
              )
            else
              Wrap(
                spacing: BmSpace.sm,
                runSpacing: BmSpace.xs,
                children: [
                  OutlinedButton.icon(
                    key: const Key('lab-report-camera'),
                    onPressed: () => _pickReport(
                      () => ref
                          .read(labReportFilesProvider)
                          .pick(PhotoSource.camera),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(t.scoutingCamera),
                  ),
                  OutlinedButton.icon(
                    key: const Key('lab-report-gallery'),
                    onPressed: () => _pickReport(
                      () => ref
                          .read(labReportFilesProvider)
                          .pick(PhotoSource.gallery),
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(t.scoutingGallery),
                  ),
                  OutlinedButton.icon(
                    key: const Key('lab-report-file'),
                    onPressed: () =>
                        _pickReport(ref.read(reportFilePickerProvider).pick),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(t.labTestReportFile),
                  ),
                ],
              ),
            const SizedBox(height: BmSpace.xxs),
            Text(
              t.labTestReportLocal,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
            gap,
            TextField(
              key: const Key('lab-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.labTestNote,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _note.text = text,
                ),
              ),
            ),
            const SizedBox(height: BmSpace.sm),
            dateTile(
              const Key('lab-next-due'),
              t.labTestNextDue,
              _nextDue,
              () async {
                final d = await _pickDate(
                  _nextDue ?? today,
                  DateTime(today.year, today.month, today.day),
                  DateTime(today.year + 5, 12, 31),
                );
                if (d != null) setState(() => _nextDue = d);
              },
              clearKey: const Key('lab-next-due-clear'),
              onClear: () => setState(() => _nextDue = null),
            ),
            Text(
              t.labTestNextDueHint,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: BmSpace.lg),
            const _AskExpertNote(),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('save-lab-test'),
            onPressed: _save,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

/// One typed value: name on its own line, then value, unit and a remove button.
class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    super.key,
    required this.index,
    required this.fields,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _ReadingFields fields;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    String? check(String? _) =>
        fields.isBlank || fields.isComplete ? null : t.labTestReadingIncomplete;
    return Padding(
      padding: const EdgeInsets.only(top: BmSpace.sm),
      child: BmCard(
        elevated: false,
        radius: BmRadius.tile,
        padding: const EdgeInsets.fromLTRB(
          BmSpace.sm,
          BmSpace.xs,
          BmSpace.xxs,
          BmSpace.xs,
        ),
        child: Column(
          children: [
            TextFormField(
              key: Key('lab-param-$index'),
              controller: fields.parameter,
              maxLength: 60,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                counterText: '',
                labelText: t.labTestParameter,
              ),
              validator: check,
            ),
            const SizedBox(height: BmSpace.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: Key('lab-value-$index'),
                    controller: fields.value,
                    maxLength: 30,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: t.labTestValue,
                    ),
                  ),
                ),
                const SizedBox(width: BmSpace.xs),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: Key('lab-unit-$index'),
                    controller: fields.unit,
                    maxLength: 20,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: t.labTestUnit,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('lab-remove-$index'),
                  tooltip: t.labTestRemoveReading,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
