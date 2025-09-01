import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recoveryplus/services/database_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _verificationId;
  int? _resendToken;

  User? get user => _user;
  String? get verificationId => _verificationId;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Email authentication methods
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      notifyListeners();
      return _user;
    } catch (error) {
      rethrow;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      notifyListeners();
      return _user;
    } catch (error) {
      rethrow;
    }
  }

  // Phone authentication methods
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<User?> signInWithOTP(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is null');
      }

      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      _user = result.user;
      notifyListeners();
      return _user;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _verificationId = null;
    _resendToken = null;
    notifyListeners();
  }

  // Check if user is logged in
  bool get isLoggedIn => _user != null;

  // Add this method to your existing AuthService class
  Future<void> saveUserDataAfterSignup(
    String name,
    String surgeryType,
    DateTime surgeryDate,
    String doctorName,
  ) async {
    if (_user == null) return;

    final databaseService = DatabaseService(uid: _user!.uid);
    await databaseService.updateUserData(
      name,
      surgeryType,
      surgeryDate,
      doctorName,
    );
  }
}
