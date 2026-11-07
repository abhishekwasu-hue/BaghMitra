import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/registration.dart';
import 'package:bagmitra/features/market_link/presentation/profile_widgets.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/data/place_geocoder.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const marketLinkConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
  marketLink: true,
);

/// A 360 dp phone (the owner's phone check, build prompt §4).
const smallPhone = Size(360, 780);

final _on = DateTime.utc(2026, 11, 7);

MarketProfile sampleTrader({String id = 'b1', int deals = 12}) => MarketProfile(
  subjectType: 'buyer',
  id: id,
  kind: 'trader',
  name: 'रमेश पाटील',
  firm: 'पाटील फ्रुट कंपनी',
  phone: '+919800000001',
  markets: const ['वरुड बाजार समिती'],
  taluka: 'वरुड',
  district: 'अमरावती',
  crops: const ['santra', 'mosambi'],
  dealsCompleted: deals,
  stars: const [
    QuestionStars('trader_on_date', 4.5, 8),
    QuestionStars('trader_paid_as_agreed', 4, 8),
  ],
  tags: const [
    TagCount(
      {'mr': 'ठरलेल्या दिवशी आले', 'hi': 'तय दिन आए', 'en': 'On date'},
      'positive',
      6,
    ),
  ],
  badges: [
    ProfileBadge('checked', _on),
    ProfileBadge('registered_from', _on, place: 'वरुड, अमरावती'),
  ],
);

MarketProfile sampleBroker() => MarketProfile(
  subjectType: 'broker',
  id: 'k1',
  kind: 'broker',
  name: 'सुरेश वानखडे',
  phone: '+919800000002',
  village: 'शेंदुरजना घाट',
  taluka: 'वरुड',
  district: 'अमरावती',
  areas: const ['वरुड', 'मोर्शी'],
  dealsCompleted: 3,
  badges: [ProfileBadge('checked', _on)],
);

MarketProfile sampleWeighbridge({bool expired = true}) => MarketProfile(
  subjectType: 'provider',
  id: 'p1',
  kind: 'weighbridge',
  name: 'वरुड वजनकाटा',
  phone: '+919800000003',
  village: 'वरुड',
  taluka: 'वरुड',
  district: 'अमरावती',
  certValidUntil: DateTime.utc(2026, 11, 6),
  certificateExpired: expired,
  distanceKm: 2,
  badges: [ProfileBadge('checked', _on)],
);

MarketProfile sampleTransporter() => MarketProfile(
  subjectType: 'provider',
  id: 'p2',
  kind: 'transporter',
  name: 'गणेश ट्रान्सपोर्ट',
  phone: '+919800000004',
  village: 'मोर्शी',
  taluka: 'मोर्शी',
  district: 'अमरावती',
  vehicleNumbers: const ['MH27AB1234'],
  capacityT: 9,
  distanceKm: 18,
  badges: [ProfileBadge('checked', _on)],
);

class FakeRegistrationApi implements RegistrationApi {
  FakeRegistrationApi({
    this.own = const [],
    this.listed = const [],
    this.services = const [],
    this.error,
  });

  List<MarketProfile> own;
  List<MarketProfile> listed;
  List<MarketProfile> services;
  Object? error;
  final registered = <(RegistrationRole, Map<String, Object?>)>[];
  final documents = <(String, DocKind, int, DateTime?)>[];
  final queries = <Map<String, Object?>>[];
  MarketCallException? refuseWith;

  void _fail() {
    if (error != null) throw error!;
  }

  @override
  Future<void> register(
    RegistrationRole role,
    Map<String, Object?> body,
  ) async {
    _fail();
    if (refuseWith case final e?) throw e;
    registered.add((role, body));
  }

  @override
  Future<List<MarketProfile>> mine() async {
    _fail();
    return own;
  }

  @override
  Future<List<MarketProfile>> people({
    required String role,
    String? taluka,
    String? district,
    String sort = 'rating',
  }) async {
    _fail();
    queries.add({
      'role': role,
      'taluka': taluka,
      'district': district,
      'sort': sort,
    });
    return listed;
  }

  @override
  Future<MarketProfile> profile(String subjectType, String id) async {
    _fail();
    return [...listed, ...services].firstWhere((p) => p.id == id);
  }

  @override
  Future<List<MarketProfile>> providers({
    ProviderKind? kind,
    String? district,
    String? taluka,
    String? plotId,
  }) async {
    _fail();
    queries.add({'type': kind?.api, 'plot_id': plotId, 'district': district});
    return [
      for (final s in services)
        if (kind == null || s.kind == kind.api) s,
    ];
  }

  @override
  Future<MarketProfile> setAddress(
    String subjectType,
    String id,
    String? address,
  ) async => own.first;

  @override
  Future<MarketProfile> addDocument(
    String subjectType,
    String id,
    DocKind doc,
    List<int> jpeg, {
    DateTime? validUntil,
  }) async {
    documents.add((id, doc, jpeg.length, validUntil));
    return own.first;
  }
}

/// A grower in Warud taluka, Amravati district (the list filters start there).
Future<void> seedPlace(AppDatabase db) async {
  await (db.update(db.farmerProfiles)..where((p) => p.id.equals('u1'))).write(
    const FarmerProfilesCompanion(
      displayName: Value('रमेश'),
      village: Value('वरुड'),
      taluka: Value('वरुड'),
      district: Value('अमरावती'),
    ),
  );
}

Future<AppDatabase> pumpMarketLink(
  WidgetTester tester,
  String route, {
  required FakeRegistrationApi api,
  List<String>? dialled,
  ThemeMode themeMode = ThemeMode.light,
  Size size = smallPhone,
  Future<void> Function(AppDatabase db)? seed,
  List<Override> overrides = const [],
  Locale locale = const Locale('mr'),
  LocationService? location,
  PlaceGeocoder? geocoder,
}) => pumpApp(
  tester,
  location: location,
  geocoder: geocoder,
  config: marketLinkConfig,
  initialLocation: route,
  themeMode: themeMode,
  size: size,
  locale: locale,
  seed: (db) async {
    await seedPlace(db);
    await seed?.call(db);
  },
  overrides: [
    registrationApiProvider.overrideWithValue(api),
    phoneDialerProvider.overrideWithValue((phone) async {
      dialled?.add(phone);
      return true;
    }),
    ...overrides,
  ],
);
