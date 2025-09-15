import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recoveryplus/services/database_service.dart';
import 'dart:async'; // Added import
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _verificationId;
  int? _resendToken;

  final Completer<User?> _userLoadedCompleter = Completer<User?>(); // Added completer

  User? get user => _user;
  String? get verificationId => _verificationId;
  Future<User?> get userLoaded => _userLoadedCompleter.future; // Added getter

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      debugPrint('[AuthService] Auth state changed. User: ${user?.uid}');
      _user = user;
      notifyListeners();
      if (!_userLoadedCompleter.isCompleted) { // Complete only once
        _userLoadedCompleter.complete(user);
      }
    });
  }

  // Email authentication methods
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      debugPrint('[AuthService] Attempting to sign up with email: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      if (_user != null) {
        debugPrint('[AuthService] Sign up successful. User ID: ${_user!.uid}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_logged_in_uid', _user!.uid);
      }
      notifyListeners();
      return _user;
    } catch (error) {
      debugPrint('[AuthService] ❌ Error during email sign up: $error');
      rethrow;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('[AuthService] Attempting to sign in with email: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      if (_user != null) {
        debugPrint('[AuthService] Sign in successful. User ID: ${_user!.uid}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_logged_in_uid', _user!.uid);
      }
      notifyListeners();
      return _user;
    } catch (error) {
      debugPrint('[AuthService] ❌ Error during email sign in: $error');
      rethrow;
    }
  }

  // Phone authentication methods
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      debugPrint('[AuthService] Attempting to verify phone number: $phoneNumber');
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[AuthService] Phone verification completed automatically. Signing in...');
          await _auth.signInWithCredential(credential);
          debugPrint('[AuthService] Auto sign in successful.');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[AuthService] ❌ Phone verification failed: ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[AuthService] Verification code sent. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[AuthService] Code auto retrieval timeout. Verification ID: $verificationId');
          _verificationId = verificationId;
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (error) {
      debugPrint('[AuthService] ❌ Error in verifyPhoneNumber: $error');
      rethrow;
    }
  }

  Future<User?> signInWithOTP(String smsCode) async {
    try {
      debugPrint('[AuthService] Attempting to sign in with OTP.');
      if (_verificationId == null) {
        debugPrint('[AuthService] ❌ Verification ID is null.');
        throw Exception('Verification ID is null');
      }

      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      _user = result.user;
      if (_user != null) {
        debugPrint('[AuthService] Sign in with OTP successful. User ID: ${_user!.uid}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_logged_in_uid', _user!.uid);
      }
      notifyListeners();
      return _user;
    } catch (error) {
      debugPrint('[AuthService] ❌ Error during OTP sign in: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('[AuthService] Attempting to sign out user: ${_user?.uid}');
    await _auth.signOut();
    _user = null;
    _verificationId = null;
    _resendToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_logged_in_uid');
    debugPrint('[AuthService] Sign out successful.');
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
    debugPrint('[AuthService] Saving user data after sign up for user: ${_user?.uid}');
    if (_user == null) {
      debugPrint('[AuthService] ❌ Cannot save user data, user is null.');
      return;
    }

    final databaseService = DatabaseService(uid: _user!.uid);
    await databaseService.updateUserData(
      name,
      surgeryType,
      surgeryDate,
      doctorName,
    );
    debugPrint('[AuthService] User data saved successfully.');
  }
}
