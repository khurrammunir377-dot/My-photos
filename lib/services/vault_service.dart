import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Vault's PIN and unlock state.
///
/// The unlock state is intentionally kept in memory only (not persisted) -
/// it resets every time the app is fully closed and reopened, which is the
/// expected/secure behavior for a private vault (same as most "private
/// photo vault" apps: unlocking is per-session, not sticky forever).
class VaultService {
  VaultService._internal();
  static final VaultService instance = VaultService._internal();

  static const _pinHashKey = 'vault_pin_hash';
  bool _unlockedThisSession = false;

  bool get isUnlocked => _unlockedThisSession;

  void lock() => _unlockedThisSession = false;

  Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinHashKey) != null;
  }

  String _hash(String pin) {
    return sha256.convert(utf8.encode('vault_salt_v1_$pin')).toString();
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hash(pin));
    _unlockedThisSession = true;
  }

  Future<bool> checkPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinHashKey);
    if (stored == null) return false;
    final matches = stored == _hash(pin);
    if (matches) _unlockedThisSession = true;
    return matches;
  }

  Future<void> changePin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hash(newPin));
  }

  Future<void> resetVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
    _unlockedThisSession = false;
  }
}
