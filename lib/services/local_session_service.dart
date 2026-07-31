import 'package:shared_preferences/shared_preferences.dart';

/// Stand-in for Firebase Auth while [AppConstants.kFirebaseEnabled] is false.
/// Stores a simple "logged in" flag and email locally on the device - no
/// real accounts, no network calls, nothing shared across devices. This lets
/// you test the rest of the app (folders, camera, filters, gallery) without
/// needing a Firebase project set up yet.
class LocalSessionService {
  static const _keyLoggedIn = 'local_logged_in';
  static const _keyEmail = 'local_user_email';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<void> login(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, email.trim());
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
  }
}
