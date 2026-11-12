import 'dart:async';

import '../../../core/app_log.dart';

/// A server push (weather risk alert, govt-feed reminder) that arrived while the app is open.
/// When the app is closed or in the background Android shows it by itself.
class PushNote {
  const PushNote({
    required this.title,
    required this.body,
    this.data = const {},
  });
  final String title;
  final String body;

  /// What the server put in the push's `data`: where a tap opens (see `pushLink`).
  final Map<String, String> data;
}

/// The phone's push service (Firebase Cloud Messaging in a build with push on).
abstract interface class PushMessaging {
  /// Starts the service once; false when push is not available on this build or phone.
  Future<bool> start();

  /// This phone's push token, or null when the service has none yet.
  Future<String?> token();

  /// A new token after the service replaced the old one.
  Stream<String> get tokenRefresh;

  /// Pushes that arrive while the app is in the foreground.
  Stream<PushNote> get foregroundNotes;

  /// Shows a foreground push as a phone notification.
  Future<void> show(PushNote note);

  /// The `data` of each push the grower taps while the app runs (in the background, or a
  /// foreground push shown by [show]).
  Stream<Map<String, String>> get taps;

  /// The `data` of the push whose tap started the app, once; null otherwise.
  Future<Map<String, String>?> initialTap();
}

/// Push is off (the default build, demo mode, tests): nothing starts, nothing is shown.
class NoPushMessaging implements PushMessaging {
  const NoPushMessaging();

  @override
  Future<bool> start() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<PushNote> get foregroundNotes => const Stream.empty();

  @override
  Future<void> show(PushNote note) async {}

  @override
  Stream<Map<String, String>> get taps => const Stream.empty();

  @override
  Future<Map<String, String>?> initialTap() async => null;
}

/// The API's device endpoints (`POST` / `DELETE /v1/me/devices`).
abstract interface class PushDeviceApi {
  Future<void> register(String token);
  Future<void> unregister(String token);
}

/// Keeps the API's list of this phone's push token in step with the signed-in account:
/// registers on sign-in (the server moves a token to the account now signed in) and again
/// when the token changes, and removes it before sign-out. Failures are logged, never shown:
/// the next sign-in or app start registers again.
class PushRegistrar {
  PushRegistrar({
    required this._messaging,
    required this._api,
    required this._log,
    this.unregisterTimeout = const Duration(seconds: 5),
  });

  /// How long sign-out waits for the API before it goes on without it.
  final Duration unregisterTimeout;

  final PushMessaging _messaging;
  final PushDeviceApi _api;
  final AppLog _log;
  final _subs = <StreamSubscription<Object>>[];
  final _opens = StreamController<Map<String, String>>.broadcast();
  bool? _started;
  String? _userId;
  String? _token;

  /// The token last registered for the signed-in account (null: none).
  String? get registeredToken => _token;

  /// The `data` of each push the grower opened: taps while the app runs, and the one whose
  /// tap started the app (once the service has started). The app root routes them.
  Stream<Map<String, String>> get opens => _opens.stream;

  void _open(Map<String, String> data) {
    if (!_opens.isClosed) _opens.add(data);
  }

  Future<bool> _start() async {
    final started = _started ??= await _messaging.start();
    if (started && _subs.isEmpty) {
      _subs
        ..add(_messaging.tokenRefresh.listen(_onRefresh))
        ..add(
          _messaging.foregroundNotes.listen(
            (note) => unawaited(
              _messaging
                  .show(note)
                  .catchError(
                    (Object e) => _log.log('push show: ${e.runtimeType}'),
                  ),
            ),
          ),
        )
        ..add(_messaging.taps.listen(_open));
      unawaited(
        _messaging.initialTap().then(
          (data) {
            if (data != null) _open(data);
          },
          onError: (Object e) => _log.log('push initial tap: ${e.runtimeType}'),
        ),
      );
    }
    return started;
  }

  /// [userId] is signed in and the phone holds its records: register this phone's token.
  Future<void> signedIn(String userId) async {
    if (!await _start()) return;
    if (_userId == userId && _token != null) return;
    _userId = userId;
    final token = await _messaging.token();
    if (token == null) return;
    await _register(token);
  }

  Future<void> _onRefresh(String token) async {
    if (_userId == null || token == _token) return;
    await _register(token);
  }

  Future<void> _register(String token) async {
    try {
      await _api.register(token);
      _token = token;
    } on Object catch (e) {
      _log.log('push register: ${e.runtimeType}');
    }
  }

  /// Called just before sign-out, while the session can still reach the API, so pushes for
  /// this account stop on this phone.
  Future<void> beforeSignOut() async {
    final token = _token;
    _userId = null;
    _token = null;
    if (token == null) return;
    try {
      // Offline or slow: do not hold up the sign-out; FCM reports the token later anyway.
      await _api.unregister(token).timeout(unregisterTimeout);
    } on Object catch (e) {
      _log.log('push unregister: ${e.runtimeType}');
    }
  }

  /// The session ended some other way (account deletion, expiry): the server side is gone or
  /// unreachable, so only forget what was registered; the next sign-in registers again.
  void signedOut() {
    _userId = null;
    _token = null;
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _opens.close();
  }
}
