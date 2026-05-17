import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Wreniq push notification service.
// Wraps flutter_local_notifications for immediate and scheduled reminders.
// Call NotificationService.init() from main() before runApp().
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId   = 'wreniq_alerts';
  static const _channelName = 'Wreniq Alerts';
  static const _channelDesc = 'Maintenance reminders and vehicle alerts';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
  );

  static const _notifDetails = NotificationDetails(android: _androidDetails);

  // ── Initialisation ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit     = DarwinInitializationSettings(
      requestAlertPermission: false, // request explicitly via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> get hasPermission async =>
      (await Permission.notification.status).isGranted;

  // ── Core show ──────────────────────────────────────────────────────────────

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(id, title, body, _notifDetails);
    } catch (_) {
      // Silently fail — notifications are non-critical
    }
  }

  // ── Predefined reminder types ──────────────────────────────────────────────

  static Future<void> oilChangeReminder() => show(
        id: 10,
        title: 'Oil Change Due',
        body: 'Your oil change service is coming up. Schedule an appointment.',
      );

  static Future<void> batteryWarning() => show(
        id: 11,
        title: 'Battery Warning',
        body: 'Your vehicle battery may need testing. Cold weather reduces battery life.',
      );

  static Future<void> maintenanceReminder(String item) => show(
        id: 12,
        title: 'Maintenance Due: $item',
        body: 'Your $item service is coming up. Stay on top of maintenance.',
      );

  static Future<void> tireInspectionReminder() => show(
        id: 13,
        title: 'Tire Inspection',
        body: 'Check tire pressure and tread depth. Proper inflation improves safety.',
      );

  static Future<void> recallAlert(String vehicleName) => show(
        id: 14,
        title: 'Recall Alert',
        body: 'There may be an active recall for your $vehicleName. Check NHTSA.',
      );

  static Future<void> streakReminder() => show(
        id: 15,
        title: "Don't break your streak!",
        body: 'Open Wreniq today to keep your streak alive.',
      );
}
