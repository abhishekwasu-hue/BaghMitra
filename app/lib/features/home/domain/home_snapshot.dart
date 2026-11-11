/// Everything the "today's orchard" screen shows. In demo mode (no backend) it comes from a
/// bundled sample; otherwise only from the grower's own profile, plots, bahar cycles, saved
/// weather and saved mandi prices (`local_home_repository.dart`). A missing block is null.
class HomeSnapshot {
  const HomeSnapshot({
    required this.farmerName,
    this.weather,
    this.stage,
    this.tasks = const [],
    this.market,
    this.alerts = const [],
    this.isDemo = false,
    this.plotId,
    this.weatherNote,
  });

  factory HomeSnapshot.fromJson(
    Map<String, Object?> j, {
    bool isDemo = false,
  }) => HomeSnapshot(
    farmerName: j['farmer_name']! as String,
    weather: WeatherNow.fromJson(_map(j['weather'])),
    stage: StageSummary.fromJson(_map(j['stage'])),
    tasks: [
      for (final t in j['tasks']! as List<Object?>) TaskItem.fromJson(_map(t)),
    ],
    market: j['market'] == null
        ? null
        : MarketQuote.fromJson(_map(j['market'])),
    alerts: [if (j['alert'] case final a?) RiskAlert.fromJson(_map(a))],
    isDemo: isDemo,
  );

  /// Empty when the grower gave no name.
  final String farmerName;
  final WeatherNow? weather;

  /// Null when there is no plot, or the first plot has no planned / active bahar.
  final StageSummary? stage;

  /// Sample tasks (demo only). Real tasks come from the tasks table.
  final List<TaskItem> tasks;
  final MarketQuote? market;

  /// The saved risk alerts, in the API order; home shows the first one switched on.
  final List<RiskAlert> alerts;
  RiskAlert? get alert => alerts.firstOrNull;
  final bool isDemo;

  /// The plot the home blocks describe (the first plot); null when the grower has none.
  final String? plotId;

  /// Why there is no weather for [plotId], when there is none.
  final WeatherNote? weatherNote;

  bool get hasPlot => plotId != null || isDemo;

  String get initial =>
      farmerName.isEmpty ? '' : String.fromCharCodes(farmerName.runes.take(1));

  HomeSnapshot withTasks(List<TaskItem> tasks) => HomeSnapshot(
    farmerName: farmerName,
    weather: weather,
    stage: stage,
    tasks: tasks,
    market: market,
    alerts: alerts,
    isDemo: isDemo,
    plotId: plotId,
    weatherNote: weatherNote,
  );
}

/// Why the home header shows no weather.
enum WeatherNote {
  /// The plot has no saved location, so the server cannot forecast it.
  needsLocation,

  /// Nothing saved on the phone yet; it comes once the phone is online.
  notYetLoaded,
}

Map<String, Object?> _map(Object? o) =>
    (o! as Map<Object?, Object?>).cast<String, Object?>();

class WeatherNow {
  const WeatherNow({
    required this.place,
    required this.tempC,
    this.condition,
    this.maxC,
    this.minC,
    this.soilMoisturePct,
  });

  factory WeatherNow.fromJson(Map<String, Object?> j) => WeatherNow(
    place: j['place']! as String,
    condition: j['condition'] as String?,
    tempC: j['temp_c']! as int,
    maxC: j['max_c'] as int?,
    soilMoisturePct: j['soil_moisture_pct'] as int?,
  );

  final String place;
  final String? condition;

  /// The big number. The sample shows "now"; real data shows today's forecast maximum.
  final int tempC;
  final int? maxC;
  final int? minC;
  final int? soilMoisturePct;
}

enum StageKind { stress, flowering, fruitSet, fruitGrowth, harvest }

class StageMilestone {
  const StageMilestone({
    required this.kind,
    required this.label,
    required this.position,
  });

  factory StageMilestone.fromJson(Map<String, Object?> j) => StageMilestone(
    kind: StageKind.values.byName(j['kind']! as String),
    label: j['label']! as String,
    position: (j['position']! as num).toDouble(),
  );

  final StageKind kind;
  final String label;
  final double position;
}

class StageSummary {
  const StageSummary({
    required this.tag,
    required this.currentName,
    required this.milestones,
    required this.currentIndex,
    required this.progress,
    this.day,
    this.nextName,
    this.nextInDays,
    this.harvestMonth,
  });

  factory StageSummary.fromJson(Map<String, Object?> j) => StageSummary(
    tag: j['tag']! as String,
    currentName: j['current_name']! as String,
    day: j['day'] as int?,
    milestones: [
      for (final m in j['milestones']! as List<Object?>)
        StageMilestone.fromJson(_map(m)),
    ],
    currentIndex: j['current_index']! as int,
    progress: (j['progress']! as num).toDouble(),
    nextName: j['next_name'] as String?,
    nextInDays: j['next_in_days'] as int?,
    harvestMonth: DateTime.tryParse(j['harvest_month'] as String? ?? ''),
  );

  final String tag;
  final String currentName;

  /// Days since the first dated stage; null before it or when no stage has a date.
  final int? day;
  final List<StageMilestone> milestones;

  /// The milestone reached last; -1 when none is reached yet.
  final int currentIndex;
  final double progress;
  final String? nextName;
  final int? nextInDays;
  final DateTime? harvestMonth;
}

enum TaskKind { irrigation, spray, scouting, other }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.done,
  });

  factory TaskItem.fromJson(Map<String, Object?> j) => TaskItem(
    id: j['id']! as String,
    kind: TaskKind.values.byName(j['kind']! as String),
    title: j['title']! as String,
    subtitle: j['subtitle']! as String,
    done: j['done']! as bool,
  );

  final String id;
  final TaskKind kind;
  final String title;
  final String subtitle;
  final bool done;

  TaskItem copyWith({bool? done}) => TaskItem(
    id: id,
    kind: kind,
    title: title,
    subtitle: subtitle,
    done: done ?? this.done,
  );
}

class MarketQuote {
  const MarketQuote({
    required this.market,
    required this.pricePerQuintal,
    this.grade,
    this.weeklyChangePct,
    this.day,
  });

  factory MarketQuote.fromJson(Map<String, Object?> j) => MarketQuote(
    market: j['market']! as String,
    pricePerQuintal: j['price_per_quintal']! as int,
    grade: j['grade'] as String?,
    weeklyChangePct: j['weekly_change_pct'] as int?,
  );

  final String market;

  /// Modal price, exactly as published.
  final int pricePerQuintal;
  final String? grade;
  final int? weeklyChangePct;

  /// The market day of the price (real data).
  final DateTime? day;
}

class RiskAlert {
  const RiskAlert({
    required this.title,
    this.body,
    this.source,
    this.firstDay,
    this.ruleKey,
  });

  factory RiskAlert.fromJson(Map<String, Object?> j) => RiskAlert(
    title: j['title']! as String,
    body: j['body'] as String?,
    ruleKey: j['rule_key'] as String?,
  );

  final String title;
  final String? body;

  /// The risk rule (e.g. `psylla_degree_days`) the grower can switch off with the ⚠
  /// button (Q133); null keeps the alert without that button.
  final String? ruleKey;

  /// Where a real (rule-based) alert comes from, and the day it starts.
  final String? source;
  final DateTime? firstDay;
}
