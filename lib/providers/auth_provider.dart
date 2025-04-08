import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _userId;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get userEmail => _userEmail;

  Future<bool> login(String email, String password) async {
    // TODO: Implement actual login API call
    try {
      // Simulating a successful login for now
      _token = 'dummy_token';
      _userId = 'user_123';
      _userEmail = email;
      _isAuthenticated = true;

      // Store auth data
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
      prefs.setString('userId', _userId!);
      prefs.setString('userEmail', _userEmail!);

      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _userEmail = prefs.getString('userEmail');
    _isAuthenticated = true;

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userEmail = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

    notifyListeners();
  }
}
