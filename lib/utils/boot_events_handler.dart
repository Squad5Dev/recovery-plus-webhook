import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:recoveryplus/services/notification_service.dart';
import 'package:recoveryplus/services/auth_service.dart';
import 'package:recoveryplus/services/database_service.dart';
import 'package:recoveryplus/models/appointment.dart';

Future<void> handleBootEvents(NotificationService notificationService, AuthService authService) async {
  final prefs = await SharedPreferences.getInstance();
  final lastScheduleTime = prefs.getInt('last_schedule_time') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;

  // Only reschedule if a significant amount of time has passed (e.g., 1 hour)
  // or if the app was likely killed/device rebooted.
  if (now - lastScheduleTime > 3600000) {
    debugPrint('[BootEventsHandler] 🔄 Device reboot detected or app restarted, rescheduling notifications...');

    // Wait for Firebase auth state to be resolved using AuthService's userLoaded future
    User? user = await authService.userLoaded;
    String? uidToReschedule = user?.uid;

    if (uidToReschedule == null) {
      // If no user is currently logged in, try to get the last logged-in UID from SharedPreferences
      final storedUid = prefs.getString('last_logged_in_uid');
      if (storedUid != null) {
        uidToReschedule = storedUid;
        debugPrint('[BootEventsHandler] ℹ️ No active user, but found last logged-in UID: $uidToReschedule. Attempting to reschedule.');
      } else {
        debugPrint('[BootEventsHandler] ℹ️ No user logged in and no last logged-in UID found, skipping notification rescheduling.');
        await prefs.setInt('last_schedule_time', now);
        return;
      }
    }

    final databaseService = DatabaseService(uid: uidToReschedule!);
    debugPrint('[BootEventsHandler] Cancelling all previous notifications...');
    await notificationService.cancelAllNotifications(); // Clear any old notifications
    debugPrint('[BootEventsHandler] All previous notifications cancelled.');

    try {
      // 1. Reschedule Medications
      final medicationSnapshot = await databaseService.getMedications();
      if (medicationSnapshot.docs.isNotEmpty) {
        for (var doc in medicationSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timeString = data['time'] as String?;
          if (timeString != null) {
            final timeParts = timeString.split(':');
            if (timeParts.length == 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              debugPrint('[BootEventsHandler] Rescheduling medication reminder for: ${data['medication']}');
              await notificationService.scheduleBackgroundCompatibleReminder(
                docId: doc.id,
                medicationName: data['medication'] ?? 'Unknown Medication',
                dosage: data['dosage'] ?? '',
                time: TimeOfDay(hour: hour, minute: minute),
              );
              debugPrint('[BootEventsHandler] ✅ Rescheduled medication: ${data['medication']} at $timeString');
            }
          }
        }
      } else {
        debugPrint('[BootEventsHandler] ℹ️ No medications found to reschedule.');
      }

      // 2. Reschedule Appointments
      final appointmentQuerySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: uidToReschedule)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dateTime')
          .get();

      if (appointmentQuerySnapshot.docs.isNotEmpty) {
        for (var doc in appointmentQuerySnapshot.docs) {
          final appointment = Appointment.fromMap(doc.data(), doc.id);
          // Only schedule if the appointment is in the future
          if (appointment.dateTime.isAfter(DateTime.now())) {
            debugPrint('[BootEventsHandler] Rescheduling appointment reminder for: ${appointment.title}');
            await notificationService.scheduleAppointmentReminderSingle(
              id: appointment.id.hashCode,
              title: appointment.title,
              doctorName: appointment.doctorName,
              location: appointment.location,
              scheduledDate: appointment.dateTime,
              reminderTime: const TimeOfDay(hour: 9, minute: 0), // Default 9 AM
            );
            debugPrint('[BootEventsHandler] ✅ Rescheduled appointment: ${appointment.title} on ${appointment.dateTime}');
          } else {
            debugPrint('[BootEventsHandler] ⏭️ Skipping appointment reschedule for "${appointment.title}" because it is in the past.');
          }
        }
      } else {
        debugPrint('[BootEventsHandler] ℹ️ No upcoming appointments found to reschedule.');
      }
    } catch (e) {
      debugPrint('[BootEventsHandler] ❌ Error during notification rescheduling: $e');
    }
  } else {
    debugPrint('[BootEventsHandler] ⏭️ Skipping notification reschedule because it ran recently.');
  }
  await prefs.setInt('last_schedule_time', now);
}