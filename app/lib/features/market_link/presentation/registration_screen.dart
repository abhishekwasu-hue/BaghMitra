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
import '../../market/domain/market_crops.dart';
import '../../plots/data/location_service.dart';
import '../../voice/presentation/voice_mic_button.dart';
import '../data/registration_api.dart';
import '../domain/registration.dart';
import 'profile_widgets.dart';

/// Trader / exporter / broker / provider registration (spec v1.5 §2, §4; L2), on the one
/// existing sign-in. Step 1: the permission explainer and the ONE foreground GPS fix
/// (required, addendum 3). Step 2: the role's fields (numbers first, big choices, optional
/// address). Document photos are added afterwards on "my registration".
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.role});

  final RegistrationRole role;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _firm = TextEditingController();
  final _village = TextEditingController();
  final _taluka = TextEditingController();
  final _district = TextEditingController();
  final _areas = TextEditingController();
  final _address = TextEditingController();
  final _gst = TextEditingController();
  final _apmc = TextEditingController();
  final _fssai = TextEditingController();
  final _iec = TextEditingController();
  final _apeda = TextEditingController();
  final _vehicles = TextEditingController();
  final _capacity = TextEditingController();
  final _crops = <String>{'santra'};
  RegistrationFix? _fix;
  LocationProblem? _fixProblem;
  bool _fixing = false;
  bool _sending = false;
  String? _error;
  ProviderKind? _kind;
  DateTime? _certUntil;
  bool _refrigerated = false;

  RegistrationRole get _role => widget.role;

  @override
  void initState() {
    super.initState();
    // Pre-filled from the sign-in and the grower profile when they load; never overwrites
    // what the person typed.
    void fill(TextEditingController c, String? value) {
      if (c.text.isEmpty && value != null) c.text = value;
    }

    ref
      ..listenManual(
        sessionProvider,
        (_, next) => fill(_phone, next.value?.phone.replaceFirst('+91', '')),
        fireImmediately: true,
      )
      ..listenManual(profileProvider, (_, next) {
        final profile = next.value;
        fill(_name, profile?.displayName);
        fill(_village, profile?.village);
        fill(_taluka, profile?.taluka);
        fill(_district, profile?.district);
      }, fireImmediately: true);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _firm,
      _village,
      _taluka,
      _district,
      _areas,
      _address,
      _gst,
      _apmc,
      _fssai,
      _iec,
      _apeda,
      _vehicles,
      _capacity,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _takeFix() async {
    setState(() {
      _fixing = true;
      _fixProblem = null;
    });
    try {
      final fix = await takeRegistrationFix(
        ref.read(locationServiceProvider),
        ref.read(placeGeocoderProvider),
        languageCode: Localizations.localeOf(context).languageCode,
        now: ref.read(clockProvider),
      );
      if (!mounted) return;
      setState(() {
        _fix = fix;
        // The phone's own geocoder fills the stated district, so a mismatch is real (Q87).
        if (fix.district case final d?) _district.text = d;
        if (_village.text.isEmpty && fix.place != null) {
          _village.text = fix.place!;
        }
      });
    } on FixFailure catch (e) {
      if (mounted) setState(() => _fixProblem = e.problem);
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  String? _clean(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  String? _upper(TextEditingController c) => _clean(c)?.toUpperCase();

  Map<String, Object?> _body() {
    final common = <String, Object?>{
      'name': _clean(_name),
      'phone': normalisePhone(_phone.text),
      'district': _clean(_district),
      'taluka': _clean(_taluka),
      'address': _clean(_address),
      'fix': _fix!.toJson(),
    };
    return switch (_role) {
      RegistrationRole.trader || RegistrationRole.exporter => {
        ...common,
        'firm': _clean(_firm),
        'markets': splitList(_areas.text),
        'crops': _crops.toList(),
        'gst_no': _upper(_gst),
        'apmc_licence_no': _upper(_apmc),
        'fssai_no': _clean(_fssai),
        'iec_no': _upper(_iec),
        'apeda_no': _upper(_apeda),
      },
      RegistrationRole.broker => {
        ...common,
        'village': _clean(_village),
        'service_areas': splitList(_areas.text),
        'crops': _crops.toList(),
      },
      RegistrationRole.provider => {
        ...common,
        'kind': _kind!.api,
        'village': _clean(_village),
        'service_areas': splitList(_areas.text),
        if (_kind == ProviderKind.weighbridge)
          'cert_valid_until': _certUntil?.toIso8601String().substring(0, 10),
        if (_kind == ProviderKind.transporter) ...{
          'vehicle_numbers': [
            for (final v in splitList(_vehicles.text)) v.toUpperCase(),
          ],
          'capacity_t': double.tryParse(_capacity.text.trim()),
          'refrigerated': _refrigerated,
        },
      },
    };
  }

  String? _formError(AppLocalizations t) {
    if (_role == RegistrationRole.provider && _kind == null) {
      return t.mlErrPickKind;
    }
    if (_role == RegistrationRole.trader &&
        _clean(_gst) == null &&
        _clean(_apmc) == null &&
        _clean(_iec) == null) {
      return t.mlErrOneNumber;
    }
    if (_kind == ProviderKind.weighbridge &&
        _role == RegistrationRole.provider &&
        _certUntil == null) {
      return t.mlErrCertDate;
    }
    return null;
  }

  String _refusal(AppLocalizations t, MarketCallException e) =>
      switch (e.code) {
        'registration_fix_stale' => t.mlErrFixStale,
        'profile_exists' => t.mlErrExists,
        'exporter_needs_iec' => t.mlIecRequired,
        'trader_needs_a_number' => t.mlErrOneNumber,
        _ => t.mlErrCheckFields,
      };

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final valid = _form.currentState?.validate() ?? false;
    final error = _formError(t);
    setState(() => _error = error);
    if (!valid || error != null) return;
    setState(() => _sending = true);
    try {
      await ref.read(registrationApiProvider).register(_role, _body());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.mlSubmitted)));
      context.canPop() ? context.pop() : context.go(Routes.home);
    } on MarketCallException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.problem == MarketCallProblem.refused
            ? _refusal(t, e)
            : (e.problem == MarketCallProblem.offline
                  ? t.mlOffline
                  : t.mlServerBusy);
        if (e.code == 'registration_fix_stale') _fix = null;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _title(AppLocalizations t) => switch (_role) {
    RegistrationRole.trader => t.mlRegisterTrader,
    RegistrationRole.exporter => t.mlRegisterExporter,
    RegistrationRole.broker => t.mlRegisterBroker,
    RegistrationRole.provider => t.mlRegisterProvider,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fix = _fix;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(_title(t))),
      body: fix == null ? _fixStep(t) : _formStep(t, fix),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error case final error? when fix != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                BmSpace.xs,
                BmSpace.lg,
                0,
              ),
              child: Text(
                error,
                key: const Key('ml-error'),
                style: BmType.bodyStrong.copyWith(color: context.bm.danger),
              ),
            ),
          BottomActions(
            children: [
              if (fix == null)
                FilledButton.icon(
                  key: const Key('ml-take-fix'),
                  onPressed: _fixing ? null : _takeFix,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(_fixing ? t.mlFixTaking : t.mlFixTake),
                )
              else
                FilledButton(
                  key: const Key('ml-submit'),
                  onPressed: _sending ? null : _submit,
                  child: Text(t.mlSubmit),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fixStep(AppLocalizations t) {
    final c = context.bm;
    final problem = _fixProblem;
    return ListView(
      padding: const EdgeInsets.all(BmSpace.lg),
      children: [
        BmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, size: 40, color: c.brand),
              const SizedBox(height: BmSpace.xs),
              Text(t.mlFixTitle, style: BmType.cardTitle),
              const SizedBox(height: BmSpace.xs),
              Text(t.mlFixWhy, style: BmType.body),
            ],
          ),
        ),
        const SizedBox(height: BmSpace.md),
        InfoNote(t.mlFixOnce),
        const SizedBox(height: BmSpace.xs),
        InfoNote(t.mlPhonePublicNote),
        if (problem != null) ...[
          const SizedBox(height: BmSpace.md),
          Text(
            switch (problem) {
              LocationProblem.serviceOff => t.boundaryServiceOff,
              LocationProblem.denied => t.mlFixDenied,
              LocationProblem.deniedForever => t.boundaryDeniedForever,
              LocationProblem.failed => t.boundaryFailed,
            },
            key: const Key('ml-fix-problem'),
            style: BmType.bodyStrong.copyWith(color: c.danger),
          ),
          if (problem != LocationProblem.failed)
            TextButton(
              onPressed: () =>
                  ref.read(locationServiceProvider).openSettings(problem),
              child: Text(t.plotPointOpenSettings),
            ),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? Function(String)? check,
    bool required = false,
    TextInputType? keyboard,
    bool voice = false,
    bool caps = false,
    String? key,
  }) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: TextFormField(
        key: Key('ml-field-${key ?? label}'),
        controller: c,
        keyboardType: keyboard,
        textCapitalization: caps
            ? TextCapitalization.characters
            : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: voice
              ? VoiceMicButton(
                  onResult: (text, {required isFinal}) => c.text = text,
                )
              : null,
        ),
        validator: (v) {
          final value = (v ?? '').trim();
          if (value.isEmpty) return required ? t.fieldRequired : null;
          return check?.call(value);
        },
      ),
    );
  }

  Widget _formStep(AppLocalizations t, RegistrationFix fix) {
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final buyer =
        _role == RegistrationRole.trader || _role == RegistrationRole.exporter;
    final place = [?fix.place, ?fix.district].join(', ');
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.sm,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          Row(
            key: const Key('ml-fix-taken'),
            children: [
              Icon(Icons.check_circle_rounded, color: c.brand),
              const SizedBox(width: BmSpace.xs),
              Expanded(
                child: Text(
                  t.mlFixTaken(
                    place.isEmpty ? '—' : place,
                    formatInt(fix.accuracyM.round(), lang),
                  ),
                  style: BmType.bodyStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: BmSpace.md),
          if (_role == RegistrationRole.provider) ...[
            Text(t.mlPickKind, style: BmType.formLabel),
            const SizedBox(height: BmSpace.xs),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: BmSpace.xs,
              crossAxisSpacing: BmSpace.xs,
              childAspectRatio: 2.2,
              children: [
                for (final k in ProviderKind.values)
                  ChoiceCard(
                    key: Key('ml-kind-${k.api}'),
                    label: providerKindLabel(t, k),
                    selected: _kind == k,
                    onTap: () => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.md),
          ],
          _field(
            _name,
            t.mlFieldName,
            required: true,
            voice: true,
            key: 'name',
          ),
          _field(
            _phone,
            t.mlFieldPhone,
            required: true,
            keyboard: TextInputType.phone,
            check: (v) => normalisePhone(v) == null ? t.mlErrPhone : null,
            key: 'phone',
          ),
          if (buyer) _field(_firm, t.mlFieldFirm, voice: true, key: 'firm'),
          if (!buyer)
            _field(_village, t.mlFieldVillage, required: true, key: 'village'),
          _field(_taluka, t.mlFieldTaluka, key: 'taluka'),
          _field(_district, t.mlFieldDistrict, required: true, key: 'district'),
          _field(
            _areas,
            buyer ? t.mlFieldMarkets : t.mlFieldAreas,
            required:
                _kind == ProviderKind.labourGang ||
                _kind == ProviderKind.crateSupplier,
            key: 'areas',
          ),
          if (_role != RegistrationRole.provider) ...[
            Text(t.mlFieldCrops, style: BmType.formLabel),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final crop in marketCrops.take(4))
                  FilterChip(
                    key: Key('ml-crop-${crop.key}'),
                    label: Text(marketCropName(crop.key, lang)),
                    selected: _crops.contains(crop.key),
                    onSelected: (on) => setState(
                      () => on ? _crops.add(crop.key) : _crops.remove(crop.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.md),
          ],
          if (buyer) ..._numberFields(t),
          if (_kind == ProviderKind.weighbridge) _certDate(t, lang),
          if (_kind == ProviderKind.transporter) ...[
            _field(
              _vehicles,
              t.mlFieldVehicles,
              required: true,
              keyboard: TextInputType.text,
              caps: true,
              key: 'vehicles',
            ),
            _field(
              _capacity,
              t.mlFieldCapacity,
              required: true,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              check: (v) {
                final n = double.tryParse(v);
                return n == null || n <= 0 || n > 100 ? t.mlErrCapacity : null;
              },
              key: 'capacity',
            ),
            SwitchListTile(
              key: const Key('ml-refrigerated'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.mlFieldRefrigerated, style: BmType.body),
              value: _refrigerated,
              onChanged: (v) => setState(() => _refrigerated = v),
            ),
          ],
          _field(_address, t.mlFieldAddress, voice: true, key: 'address'),
          if (_role == RegistrationRole.broker) InfoNote(t.mlBrokerCallNote),
        ],
      ),
    );
  }

  List<Widget> _numberFields(AppLocalizations t) => [
    InfoNote(
      _role == RegistrationRole.exporter ? t.mlIecRequired : t.mlNumbersNote,
    ),
    const SizedBox(height: BmSpace.sm),
    if (_role == RegistrationRole.exporter)
      _field(
        _iec,
        t.mlFieldIec,
        required: true,
        check: (v) => iecPattern.hasMatch(v.toUpperCase()) ? null : t.mlErrIec,
        caps: true,
        key: 'iec',
      ),
    _field(
      _gst,
      t.mlFieldGst,
      check: (v) => gstinPattern.hasMatch(v.toUpperCase()) ? null : t.mlErrGst,
      caps: true,
      key: 'gst',
    ),
    _field(_apmc, t.mlFieldApmc, caps: true, key: 'apmc'),
    if (_role == RegistrationRole.trader)
      _field(
        _iec,
        t.mlFieldIec,
        check: (v) => iecPattern.hasMatch(v.toUpperCase()) ? null : t.mlErrIec,
        caps: true,
        key: 'iec',
      ),
    _field(
      _fssai,
      t.mlFieldFssai,
      keyboard: TextInputType.number,
      check: (v) => fssaiPattern.hasMatch(v) ? null : t.mlErrFssai,
      key: 'fssai',
    ),
    _field(_apeda, t.mlFieldApeda, caps: true, key: 'apeda'),
  ];

  Widget _certDate(AppLocalizations t, String lang) {
    final until = _certUntil;
    return Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.sm),
      child: OutlinedButton.icon(
        key: const Key('ml-cert-date'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(BottomActions.actionHeight),
        ),
        icon: const Icon(Icons.event_rounded),
        label: Text(
          until == null
              ? t.mlFieldCertUntil
              : t.mlCertUntilValue(formatDate(until, lang)),
        ),
        onPressed: () async {
          final now = ref.read(clockProvider)();
          final picked = await showDatePicker(
            context: context,
            initialDate: until ?? now,
            firstDate: now.subtract(const Duration(days: 365 * 3)),
            lastDate: now.add(const Duration(days: 365 * 5)),
          );
          if (picked != null) setState(() => _certUntil = picked);
        },
      ),
    );
  }
}

/// A big tappable choice (provider kind, role): at least 56 dp, brand outline when picked.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.brandSoft : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BmRadius.tile),
          side: BorderSide(
            color: selected ? c.brand : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(BmRadius.tile),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BottomActions.actionHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(BmSpace.sm),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: c.brandStrong),
                    const SizedBox(width: BmSpace.xs),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: BmType.bodyStrong,
                      textAlign: icon == null
                          ? TextAlign.center
                          : TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
