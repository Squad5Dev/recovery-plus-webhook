// lib/services/export_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:recoveryplus/services/statistics_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportService {
  static Future<void> exportData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all user data
      final allData = await _fetchAllUserData(user.uid);

      // Convert to CSV
      final csvData = _convertToCSV(allData);

      // Save to file and share
      await _shareCSVFile(
        csvData,
        'recovery_data_${DateTime.now().toString().replaceAll(' ', '_')}.csv',
      );
    } catch (error) {
      print('Export error: $error');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _fetchAllUserData(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .get();

    final painLogs = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .collection('pain_logs')
        .orderBy('timestamp', descending: true)
        .get();

    final medications = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .get();

    final exercises = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(userId)
        .collection('exercises')
        .orderBy('createdAt', descending: true)
        .get();

    return {
      'user_data': userDoc.data(),
      'pain_logs': painLogs.docs.map((doc) => doc.data()).toList(),
      'medications': medications.docs.map((doc) => doc.data()).toList(),
      'exercises': exercises.docs.map((doc) => doc.data()).toList(),
    };
  }

  static String _convertToCSV(Map<String, dynamic> data) {
    final csvData = <List<dynamic>>[];

    // Add headers
    csvData.add(['Data Type', 'Date', 'Description', 'Value', 'Status']);

    // Add user data
    final userData = data['user_data'] as Map<String, dynamic>?;
    if (userData != null) {
      csvData.add([
        'User Profile',
        userData['createdAt']?.toDate().toString() ?? '',
        '${userData['name'] ?? ''} - ${userData['surgeryType'] ?? ''}',
        'Doctor: ${userData['doctorName'] ?? ''}',
        'Active',
      ]);
    }

    // Add pain logs
    final painLogs = data['pain_logs'] as List<dynamic>?;
    painLogs?.forEach((log) {
      csvData.add([
        'Pain Log',
        log['timestamp']?.toDate().toString() ?? '',
        log['notes'] ?? '',
        'Level: ${log['painLevel'] ?? 0}',
        'Recorded',
      ]);
    });

    // Add medications
    final medications = data['medications'] as List<dynamic>?;
    medications?.forEach((med) {
      csvData.add([
        'Medication',
        med['createdAt']?.toDate().toString() ?? '',
        med['medication'] ?? '',
        'Dosage: ${med['dosage'] ?? ''}',
        med['taken'] == true ? 'Taken' : 'Missed',
      ]);
    });

    // Add exercises
    final exercises = data['exercises'] as List<dynamic>?;
    exercises?.forEach((exercise) {
      csvData.add([
        'Exercise',
        exercise['createdAt']?.toDate().toString() ?? '',
        exercise['exercise'] ?? '',
        'Sets: ${exercise['sets'] ?? 0}, Reps: ${exercise['reps'] ?? 0}',
        exercise['completed'] == true ? 'Completed' : 'Pending',
      ]);
    });

    return const ListToCsvConverter().convert(csvData);
  }

  static Future<void> _shareCSVFile(String csvData, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Recovery Plus Data Export',
        text: 'Here is your health data export from Recovery Plus app.',
      );

      // Clean up after sharing
      await file.delete();
    } catch (error) {
      print('File sharing error: $error');
      rethrow;
    }
  }

  static Future<void> exportPainData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final painLogs = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(user.uid)
        .collection('pain_logs')
        .orderBy('timestamp', descending: true)
        .get();

    final csvData = _convertPainDataToCSV(
      painLogs.docs.map((doc) => doc.data()).toList(),
    );
    await _shareCSVFile(
      csvData,
      'pain_data_${DateTime.now().toString().replaceAll(' ', '_')}.csv',
    );
  }

  static String _convertPainDataToCSV(List<dynamic> painLogs) {
    final csvData = <List<dynamic>>[];

    csvData.add(['Date', 'Pain Level', 'Notes', 'Location', 'Activities']);

    painLogs.forEach((log) {
      csvData.add([
        log['timestamp']?.toDate().toString() ?? '',
        log['painLevel'] ?? 0,
        log['notes'] ?? '',
        log['location'] ?? '',
        log['activities'] ?? '',
      ]);
    });

    return const ListToCsvConverter().convert(csvData);
  }

  static Future<void> exportMedicationData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final medications = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(user.uid)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .get();

    final csvData = _convertMedicationDataToCSV(
      medications.docs.map((doc) => doc.data()).toList(),
    );
    await _shareCSVFile(
      csvData,
      'medication_data_${DateTime.now().toString().replaceAll(' ', '_')}.csv',
    );
  }

  static String _convertMedicationDataToCSV(List<dynamic> medications) {
    final csvData = <List<dynamic>>[];

    csvData.add(['Medication', 'Dosage', 'Time', 'Status', 'Last Taken']);

    medications.forEach((med) {
      csvData.add([
        med['medication'] ?? '',
        med['dosage'] ?? '',
        med['time'] ?? '',
        med['taken'] == true ? 'Taken' : 'Missed',
        med['lastTaken']?.toDate().toString() ?? '',
      ]);
    });

    return const ListToCsvConverter().convert(csvData);
  }

  // Add these methods to your existing ExportService class
  static Future<void> exportStatisticsReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final statistics = await StatisticsService.getRecoveryStatistics();
      final weeklyProgress = await StatisticsService.getWeeklyProgress();

      final csvData = _convertStatisticsToCSV(statistics, weeklyProgress);

      await _shareCSVFile(
        csvData,
        'recovery_statistics_${DateTime.now().toString().replaceAll(' ', '_')}.csv',
      );
    } catch (error) {
      print('Statistics export error: $error');
      rethrow;
    }
  }

  static String _convertStatisticsToCSV(
    Map<String, dynamic> statistics,
    List<Map<String, dynamic>> weeklyProgress,
  ) {
    final csvData = <List<dynamic>>[];

    // Header
    csvData.add(['RECOVERY PLUS - STATISTICS REPORT']);
    csvData.add(['Generated on: ${DateTime.now()}']);
    csvData.add([]);

    // Overall Score
    csvData.add(['OVERALL RECOVERY SCORE']);
    csvData.add([
      'Score',
      '${statistics['overall_recovery_score']?.toStringAsFixed(1) ?? "0"}%',
    ]);
    csvData.add([
      'Description',
      _getScoreDescription(statistics['overall_recovery_score'] ?? 0),
    ]);
    csvData.add([]);

    // Pain Statistics
    final pain = statistics['pain'] as Map<String, dynamic>?;
    if (pain != null) {
      csvData.add(['PAIN ANALYSIS']);
      csvData.add([
        'Average Pain',
        '${pain['average_pain']?.toStringAsFixed(1) ?? "0"}/10',
      ]);
      csvData.add([
        'Highest Pain',
        '${pain['max_pain']?.toStringAsFixed(1) ?? "0"}/10',
      ]);
      csvData.add([
        'Lowest Pain',
        '${pain['min_pain']?.toStringAsFixed(1) ?? "0"}/10',
      ]);
      csvData.add(['Trend', pain['trend_description']]);
      csvData.add(['Total Entries', pain['total_entries']]);
      csvData.add([]);
    }

    // Medication Statistics
    final meds = statistics['medications'] as Map<String, dynamic>?;
    if (meds != null) {
      csvData.add(['MEDICATION ADHERENCE']);
      csvData.add([
        'Adherence Rate',
        '${meds['adherence_rate']?.toStringAsFixed(1) ?? "0"}%',
      ]);
      csvData.add(['Level', meds['adherence_level']]);
      csvData.add([
        'Taken',
        '${meds['taken_medications']}/${meds['total_medications']}',
      ]);
      csvData.add(['Missed', meds['missed_medications']]);
      csvData.add([]);
    }

    // Exercise Statistics
    final exercises = statistics['exercises'] as Map<String, dynamic>?;
    if (exercises != null) {
      csvData.add(['EXERCISE PROGRESS']);
      csvData.add([
        'Completion Rate',
        '${exercises['completion_rate']?.toStringAsFixed(1) ?? "0"}%',
      ]);
      csvData.add(['Level', exercises['completion_level']]);
      csvData.add([
        'Completed',
        '${exercises['completed_exercises']}/${exercises['total_exercises']}',
      ]);
      csvData.add(['Pending', exercises['pending_exercises']]);
      csvData.add([]);
    }

    // Weekly Progress
    if (weeklyProgress.isNotEmpty) {
      csvData.add(['WEEKLY PAIN TREND']);
      csvData.add(['Week', 'Average Pain', 'Entries']);
      weeklyProgress.forEach((week) {
        csvData.add([
          week['week'],
          week['average_pain']?.toStringAsFixed(1) ?? "0",
          week['entries'],
        ]);
      });
    }

    return const ListToCsvConverter().convert(csvData);
  }

  static String _getScoreDescription(double score) {
    if (score >= 90) return 'Excellent recovery - You\'re doing amazing!';
    if (score >= 75) return 'Great progress - Keep up the good work!';
    if (score >= 60) return 'Good recovery - Steady improvement';
    if (score >= 40) return 'Fair progress - Room for improvement';
    return 'Needs attention - Consult your healthcare provider';
  }

  // Add to your existing ExportService class
  static Future<void> exportPhotoData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final photos = await FirebaseFirestore.instance
        .collection('recovery_data')
        .doc(user.uid)
        .collection('recovery_photos')
        .orderBy('timestamp', descending: true)
        .get();

    final csvData = _convertPhotoDataToCSV(
      photos.docs.map((doc) => doc.data()).toList(),
    );

    await _shareCSVFile(
      csvData,
      'photo_documentation_${DateTime.now().toString().replaceAll(' ', '_')}.csv',
    );
  }

  static String _convertPhotoDataToCSV(List<dynamic> photos) {
    final csvData = <List<dynamic>>[];

    csvData.add(['Title', 'Description', 'Date', 'Image URL']);

    photos.forEach((photo) {
      csvData.add([
        photo['title'] ?? '',
        photo['description'] ?? '',
        photo['timestamp']?.toDate().toString() ?? '',
        photo['imageUrl'] ?? '',
      ]);
    });

    return const ListToCsvConverter().convert(csvData);
  }
}
