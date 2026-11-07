import 'registration.dart';

/// Market-link interests and the introduction (spec v1.5 §3 steps 3-5, L4): the phone's
/// read of the API's answers. An interest holds rate and basis, quantity and the proposed
/// harvest date only; everything else is settled by the people off the app.

String? _s(Object? v) => v as String?;

String _place(Iterable<String?> parts) => {
  for (final s in parts)
    if (s != null && s.trim().isNotEmpty) s.trim(),
}.join(', ');

/// A published lot as a verified trader or broker sees it: place names, never the grower.
class BuyerLot {
  const BuyerLot({
    required this.id,
    required this.crop,
    required this.quantityT,
    required this.harvestFrom,
    required this.harvestTo,
    required this.basis,
    this.variety,
    this.quality,
    this.askingRatePaise,
    this.village,
    this.taluka,
    this.district,
    this.photoIds = const [],
  });

  factory BuyerLot.fromJson(Map<String, Object?> j) => BuyerLot(
    id: j['id']! as String,
    crop: j['crop']! as String,
    variety: _s(j['variety']),
    quantityT: (j['quantity_t']! as num).toDouble(),
    quality: _s(j['quality']),
    harvestFrom: DateTime.parse(j['harvest_from']! as String),
    harvestTo: DateTime.parse(j['harvest_to']! as String),
    basis: j['basis']! as String,
    askingRatePaise: (j['asking_rate_paise'] as num?)?.toInt(),
    village: _s(j['village']),
    taluka: _s(j['taluka']),
    district: _s(j['district']),
    photoIds: [
      for (final p in (j['photos'] as List?) ?? const [])
        (p as Map)['id']! as String,
    ],
  );

  final String id;
  final String crop;
  final String? variety;
  final double quantityT;
  final String? quality;
  final DateTime harvestFrom;
  final DateTime harvestTo;
  final String basis;
  final int? askingRatePaise;
  final String? village;
  final String? taluka;
  final String? district;
  final List<String> photoIds;

  String get place => _place([village, taluka, district]);
}

/// The lot an interest is about, as its sender saw it.
class LotBrief {
  const LotBrief({
    required this.id,
    required this.crop,
    required this.quantityT,
    required this.basis,
    required this.status,
    this.variety,
    this.village,
    this.taluka,
    this.district,
  });

  factory LotBrief.fromJson(Map<String, Object?> j) => LotBrief(
    id: j['id']! as String,
    crop: j['crop']! as String,
    variety: _s(j['variety']),
    quantityT: (j['quantity_t']! as num).toDouble(),
    basis: j['basis']! as String,
    village: _s(j['village']),
    taluka: _s(j['taluka']),
    district: _s(j['district']),
    status: j['status']! as String,
  );

  final String id;
  final String crop;
  final String? variety;
  final double quantityT;
  final String basis;
  final String? village;
  final String? taluka;
  final String? district;
  final String status;

  String get place => _place([village, taluka, district]);
}

/// open, accepted, closed (another was accepted or the lot was closed) or withdrawn.
enum InterestStatus { open, accepted, closed, withdrawn }

class Interest {
  const Interest({
    required this.id,
    required this.lotId,
    required this.basis,
    required this.ratePaise,
    required this.harvestDate,
    required this.status,
    required this.viaBroker,
    this.quantityT,
    this.dealId,
  });

  factory Interest.fromJson(Map<String, Object?> j) => Interest(
    id: j['id']! as String,
    lotId: j['lot_id']! as String,
    basis: j['basis']! as String,
    ratePaise: (j['rate_paise']! as num).toInt(),
    quantityT: (j['quantity_t'] as num?)?.toDouble(),
    harvestDate: DateTime.parse(j['harvest_date']! as String),
    status: InterestStatus.values.byName(j['status']! as String),
    viaBroker: j['via_broker'] as bool? ?? false,
    dealId: _s(j['deal_id']),
  );

  final String id;
  final String lotId;
  final String basis;
  final int ratePaise;
  final double? quantityT;
  final DateTime harvestDate;
  final InterestStatus status;
  final bool viaBroker;

  /// Set once the grower accepted it: the introduction to open.
  final String? dealId;
}

/// One of the caller's own interests (as trader or as the named broker).
class SentInterest {
  const SentInterest(this.interest, this.lot);

  factory SentInterest.fromJson(Map<String, Object?> j) => SentInterest(
    Interest.fromJson(j),
    LotBrief.fromJson((j['lot']! as Map).cast<String, Object?>()),
  );

  final Interest interest;
  final LotBrief lot;
}

/// An interest on the grower's own lot with the trader's (and broker's) public profile.
class LotInterest {
  const LotInterest(this.interest, this.trader, this.broker);

  factory LotInterest.fromJson(Map<String, Object?> j) => LotInterest(
    Interest.fromJson(j),
    MarketProfile.fromJson((j['trader']! as Map).cast<String, Object?>()),
    switch (j['broker']) {
      final Map<Object?, Object?> m => MarketProfile.fromJson(
        m.cast<String, Object?>(),
      ),
      _ => null,
    },
  );

  final Interest interest;
  final MarketProfile trader;
  final MarketProfile? broker;
}

class Contact {
  const Contact({required this.name, required this.phone, this.firm});

  factory Contact.fromJson(Map<String, Object?> j) => Contact(
    name: _s(j['name']) ?? '',
    firm: _s(j['firm']),
    phone: _s(j['phone']),
  );

  final String name;
  final String? firm;

  /// Null when the grower signed in without a phone number.
  final String? phone;
}

/// Both sides' contacts after the grower accepted (decision g). Nothing about their deal.
class Introduction {
  const Introduction({
    required this.dealId,
    required this.acceptedAt,
    required this.lot,
    required this.interest,
    required this.grower,
    required this.growerPlace,
    required this.trader,
    this.plotName,
    this.pin,
    this.broker,
  });

  factory Introduction.fromJson(Map<String, Object?> j) {
    final g = (j['grower']! as Map).cast<String, Object?>();
    final pin = (g['pin'] as Map?)?.cast<String, Object?>();
    return Introduction(
      dealId: j['deal_id']! as String,
      acceptedAt: DateTime.parse(j['accepted_at']! as String),
      lot: LotBrief.fromJson((j['lot']! as Map).cast<String, Object?>()),
      interest: Interest.fromJson(
        (j['interest']! as Map).cast<String, Object?>(),
      ),
      grower: Contact.fromJson(g),
      growerPlace: _place([
        _s(g['village']),
        _s(g['taluka']),
        _s(g['district']),
      ]),
      plotName: _s(g['plot_name']),
      pin: pin == null
          ? null
          : (
              lat: (pin['lat']! as num).toDouble(),
              lon: (pin['lon']! as num).toDouble(),
            ),
      trader: Contact.fromJson((j['trader']! as Map).cast<String, Object?>()),
      broker: switch (j['broker']) {
        final Map<Object?, Object?> m => Contact.fromJson(
          m.cast<String, Object?>(),
        ),
        _ => null,
      },
    );
  }

  final String dealId;
  final DateTime acceptedAt;
  final LotBrief lot;
  final Interest interest;
  final Contact grower;
  final String growerPlace;
  final String? plotName;
  final ({double lat, double lon})? pin;
  final Contact trader;
  final Contact? broker;
}
