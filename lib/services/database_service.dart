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
    print("DatabaseService: Attempting to update user data for UID: $uid");
    try {
      await recoveryCollection.doc(uid).set({
        'name': name,
        'surgeryType': surgeryType,
        'surgeryDate': surgeryDate,
        'doctorName': doctorName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("DatabaseService: User data updated successfully for UID: $uid");
    } catch (e, stackTrace) {
      print("DatabaseService: Error updating user data for UID: $uid - $e\n$stackTrace");
      rethrow;
    }
  }

  // 2. PAIN TRACKING OPERATIONS
  // In lib/services/database_service.dart
  Future<void> addPainLevel(int painLevel, String notes) async {
    print("DatabaseService: Attempting to add pain level: $painLevel for UID: $uid");
    try {
      if (uid == null) {
        throw Exception('User ID is null - user not authenticated');
      }

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

      print("DatabaseService: Pain data saved successfully for UID: $uid!");
    } catch (error, stackTrace) {
      print("DatabaseService: Error saving pain data for UID: $uid - $error\n$stackTrace");
      rethrow;
    }
  }

  // 3. MEDICATION OPERATIONS
  // Medication-related methods
  Future<String> addMedication(
    String medication,
    String dosage,
    String time,
  ) async {
    print("DatabaseService: Attempting to add medication: $medication for UID: $uid");
    try {
      if (uid == null) throw Exception('User not authenticated');

      final docRef = await recoveryCollection.doc(uid).collection('medications').add({
        'medication': medication,
        'dosage': dosage,
        'time': time,
        'taken': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('DatabaseService: Medication added successfully with ID: ${docRef.id} for UID: $uid');
      return docRef.id;
    } catch (error, stackTrace) {
      print("DatabaseService: Error adding medication for UID: $uid - $error\n$stackTrace");
      rethrow;
    }
  }

  Future<void> updateMedication(String docId, bool taken) async {
    print("DatabaseService: Attempting to update medication status for docId: $docId to taken: $taken for UID: $uid");
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('medications')
          .doc(docId)
          .update({'taken': taken, 'updatedAt': FieldValue.serverTimestamp()});

      print('DatabaseService: Medication updated successfully for docId: $docId');
    } catch (error, stackTrace) {
      print("DatabaseService: Error updating medication for docId: $docId - $error\n$stackTrace");
      rethrow;
    }
  }

  Future<void> deleteMedication(String docId) async {
    print("DatabaseService: Attempting to delete medication with docId: $docId for UID: $uid");
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('medications')
          .doc(docId)
          .delete();

      print('DatabaseService: Medication deleted successfully for docId: $docId');
    } catch (error, stackTrace) {
      print("DatabaseService: Error deleting medication for docId: $docId - $error\n$stackTrace");
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
  Future<void> addExercise(String name, String duration, String frequency) async {
    print("DatabaseService: Attempting to add exercise: $name (Duration: $duration, Frequency: $frequency) for UID: $uid");
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection.doc(uid).collection('exercises').add({
        'name': name,
        'duration': duration,
        'frequency': frequency,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('DatabaseService: Exercise added successfully: $name for UID: $uid');
    } catch (error, stackTrace) {
      print("DatabaseService: Error adding exercise: $name for UID: $uid - $error\n$stackTrace");
      rethrow;
    }
  }

  Future<void> updateExerciseStatus(String docId, bool completed) async {
    print("DatabaseService: Attempting to update exercise status for docId: $docId to completed: $completed for UID: $uid");
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

      print('DatabaseService: Exercise status updated successfully for docId: $docId');
    } catch (error, stackTrace) {
      print("DatabaseService: Error updating exercise status for docId: $docId - $error\n$stackTrace");
      rethrow;
    }
  }

  Future<void> deleteExercise(String docId) async {
    print("DatabaseService: Attempting to delete exercise with docId: $docId for UID: $uid");
    try {
      if (uid == null) throw Exception('User not authenticated');

      await recoveryCollection
          .doc(uid)
          .collection('exercises')
          .doc(docId)
          .delete();

      print('DatabaseService: Exercise deleted successfully for docId: $docId');
    } catch (error, stackTrace) {
      print("DatabaseService: Error deleting exercise for docId: $docId - $error\n$stackTrace");
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
    print("DatabaseService: Attempting to delete all user data for UID: $uid");
    try {
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

      await batch.commit();
      print("DatabaseService: All user data deleted successfully for UID: $uid");
    } catch (error, stackTrace) {
      print("DatabaseService: Error deleting user data for UID: $uid - $error\n$stackTrace");
      rethrow;
    }
  }
}
