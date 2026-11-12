/// Where a tap on a server push opens (OPEN_QUESTIONS Q147). The API puts the target in the
/// push's `data` (push/updates.py, push/deliver.py, feed/alerts.py); anything unknown or
/// malformed opens nothing, so a push can never steer the app to an arbitrary path.
library;

/// The screen a push opens, and for a market push the crop to show there.
typedef PushLink = ({String route, String? crop});

final _id = RegExp(r'^[0-9a-fA-F-]{8,64}$');
final _crop = RegExp(r'^[a-z_]{2,32}$');

String? _ok(String? id) => id != null && _id.hasMatch(id) ? id : null;

PushLink? pushLink(Map<String, Object?> data) {
  String? s(String key) => switch (data[key]) {
    final String v when v.isNotEmpty => v,
    _ => null,
  };
  PushLink to(String route, [String? crop]) => (route: route, crop: crop);
  switch (s('kind')) {
    case 'article':
      if (_ok(s('thread_id')) case final thread?) {
        return to('/feed-thread/$thread');
      }
      if (_ok(s('item_id')) case final item?) return to('/feed/$item');
      return to('/feed');
    case 'feed_alert':
      if (_ok(s('item_id')) case final item?) return to('/feed/$item');
      return to('/feed');
    case 'feed_digest':
      return to('/feed');
    case 'market':
      final crop = s('crop');
      return to('/market', crop != null && _crop.hasMatch(crop) ? crop : null);
    case 'weather_change':
      if (_ok(s('plot_id')) case final plot?) return to('/plots/$plot/weather');
      return null;
    case null:
      // A risk alert (push/deliver.py) carries the plot and the rule, no kind: its storm
      // rules open the claim kit, the others the 15-day forecast.
      final plot = _ok(s('plot_id'));
      if (plot == null || s('rule_key') == null) return null;
      if (s('action') == 'claim_kit') return to('/claim-kit?plot=$plot');
      return to('/plots/$plot/weather');
    default:
      return null;
  }
}
