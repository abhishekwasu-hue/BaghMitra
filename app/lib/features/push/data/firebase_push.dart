import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/app_log.dart';
import '../domain/push.dart';

/// The Android channel server pushes use; the API names it in every message (push/fcm.py).
const pushChannelId = 'alerts';

/// Firebase Cloud Messaging. Used only in a build with `--dart-define=PUSH=true` and the
/// project's `android/app/google-services.json` (runbook docs/runbooks/push-notifications.md).
/// If Firebase cannot start (for example the file was left out) push stays off and the app
/// works as before.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging({
    required this._log,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final AppLog _log;
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool> start() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              pushChannelId,
              'Alerts',
              description:
                  'Weather risk alerts and government scheme reminders',
              importance: Importance.high,
            ),
          );
      return true;
    } on Object catch (e) {
      _log.log('push off: firebase did not start (${e.runtimeType})');
      return false;
    }
  }

  // The FCM registration token is what the API's HTTP v1 sender targets (`message.token`).
  // firebase_messaging 17 marks it deprecated in favour of the new installation-ID
  // registration; switching needs the server to send by FID as well, so it stays for now.
  @override
  // ignore: deprecated_member_use
  Future<String?> token() => FirebaseMessaging.instance.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushNote> get foregroundNotes => FirebaseMessaging.onMessage
      .map((m) => m.notification)
      .where((n) => n != null)
      .map((n) => PushNote(title: n!.title ?? '', body: n.body ?? ''));

  @override
  Future<void> show(PushNote note) => _plugin.show(
    id: note.hashCode & 0x7fffffff,
    title: note.title,
    body: note.body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        pushChannelId,
        'Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
