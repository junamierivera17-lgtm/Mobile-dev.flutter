import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _userSessionKey = 'user_session';

  AuthProvider() {
    _loadUserFromSession();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<User?> login(String id, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await DatabaseService.getUserById(id);

      if (user != null && user.password == password) {
        _currentUser = user;
        await _saveUserToSession(user);
        return user;
      }
      return null; // Return null if login fails
    } catch (e) {
      _error = 'An error occurred during login: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _currentUser = null;
    
    // Clear user session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userSessionKey);
    
    _setLoading(false);
  }

  Future<void> _saveUserToSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userSessionKey, userJson);
  }

  Future<void> _loadUserFromSession() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userSessionKey);

    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = User.fromJson(userData);
      } catch (e) {
        // Handle potential JSON decoding errors
        _error = 'Failed to load user session: $e';
        _currentUser = null;
      }
    }
    _setLoading(false);
  }
}
