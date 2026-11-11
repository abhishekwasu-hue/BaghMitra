import 'dart:convert';

import 'package:bagmitra/api/generated/bagmitra.enums.swagger.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/tasks/domain/farm_task.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:drift/drift.dart' show Value;

/// A production-like build: a backend is configured, so the demo home is never used.
const realConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: 'https://x.supabase.co',
  supabaseAnonKey: 'anon',
  devGallery: false,
  testBuild: '',
  speechEngine: 'on_device',
);

/// The same production-like build with the developer component gallery switched on.
const realDevConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: 'https://x.supabase.co',
  supabaseAnonKey: 'anon',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
);

const homePlotId = 'p1';

/// One located block with a dated Mrig bahar, two tasks, cached weather with an alert and
/// cached mandi prices. The test clock is 2026-10-13. [current] is the saved current
/// reading (the API's `current` block), none by default.
Future<void> seedHomeData(
  AppDatabase db, {
  String lang = 'mr',
  Map<String, Object?>? current,
}) async {
  await (db.update(db.farmerProfiles)..where((p) => p.id.equals('u1'))).write(
    const FarmerProfilesCompanion(displayName: Value('सुनील')),
  );
  await PlotRepository(db).save(
    const Plot(
      id: homePlotId,
      name: 'बाग १',
      crop: 'santra',
      areaSqM: 3 * Plot.sqMPerAcre,
      centroidLat: 21.2468,
      centroidLon: 77.7512,
    ),
  );
  await BaharRepository(db).save(
    BaharCycle(
      id: 'b1',
      plotId: homePlotId,
      bahar: 'mrig',
      seasonYear: 2026,
      status: 'active',
      actual: {
        'stress_start': DateTime(2026, 5, 10),
        'flowering': DateTime(2026, 6, 20),
        'fruit_set': DateTime(2026, 7, 25),
      },
      planned: {'harvest': DateTime(2027, 2, 15)},
    ),
  );
  final tasks = TasksRepository(db, clock: () => DateTime.utc(2026, 10, 13, 6));
  await tasks.save(
    FarmTask(
      id: 't1',
      title: 'ठिबक ३ तास — बाग १',
      kind: 'irrigation',
      dueOn: DateTime(2026, 10, 13),
      plotId: homePlotId,
      source: 'manual',
    ),
  );
  await tasks.save(
    FarmTask(
      id: 't2',
      title: 'सिल्ला पाहणी — १० झाडं',
      kind: 'scouting',
      dueOn: DateTime(2026, 10, 12),
      plotId: homePlotId,
      source: 'manual',
    ),
  );
  await db.writeMeta(
    PlotWeatherCache.keyFor(homePlotId, lang),
    jsonEncode({
      'saved_at': '2026-10-13T05:00:00.000Z',
      'weather': {
        'days': [
          for (var i = 0; i < 4; i++)
            {
              'day': '2026-10-${13 + i}',
              't_max_c': 35.0 + i,
              't_min_c': 21.0,
              'precip_mm': 0.0,
              'rh_mean_pct': 50.0,
              'wind_gust_kmh': 20.0,
            },
        ],
        'alerts': [
          {
            'rule_key': 'heat_fruit_drop',
            'first_day': '2026-10-14',
            'value': 35.0,
            'units': null,
            'text': 'Heat of 35 °C or more expected: risk of fruit drop.',
            'source': 'ICAR-CCRI Nagpur',
            'status': 'reviewed',
          },
        ],
        'stale': false,
        'current': ?current,
      },
    }),
  );
  await db.writeMeta(
    MarketPricesCache.keyFor('santra', V1MarketPricesGetScope.all),
    jsonEncode({
      'saved_at': '2026-10-13T05:00:00.000Z',
      'prices': {
        'prices': [
          {
            'day': '2026-10-12',
            'market': 'Azadpur',
            'state': 'NCT of Delhi',
            'district': 'North Delhi',
            'commodity': 'Orange',
            'modal_rs_per_quintal': 5200,
            'source': 'agmarknet',
            'is_local': false,
            'is_major': true,
          },
          {
            'day': '2026-10-11',
            'market': 'Warud',
            'state': 'Maharashtra',
            'district': 'Amravati',
            'commodity': 'Orange',
            'modal_rs_per_quintal': 3400,
            'source': 'agmarknet',
            'is_local': true,
            'is_major': false,
          },
        ],
        'stale': false,
      },
    }),
  );
}
