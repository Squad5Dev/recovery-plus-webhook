// services/appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recoveryplus/models/appointment.dart';
import 'package:recoveryplus/services/notification_service.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Get all appointments for a user
  static Stream<List<Appointment>> getAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Appointment.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            } catch (e) {
              print('Error parsing appointment ${doc.id}: $e');
              return Appointment(
                id: doc.id,
                userId: userId,
                title: 'Error loading',
                doctorName: '',
                location: '',
                hospitalContact: '',
                notes: '',
                dateTime: DateTime.now(),
                isCompleted: false,
              );
            }
          }).toList();
        })
        .handleError((error) {
          print('Error in appointments stream: $error');
          return [];
        });
  }

  // Get upcoming appointments
  static Stream<List<Appointment>> getUpcomingAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .where(
          'dateTime',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(Duration(hours: 24)),
          ),
        )
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
          final appointments = snapshot.docs.map((doc) {
            return Appointment.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return appointments;
        })
        .handleError((error) {
          print('Stream error: $error');
          return [];
        });
  }

  // Add a new appointment with notification
  static Future<void> addAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());

      // Schedule appointment notification - FIXED METHOD NAME
      await _notificationService.scheduleAppointmentReminder(
        id: appointment.id.hashCode, // Use appointment ID as base
        title: appointment.title,
        doctorName: appointment.doctorName,
        location: appointment.location,
        scheduledDate: appointment.dateTime,
        reminderTime: TimeOfDay(hour: 9, minute: 0), // 9:00 AM daily
      );
      // OR for single reminder on appointment day only:
      await _notificationService.scheduleAppointmentReminderSingle(
        id: appointment.id.hashCode,
        title: appointment.title,
        doctorName: appointment.doctorName,
        location: appointment.location,
        scheduledDate: appointment.dateTime,
        reminderTime: TimeOfDay(
          hour: 9,
          minute: 0,
        ), // 9:00 AM on appointment day
      );
    } catch (e) {
      print('Error adding appointment: $e');
      throw Exception('Failed to add appointment');
    }
  }

  // Update an existing appointment with notification
  static Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(appointment.toMap());

      // Cancel old notification and schedule new one - FIXED METHOD NAME
      await _notificationService.cancelAppointmentNotifications(
        appointment.id.hashCode,
      );

      await _notificationService.scheduleAppointmentReminder(
        id: appointment.id.hashCode,
        title: appointment.title,
        doctorName: appointment.doctorName,
        location: appointment.location,
        scheduledDate: appointment.dateTime,
      );
    } catch (e) {
      print('Error updating appointment: $e');
      throw Exception('Failed to update appointment');
    }
  }

  // Delete an appointment with notification cancellation
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();

      // Cancel notification - FIXED METHOD NAME
      await _notificationService.cancelAppointmentNotifications(
        appointmentId.hashCode,
      );
    } catch (e) {
      print('Error deleting appointment: $e');
      throw Exception('Failed to delete appointment');
    }
  }

  // Mark appointment as completed with notification cancellation
  static Future<void> markAsCompleted(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'isCompleted': true,
      });

      // Cancel notification since appointment is completed - FIXED METHOD NAME
      await _notificationService.cancelAppointmentNotifications(
        appointmentId.hashCode,
      );
    } catch (e) {
      print('Error marking appointment as completed: $e');
      throw Exception('Failed to mark appointment as completed');
    }
  }
}
