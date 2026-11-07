import '../../bahar/domain/bahar_cycle.dart';

/// Sale basis of a lot (spec v1.5 §3 step 1): per tonne, per crate, or the whole orchard.
const lotBases = ['per_tonne', 'per_crate', 'lump_sum'];

/// A lot is published with 3 to 8 in-app photos (the server checks it again).
const lotMinPhotos = 3;
const lotMaxPhotos = 8;

/// One in-app camera photo of a lot, stamped with when and where it was taken.
class LotPhoto {
  const LotPhoto({
    required this.id,
    required this.lotId,
    required this.capturedAt,
    required this.lat,
    required this.lon,
    this.photoPath,
    this.photoKey,
  });

  final String id;
  final String lotId;
  final DateTime capturedAt;
  final double lat;
  final double lon;

  /// The file on this phone (never synced).
  final String? photoPath;

  /// The uploaded object; set once the photo is backed up.
  final String? photoKey;

  bool get uploaded => photoKey != null;

  LotPhoto withKey(String key) => LotPhoto(
    id: id,
    lotId: lotId,
    capturedAt: capturedAt,
    lat: lat,
    lon: lon,
    photoPath: photoPath,
    photoKey: key,
  );

  /// Payload for the `market_lot_photo` sync entity.
  Map<String, Object?> toPayload() => {
    'lot_id': lotId,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'lat': lat,
    'lon': lon,
    'photo_key': photoKey,
  };

  static LotPhoto fromPayload(String id, Map<String, Object?> p) => LotPhoto(
    id: id,
    lotId: p['lot_id']! as String,
    capturedAt: DateTime.parse(p['captured_at']! as String),
    lat: (p['lat']! as num).toDouble(),
    lon: (p['lon']! as num).toDouble(),
    photoKey: p['photo_key'] as String?,
  );
}

/// A grower's produce shown for sale. Drafted offline; published only by the server.
class MarketLot {
  const MarketLot({
    required this.id,
    required this.plotId,
    required this.crop,
    required this.quantityT,
    required this.harvestFrom,
    required this.harvestTo,
    required this.basis,
    this.baharCycleId,
    this.variety,
    this.quality,
    this.askingRatePaise,
    this.status = 'draft',
    this.publishedAt,
    this.orchardCheck,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final String crop;
  final String? variety;
  final double quantityT;
  final String? quality;
  final DateTime harvestFrom;
  final DateTime harvestTo;

  /// per_tonne | per_crate | lump_sum ([lotBases]).
  final String basis;

  /// Per tonne, per crate or the whole amount, by [basis]; null when not given.
  final int? askingRatePaise;

  /// draft | published | closed (the server's).
  final String status;
  final DateTime? publishedAt;

  /// The server's real orchard check at publish (spec §4C): inside / near / outside /
  /// unmapped. A published lot that is neither inside nor near waits for an admin check.
  final String? orchardCheck;

  bool get isDraft => status == 'draft';

  /// Published, but not shown to traders until an admin checks it.
  bool get awaitingCheck =>
      status == 'published' &&
      orchardCheck != 'inside' &&
      orchardCheck != 'near';

  /// Payload for the `market_lot` sync entity: the grower's fields only.
  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'quantity_t': quantityT,
    'quality': quality,
    'harvest_from': BaharCycle.isoDate(harvestFrom),
    'harvest_to': BaharCycle.isoDate(harvestTo),
    'basis': basis,
    'asking_rate_paise': askingRatePaise,
  };

  static MarketLot fromPayload(String id, Map<String, Object?> p) => MarketLot(
    id: id,
    plotId: p['plot_id']! as String,
    baharCycleId: p['bahar_cycle_id'] as String?,
    crop: p['crop'] as String? ?? '',
    variety: p['variety'] as String?,
    quantityT: (p['quantity_t']! as num).toDouble(),
    quality: p['quality'] as String?,
    harvestFrom: DateTime.parse(p['harvest_from']! as String),
    harvestTo: DateTime.parse(p['harvest_to']! as String),
    basis: p['basis']! as String,
    askingRatePaise: p['asking_rate_paise'] as int?,
    status: p['status'] as String? ?? 'draft',
    publishedAt: p['published_at'] == null
        ? null
        : DateTime.parse(p['published_at']! as String),
    orchardCheck: p['orchard_check'] as String?,
  );
}
