import 'package:bagmitra/api/generated/bagmitra.swagger.dart'
    show MarketPrices, PlotWeather;
import 'package:bagmitra/features/bahar/data/bahar_catalog.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/features/home/data/local_home_repository.dart';
import 'package:bagmitra/features/home/domain/home_snapshot.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/features/profile/domain/farmer_profile.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const _plot = Plot(
  id: 'p1',
  name: 'Block 1',
  crop: 'santra',
  areaSqM: 2 * Plot.sqMPerAcre,
  centroidLat: 21,
  centroidLon: 77,
);

BaharCycle _cycle({
  String id = 'b1',
  String status = 'active',
  int season = 2026,
  Map<String, DateTime> actual = const {},
  Map<String, DateTime> planned = const {},
}) => BaharCycle(
  id: id,
  plotId: 'p1',
  bahar: 'mrig',
  seasonYear: season,
  status: status,
  actual: actual,
  planned: planned,
);

void main() {
  late BaharCatalogData catalog;
  setUpAll(
    () async => catalog = await BaharCatalog(bundle: FileAssetBundle()).load(),
  );

  HomeSnapshot build({
    List<Plot> plots = const [_plot],
    List<BaharCycle> cycles = const [],
    CachedWeather? weather,
    bool weatherLoading = false,
    CachedMarketPrices? prices,
    String? name,
  }) => buildLocalHomeSnapshot(
    profile: FarmerProfile(id: 'u1', language: 'en', displayName: name),
    plots: plots,
    cycles: cycles,
    catalog: catalog,
    weather: weather,
    weatherLoading: weatherLoading,
    prices: prices,
    today: DateTime(2026, 10, 13, 6),
    lang: 'en',
    acresLabel: (a) => '${a.round()} acres',
  );

  test('no plot: every block is empty and it is never demo', () {
    final s = build(plots: const []);
    expect(s.isDemo, isFalse);
    expect(s.hasPlot, isFalse);
    expect(s.farmerName, '');
    expect(s.initial, '');
    expect(s.stage, isNull);
    expect(s.weather, isNull);
    expect(s.weatherNote, isNull);
    expect(s.market, isNull);
    expect(s.alert, isNull);
    expect(s.tasks, isEmpty);
  });

  test('weather note: no location, not loaded yet, or still loading', () {
    const bare = Plot(id: 'p1', name: 'B', crop: 'santra', areaSqM: 1);
    expect(build(plots: [bare]).weatherNote, WeatherNote.needsLocation);
    expect(build().weatherNote, WeatherNote.notYetLoaded);
    expect(build(weatherLoading: true).weatherNote, isNull);
  });

  test("today's forecast and the first alert come from the saved weather", () {
    final s = build(
      name: ' Sunil ',
      weather: CachedWeather(
        PlotWeather.fromJson({
          'days': [
            {'day': '2026-10-12', 't_max_c': 30.0, 't_min_c': 18.0},
            {'day': '2026-10-13', 't_max_c': 35.4, 't_min_c': 20.6},
          ],
          'alerts': [
            {
              'rule_key': 'heat',
              'first_day': '2026-10-14',
              'value': 35.0,
              'text': 'Heat ahead',
              'source': 'ICAR',
              'status': 'reviewed',
            },
          ],
          'stale': false,
        }),
        DateTime.utc(2026, 10, 13),
      ),
    );
    expect(s.farmerName, 'Sunil');
    expect(s.weather!.tempC, 35);
    expect(s.weather!.minC, 21);
    expect(s.weather!.place, 'Block 1');
    expect(s.weather!.soilMoisturePct, isNull);
    expect(s.alert!.title, 'Heat ahead');
    expect(s.alert!.source, 'ICAR');
    expect(s.alert!.firstDay, DateTime(2026, 10, 14));
  });

  test('stage from the grower dates: active beats planned, actual beats '
      'planned, nodes sit at their dates', () {
    final s = build(
      cycles: [
        _cycle(id: 'old', status: 'planned', season: 2027),
        _cycle(
          actual: {
            'stress_start': DateTime(2026, 5, 10),
            'flowering': DateTime(2026, 6, 20),
          },
          planned: {
            'flowering': DateTime(2026, 6, 2),
            'fruit_set': DateTime(2026, 11, 2),
            'harvest': DateTime(2027, 2, 15),
          },
        ),
      ],
    );
    final st = s.stage!;
    expect(st.tag, 'Mrig bahar · Block 1 · 2 acres');
    expect(st.currentName, 'Flowering');
    expect(st.currentIndex, 1);
    expect(st.day, 156);
    expect(st.nextName, 'Fruit set');
    expect(st.nextInDays, 20);
    expect(st.harvestMonth, DateTime(2027, 2, 15));
    expect(st.milestones.first.position, 0);
    expect(st.milestones.last.position, 1);
    expect(st.milestones[1].position, closeTo(1 / 3, 1e-9));
    // Flowering (20 Jun) to fruit set (2 Nov): 115 of 135 days gone.
    expect(st.progress, closeTo(1 / 3 + (1 / 3) * (115 / 135), 1e-9));
    expect(st.milestones.map((m) => m.kind), [
      StageKind.stress,
      StageKind.flowering,
      StageKind.fruitSet,
      StageKind.harvest,
    ]);
  });

  test('a bahar with no dates still shows, evenly, with nothing reached', () {
    final st = build(cycles: [_cycle(status: 'planned')]).stage!;
    expect(st.currentIndex, -1);
    expect(st.currentName, 'Mrig bahar');
    expect(st.day, isNull);
    expect(st.nextName, isNull);
    expect(st.harvestMonth, isNull);
    expect(st.progress, 0);
    expect(st.milestones[1].position, closeTo(1 / 3, 1e-9));
  });

  test('a bahar that starts later counts down to its first stage', () {
    final st = build(
      cycles: [
        _cycle(
          status: 'planned',
          planned: {'stress_start': DateTime(2026, 10, 20)},
        ),
      ],
    ).stage!;
    expect(st.day, isNull);
    expect(st.nextName, 'Water stress starts');
    expect(st.nextInDays, 7);
  });

  test('harvest as the next stage is not repeated as the harvest month', () {
    final st = build(
      cycles: [
        _cycle(
          actual: {'fruit_set': DateTime(2026, 8, 2)},
          planned: {'harvest': DateTime(2027, 2, 15)},
        ),
      ],
    ).stage!;
    expect(st.nextName, 'Harvest');
    expect(st.harvestMonth, isNull);
  });

  test('finished or abandoned bahars are not shown', () {
    expect(
      build(
        cycles: [
          _cycle(status: 'completed'),
          _cycle(id: 'b2', status: 'abandoned'),
        ],
      ).stage,
      isNull,
    );
  });

  test('price: the newest local market, else the newest of all', () {
    Map<String, Object?> row(String market, String day, int rs, bool local) => {
      'day': day,
      'market': market,
      'state': 'MH',
      'district': 'D',
      'commodity': 'Orange',
      'modal_rs_per_quintal': rs,
      'source': 'agmarknet',
      'is_local': local,
      'is_major': !local,
      'variety': 'Nagpuri',
    };
    CachedMarketPrices prices(List<Map<String, Object?>> rows) =>
        CachedMarketPrices(
          MarketPrices.fromJson({'prices': rows, 'stale': false}),
          DateTime.utc(2026, 10, 13),
        );
    final local = build(
      prices: prices([
        row('Far', '2026-10-12', 5000, false),
        row('Warud', '2026-10-10', 3300, true),
        row('Morshi', '2026-10-11', 3400, true),
      ]),
    ).market!;
    expect(local.market, 'Morshi');
    expect(local.pricePerQuintal, 3400);
    expect(local.grade, 'Nagpuri');
    expect(local.weeklyChangePct, isNull);
    expect(local.day, DateTime(2026, 10, 11));

    final any = build(
      prices: prices([
        row('A', '2026-10-09', 4000, false),
        row('B', '2026-10-12', 4100, false),
      ]),
    ).market!;
    expect(any.market, 'B');
    expect(build(prices: prices(const [])).market, isNull);
  });
}
