// Kunlik eslatma (o‘quvchi tanlagan vaqtda) / ежедневное напоминание (во время, выбранное учеником).
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _id = 1;

  static Future<bool> _init() async {
    if (_ready) return true;
    if (kIsWeb) return false;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Ruxsat so‘rash / запрос разрешения.
  static Future<bool> askPermission() async {
    if (!await _init()) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await a?.requestNotificationsPermission() ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Har kuni shu vaqtda eslatma (minutes — 0..1439) / напоминание каждый день в это время.
  static Future<void> schedule(int minutes, {required String title, required String body}) async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: _id);
      if (minutes < 0) return;
      // Mahalliy vaqtni UTC ga aylantiramiz (O‘zbekistonda yozgi vaqt yo‘q).
      // Переводим местное время в UTC (в Узбекистане нет перехода на летнее время).
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      final when = tz.TZDateTime.from(at.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        id: _id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Kunlik eslatma',
            channelDescription: 'Idrok Academy',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancel() async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
