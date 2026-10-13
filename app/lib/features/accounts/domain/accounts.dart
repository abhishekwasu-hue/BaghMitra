import '../../bahar/domain/bahar_cycle.dart';

/// Money is whole paise everywhere (exact sums; formatted as rupees only for display).
class Expense {
  const Expense({
    required this.id,
    required this.plotId,
    required this.spentOn,
    required this.category,
    required this.amountPaise,
    this.baharCycleId,
    this.note,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime spentOn;

  /// Slug from `assets/config/expense_categories.json`.
  final String category;
  final int amountPaise;
  final String? note;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'spent_on': BaharCycle.isoDate(spentOn),
    'category': category,
    'amount_paise': amountPaise,
    'note': note,
  };

  static Expense fromPayload(String id, Map<String, Object?> p) => Expense(
    id: id,
    plotId: p['plot_id']! as String,
    baharCycleId: p['bahar_cycle_id'] as String?,
    spentOn: DateTime.parse(p['spent_on']! as String),
    category: p['category']! as String,
    amountPaise: p['amount_paise']! as int,
    note: p['note'] as String?,
  );
}

class Income {
  const Income({
    required this.id,
    required this.plotId,
    required this.soldOn,
    required this.buyerName,
    required this.quantityKg,
    required this.ratePaisePerQuintal,
    required this.paymentStatus,
    this.baharCycleId,
    this.grade,
    this.deductionsPaise = 0,
    this.paidPaise = 0,
    this.paidOn,
  });

  static const kgPerQuintal = 100;

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime soldOn;
  final String buyerName;
  final String? grade;
  final double quantityKg;
  final int ratePaisePerQuintal;
  final int deductionsPaise;

  /// pending | partial | paid
  final String paymentStatus;
  final int paidPaise;
  final DateTime? paidOn;

  int get grossPaise =>
      (quantityKg * ratePaisePerQuintal / kgPerQuintal).round();
  int get netPaise => grossPaise - deductionsPaise;

  /// What the buyer still owes; never negative, zero once marked paid.
  int get duesPaise =>
      paymentStatus == 'paid' ? 0 : (netPaise - paidPaise).clamp(0, netPaise);

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'sold_on': BaharCycle.isoDate(soldOn),
    'buyer_name': buyerName,
    'grade': grade,
    'quantity_kg': quantityKg,
    'rate_paise_per_quintal': ratePaisePerQuintal,
    'deductions_paise': deductionsPaise,
    'payment_status': paymentStatus,
    'paid_paise': paidPaise,
    'paid_on': paidOn == null ? null : BaharCycle.isoDate(paidOn!),
  };

  static Income fromPayload(String id, Map<String, Object?> p) => Income(
    id: id,
    plotId: p['plot_id']! as String,
    baharCycleId: p['bahar_cycle_id'] as String?,
    soldOn: DateTime.parse(p['sold_on']! as String),
    buyerName: p['buyer_name']! as String,
    grade: p['grade'] as String?,
    quantityKg: (p['quantity_kg']! as num).toDouble(),
    ratePaisePerQuintal: p['rate_paise_per_quintal']! as int,
    deductionsPaise: p['deductions_paise']! as int,
    paymentStatus: p['payment_status']! as String,
    paidPaise: p['paid_paise']! as int,
    paidOn: switch (p['paid_on']) {
      final String d => DateTime.parse(d),
      _ => null,
    },
  );
}
