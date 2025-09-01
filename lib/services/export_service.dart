import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // Add this import for utf8 encoding

class ExportService {
  static Future<void> exportData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all user data
      final userData = await _fetchAllData(user.uid);

      // Convert to CSV format
      final csvData = _convertToCSV(userData);

      // Convert string to bytes using utf8 encoding
      final csvBytes = utf8.encode(csvData);

      // Share the file
      await Share.shareXFiles([
        XFile.fromData(
          csvBytes, // Use the encoded bytes instead of codeUnits
          mimeType: 'text/csv',
          name: 'recovery_data_${DateTime.now().millisecondsSinceEpoch}.csv',
        ),
      ]);
    } catch (error) {
      print('Export error: $error');
    }
  }

  static Future<Map<String, dynamic>> _fetchAllData(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .get();

    final painLogs = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .collection('pain_logs')
        .get();

    final medications = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .collection('medications')
        .get();

    final exercises = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .collection('exercises')
        .get();

    return {
      'user_data': userDoc.data(),
      'pain_logs': painLogs.docs.map((doc) => doc.data()).toList(),
      'medications': medications.docs.map((doc) => doc.data()).toList(),
      'exercises': exercises.docs.map((doc) => doc.data()).toList(),
    };
  }

  static String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Add headers
    buffer.writeln('Data Type,Date,Description,Value');

    // Add pain logs
    for (final log in data['pain_logs'] ?? []) {
      buffer.writeln(
        'Pain,${log['timestamp']},${log['notes']},${log['painLevel']}',
      );
    }

    // Add medications
    for (final med in data['medications'] ?? []) {
      buffer.writeln(
        'Medication,${med['createdAt']},${med['medication']},${med['dosage']}',
      );
    }

    // Add exercises
    for (final exercise in data['exercises'] ?? []) {
      buffer.writeln(
        'Exercise,${exercise['createdAt']},${exercise['exercise']},Sets: ${exercise['sets']} Reps: ${exercise['reps']}',
      );
    }

    return buffer.toString();
  }
}
