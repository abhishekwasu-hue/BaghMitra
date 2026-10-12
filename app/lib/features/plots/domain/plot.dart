/// An orchard block. Crop, irrigation, water and soil are slugs into admin-managed lists.
class Plot {
  const Plot({
    required this.id,
    required this.name,
    required this.crop,
    required this.areaSqM,
    this.variety,
    this.plantingYear,
    this.treeCount,
    this.rowSpacingM,
    this.plantSpacingM,
    this.irrigationType,
    this.waterSource,
    this.soilType,
    this.centroidLat,
    this.centroidLon,
    this.boundary,
  });

  static const sqMPerAcre = 4046.8564224;

  final String id;
  final String name;
  final String crop;
  final double areaSqM;
  final String? variety;
  final int? plantingYear;
  final int? treeCount;
  final double? rowSpacingM;
  final double? plantSpacingM;
  final String? irrigationType;
  final String? waterSource;
  final String? soilType;
  final double? centroidLat;
  final double? centroidLon;

  /// GeoJSON Polygon, as decoded JSON.
  final Map<String, Object?>? boundary;

  double get areaAcres => areaSqM / sqMPerAcre;

  /// Payload for the `plot` sync entity (see api sync/payloads.py PlotPayload).
  Map<String, Object?> toPayload() => {
    'name': name,
    'crop': crop,
    'variety': variety,
    'area_sq_m': areaSqM,
    'planting_year': plantingYear,
    'tree_count': treeCount,
    'row_spacing_m': rowSpacingM,
    'plant_spacing_m': plantSpacingM,
    'irrigation_type': irrigationType,
    'water_source': waterSource,
    'soil_type': soilType,
    'centroid_lat': centroidLat,
    'centroid_lon': centroidLon,
    'boundary': boundary,
  };

  static Plot fromPayload(String id, Map<String, Object?> p) => Plot(
    id: id,
    name: p['name']! as String,
    crop: p['crop']! as String,
    areaSqM: (p['area_sq_m']! as num).toDouble(),
    variety: p['variety'] as String?,
    plantingYear: p['planting_year'] as int?,
    treeCount: p['tree_count'] as int?,
    rowSpacingM: (p['row_spacing_m'] as num?)?.toDouble(),
    plantSpacingM: (p['plant_spacing_m'] as num?)?.toDouble(),
    irrigationType: p['irrigation_type'] as String?,
    waterSource: p['water_source'] as String?,
    soilType: p['soil_type'] as String?,
    centroidLat: (p['centroid_lat'] as num?)?.toDouble(),
    centroidLon: (p['centroid_lon'] as num?)?.toDouble(),
    boundary: (p['boundary'] as Map<Object?, Object?>?)
        ?.cast<String, Object?>(),
  );
}
