import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'package_admin_repository.dart';
import 'package_strings.dart';

/// A picked QR image: bytes and content type; null when cancelled.
typedef PickQr = Future<(Uint8List, String)?> Function();

Future<(Uint8List, String)?> _pickQr() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg'],
  );
  if (file == null) return null;
  final png = file.extension?.toLowerCase() == 'png';
  return (await file.readAsBytes(), png ? 'image/png' : 'image/jpeg');
}

String packageDate(DateTime d) =>
    d.toLocal().toIso8601String().substring(0, 10);

/// Whole rupees typed by the admin -> paise (null when empty or not a number).
int? rupeesToPaise(String text) {
  final v = int.tryParse(text.trim());
  return v == null || v <= 0 ? null : v * 100;
}

String _rupees(int? paise) => paise == null ? '' : '${paise ~/ 100}';

void packageSay(BuildContext context, String text) =>
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

const _companyFields = [
  'legal_name',
  'trade_name',
  'address',
  'gstin',
  'pan',
  'bank_account_name',
  'bank_ifsc',
  'bank_account_last4',
  'upi_id',
  'invoice_prefix',
  'gst_rate',
];

/// The admin web's "Sale package" section (§4E).
class PackageSection extends StatelessWidget {
  const PackageSection({required this.repo, super.key});
  final PackageAdminRepository repo;

  @override
  Widget build(BuildContext context) => PackageSettingsPage(repo: repo);
}

/// Company profile and package settings (§4E). The switch cannot turn ON while legal
/// name, GSTIN, UPI ID or price is empty; the page names the missing fields.
class PackageSettingsPage extends StatefulWidget {
  const PackageSettingsPage({required this.repo, this.pickQr, super.key});
  final PackageAdminRepository repo;
  final PickQr? pickQr;

  @override
  State<PackageSettingsPage> createState() => _PackageSettingsPageState();
}

class _PackageSettingsPageState extends State<PackageSettingsPage> {
  final _text = {for (final f in _companyFields) f: TextEditingController()};
  final _price = TextEditingController();
  final _days = TextEditingController();
  PackageCompanyOut? _company;
  PackageSettingsOut? _settings;
  bool _enabled = false;
  DateTime? _start;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._text.values, _price, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (company, settings) = await (
        widget.repo.company(),
        widget.repo.settings(),
      ).wait;
      if (!mounted) return;
      final json = company.toJson();
      setState(() {
        _company = company;
        _showSettings(settings);
        for (final f in _companyFields) {
          final key = f == 'gst_rate' ? 'gst_rate_percent' : f;
          _text[f]!.text = '${json[key] ?? ''}';
        }
      });
    } on KbAdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _showSettings(PackageSettingsOut s) {
    _settings = s;
    _enabled = s.enabled;
    _start = s.startsAt;
    _price.text = _rupees(s.pricePaise);
    _days.text = s.validityDays == null ? '' : '${s.validityDays}';
  }

  String _v(String f) => _text[f]!.text.trim();

  Future<void> _run(Future<void> Function() call) async {
    final s = PackageStrings.of(context);
    try {
      await call();
      if (mounted) packageSay(context, s['saved']);
    } on KbAdminException catch (e) {
      if (mounted) packageSay(context, packageErrorText(s, e.message));
    }
  }

  Future<void> _saveCompany() => _run(() async {
    final saved = await widget.repo.saveCompany(
      PackageCompanyIn(
        legalName: _v('legal_name'),
        tradeName: _v('trade_name'),
        address: _v('address'),
        gstin: _v('gstin').toUpperCase(),
        pan: _v('pan').toUpperCase(),
        bankAccountName: _v('bank_account_name'),
        bankIfsc: _v('bank_ifsc').toUpperCase(),
        bankAccountLast4: _v('bank_account_last4'),
        upiId: _v('upi_id'),
        invoicePrefix: _v('invoice_prefix').toUpperCase(),
        gstRatePercent: _v('gst_rate'),
      ),
    );
    final settings = await widget.repo.settings();
    setState(() {
      _company = saved;
      _settings = settings;
    });
  });

  Future<void> _saveSettings() => _run(() async {
    final saved = await widget.repo.saveSettings(
      PackageSettingsIn(
        enabled: _enabled,
        pricePaise: rupeesToPaise(_price.text),
        validityDays: int.tryParse(_days.text.trim()),
        startsAt: _start,
      ),
    );
    setState(() => _showSettings(saved));
  });

  Future<void> _uploadQr() async {
    final picked = await (widget.pickQr ?? _pickQr)();
    if (picked == null) return;
    await _run(() async {
      final saved = await widget.repo.uploadQr(picked.$1, picked.$2);
      setState(() => _company = saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = PackageStrings.of(context);
    final c = context.bm;
    if (_error case final e?) return Text(e, style: BmType.body);
    final settings = _settings;
    if (settings == null || _company == null) {
      return LoadingState(label: s['settings']);
    }
    Widget field(String f, {int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: BmSpace.xs),
      child: TextField(
        key: Key('pkg-$f'),
        controller: _text[f],
        maxLines: lines,
        decoration: InputDecoration(labelText: s[f]),
      ),
    );
    final missing = settings.missing.map((f) => s[f]).join(', ');
    return ListView(
      padding: const EdgeInsets.only(top: BmSpace.xs),
      children: [
        if (settings.missing.isNotEmpty) ...[
          Container(
            key: const Key('pkg-missing'),
            padding: const EdgeInsets.all(BmSpace.md),
            decoration: BoxDecoration(
              border: Border.all(color: c.warnBorder),
              borderRadius: BorderRadius.circular(BmRadius.tile),
            ),
            child: Text(
              s.fill('missing', missing),
              style: BmType.bodyStrong.copyWith(color: c.warnTitle),
            ),
          ),
          const SizedBox(height: BmSpace.md),
        ],
        BmCard(
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: s['settings']),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  key: const Key('pkg-switch'),
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  title: Text(s['switch'], style: BmType.bodyStrong),
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ),
              Wrap(
                spacing: BmSpace.md,
                children: [
                  for (final (key, ctrl) in [
                    ('price_paise', _price),
                    ('validity_days', _days),
                  ])
                    SizedBox(
                      width: 200,
                      child: TextField(
                        key: Key('pkg-$key'),
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(labelText: s[key]),
                      ),
                    ),
                  TextButton.icon(
                    key: const Key('pkg-start'),
                    icon: const Icon(Icons.event_rounded),
                    label: Text(
                      '${s['starts_at']}: '
                      '${_start == null ? '—' : packageDate(_start!)}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                ],
              ),
              const SizedBox(height: BmSpace.sm),
              FilledButton(
                key: const Key('pkg-save-settings'),
                onPressed: _saveSettings,
                child: Text(s['save']),
              ),
            ],
          ),
        ),
        const SizedBox(height: BmSpace.md),
        BmCard(
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: s['company']),
              const SizedBox(height: BmSpace.sm),
              for (final f in _companyFields)
                field(f, lines: f == 'address' ? 2 : 1),
              Row(
                children: [
                  Icon(
                    _company!.merchantQr
                        ? Icons.check_circle_rounded
                        : Icons.qr_code_2_rounded,
                    color: _company!.merchantQr ? c.brandStrong : c.inkMuted,
                  ),
                  const SizedBox(width: BmSpace.xs),
                  Text(
                    '${s['merchant_qr']}: '
                    '${_company!.merchantQr ? s['qr_set'] : s['qr_none']}',
                    style: BmType.body,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 220,
                    child: OutlinedButton(
                      key: const Key('pkg-upload-qr'),
                      onPressed: _uploadQr,
                      child: Text(s['upload_qr']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BmSpace.sm),
              FilledButton(
                key: const Key('pkg-save-company'),
                onPressed: _saveCompany,
                child: Text(s['save']),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `missing: legal_name, gstin` from the API -> the field names in the admin's language.
String packageErrorText(PackageStrings s, String message) {
  const prefix = 'missing: ';
  if (!message.startsWith(prefix)) return s[message];
  final names = message.substring(prefix.length).split(', ').map((f) => s[f]);
  return s.fill('missing', names.join(', '));
}
