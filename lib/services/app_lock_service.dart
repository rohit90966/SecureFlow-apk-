import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _pinKey = 'app_lock_pin';
  static const String _patternKey = 'app_lock_pattern';
  static const String _lockTypeKey = 'app_lock_type';
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _lockTimeoutKey = 'app_lock_timeout';
  static const String _lastUnlockKey = 'last_unlock_timestamp';

  // Lock types
  static const String lockTypeNone = 'none';
  static const String lockTypePIN = 'pin';
  static const String lockTypePattern = 'pattern';

  // Timeout options (in minutes)
  static const List<int> timeoutOptions = [0, 1, 5, 10, 30];

  Future<void> initialize() async {
    // Ensure encryption keys are available
    await _secureStorage.read(key: _pinKey);
  }

  // Check if app lock is enabled
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  // Get current lock type
  Future<String> getLockType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockTypeKey) ?? lockTypeNone;
  }

  // Enable PIN lock
  Future<bool> enablePINLock(String pin) async {
    try {
      if (pin.length != 4) {
        throw Exception('PIN must be 4 digits');
      }

      await _secureStorage.write(key: _pinKey, value: pin);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockTypeKey, lockTypePIN);
      await prefs.setBool(_lockEnabledKey, true);
      await _updateLastUnlockTime();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Enable Pattern lock
  Future<bool> enablePatternLock(List<int> pattern) async {
    try {
      if (pattern.length < 4) {
        throw Exception('Pattern must have at least 4 points');
      }

      final patternString = pattern.join(',');
      await _secureStorage.write(key: _patternKey, value: patternString);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockTypeKey, lockTypePattern);
      await prefs.setBool(_lockEnabledKey, true);
      await _updateLastUnlockTime();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Disable app lock
  Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.setString(_lockTypeKey, lockTypeNone);
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _patternKey);
  }

  // Verify PIN
  Future<bool> verifyPIN(String pin) async {
    try {
      final storedPIN = await _secureStorage.read(key: _pinKey);
      if (storedPIN == pin) {
        await _updateLastUnlockTime();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Verify Pattern
  Future<bool> verifyPattern(List<int> pattern) async {
    try {
      final storedPattern = await _secureStorage.read(key: _patternKey);
      final patternString = pattern.join(',');
      if (storedPattern == patternString) {
        await _updateLastUnlockTime();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if app should be locked
  Future<bool> shouldShowLock() async {
    final isEnabled = await isLockEnabled();
    if (!isEnabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastUnlock = prefs.getInt(_lastUnlockKey);
    final timeout = prefs.getInt(_lockTimeoutKey) ?? 0;

    if (lastUnlock == null) return true;

    // If timeout is 0, always lock
    if (timeout == 0) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastUnlock;
    final timeoutMs = timeout * 60 * 1000; // Convert minutes to milliseconds

    return difference > timeoutMs;
  }

  // Set lock timeout
  Future<void> setLockTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lockTimeoutKey, minutes);
  }

  // Get current timeout
  Future<int> getLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lockTimeoutKey) ?? 0;
  }

  // Update last unlock time
  Future<void> _updateLastUnlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUnlockKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Clear all lock data (for logout)
  Future<void> clearLockData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockEnabledKey);
    await prefs.remove(_lockTypeKey);
    await prefs.remove(_lockTimeoutKey);
    await prefs.remove(_lastUnlockKey);
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _patternKey);
  }
}