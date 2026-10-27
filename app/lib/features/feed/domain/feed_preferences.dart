/// The grower's Sarkari Sandesh alert settings (`/v1/me/feed-preferences`). Quiet hours
/// are India local "HH:MM" times; equal start and end means no quiet hours.
class FeedPreferences {
  const FeedPreferences({
    this.quietStart = '21:00',
    this.quietEnd = '07:00',
    this.weeklyCap = 3,
    this.optedOut = const {},
    this.digestWeekly = true,
  });

  factory FeedPreferences.fromJson(Map<String, Object?> j) => FeedPreferences(
    quietStart: j['quiet_start']! as String,
    quietEnd: j['quiet_end']! as String,
    weeklyCap: (j['weekly_cap']! as num).toInt(),
    optedOut: {
      for (final c in (j['opted_out'] as List?) ?? const []) c as String,
    },
    digestWeekly: j['digest_weekly']! as bool,
  );

  /// The server's defaults, shown before the first answer arrives.
  static const defaults = FeedPreferences();

  /// The alert kinds a grower can switch off, as the API names them.
  static const categories = ['deadline', 'payment', 'window_open'];

  /// The range the screen offers for alerts per week.
  static const minWeeklyCap = 1;
  static const maxWeeklyCap = 7;

  final String quietStart;
  final String quietEnd;
  final int weeklyCap;
  final Set<String> optedOut;
  final bool digestWeekly;

  /// Alerts per week, held to what the screen offers.
  int get shownWeeklyCap => weeklyCap.clamp(minWeeklyCap, maxWeeklyCap);

  FeedPreferences copyWith({
    String? quietStart,
    String? quietEnd,
    int? weeklyCap,
    Set<String>? optedOut,
    bool? digestWeekly,
  }) => FeedPreferences(
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    weeklyCap: weeklyCap ?? this.weeklyCap,
    optedOut: optedOut ?? this.optedOut,
    digestWeekly: digestWeekly ?? this.digestWeekly,
  );

  /// Switches one category on (alerts wanted) or off (opted out).
  FeedPreferences withCategory(String category, {required bool on}) => copyWith(
    optedOut: on ? ({...optedOut}..remove(category)) : {...optedOut, category},
  );

  Map<String, Object?> toJson() => {
    'quiet_start': quietStart,
    'quiet_end': quietEnd,
    'weekly_cap': weeklyCap,
    'opted_out': [
      for (final c in categories)
        if (optedOut.contains(c)) c,
    ],
    'digest_weekly': digestWeekly,
  };

  /// "HH:MM" from an hour and minute.
  static String hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// (hour, minute) from "HH:MM"; midnight for anything unreadable.
  static (int, int) parseHhmm(String v) {
    final parts = v.split(':');
    if (parts.length != 2) return (0, 0);
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return (0, 0);
    }
    return (h, m);
  }
}
