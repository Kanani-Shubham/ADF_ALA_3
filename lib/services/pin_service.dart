import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const String _pinKey = 'secure_notes_pin';
  static const String _lockEnabledKey = 'secure_notes_lock_enabled';

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_pinKey) ?? '').isNotEmpty;
  }

  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  static Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  static Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_lockEnabledKey, true);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) == pin;
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_lockEnabledKey, false);
  }
}
