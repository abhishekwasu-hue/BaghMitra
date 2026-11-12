// "बिलावरून भरा" (OPEN_QUESTIONS Q136): the server reads the agri-input shop's bill
// (`POST /v1/bills/read`) and the farmer picks a line to fill the spray or expense form.
// Online only: nothing is queued. A field the farmer already typed is never overwritten.

/// One line of the bill as the server read it.
class BillItem {
  const BillItem({
    required this.name,
    this.activeIngredient,
    this.quantity,
    this.unit,
    this.amountRs,
  });

  final String name;
  final String? activeIngredient;
  final double? quantity;
  final String? unit;
  final double? amountRs;

  static BillItem fromJson(Map<String, dynamic> j) => BillItem(
    name: (j['name'] as String? ?? '').trim(),
    activeIngredient: _text(j['active_ingredient']),
    quantity: (j['quantity'] as num?)?.toDouble(),
    unit: _text(j['unit']),
    amountRs: (j['amount_rs'] as num?)?.toDouble(),
  );

  /// "500 ml": the quantity and its unit, for the dose field; null without a quantity.
  String? get quantityText {
    final q = quantity;
    if (q == null) return null;
    return [_number(q), ?unit].join(' ');
  }
}

/// The server's answer for one bill photo.
class BillReading {
  const BillReading({
    required this.items,
    required this.unsure,
    this.shopName,
    this.billDate,
    this.billNo,
    this.totalRs,
  });

  final String? shopName;
  final DateTime? billDate;
  final String? billNo;
  final List<BillItem> items;
  final double? totalRs;

  /// The server could not read the bill well: the farmer fills the form by hand.
  final bool unsure;

  static BillReading fromJson(Map<String, dynamic> j) {
    final date = _text(j['bill_date']);
    return BillReading(
      shopName: _text(j['shop_name']),
      billDate: date == null ? null : DateTime.tryParse(date),
      billNo: _text(j['bill_no']),
      items: [
        for (final i in (j['items'] as List<dynamic>? ?? const []))
          BillItem.fromJson(i as Map<String, dynamic>),
      ].where((i) => i.name.isNotEmpty).toList(),
      totalRs: (j['total_rs'] as num?)?.toDouble(),
      unsure: j['unsure'] as bool? ?? false,
    );
  }
}

String? _text(Object? v) {
  final s = v is String ? v.trim() : null;
  return s == null || s.isEmpty ? null : s;
}

/// A rupee amount or a quantity as the farmer would type it: no trailing ".0".
String _number(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

/// Rupees for a form's amount field ("1250" or "1250.5").
String rupeesFieldText(double rs) => _number(rs);

/// Form fields "बिलावरून भरा" can fill.
enum BillField { product, active, dose, cost, amount, date, note }

/// What to write into the form: only fields that are still empty (or the date still at
/// today's default) are in it.
typedef BillFill = Map<BillField, String>;

/// The spray form ("फवारणी नोंदवा") from one picked bill line. [current] holds what the form
/// has now (trimmed text; empty = not typed). [dateIsDefault]: the date is still today's.
/// The date is filled only from a bill date inside [firstDate]..[lastDate] (the picker's).
({BillFill fill, DateTime? date}) sprayFill({
  required BillItem item,
  required BillReading bill,
  required Map<BillField, String> current,
  required bool dateIsDefault,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final fill = <BillField, String>{};
  void put(BillField f, String? v) {
    if (v != null && v.isNotEmpty && (current[f] ?? '').isEmpty) fill[f] = v;
  }

  put(BillField.product, item.name);
  put(BillField.active, item.activeIngredient);
  put(BillField.dose, item.quantityText);
  put(BillField.cost, item.amountRs == null ? null : _number(item.amountRs!));
  final date = _date(bill, dateIsDefault, firstDate, lastDate);
  return (fill: fill, date: date);
}

/// Product fields of the spray form a bill line can fill.
const sprayProductFields = [
  BillField.product,
  BillField.active,
  BillField.dose,
  BillField.cost,
];

/// The spray form's product blocks (a tank mix, Q142) from several picked bill lines: each
/// line fills one block, in order, with [sprayFill]'s rule (only empty fields). A block
/// whose product fields are all typed already can take nothing, so the line goes to the
/// next one; lines left over get new blocks. [blocks] holds each block's current product
/// fields. [fills] is index-aligned with the blocks (longer than [blocks] when new ones are
/// needed; an untouched block has an empty fill).
({List<BillFill> fills, DateTime? date}) sprayFillMany({
  required List<BillItem> items,
  required BillReading bill,
  required List<Map<BillField, String>> blocks,
  required bool dateIsDefault,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  bool full(Map<BillField, String> b) =>
      sprayProductFields.every((f) => (b[f] ?? '').isNotEmpty);
  final fills = [for (final _ in blocks) <BillField, String>{}];
  var next = 0;
  DateTime? date;
  for (final item in items) {
    while (next < blocks.length && full(blocks[next])) {
      next++;
    }
    final current = next < blocks.length
        ? blocks[next]
        : const <BillField, String>{};
    final r = sprayFill(
      item: item,
      bill: bill,
      current: current,
      dateIsDefault: dateIsDefault,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (next < fills.length) {
      fills[next] = r.fill;
    } else {
      fills.add(r.fill);
    }
    date ??= r.date;
    next++;
  }
  return (fills: fills, date: date);
}

/// The expense form ("खर्च जोडा") from the bill: the amount of the picked line, or the bill
/// total when [item] is null; the date; and a note `item · bill label` where
/// [billLabel] is the localised `shop बिल #no` (null when the bill has neither).
({BillFill fill, DateTime? date}) expenseFill({
  required BillItem? item,
  required BillReading bill,
  required String? billLabel,
  required Map<BillField, String> current,
  required bool dateIsDefault,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final fill = <BillField, String>{};
  void put(BillField f, String? v) {
    if (v != null && v.isNotEmpty && (current[f] ?? '').isEmpty) fill[f] = v;
  }

  final rs = item == null ? bill.totalRs : item.amountRs;
  put(BillField.amount, rs == null || rs <= 0 ? null : _number(rs));
  final note = [?item?.name, ?billLabel].join(' · ');
  put(BillField.note, note.length > 500 ? note.substring(0, 500) : note);
  final date = _date(bill, dateIsDefault, firstDate, lastDate);
  return (fill: fill, date: date);
}

DateTime? _date(
  BillReading bill,
  bool dateIsDefault,
  DateTime firstDate,
  DateTime lastDate,
) {
  final d = bill.billDate;
  if (!dateIsDefault || d == null) return null;
  final day = DateTime(d.year, d.month, d.day);
  return day.isBefore(firstDate) || day.isAfter(lastDate) ? null : day;
}
