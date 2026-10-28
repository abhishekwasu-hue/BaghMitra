import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../voice/presentation/voice_mic_button.dart';
import '../domain/claim_kit.dart';
import '../domain/insurance_policy.dart';

String insuranceSchemeLabel(AppLocalizations t, String scheme) =>
    switch (scheme) {
      'pmfby' => t.insuranceSchemePmfby,
      'rwbcis' => t.insuranceSchemeRwbcis,
      'other' => t.insuranceSchemeOther,
      _ => t.insuranceSchemeUnknown,
    };

String insuranceSeasonLabel(AppLocalizations t, String season) =>
    season == 'mrig' ? t.insuranceSeasonMrig : t.insuranceSeasonAmbia;

/// "RWBCIS · Ambia bahar 2027 · Insurer · No. 123": what the grower entered, nothing more.
String policySummary(AppLocalizations t, InsurancePolicy p, String lang) => [
  insuranceSchemeLabel(t, p.scheme),
  [
    insuranceSeasonLabel(t, p.season),
    if (p.seasonYear != null) formatYear(p.seasonYear!, lang),
  ].join(' '),
  if (p.insurerName != null) p.insurerName!,
  if (p.policyNumber != null) t.insurancePolicyNo(p.policyNumber!),
].join(' · ');

/// Deadlines from published official notices that fit this plot's policies (or any
/// bahar when no policy is recorded). Empty when nothing matches: no date is ever guessed.
List<InsuranceDeadline> deadlinesFor(
  List<InsuranceDeadline> all,
  List<InsurancePolicy> policies,
  DateTime today,
) {
  final seasons = {for (final p in policies) p.season};
  return [
    for (final d in all)
      if (seasons.isEmpty
          ? d.appliesTo(null, today)
          : seasons.any((s) => d.appliesTo(s, today)))
        d,
  ];
}

/// One plot's crop insurance: enrolment deadlines from the govt feed (only when a published
/// notice matches), the policies the grower recorded, and the loss records (claim kits).
class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({required this.plotId, super.key});
  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.watch(clockProvider)();
    final policies =
        ref.watch(insurancePoliciesProvider(plotId)).value ?? const [];
    final kits = [
      for (final k in ref.watch(claimKitsProvider).value ?? const <ClaimKit>[])
        if (k.plotId == plotId) k,
    ];
    final deadlines = deadlinesFor(
      ref.watch(insuranceDeadlinesProvider(lang)).value ?? const [],
      policies,
      today,
    );
    final empty = policies.isEmpty && kits.isEmpty && deadlines.isEmpty;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.lg, bottom: BmSpace.xs),
      child: Text(title, style: BmType.section.copyWith(color: c.brand)),
    );
    Widget tile({
      required Key key,
      required String title,
      required List<String> lines,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(BmRadius.card),
        onTap: onTap,
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
                    Text(title, style: BmType.bodyStrong),
                    for (final l in lines) ...[
                      const SizedBox(height: BmSpace.xs),
                      Text(l, style: BmType.body.copyWith(color: c.inkMuted)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.insuranceTitle)),
      body: empty
          ? EmptyState(glyph: BmGlyph.ledger, message: t.insuranceEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                for (final d in deadlines)
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.sm),
                    child: BmCard(
                      key: Key('deadline-${d.itemId}'),
                      elevated: false,
                      radius: BmRadius.card,
                      padding: const EdgeInsets.all(BmSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.insuranceDeadline(formatDate(d.dueDate, lang)),
                            style: BmType.bodyStrong.copyWith(
                              color: c.accentInk,
                            ),
                          ),
                          const SizedBox(height: BmSpace.xs),
                          Text(d.title, style: BmType.body),
                          const SizedBox(height: BmSpace.xs),
                          Text(
                            t.insuranceDeadlineNote,
                            style: BmType.meta.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                section(t.insuranceTitle),
                if (policies.isEmpty) EmptyNote(t.insurancePoliciesNone),
                for (final p in policies)
                  tile(
                    key: Key('policy-${p.id}'),
                    title: policySummary(t, p, lang),
                    lines: [
                      if (p.enrolledOn != null)
                        t.insuranceEnrolled(formatDate(p.enrolledOn!, lang)),
                      if (p.premiumPaidPaise != null)
                        t.insurancePremiumLine(
                          formatPaise(p.premiumPaidPaise!, lang),
                        ),
                      if (p.sumInsuredPaise != null)
                        t.insuranceSumLine(
                          formatPaise(p.sumInsuredPaise!, lang),
                        ),
                      if (p.note != null) p.note!,
                    ],
                    onTap: () => context.push(Routes.editPolicy(plotId, p.id)),
                  ),
                if (kits.isNotEmpty) section(t.insuranceClaims),
                for (final k in kits)
                  tile(
                    key: Key('claim-${k.id}'),
                    title: t.insuranceClaimLine(
                      formatDate(k.lossOn, lang),
                      formatInt(k.photos.length, lang),
                    ),
                    lines: [if (k.note != null) k.note!],
                    onTap: () => context.push(Routes.openClaimKit(k.id)),
                  ),
              ],
            ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton(
            key: const Key('open-claim-kit'),
            onPressed: () => context.push(Routes.newClaimKit(plotId)),
            child: Text(t.claimKitTitle),
          ),
          FilledButton(
            key: const Key('add-policy'),
            onPressed: () => context.push(Routes.addPolicy(plotId)),
            child: Text(t.insuranceAdd),
          ),
        ],
      ),
    );
  }
}

/// Adds or edits one policy record. Scheme and bahar are required; everything else is
/// optional and stays empty unless the grower types it (no default premium or cover).
class PolicyFormScreen extends ConsumerStatefulWidget {
  const PolicyFormScreen({required this.plotId, this.policyId, super.key});
  final String plotId;
  final String? policyId;

  @override
  ConsumerState<PolicyFormScreen> createState() => _PolicyFormScreenState();
}

class _PolicyFormScreenState extends ConsumerState<PolicyFormScreen> {
  final _form = GlobalKey<FormState>();
  final _year = TextEditingController();
  final _insurer = TextEditingController();
  final _number = TextEditingController();
  final _sum = TextEditingController();
  final _premium = TextEditingController();
  final _note = TextEditingController();
  String? _scheme;
  String? _season;
  DateTime? _enrolled;
  bool _tried = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.policyId;
    if (id != null) {
      ref.read(insuranceRepositoryProvider).find(id).then((p) {
        if (p == null || !mounted) return;
        setState(() {
          _scheme = p.scheme;
          _season = p.season;
          _enrolled = p.enrolledOn;
          _year.text = p.seasonYear?.toString() ?? '';
          _insurer.text = p.insurerName ?? '';
          _number.text = p.policyNumber ?? '';
          _sum.text = p.sumInsuredPaise == null
              ? ''
              : plainRupees(p.sumInsuredPaise!);
          _premium.text = p.premiumPaidPaise == null
              ? ''
              : plainRupees(p.premiumPaidPaise!);
          _note.text = p.note ?? '';
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_year, _insurer, _number, _sum, _premium, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    final valid = _form.currentState?.validate() ?? false;
    if (!valid || _scheme == null || _season == null || _saving) return;
    _saving = true;
    final repo = ref.read(insuranceRepositoryProvider);
    final year = _text(_year);
    final sum = _text(_sum);
    final premium = _text(_premium);
    await repo.save(
      InsurancePolicy(
        id: widget.policyId ?? repo.newId(),
        plotId: widget.plotId,
        scheme: _scheme!,
        season: _season!,
        seasonYear: year == null ? null : int.parse(year),
        insurerName: _text(_insurer),
        policyNumber: _text(_number),
        sumInsuredPaise: sum == null ? null : parseRupeesToPaise(sum),
        premiumPaidPaise: premium == null ? null : parseRupeesToPaise(premium),
        enrolledOn: _enrolled,
        note: _text(_note),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).plotSaved)),
    );
    context.canPop()
        ? context.pop()
        : context.go(Routes.insurance(widget.plotId));
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(t.insuranceDeletePolicy),
        content: Text(t.insuranceDeleteConfirm),
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
    await ref.read(insuranceRepositoryProvider).delete(widget.policyId!);
    if (!mounted) return;
    context.canPop()
        ? context.pop()
        : context.go(Routes.insurance(widget.plotId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.read(clockProvider)();
    final label = BmType.formLabel.copyWith(color: c.ink);
    const gap = SizedBox(height: BmSpace.md);
    const money = TextInputType.numberWithOptions(decimal: true);
    String? amount(String? v) =>
        (v ?? '').trim().isEmpty || parseRupeesToPaise(v!) != null
        ? null
        : t.invalidNumber;
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
                key: Key('choice-$s'),
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
      appBar: AppBar(
        title: Text(widget.policyId == null ? t.insuranceAdd : t.insuranceEdit),
        actions: [
          if (widget.policyId != null)
            IconButton(
              key: const Key('delete-policy'),
              tooltip: t.insuranceDeletePolicy,
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
            choice(
              t.insuranceScheme,
              insuranceSchemes,
              (s) => insuranceSchemeLabel(t, s),
              _scheme,
              (v) => _scheme = v,
            ),
            choice(
              t.insuranceSeason,
              insuranceSeasons,
              (s) => insuranceSeasonLabel(t, s),
              _season,
              (v) => _season = v,
            ),
            gap,
            TextFormField(
              key: const Key('policy-year'),
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.insuranceSeasonYear,
              ),
              validator: (v) {
                final y = int.tryParse((v ?? '').trim());
                return (v ?? '').trim().isEmpty ||
                        (y != null && y >= 2000 && y <= 2100)
                    ? null
                    : t.invalidNumber;
              },
            ),
            gap,
            TextFormField(
              key: const Key('policy-insurer'),
              controller: _insurer,
              maxLength: 120,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.insuranceInsurer,
              ),
            ),
            gap,
            TextFormField(
              key: const Key('policy-number'),
              controller: _number,
              maxLength: 60,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.insurancePolicyNumber,
              ),
            ),
            ListTile(
              key: const Key('policy-enrolled'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.insuranceEnrolledOn, style: BmType.body),
              trailing: Text(
                _enrolled == null
                    ? t.insuranceNotSet
                    : formatDate(_enrolled!, lang),
                style: BmType.bodyStrong.copyWith(color: c.brandStrong),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _enrolled ?? today,
                  firstDate: DateTime(today.year - 3),
                  lastDate: DateTime(today.year + 1, 12, 31),
                );
                if (picked != null) setState(() => _enrolled = picked);
              },
            ),
            Text(
              t.insuranceAmountsHint,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
            gap,
            TextFormField(
              key: const Key('policy-premium'),
              controller: _premium,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.insurancePremium),
              validator: amount,
            ),
            gap,
            TextFormField(
              key: const Key('policy-sum'),
              controller: _sum,
              keyboardType: money,
              decoration: InputDecoration(labelText: t.insuranceSumInsured),
              validator: amount,
            ),
            gap,
            TextField(
              key: const Key('policy-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                counterText: '',
                labelText: t.insuranceNote,
                suffixIcon: VoiceMicButton(
                  onResult: (text, {required isFinal}) => _note.text = text,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [FilledButton(onPressed: _save, child: Text(t.save))],
      ),
    );
  }
}
