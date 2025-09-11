// services/notification_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<int> _scheduledNotificationIds = {};

  // Vibration pattern
  final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

  // Channel IDs
  static const String _medicationChannelId = 'medication_channel';
  static const String _medicationChannelName = 'Medication Reminders';

  static const String _appointmentChannelId = 'appointment_channel';
  static const String _appointmentChannelName = 'Appointment Reminders';

  Future<void> initialize() async {
    try {
      // Initialize timezone with device's local timezone
      tz.initializeTimeZones();

      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Notification clicked with payload: ${response.payload}");
        },
      );

      await requestPermissions();
      await _createNotificationChannels();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    // Medication Channel
    const AndroidNotificationChannel medicationChannel =
        AndroidNotificationChannel(
          _medicationChannelId,
          _medicationChannelName,
          description: 'Reminders for taking medications',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    // Appointment Channel
    const AndroidNotificationChannel appointmentChannel =
        AndroidNotificationChannel(
          _appointmentChannelId,
          _appointmentChannelName,
          description: 'Reminders for upcoming appointments',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(medicationChannel);
    await androidPlugin?.createNotificationChannel(appointmentChannel);
  }

  Future<void> requestPermissions() async {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestPermission();
  }

  // MEDICATION REMINDER METHODS (keep your existing ones)

  Future<void> scheduleMedicationReminder({
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
    required int id,
  }) async {
    try {
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _medicationChannelId,
            _medicationChannelName,
            channelDescription: 'Reminders for taking medications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
      );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await notificationsPlugin.zonedSchedule(
        id,
        '💊 Medication Reminder',
        'Time to take $medicationName ($dosage)',
        scheduledDate,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      _scheduledNotificationIds.add(id);
      debugPrint('✅ Scheduled medication notification ID: $id for $time');
    } catch (e) {
      debugPrint('❌ Error scheduling medication notification: $e');
    }
  }

  // APPOINTMENT REMINDER METHODS - DAILY AT FIXED TIME
  Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String doctorName,
    required String location,
    required DateTime scheduledDate,
    TimeOfDay reminderTime = const TimeOfDay(
      hour: 9,
      minute: 0,
    ), // Default: 9:00 AM
  }) async {
    try {
      // Schedule notification for each day from today until appointment date
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime appointmentDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      // Only schedule if appointment is in the future
      if (appointmentDate.isAfter(now)) {
        // Calculate days between now and appointment
        final daysUntilAppointment = appointmentDate.difference(now).inDays;

        // Schedule daily reminders starting today until appointment date
        for (int i = 0; i <= daysUntilAppointment; i++) {
          final reminderDateTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day + i,
            reminderTime.hour,
            reminderTime.minute,
          );

          // Only schedule if reminder time is in the future
          if (reminderDateTime.isAfter(now)) {
            await _scheduleDailyAppointmentNotification(
              id: id + i, // Unique ID for each day
              title: title,
              doctorName: doctorName,
              location: location,
              scheduledDate: scheduledDate,
              reminderDate: reminderDateTime,
              daysUntil: daysUntilAppointment - i,
            );
          }
        }
      }

      debugPrint(
        '✅ Scheduled daily appointment reminders for: $title on ${DateFormat('MMM dd, yyyy').format(scheduledDate)}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling appointment reminders: $e');
    }
  }

  Future<void> _scheduleDailyAppointmentNotification({
    required int id,
    required String title,
    required String doctorName,
    required String location,
    required DateTime scheduledDate,
    required tz.TZDateTime reminderDate,
    required int daysUntil,
  }) async {
    final String notificationTitle = '📅 Appointment Reminder';

    String notificationBody;
    if (daysUntil == 0) {
      notificationBody =
          'Your appointment "$title" with Dr. $doctorName is today at $location';
    } else if (daysUntil == 1) {
      notificationBody =
          'Your appointment "$title" with Dr. $doctorName is tomorrow at $location';
    } else {
      notificationBody =
          'Your appointment "$title" with Dr. $doctorName is in $daysUntil days at $location';
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _appointmentChannelId,
          _appointmentChannelName,
          channelDescription: 'Reminders for upcoming appointments',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      notificationTitle,
      notificationBody,
      reminderDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'appointment_$id',
    );

    _scheduledNotificationIds.add(id);
  }

  // Alternative: Single daily reminder (only on the day of appointment)
  Future<void> scheduleAppointmentReminderSingle({
    required int id,
    required String title,
    required String doctorName,
    required String location,
    required DateTime scheduledDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime appointmentDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      if (appointmentDate.isAfter(now)) {
        // Schedule only on the appointment day at specified time
        final reminderDateTime = tz.TZDateTime(
          tz.local,
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        if (reminderDateTime.isAfter(now)) {
          const AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails(
                _appointmentChannelId,
                _appointmentChannelName,
                channelDescription: 'Reminders for upcoming appointments',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              );

          const DarwinNotificationDetails iosDetails =
              DarwinNotificationDetails(sound: 'default');

          const NotificationDetails details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          await notificationsPlugin.zonedSchedule(
            id,
            '📅 Appointment Today',
            'Your appointment "$title" with Dr. $doctorName is today at $location',
            reminderDateTime,
            details,
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'appointment_$id',
          );

          _scheduledNotificationIds.add(id);
        }
      }

      debugPrint(
        '✅ Scheduled appointment reminder for: $title on the day itself',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling appointment reminder: $e');
    }
  }

  Future<void> cancelAppointmentNotifications(int appointmentId) async {
    try {
      // Cancel exact time notification
      await cancelNotification(appointmentId);

      // Cancel reminder notification (if exists)
      await cancelNotification(appointmentId + 1000);

      debugPrint(
        '✅ Cancelled appointment notifications for ID: $appointmentId',
      );
    } catch (e) {
      debugPrint('❌ Error cancelling appointment notifications: $e');
    }
  }

  // KEEP ALL YOUR EXISTING MEDICATION METHODS
  Future<void> scheduleBackgroundCompatibleReminder({
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
    required int id,
  }) async {
    try {
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _medicationChannelId,
            _medicationChannelName,
            channelDescription: 'Reminders for taking medications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
        threadIdentifier: 'medication-reminders',
      );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await notificationsPlugin.zonedSchedule(
        id,
        '💊 Medication Reminder',
        'Time to take $medicationName ($dosage)',
        scheduledDate,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medication_$id',
      );

      _scheduledNotificationIds.add(id);
      debugPrint(
        '✅ Background-compatible medication notification scheduled: ID $id',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling background medication notification: $e');
      await scheduleMedicationReminder(
        medicationName: medicationName,
        dosage: dosage,
        time: time,
        id: id,
      );
    }
  }

  Future<void> rescheduleAllMedications(
    List<Map<String, dynamic>> medications,
  ) async {
    await cancelAllNotifications();
    debugPrint('🔄 Rescheduling ${medications.length} medications');
    for (final medication in medications) {
      final timeString = medication['time'] as String?;
      if (timeString != null) {
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          try {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            final notificationId =
                '${medication['medication']}$timeString'.hashCode;
            await scheduleBackgroundCompatibleReminder(
              id: notificationId,
              medicationName: medication['medication'] ?? 'Unknown Medication',
              dosage: medication['dosage'] ?? '',
              time: TimeOfDay(hour: hour, minute: minute),
            );
            debugPrint(
              '✅ Rescheduled medication: ${medication['medication']} at $timeString',
            );
          } catch (e) {
            debugPrint(
              '❌ Error rescheduling medication ${medication['medication']}: $e',
            );
          }
        }
      }
    }
  }

  Future<void> scheduleTestNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(seconds: 30));
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _medicationChannelId,
          _medicationChannelName,
          channelDescription: 'Reminders for taking medications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.zonedSchedule(
      9999,
      '💊 Test Reminder',
      'This is a test scheduled notification',
      scheduledDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    _scheduledNotificationIds.remove(id);
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
    _scheduledNotificationIds.clear();
  }

  Set<int> get scheduledNotificationIds => _scheduledNotificationIds;

  bool isNotificationScheduled(int id) =>
      _scheduledNotificationIds.contains(id);

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
