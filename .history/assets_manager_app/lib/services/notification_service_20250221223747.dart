import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
  }

  Future<void> scheduleMaintenance({
    required String id,
    required String assetName,
    required DateTime maintenanceDate,
    required String maintenanceType,
  }) async {
    // Schedule multiple notifications
    // 1 week before
    await _scheduleNotification(
      id: '${id}_week',
      title: 'Upcoming Maintenance',
      body: '$assetName maintenance scheduled in 1 week',
      scheduledDate: maintenanceDate.subtract(Duration(days: 7)),
      payload: id,
    );

    // 1 day before
    await _scheduleNotification(
      id: '${id}_day',
      title: 'Maintenance Tomorrow',
      body: '$assetName maintenance due tomorrow',
      scheduledDate: maintenanceDate.subtract(Duration(days: 1)),
      payload: id,
    );

    // On the day
    await _scheduleNotification(
      id: '${id}_today',
      title: 'Maintenance Due Today',
      body: '$assetName maintenance is due today',
      scheduledDate: maintenanceDate,
      payload: id,
    );
  }

  Future<void> _scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'maintenance_channel',
      'Maintenance Notifications',
      channelDescription: 'Notifications for scheduled maintenance',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
} 