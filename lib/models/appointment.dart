// models/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String? userName;
  final int? userAge; // NEW: Add userAge field
  final String? userGender;
  final String title;
  final String doctorName;
  final String location;
  final String hospitalContact; // Add this field
  final String? userContact;
  final String? medicalHistory;
  final String notes;
  final DateTime dateTime;
  final bool isCompleted;

  Appointment({
    required this.id,
    required this.userId,
    this.userName,
    this.userAge, // NEW: Add userAge parameter
    this.userGender,
    this.medicalHistory,
    required this.title,
    required this.doctorName,
    required this.location,
    required this.hospitalContact,
    this.userContact, // Add this parameter
    required this.notes,
    required this.dateTime,
    this.isCompleted = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAge': userAge, // NEW: Save userAge
      'userGender': userGender,
      'title': title,
      'doctorName': doctorName,
      'location': location,
      'hospitalContact': hospitalContact,
      'userContact': userContact,
      'notes': notes,
      'dateTime': Timestamp.fromDate(dateTime), // Always store as Timestamp
      'isCompleted': isCompleted,
    };
  }

  // Create from Map from Firestore
  static Appointment fromMap(Map<String, dynamic> map, String id) {
    print('Creating appointment from map: $map');

    // Handle DateTime conversion carefully
    DateTime dateTime;
    try {
      if (map['dateTime'] is Timestamp) {
        dateTime = (map['dateTime'] as Timestamp).toDate();
      } else if (map['dateTime'] is DateTime) {
        dateTime = map['dateTime'] as DateTime;
      } else if (map['dateTime'] is String) {
        dateTime = DateTime.parse(map['dateTime'] as String);
      } else {
        print('Warning: Invalid dateTime format, using current time');
        dateTime = DateTime.now();
      }
    } catch (e) {
      print('Error parsing dateTime: $e');
      dateTime = DateTime.now();
    }

    return Appointment(
      id: id,
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userAge: map['userAge'] != null
          ? int.tryParse(map['userAge'].toString())
          : null, // NEW: Load userAge
      userGender: map['userGender'],
      medicalHistory: map['medicalHistory'],
      title: map['title']?.toString() ?? '',
      doctorName: map['doctorName']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      hospitalContact: map['hospitalContact'] ?? '',
      userContact: map['userContact']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      dateTime: dateTime,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // Copy with method for updates
  Appointment copyWith({
    String? title,
    String? doctorName,
    String? location,
    String? notes,
    DateTime? dateTime,
    bool? isCompleted,
  }) {
    return Appointment(
      id: id,
      userId: userId,
      userName: userName,
      userAge: userAge,
      userGender: userGender,
      medicalHistory: medicalHistory,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      location: location ?? this.location,
      hospitalContact: hospitalContact ?? this.hospitalContact,
      userContact: userContact ?? this.userContact,
      notes: notes ?? this.notes,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
