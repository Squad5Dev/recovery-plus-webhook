import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Reference to the Firestore collection
  final CollectionReference recoveryCollection = FirebaseFirestore.instance
      .collection('recovery_data');

  // 1. USER DATA OPERATIONS
  Future<void> updateUserData(
    String name,
    String surgeryType,
    DateTime surgeryDate,
    String doctorName,
  ) async {
    return await recoveryCollection.doc(uid).set({
      'name': name,
      'surgeryType': surgeryType,
      'surgeryDate': surgeryDate,
      'doctorName': doctorName,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 2. PAIN TRACKING OPERATIONS
  // In lib/services/database_service.dart
  Future<void> addPainLevel(int painLevel, String notes) async {
    try {
      print('🔍 Saving pain level: $painLevel');

      if (uid == null) {
        throw Exception('User ID is null - user not authenticated');
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(uid)
          .collection('pain_logs')
          .doc() // Auto-generated ID
          .set({
            'painLevel': painLevel,
            'notes': notes,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': uid,
          });

      print('✅ Pain data saved successfully!');
    } catch (error) {
      print('❌ Error saving pain data: $error');
      rethrow;
    }
  }

  // 3. MEDICATION OPERATIONS
  // Medication-related methods
  Future<void> addMedication(
    String medication,
    String dosage,
    String time,
  ) async {
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection.doc(uid).collection('medications').add({
        'medication': medication,
        'dosage': dosage,
        'time': time,
        'taken': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Medication added successfully');
    } catch (error) {
      print('❌ Error adding medication: $error');
      rethrow;
    }
  }

  Future<void> updateMedication(String docId, bool taken) async {
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('medications')
          .doc(docId)
          .update({'taken': taken, 'updatedAt': FieldValue.serverTimestamp()});

      print('✅ Medication updated successfully');
    } catch (error) {
      print('❌ Error updating medication: $error');
      rethrow;
    }
  }

  Future<void> deleteMedication(String docId) async {
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('medications')
          .doc(docId)
          .delete();

      print('✅ Medication deleted successfully');
    } catch (error) {
      print('❌ Error deleting medication: $error');
      rethrow;
    }
  }

  Stream<QuerySnapshot> get medicationsStream {
    if (uid == null) throw Exception('User not authenticated');

    return recoveryCollection
        .doc(uid)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 4. EXERCISE OPERATIONS
  // Exercise-related methods
  Future<void> addExercise(String exercise, int sets, int reps) async {
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection.doc(uid).collection('exercises').add({
        'exercise': exercise,
        'sets': sets,
        'reps': reps,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Exercise added successfully');
    } catch (error) {
      print('❌ Error adding exercise: $error');
      rethrow;
    }
  }

  Future<void> updateExerciseStatus(String docId, bool completed) async {
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('exercises')
          .doc(docId)
          .update({
            'completed': completed,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Exercise updated successfully');
    } catch (error) {
      print('❌ Error updating exercise: $error');
      rethrow;
    }
  }

  Future<void> deleteExercise(String docId) async {
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('exercises')
          .doc(docId)
          .delete();

      print('✅ Exercise deleted successfully');
    } catch (error) {
      print('❌ Error deleting exercise: $error');
      rethrow;
    }
  }

  Stream<QuerySnapshot> get exercisesStream {
    if (uid == null) throw Exception('User not authenticated');

    return recoveryCollection
        .doc(uid)
        .collection('exercises')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 5. REAL-TIME STREAMS
  Stream<DocumentSnapshot> get userData {
    return recoveryCollection.doc(uid).snapshots();
  }

  Stream<QuerySnapshot> get painLogs {
    return recoveryCollection
        .doc(uid)
        .collection('pain_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> get medications {
    return recoveryCollection
        .doc(uid)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> get exercises {
    return recoveryCollection
        .doc(uid)
        .collection('exercises')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getExercisesByPhase(String phase) {
    return recoveryCollection
        .doc(uid)
        .collection('exercises')
        .where('phase', isEqualTo: phase)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 6. GET METHODS
  Future<DocumentSnapshot> getUserData() async {
    return await recoveryCollection.doc(uid).get();
  }

  Future<QuerySnapshot> getMedications() async {
    return await recoveryCollection
        .doc(uid)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot> getExercises() async {
    return await recoveryCollection
        .doc(uid)
        .collection('exercises')
        .orderBy('createdAt', descending: true)
        .get();
  }

  // 7. DELETE METHODS
  Future<void> deleteUserData() async {
    // Delete all user data (for account deletion)
    final batch = FirebaseFirestore.instance.batch();

    // Delete subcollections
    final medications = await recoveryCollection
        .doc(uid)
        .collection('medications')
        .get();
    for (var doc in medications.docs) {
      batch.delete(doc.reference);
    }

    final exercises = await recoveryCollection
        .doc(uid)
        .collection('exercises')
        .get();
    for (var doc in exercises.docs) {
      batch.delete(doc.reference);
    }

    final painLogs = await recoveryCollection
        .doc(uid)
        .collection('pain_logs')
        .get();
    for (var doc in painLogs.docs) {
      batch.delete(doc.reference);
    }

    // Delete main document
    batch.delete(recoveryCollection.doc(uid));

    return await batch.commit();
  }
}
