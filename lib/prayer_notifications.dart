import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();
const String kNotifEnabledKey = 'notif_enabled';

const _prayerLabels = {
  'Fajr': 'الفجر',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

/// يُستدعى مرة واحدة عند بدء التطبيق.
Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    // تعذّر تحديد المنطقة الزمنية تلقائياً؛ تبقى الأوقات بتوقيت الجهاز الافتراضي.
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await notif.initialize(initSettings);

  final android = notif.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();
}

/// يلغي كل تنبيهات الصلاة المجدولة سابقاً، ويجدول تنبيهات جديدة
/// بناءً على مواقيت اليوم وغد (يعمل بدون إنترنت لأن الأوقات محفوظة محلياً).
Future<void> scheduleAdhanNotifications({
  required Map<String, String> today,
  required Map<String, String> tomorrow,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool(kNotifEnabledKey) ?? true;
  await notif.cancelAll();
  if (!enabled) return;

  final now = DateTime.now();
  int id = 0;
  for (final entry in [
    MapEntry(now, today),
    MapEntry(now.add(const Duration(days: 1)), tomorrow),
  ]) {
    final day = entry.key;
    final times = entry.value;
    for (final k in _prayerLabels.keys) {
      final hm = times[k];
      if (hm == null) continue;
      final parts = hm.split(':');
      final dt = DateTime(day.year, day.month, day.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (dt.isBefore(now)) continue;

      await notif.zonedSchedule(
        id++,
        'حان الآن وقت صلاة ${_prayerLabels[k]}',
        'حي على الصلاة، حي على الفلاح',
        tz.TZDateTime.from(dt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel_v1',
            'تنبيه الصلاة',
            channelDescription: 'تنبيه صوتي عند دخول وقت كل صلاة',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adhan'),
            playSound: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}

Future<void> setNotificationsEnabled(bool v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kNotifEnabledKey, v);
  if (!v) await notif.cancelAll();
}

Future<bool> notificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kNotifEnabledKey) ?? true;
}
