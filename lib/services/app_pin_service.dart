import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPinService {
  static final AppPinService _instance = AppPinService._internal();
  factory AppPinService() => _instance;
  AppPinService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinKey = 'app_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinSetupCompletedKey = 'pin_setup_completed';
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _lastAttemptKey = 'last_attempt_time';
  static const String _isLockedKey = 'is_locked';

  // Check if PIN is enabled
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  // Check if PIN setup is completed
  Future<bool> isPinSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetupCompletedKey) ?? false;
  }

  // Set PIN
  Future<bool> setPin(String pin) async {
    try {
      await _secureStorage.write(key: _pinKey, value: pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pinEnabledKey, true);
      await prefs.setBool(_pinSetupCompletedKey, true);
      await resetAttempts(); // Reset attempts when setting new PIN
      return true;
    } catch (e) {
      print('Error setting PIN: $e');
      return false;
    }
  }

  // Verify PIN with security features
  Future<bool> verifyPin(String pin) async {
    try {
      // Check if locked
      if (await isLocked()) {
        return false;
      }

      final storedPin = await _secureStorage.read(key: _pinKey);
      final isCorrect = storedPin == pin;

      if (isCorrect) {
        await resetAttempts();
        return true;
      } else {
        await _incrementAttempt();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Increment attempt counter
  Future<void> _incrementAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_pinAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_pinAttemptsKey, attempts);
    await prefs.setString(_lastAttemptKey, DateTime.now().toIso8601String());

    // Lock after 5 failed attempts for 30 minutes
    if (attempts >= 5) {
      await prefs.setBool(_isLockedKey, true);
    }
  }

  // Reset attempts
  Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pinAttemptsKey, 0);
    await prefs.setBool(_isLockedKey, false);
  }

  // Check if PIN is locked
  // In your AppPinService class, update the isLocked method:
  Future<bool> isLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocked = prefs.getBool(_isLockedKey) ?? false;

    if (isLocked) {
      final lastAttempt = prefs.getString(_lastAttemptKey);
      if (lastAttempt != null) {
        final lastAttemptTime = DateTime.parse(lastAttempt);
        final now = DateTime.now();
        final difference = now.difference(lastAttemptTime);

        // Auto-unlock after 30 minutes
        if (difference.inMinutes >= 30) {
          await resetAttempts();
          return false;
        }
      } else {
        // If no last attempt time, reset the lock
        await resetAttempts();
        return false;
      }
      return true;
    }
    return false;
  }

  // Get remaining attempts
  Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_pinAttemptsKey) ?? 0;
    return 5 - attempts;
  }

  // Disable PIN
  Future<bool> disablePin() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pinEnabledKey, false);
      await resetAttempts();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if PIN is set (for initial setup)
  Future<bool> isPinSet() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Clear all PIN data (for logout)
  Future<void> clearPinData() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinEnabledKey);
      await prefs.remove(_pinSetupCompletedKey);
      await prefs.remove(_pinAttemptsKey);
      await prefs.remove(_lastAttemptKey);
      await prefs.remove(_isLockedKey);
    } catch (e) {
      // Silent fail
    }
  }
}