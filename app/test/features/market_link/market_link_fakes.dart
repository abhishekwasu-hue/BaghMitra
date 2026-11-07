import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/registration_api.dart';
import 'package:bagmitra/features/market_link/domain/registration.dart';
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

class FakeRegistrationApi implements RegistrationApi {
  FakeRegistrationApi({this.own = const [], this.error});

  List<MarketProfile> own;
  Object? error;
  final registered = <(RegistrationRole, Map<String, Object?>)>[];
  final documents = <(String, DocKind, int, DateTime?)>[];
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
  overrides: [registrationApiProvider.overrideWithValue(api), ...overrides],
);
