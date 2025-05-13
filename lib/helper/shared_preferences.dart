import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  SharedPreferenceHelper._();

  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userTypeKey = 'userType';
  static const String _userStatusKey = 'userStatus';
  static const _keyInstallationId = 'installation_id';

  static SharedPreferences? _preferences;

  static Future<void> init() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SharedPreferences: $e');
      }
    }
  }

  static Future<SharedPreferences> _getInstance() async {
    if (_preferences == null) {
      await init();
    }
    if (_preferences == null) {
      throw Exception('Failed to initialize SharedPreferences');
    }
    return _preferences!;
  }

  static Future<bool> setLoggedIn(bool value) async {
    try {
      final prefs = await _getInstance();
      return await prefs.setBool(_isLoggedInKey, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting logged in status: $e');
      }
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await _getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking login status: $e');
      }
      return false;
    }
  }

  static Future<bool> setUserEmail(String email) async {
    try {
      final prefs = await _getInstance();
      return await prefs.setString(_userEmailKey, email);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user email: $e');
      }
      return false;
    }
  }

  static Future<String?> getUserEmail() async {
    try {
      final prefs = await _getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user email: $e');
      }
      return null;
    }
  }

  static Future<bool> setUserType(String userType) async {
    try {
      final prefs = await _getInstance();
      return await prefs.setString(_userTypeKey, userType);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user type: $e');
      }
      return false;
    }
  }

  static Future<String?> getUserType() async {
    try {
      final prefs = await _getInstance();
      return prefs.getString(_userTypeKey) ?? 'user'; // default to 'user'
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user type: $e');
      }
      return 'user';
    }
  }

  static Future<bool> setUserStatus(String status) async {
    try {
      final prefs = await _getInstance();
      return await prefs.setString(_userStatusKey, status);
    } catch (e) {
      if (kDebugMode) print('Error setting user status: $e');
      return false;
    }
  }

  static Future<String?> getUserStatus() async {
    try {
      final prefs = await _getInstance();
      return prefs.getString(_userStatusKey);
    } catch (e) {
      if (kDebugMode) print('Error getting user status: $e');
      return null;
    }
  }

  static Future<void> setInstallationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInstallationId, id);
  }

  static Future<String?> getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyInstallationId);
  }

  static Future<bool> clearSession() async {
    try {
      final prefs = await _getInstance();
      // Keep installation ID when clearing session
      return await Future.wait([
        prefs.remove(_isLoggedInKey),
        prefs.remove(_userEmailKey),
        prefs.remove(_userTypeKey),
        prefs.remove(_userStatusKey),
      ]).then((_) => true);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing session: $e');
      }
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      final prefs = await _getInstance();
      return await prefs.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all preferences: $e');
      }
      return false;
    }
  }
}