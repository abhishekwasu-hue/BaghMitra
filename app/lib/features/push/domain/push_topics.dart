/// The three update pushes a grower can switch (Settings -> सूचना, OPEN_QUESTIONS Q147):
/// a new article, a market price change, a sudden weather change. The server keeps them per
/// account (`/v1/me/push-topics`) and sends only what is on; all three are on by default.
enum PushTopic { articles, market, weather }

class PushTopics {
  const PushTopics({
    this.articles = true,
    this.market = true,
    this.weather = true,
  });

  factory PushTopics.fromJson(Map<String, Object?> j) => PushTopics(
    articles: j['articles'] as bool? ?? true,
    market: j['market'] as bool? ?? true,
    weather: j['weather_change'] as bool? ?? true,
  );

  /// Shown before the server has answered once (the server's defaults).
  static const defaults = PushTopics();

  final bool articles;
  final bool market;
  final bool weather;

  bool isOn(PushTopic topic) => switch (topic) {
    PushTopic.articles => articles,
    PushTopic.market => market,
    PushTopic.weather => weather,
  };

  PushTopics withTopic(PushTopic topic, {required bool on}) => PushTopics(
    articles: topic == PushTopic.articles ? on : articles,
    market: topic == PushTopic.market ? on : market,
    weather: topic == PushTopic.weather ? on : weather,
  );

  Map<String, Object?> toJson() => {
    'articles': articles,
    'market': market,
    'weather_change': weather,
  };

  @override
  bool operator ==(Object other) =>
      other is PushTopics &&
      other.articles == articles &&
      other.market == market &&
      other.weather == weather;

  @override
  int get hashCode => Object.hash(articles, market, weather);
}
