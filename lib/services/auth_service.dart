import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'storage_service.dart';
import 'app_pin_service.dart';
import 'encryption_service.dart';
import 'native_encryption.dart';

class AuthService with ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _currentUserEmail;

  bool get isAuthenticated => _firebaseService.isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get currentUserEmail => _firebaseService.userEmail;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check Firebase auth state
      await _firebaseService.checkAuthState();

      // Check if user is already logged in with Firebase
      if (_firebaseService.isLoggedIn) {
        _isAuthenticated = true;
        _currentUserEmail = _firebaseService.userEmail;
        print('✅ User already logged in: $_currentUserEmail');

        // 🔐 CRITICAL: Restore encryption password from secure storage
        final storedPassword =
            await _secureStorage.read(key: 'user_encryption_password');
        if (storedPassword != null) {
          print('🔐 Restoring encryption keys from stored password...');
          EncryptionService.setUserPassword(storedPassword);
          print('✅ Encryption keys restored successfully');
        } else {
          print(
              '⚠️ No stored encryption password found - user may need to re-login');
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('❌ Auth service initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Firebase User Registration
  Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
  ) async {
    try {
      // 🔐 CRITICAL: Set user password BEFORE Firebase registration
      // This ensures encryption is available when creating user document
      print('🔐 Initializing encryption with user-specific keys...');
      EncryptionService.setUserPassword(password);
      print('✅ User-specific encryption keys initialized');

      final result = await _firebaseService.registerUser(email, password);

      if (result['success'] == true) {
        _isAuthenticated = true;
        _currentUserEmail = email;

        // Persist password for app restarts
        await _secureStorage.write(
          key: 'user_encryption_password',
          value: password,
        );

        // Clear any existing local data for fresh start
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_passwords');
        print('🗑️ Cleared local data for new user');

        notifyListeners();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Firebase User Login
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final result = await _firebaseService.loginUser(email, password);

      if (result['success'] == true) {
        _isAuthenticated = true;
        _currentUserEmail = email;

        // 🔐 CRITICAL: Set user password for encryption key derivation
        // This MUST happen before any password loading/decryption
        //
        // 🌍 CROSS-DEVICE COMPATIBLE:
        // Password + App Salt → PBKDF2 → Same keys on ANY device
        // This enables: Phone → Tablet → PC backup/restore
        print('🔐 Initializing encryption with user-specific keys...');
        EncryptionService.setUserPassword(password);
        print('✅ User-specific encryption keys initialized');
        print('🌍 Keys are cross-device compatible - works on any device!');

        // Store password securely for app restarts
        await _secureStorage.write(
            key: 'user_encryption_password', value: password);
        print('💾 Stored encryption password securely');

        // Clear any stale local data from previous user
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_passwords');
        print('🗑️ Cleared stale local data');

        notifyListeners();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Enhanced biometric availability check
  Future<bool> isBiometricAvailable() async {
    try {
      print('🔍 Checking biometric availability...');

      final isSupported = await _localAuth.isDeviceSupported();
      print('📱 Device supported: $isSupported');

      if (!isSupported) {
        return false;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('🔐 Can check biometrics: $canCheckBiometrics');

      if (!canCheckBiometrics) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('👆 Available biometrics: $availableBiometrics');

      final hasEnrolledBiometrics = availableBiometrics.isNotEmpty;
      print('✅ Has enrolled biometrics: $hasEnrolledBiometrics');

      return hasEnrolledBiometrics;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  // Enhanced Biometric Authentication
  Future<bool> authenticate() async {
    try {
      print('🔐 Starting biometric authentication...');

      // Check availability first
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('❌ Biometric not available');
        return false;
      }

      print('✅ Starting authentication dialog...');

      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your secure password vault',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      print('🎯 Biometric authentication result: $result');

      _isAuthenticated = result;
      notifyListeners();

      return result;
    } catch (e) {
      print('❌ Biometric authentication error: $e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> testSimpleAuth() async {
    try {
      print('🧪 Testing simple authentication...');

      final result = await _localAuth.authenticate(
        localizedReason: 'Test authentication - use fingerprint or device PIN',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: false,
        ),
      );

      print('🎯 Simple auth result: $result');
      return result;
    } catch (e) {
      print('❌ Simple auth error: $e');
      return false;
    }
  }

  // Alternative method with device credentials fallback
  Future<bool> authenticateWithFallback() async {
    try {
      print('🔐 Starting authentication with fallback...');

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('❌ Biometric not available, trying device credentials...');

        // Try with device credentials as fallback
        final result = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access your secure password vault',
          options: const AuthenticationOptions(
            biometricOnly: false,
            useErrorDialogs: true,
            stickyAuth: true,
            sensitiveTransaction: true,
          ),
        );

        _isAuthenticated = result;
        notifyListeners();
        return result;
      }

      // Use biometric-only if available
      return await authenticate();
    } catch (e) {
      print('❌ Authentication with fallback error: $e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  // Test biometric functionality
  Future<void> testBiometric() async {
    print('🧪 Testing biometric functionality...');

    final status = await checkBiometricStatus();
    print('Biometric Status: $status');

    final isAvailable = await isBiometricAvailable();
    print('Biometric Available: $isAvailable');

    if (isAvailable) {
      print('🔐 Testing authentication...');
      final result = await authenticate();
      print('Test Authentication Result: $result');
    }
  }

  // Check if biometric is available and enrolled
  Future<Map<String, dynamic>> checkBiometricStatus() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      final hasBiometrics = availableBiometrics.isNotEmpty;

      // Handle different biometric types
      final hasFingerprint = availableBiometrics.any(
        (bio) =>
            bio == BiometricType.strong ||
            bio == BiometricType.weak ||
            bio == BiometricType.fingerprint,
      );

      final hasFace = availableBiometrics.contains(BiometricType.face);
      final hasIris = availableBiometrics.contains(BiometricType.iris);

      print('📊 Biometric Status:');
      print('  - Supported: $isSupported');
      print('  - Can Check: $canCheckBiometrics');
      print('  - Has Biometrics: $hasBiometrics');
      print('  - Available Types: $availableBiometrics');

      return {
        'isSupported': isSupported,
        'canCheckBiometrics': canCheckBiometrics,
        'hasBiometrics': hasBiometrics,
        'hasFingerprint': hasFingerprint,
        'hasFace': hasFace,
        'hasIris': hasIris,
        'availableTypes': availableBiometrics,
      };
    } catch (e) {
      print('❌ Error checking biometric status: $e');
      return {
        'isSupported': false,
        'canCheckBiometrics': false,
        'hasBiometrics': false,
        'hasFingerprint': false,
        'hasFace': false,
        'hasIris': false,
        'availableTypes': [],
      };
    }
  }

  // KEEP FOR LOCAL FALLBACK - Master Password Management
  Future<void> setMasterPassword(String password) async {
    await _secureStorage.write(key: 'master_password', value: password);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<bool> verifyMasterPassword(String password) async {
    try {
      final stored = await _secureStorage.read(key: 'master_password');
      final isValid = stored == password;
      _isAuthenticated = isValid;

      // 🔐 Set user password for encryption if valid
      if (isValid) {
        print('🔐 Initializing encryption with user-specific keys...');
        EncryptionService.setUserPassword(password);
        print('✅ User-specific encryption keys initialized');
      }

      notifyListeners();
      return isValid;
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  // Check if first time - now based on Firebase login status
  Future<bool> isFirstTime() async {
    return !_firebaseService.isLoggedIn;
  }

  // FIXED: Enhanced logout with proper data clearing
  Future<void> logout() async {
    try {
      print('🚪 AuthService: Starting logout process...');
      await AppPinService().clearPinData();

      // Clear stored encryption password
      await _secureStorage.delete(key: 'user_encryption_password');
      print('🗑️ Cleared stored encryption password');

      // FIRST: Clear all local data
      await StorageService().clearAllData();

      // THEN: Logout from Firebase
      await _firebaseService.logout();

      _isAuthenticated = false;
      _currentUserEmail = null;

      print('✅ AuthService: Logout completed successfully');
      notifyListeners();
    } catch (e) {
      print('❌ AuthService: Logout error: $e');
      _isAuthenticated = false;
      _currentUserEmail = null;
      notifyListeners();
      rethrow;
    }
  }

  // Biometric Settings
  Future<bool> enableBiometric() async {
    try {
      // Verify biometric is available before enabling
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric not available on this device');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', true);
      return true;
    } catch (e) {
      print('❌ Error enabling biometric: $e');
      return false;
    }
  }

  Future<bool> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      return true;
    } catch (e) {
      print('❌ Error disabling biometric: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // Debug biometric status
  Future<void> debugBiometricStatus() async {
    print('🔍 === BIOMETRIC DEBUG INFO ===');

    try {
      // Check device support
      final isSupported = await _localAuth.isDeviceSupported();
      print('📱 Device Supported: $isSupported');

      // Check if can check biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('🔐 Can Check Biometrics: $canCheckBiometrics');

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('👆 Available Biometrics: $availableBiometrics');

      // Check if biometrics are enrolled
      final hasEnrolledBiometrics = availableBiometrics.isNotEmpty;
      print('✅ Biometrics Enrolled: $hasEnrolledBiometrics');

      // Check shared preferences setting
      final prefs = await SharedPreferences.getInstance();
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      print('⚙️ Biometric Enabled in Settings: $isBiometricEnabled');

      // Firebase auth status
      print('🔥 Firebase Auth Status: ${_firebaseService.isLoggedIn}');
      print('📧 Firebase User Email: ${_firebaseService.userEmail}');

      print('🔍 === END DEBUG INFO ===');
    } catch (e) {
      print('❌ Debug Error: $e');
    }
  }
}
