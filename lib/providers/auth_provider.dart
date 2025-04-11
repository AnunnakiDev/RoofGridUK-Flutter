import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roofgridk_app/utils/firebase_error_handler.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAuthenticated = false;
  User? _user;
  String? _userEmail;
  bool _isPro = false;

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  String? get userId => _user?.uid;
  String? get userEmail => _userEmail;
  bool get isPro => _isPro;

  AuthProvider() {
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isAuthenticated = user != null;
      _userEmail = user?.email;
      notifyListeners();
    });
    
    // Try to auto-login
    tryAutoLogin();
  }

  Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      _isAuthenticated = _user != null;
      _userEmail = _user?.email;
      
      // Store auth data for auto-login
      if (_isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isAuthenticated', true);
        
        // Check if user is pro
        await _checkProStatus();
      }
      
      notifyListeners();
      return _isAuthenticated;
    } on FirebaseAuthException catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      throw FirebaseAuthException(
        code: e.code,
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> register(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with display name
      await userCredential.user?.updateDisplayName(name);
      
      _user = userCredential.user;
      _isAuthenticated = _user != null;
      _userEmail = _user?.email;

      // Store auth data for auto-login
      if (_isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isAuthenticated', true);
      }
      
      notifyListeners();
      return _isAuthenticated;
    } on FirebaseAuthException catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      throw FirebaseAuthException(
        code: e.code,
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> tryAutoLogin() async {
    // Firebase Auth handles persistence by default
    // This will just check if we're already logged in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      _isAuthenticated = true;
      _userEmail = currentUser.email;
      
      // Check pro status
      await _checkProStatus();
      
      notifyListeners();
      return true;
    }
    
    return false;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      
      _isAuthenticated = false;
      _user = null;
      _userEmail = null;
      _isPro = false;

      final prefs = await SharedPreferences.getInstance();
      prefs.clear();

      notifyListeners();
    } catch (e) {
      // Handle logout errors
      rethrow;
    }
  }
  
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> _checkProStatus() async {
    // TODO: Implement checking if user has pro subscription from Firestore
    // This is a placeholder implementation
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('isPro') ?? false;
    notifyListeners();
  }
  
  Future<void> upgradeToProStatus() async {
    // TODO: Implement actual upgrade to pro logic with payment processing
    // This is a placeholder implementation for now
    _isPro = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isPro', true);
    notifyListeners();
  }
}
}
