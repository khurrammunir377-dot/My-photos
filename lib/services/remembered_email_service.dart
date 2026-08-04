import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last email used to log in on this device, even after
/// logout, so the login screen can offer a quick "Continue as..." instead
/// of an empty form every time.
class RememberedEmailService {
  static const _key = 'last_used_email';

  Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> save(String email) async {
    if (email.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, email.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
