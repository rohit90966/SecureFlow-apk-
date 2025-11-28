import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'firebase_service.dart';
import 'encryption_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _passwordsKey = 'saved_passwords';
  static const String _categoriesKey = 'password_categories';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _encryptionEnabledKey = 'encryption_enabled';
  static const String _migrationCompletedKey = 'migration_completed';
  static const String _cloudBackupEnabledKey = 'cloud_backup_enabled';
  static const String _userSessionKey = 'user_session_data';

  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitialized = false;

  // Sync status with detailed information
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      await initialize();

      final prefs = await SharedPreferences.getInstance();
      final localPasswords = await _getLocalPasswords();
      final firebasePasswords = _firebaseService.isLoggedIn
          ? await _firebaseService.getPasswords()
          : [];

      final lastSync = prefs.getInt(_lastSyncKey);
      final encryptionEnabled = prefs.getBool(_encryptionEnabledKey) ?? false;
      final migrationCompleted = prefs.getBool(_migrationCompletedKey) ?? false;
      final cloudBackupEnabled = prefs.getBool(_cloudBackupEnabledKey) ?? false;

      return {
        'lastSync': lastSync != null
            ? DateTime.fromMillisecondsSinceEpoch(lastSync).toString()
            : 'Never',
        'cloudCount': firebasePasswords.length,
        'localCount': localPasswords.length,
        'encryptionEnabled': encryptionEnabled,
        'migrationCompleted': migrationCompleted,
        'cloudBackupEnabled': cloudBackupEnabled,
        'hasCloudConnection': _firebaseService.isLoggedIn,
        'userEmail': _firebaseService.userEmail,
        'encryptionKeyAvailable': EncryptionService.hasKey,
        'storageInitialized': _isInitialized,
      };
    } catch (e) {
      return {
        'lastSync': 'Error',
        'cloudCount': 0,
        'localCount': 0,
        'encryptionEnabled': false,
        'migrationCompleted': false,
        'cloudBackupEnabled': false,
        'hasCloudConnection': false,
        'error': e.toString(),
      };
    }
  }

  // Test encryption functionality
  Future<bool> testEncryption() async {
    try {
      await initialize();

      const testString = 'test_password_123_secure_vault';
      final encrypted = EncryptionService.encrypt(testString);
      final decrypted = EncryptionService.decrypt(encrypted);

      final success = testString == decrypted;

      if (success) {
        print('✅ Encryption test PASSED');
      } else {
        print('❌ Encryption test FAILED');
        print('Original: $testString');
        print('Decrypted: $decrypted');
      }

      return success;
    } catch (e) {
      print('❌ Encryption test ERROR: $e');
      return false;
    }
  }

  // Initialize storage service with comprehensive setup
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔄 StorageService: Initializing...');

    // Refresh auth state before attempting secure key restoration
    try {
      await _firebaseService.checkAuthState();
      print('✅ Auth state checked');
    } catch (e) {
      print('⚠️ Auth state check failed: $e');
    }

    await EncryptionService.initialize();
    print('✅ Encryption service initialized');

    // 🔐 CRITICAL: Restore user password from secure storage if logged in
    if (_firebaseService.isLoggedIn) {
      try {
        final secureStorage = FlutterSecureStorage();
        final storedPassword =
            await secureStorage.read(key: 'user_encryption_password');

        if (storedPassword != null && storedPassword.isNotEmpty) {
          print(
              '🔐 StorageService: Restoring encryption password from secure storage');
          EncryptionService.setUserPassword(storedPassword);
          print(
              '✅ StorageService: Encryption password restored - decryption ready');

          // 🔄 Check if we need to clear incompatible encrypted data
          await _clearIncompatibleEncryptedData();
        } else {
          print(
              '⚠️ StorageService: No stored password found - decryption will fail');
          print(
              '💡 Recommendation: User should re-login to restore encryption keys');
        }
      } catch (e) {
        print('❌ StorageService: Failed to restore encryption password: $e');
      }
    }

    _isInitialized = true;
    print('✅ StorageService: Initialization completed');

    await _migrateExistingData();
    print('✅ Migration check completed');

    // Attempt legacy migration (normalize any old encryption) if we have a key
    if (_firebaseService.isLoggedIn && EncryptionService.hasKey) {
      try {
        await _migrateLegacyEncryptedData();
        print('✅ Legacy migration attempted');
      } catch (e) {
        print('⚠️ Legacy migration error: $e');
      }
    }

    print('🎉 StorageService: Fully initialized and ready');
  }

  // Clear old incompatible encrypted data that's unrecoverable
  Future<void> _clearIncompatibleEncryptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationFlag = prefs.getBool('dart_encryption_migrated') ?? false;

      if (migrationFlag) {
        return; // Already migrated
      }

      print('═══════════════════════════════════════');
      print('🔄 ENCRYPTION MIGRATION: Incompatible Data Cleanup');
      print('═══════════════════════════════════════');

      // Check if we have potentially incompatible data
      final jsonString = prefs.getString(_passwordsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          if (jsonList.isNotEmpty) {
            final firstItem = Map<String, dynamic>.from(jsonList[0]);
            final passwordField = firstItem['password']?.toString() ?? '';

            // If data looks encrypted but we can't decrypt it, clear it
            if (passwordField.isNotEmpty && passwordField.length > 50) {
              print(
                  '🗑️ Detected potentially incompatible encrypted data - clearing...');
              await prefs.remove(_passwordsKey);
              await prefs.remove(_lastSyncKey);
              await prefs.remove('saved_passwords');
              await prefs.remove('password_categories');
              print('✅ Incompatible data cleared');
            }
          }
        } catch (e) {
          print('⚠️ Data inspection failed: $e');
        }
      }

      await prefs.setBool('dart_encryption_migrated', true);
      print('✅ Migration flag set');
      print('═══════════════════════════════════════\n');
    } catch (e) {
      print('⚠️ Migration check failed: $e');
    }
  }

  /// Verify that existing encrypted passwords can be decrypted
  /// If decryption fails, clear local data and force recovery from Firebase
  Future<void> _verifyDecryption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_passwordsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return; // No data to verify
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isEmpty) return;

      // Test decrypt first password
      final firstPwd = Map<String, dynamic>.from(jsonList[0]);

      if (firstPwd['isEncrypted'] == true && firstPwd['password'] != null) {
        try {
          final encryptedPwd = firstPwd['password'].toString();
          if (EncryptionService.isEncrypted(encryptedPwd)) {
            // Try to decrypt
            final decrypted = EncryptionService.decrypt(encryptedPwd);
            if (decrypted != '[Decryption Failed]') {
              print('✅ Decryption verification passed');
              return;
            } else {
              throw Exception('Decryption returned failure marker');
            }
          }
        } catch (e) {
          print('❌ Decryption verification failed: $e');
          print('🔄 Clearing local data and recovering from Firebase...');

          // Clear corrupted local data
          await prefs.remove(_passwordsKey);
          await prefs.remove(_lastSyncKey);

          // Force recovery from Firebase
          if (_firebaseService.isLoggedIn) {
            await recoverPasswordsFromFirebase();
            print('✅ Data recovered from Firebase');
          } else {
            print('⚠️ Cannot recover - user not logged in');
          }
        }
      }
    } catch (e) {
      print('⚠️ Decryption verification error: $e');
    }
  }

  // Migrate unencrypted data to encrypted format
  Future<void> _migrateExistingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationCompleted = prefs.getBool(_migrationCompletedKey) ?? false;

      if (migrationCompleted) return;

      final jsonString = prefs.getString(_passwordsKey);
      if (jsonString == null || jsonString.isEmpty) {
        await prefs.setBool(_migrationCompletedKey, true);
        return;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Map<String, dynamic>> passwords = jsonList.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      bool needsMigration = passwords.any((pwd) =>
          pwd['isEncrypted'] != true &&
          pwd['password'] != null &&
          pwd['password'].toString().isNotEmpty);

      if (needsMigration) {
        print(
            '🔄 Migrating ${passwords.length} passwords to encrypted format...');

        final migratedPasswords = passwords.map((password) {
          return _encryptPasswordData(password);
        }).toList();

        final migratedJsonString = jsonEncode(migratedPasswords);
        await prefs.setString(_passwordsKey, migratedJsonString);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_migrationCompletedKey, true);

        print(
            '✅ Migration completed: ${migratedPasswords.length} passwords encrypted');
      } else {
        await prefs.setBool(_migrationCompletedKey, true);
      }
    } catch (e) {
      print('❌ Migration error: $e');
      // Don't block initialization on migration failure
    }
  }

  // Save password with comprehensive error handling and sync
  Future<bool> savePassword(Map<String, dynamic> passwordData) async {
    try {
      await initialize();

      if (!_firebaseService.isLoggedIn) {
        throw Exception('User not logged in. Please login again.');
      }

      final userId = _firebaseService.getCurrentUserId();
      if (userId == null) {
        throw Exception(
            'Unable to get user information. Please restart the app.');
      }

      print('💾 Saving password: ${passwordData['title']}');

      final encryptedPasswordData = _encryptPasswordData(passwordData);
      final saved = await _firebaseService.savePassword(encryptedPasswordData);

      if (saved) {
        final currentPasswords = await _getLocalPasswords();
        final existingIndex = currentPasswords
            .indexWhere((p) => p['id'] == encryptedPasswordData['id']);

        if (existingIndex != -1) {
          currentPasswords[existingIndex] = encryptedPasswordData;
          print('✅ Password updated locally');
        } else {
          currentPasswords.add(encryptedPasswordData);
          print('✅ Password added locally');
        }

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(currentPasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_cloudBackupEnabledKey, true);

        print('✅ Local storage updated');

        // Trigger backup after successful save
        await _createBackupAfterChange();

        return true;
      } else {
        throw Exception('Failed to save password to cloud');
      }
    } catch (e) {
      print('❌ Save password error: $e');
      throw Exception('Failed to save password: ${e.toString()}');
    }
  }

  // Load passwords with comprehensive recovery mechanisms
  Future<List<Map<String, dynamic>>> loadPasswords() async {
    try {
      await initialize();

      // CRITICAL: Verify user password is set before attempting decryption
      if (_firebaseService.isLoggedIn) {
        // First-time load after login: recover from Firebase
        final prefs = await SharedPreferences.getInstance();
        final localData = prefs.getString(_passwordsKey);

        if (localData == null || localData.isEmpty) {
          print(
              '🔄 StorageService: No local data, recovering from Firebase...');
          final firebasePasswords = await _firebaseService.getPasswords();

          if (firebasePasswords.isEmpty) {
            print('ℹ️ No passwords in Firebase - starting fresh');
            return [];
          }

          // Check if data is encrypted with old incompatible encryption
          print('🔍 Checking if Firebase data needs migration...');
          final needsMigration = firebasePasswords.any((pwd) =>
              pwd['isEncrypted'] == true ||
              (pwd['password'] != null &&
                  pwd['password'].toString().length > 50));

          if (needsMigration) {
            print('⚠️ Firebase contains old encrypted data!');
            print('🗑️ Clearing incompatible encrypted data...');
            // Return empty list - user must re-enter their passwords
            return [];
          }

          // Return plain unencrypted data from Firebase
          return firebasePasswords.map((pwd) {
            return {
              'documentId': pwd['documentId'],
              'id': pwd['id'] ?? pwd['documentId'],
              'title': pwd['title'] ?? '',
              'username': pwd['username'] ?? '',
              'password': pwd['password'] ?? '',
              'website': pwd['website'] ?? '',
              'category': pwd['category'] ?? 'General',
              'notes': pwd['notes'] ?? '',
              'strength': pwd['strength'] ?? 'Moderate',
              'created_date':
                  pwd['created_date']?.toString() ?? DateTime.now().toString(),
              'isEncrypted': false,
            };
          }).toList();
        }

        // Load from Firebase and sync
        try {
          print('🔄 StorageService: Loading passwords from Firebase...');
          final firebasePasswords = await _firebaseService.getPasswords();
          print(
              '📥 StorageService: Loaded ${firebasePasswords.length} passwords from Firebase');

          if (firebasePasswords.isNotEmpty) {
            // Convert Timestamp objects before processing
            final sanitizedPasswords = firebasePasswords.map((pwd) {
              final sanitized = Map<String, dynamic>.from(pwd);
              sanitized.forEach((key, value) {
                if (value != null && value.toString().contains('Timestamp')) {
                  try {
                    final timestamp = value as dynamic;
                    sanitized[key] = timestamp.millisecondsSinceEpoch;
                  } catch (e) {
                    sanitized.remove(key);
                  }
                }
              });
              return sanitized;
            }).toList();

            final convertedPasswords = sanitizedPasswords.map((doc) {
              return _decryptPasswordData(doc);
            }).toList();

            // Cache to local storage
            final prefs = await SharedPreferences.getInstance();
            final jsonString = jsonEncode(sanitizedPasswords);
            await prefs.setString(_passwordsKey, jsonString);
            await prefs.setInt(
                _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
            await prefs.setBool(_encryptionEnabledKey, true);
            await prefs.setBool(_cloudBackupEnabledKey, true);

            print(
                '✅ StorageService: Returned ${convertedPasswords.length} decrypted passwords');
            return convertedPasswords;
          } else {
            print(
                '⚠️ StorageService: No passwords in Firebase, loading from local cache');
          }
        } catch (firebaseError) {
          print('❌ StorageService: Firebase load error: $firebaseError');
          // Fall through to local storage
        }
      } else {
        print(
            '⚠️ StorageService: User not logged in, loading from local cache');
      }

      final localPasswords = await _getLocalPasswords();
      print(
          '📂 StorageService: Loaded ${localPasswords.length} passwords from local cache');
      return localPasswords;
    } catch (e) {
      print('❌ StorageService: Load failed: $e');
      return await _getLocalPasswords();
    }
  }

  // Recover passwords from Firebase with comprehensive error handling
  Future<void> recoverPasswordsFromFirebase() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        print('⚠️ StorageService: Cannot recover - user not logged in');
        return;
      }

      print('🔄 StorageService: Starting password recovery from Firebase...');

      // First, try to load from main passwords collection
      final mainPasswords = await _firebaseService.getPasswords();
      print(
          '📥 StorageService: Found ${mainPasswords.length} passwords in main collection');

      if (mainPasswords.isNotEmpty) {
        // Convert Timestamp objects to milliseconds before encoding
        final sanitizedPasswords = mainPasswords.map((pwd) {
          final sanitized = Map<String, dynamic>.from(pwd);
          sanitized.forEach((key, value) {
            if (value != null && value.toString().contains('Timestamp')) {
              try {
                final timestamp = value as dynamic;
                sanitized[key] = timestamp.millisecondsSinceEpoch;
              } catch (e) {
                sanitized.remove(key);
              }
            }
          });
          return sanitized;
        }).toList();

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(sanitizedPasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_cloudBackupEnabledKey, true);
        print(
            '✅ StorageService: Recovered ${mainPasswords.length} passwords from Firebase main collection');
        return;
      }

      // If main collection is empty, try backup collection
      print('🔍 StorageService: Main collection empty, checking backup...');
      final backupInfo = await _firebaseService.getBackupInfo();

      if (backupInfo != null && backupInfo['passwords'] != null) {
        final backupPasswords =
            List<Map<String, dynamic>>.from(backupInfo['passwords']);
        print(
            '📥 StorageService: Found ${backupPasswords.length} passwords in backup');

        if (backupPasswords.isNotEmpty) {
          final sanitizedPasswords = backupPasswords.map((pwd) {
            final sanitized = Map<String, dynamic>.from(pwd);
            sanitized.forEach((key, value) {
              if (value != null && value.toString().contains('Timestamp')) {
                try {
                  final timestamp = value as dynamic;
                  sanitized[key] = timestamp.millisecondsSinceEpoch;
                } catch (e) {
                  sanitized.remove(key);
                }
              }
            });
            return sanitized;
          }).toList();

          final prefs = await SharedPreferences.getInstance();
          final jsonString = jsonEncode(sanitizedPasswords);
          await prefs.setString(_passwordsKey, jsonString);
          await prefs.setInt(
              _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
          await prefs.setBool(_encryptionEnabledKey, true);
          await prefs.setBool(_cloudBackupEnabledKey, true);
          print(
              '✅ StorageService: Recovered ${backupPasswords.length} passwords from backup');
          return;
        }
      }

      print(
          '⚠️ StorageService: No passwords found in Firebase (main or backup)');
    } catch (e) {
      print('❌ StorageService: Password recovery failed: $e');
      rethrow;
    }
  }

  // Get local passwords with decryption
  Future<List<Map<String, dynamic>>> _getLocalPasswords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_passwordsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) {
        final data = Map<String, dynamic>.from(item);
        return _decryptPasswordData(data);
      }).toList();
    } catch (e) {
      print('❌ _getLocalPasswords error: $e');
      return [];
    }
  }

  // Get passwords in their STORED format (encrypted) for backup purposes
  Future<List<Map<String, dynamic>>> _getLocalPasswordsEncrypted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_passwordsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ _getLocalPasswordsEncrypted error: $e');
      return [];
    }
  }

  // Update password with comprehensive sync
  Future<bool> updatePassword(
      String passwordId, Map<String, dynamic> updates) async {
    try {
      await initialize();

      final encryptedUpdates = {...updates};
      // Encrypt any sensitive fields present in updates
      final fieldsToEncrypt = [
        'password',
        'username',
        'title',
        'website',
        'notes',
        'category'
      ];
      bool anyEncrypted = false;

      for (final field in fieldsToEncrypt) {
        if (updates.containsKey(field) && updates[field] != null) {
          final value = updates[field].toString();
          if (value.isNotEmpty && !EncryptionService.isEncrypted(value)) {
            encryptedUpdates[field] = EncryptionService.encrypt(value);
            anyEncrypted = true;
          }
        }
      }

      if (anyEncrypted) {
        encryptedUpdates['isEncrypted'] = true;
      }

      final updated =
          await _firebaseService.updatePassword(passwordId, encryptedUpdates);

      if (updated) {
        final currentPasswords = await _getLocalPasswords();
        final index =
            currentPasswords.indexWhere((pwd) => pwd['id'] == passwordId);

        if (index != -1) {
          final localEncryptedUpdates = {...encryptedUpdates};
          final updatedPassword = {
            ...currentPasswords[index],
            ...localEncryptedUpdates
          };
          currentPasswords[index] = updatedPassword;

          final prefs = await SharedPreferences.getInstance();
          final jsonString = jsonEncode(currentPasswords);
          await prefs.setString(_passwordsKey, jsonString);
          await prefs.setInt(
              _lastSyncKey, DateTime.now().millisecondsSinceEpoch);

          print('✅ Password updated locally: $passwordId');
        }

        await _createBackupAfterChange();
      }

      return updated;
    } catch (e) {
      print('❌ Update password error: $e');
      return false;
    }
  }

  // Delete password with comprehensive cleanup
  Future<bool> deletePassword(String passwordId) async {
    try {
      print('🔄 StorageService: Starting deletion for ID: $passwordId');

      // Get current passwords to find the exact document
      final currentPasswords = await _getLocalPasswords();

      // Find the password using multiple identifier options
      final passwordToDelete = currentPasswords.firstWhere(
        (pwd) {
          final docIdMatch = pwd['documentId'] == passwordId;
          final idMatch = pwd['id'] == passwordId;
          final idStringMatch = pwd['id'].toString() == passwordId;
          final isMatch = docIdMatch || idMatch || idStringMatch;

          if (isMatch) {
            print(
                '✅ StorageService: Found password - Title: ${pwd['title']}, id: ${pwd['id']}, documentId: ${pwd['documentId']}');
          }
          return isMatch;
        },
        orElse: () => {},
      );

      if (passwordToDelete.isEmpty) {
        print('❌ StorageService: No password found for ID: $passwordId');
        return false;
      }

      // Determine the correct documentId for Firebase
      final String documentId;
      if (passwordToDelete['documentId'] != null) {
        documentId = passwordToDelete['documentId'];
        print('📄 StorageService: Using documentId from data: $documentId');
      } else {
        documentId = passwordId;
        print(
            '🔧 StorageService: Using provided ID as documentId: $documentId');
      }

      // Delete from Firebase
      final deleted = await _firebaseService.deletePassword(documentId);

      if (deleted) {
        print('✅ StorageService: Firebase deletion successful');

        // Remove from local storage using all possible identifiers
        final initialLength = currentPasswords.length;
        currentPasswords.removeWhere((pwd) {
          final shouldRemove = pwd['documentId'] == documentId ||
              pwd['id'] == passwordId ||
              pwd['id'].toString() == passwordId ||
              pwd['documentId'] == passwordId;

          if (shouldRemove) {
            print(
                '🗑️ StorageService: Removing local password: ${pwd['title']}');
          }
          return shouldRemove;
        });

        final removedCount = initialLength - currentPasswords.length;
        print(
            '📊 StorageService: Removed $removedCount passwords from local storage');

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(currentPasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

        print('💾 StorageService: Local storage updated successfully');

        // Create backup
        await _createBackupAfterChange();
        print('☁️ StorageService: Backup triggered');

        return true;
      } else {
        print('❌ StorageService: Firebase deletion returned false');
        return false;
      }
    } catch (e) {
      print('💥 StorageService: Exception in deletePassword: $e');
      return false;
    }
  }

  // Sync data between local and cloud
  Future<bool> syncData() async {
    try {
      await initialize();

      if (!_firebaseService.isLoggedIn) {
        return false;
      }

      final firebasePasswords = await _firebaseService.getPasswords();

      if (firebasePasswords.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(firebasePasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_cloudBackupEnabledKey, true);
        return true;
      } else {
        final localPasswords = await _getLocalPasswords();
        if (localPasswords.isNotEmpty) {
          final result = await backupToCloud();
          return result;
        } else {
          return true;
        }
      }
    } catch (e) {
      print('❌ Sync data error: $e');
      return false;
    }
  }

  // Save multiple passwords at once
  Future<bool> savePasswords(List<Map<String, dynamic>> passwords) async {
    try {
      await initialize();

      final encryptedPasswords = passwords.map((password) {
        return _encryptPasswordData(password);
      }).toList();

      bool allSaved = true;
      for (var password in encryptedPasswords) {
        final saved = await _firebaseService.savePassword(password);
        if (!saved) allSaved = false;
      }

      if (allSaved) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(encryptedPasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_cloudBackupEnabledKey, true);
      }

      return allSaved;
    } catch (e) {
      print('❌ Save passwords error: $e');
      return false;
    }
  }

  // Refresh data from Firebase
  Future<void> refreshFromFirebase() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('Not logged in to Firebase');
      }

      final firebasePasswords = await _firebaseService.getPasswords();

      if (firebasePasswords.isNotEmpty) {
        // Sanitize any Firestore Timestamp objects before encoding
        final sanitizedPasswords = firebasePasswords.map((pwd) {
          final sanitized = Map<String, dynamic>.from(pwd);
          sanitized.forEach((key, value) {
            if (value != null && value.toString().contains('Timestamp')) {
              try {
                final ts = value as dynamic;
                sanitized[key] = ts.millisecondsSinceEpoch;
              } catch (_) {
                sanitized.remove(key);
              }
            }
          });
          return sanitized;
        }).toList();

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(sanitizedPasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_cloudBackupEnabledKey, true);
      } else {
        throw Exception('No data found in Firebase');
      }
    } catch (e) {
      throw e;
    }
  }

  // Check if cloud backup exists
  Future<bool> hasCloudBackup() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        return false;
      }

      final backupInfo = await _firebaseService.getBackupInfo();
      return backupInfo != null && backupInfo['totalPasswords'] != null;
    } catch (e) {
      return false;
    }
  }

  // Get cloud backup information
  Future<Map<String, dynamic>> getCloudBackupInfo() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        return {'hasBackup': false, 'count': 0, 'lastBackup': null};
      }

      final backupInfo = await _firebaseService.getBackupInfo();
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);

      if (backupInfo != null) {
        return {
          'hasBackup': true,
          'count': backupInfo['totalPasswords'] ?? 0,
          'lastBackup': backupInfo['backupTimestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  backupInfo['backupTimestamp'])
              : null,
          'userEmail': _firebaseService.userEmail,
        };
      } else {
        return {
          'hasBackup': false,
          'count': 0,
          'lastBackup': lastSync != null
              ? DateTime.fromMillisecondsSinceEpoch(lastSync)
              : null,
          'userEmail': _firebaseService.userEmail,
        };
      }
    } catch (e) {
      return {
        'hasBackup': false,
        'count': 0,
        'lastBackup': null,
        'error': e.toString()
      };
    }
  }

  // Restore from cloud backup
  Future<bool> restoreFromCloudBackup() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('Not logged in to Firebase');
      }

      final backupInfo = await _firebaseService.getBackupInfo();

      if (backupInfo == null || backupInfo['passwords'] == null) {
        throw Exception('No backup found in cloud');
      }

      final backupPasswords =
          List<Map<String, dynamic>>.from(backupInfo['passwords']);

      if (backupPasswords.isEmpty) {
        throw Exception('Backup is empty');
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(backupPasswords);
      await prefs.setString(_passwordsKey, jsonString);
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_encryptionEnabledKey, true);
      await prefs.setBool(_cloudBackupEnabledKey, true);

      return true;
    } catch (e) {
      throw Exception('Restore failed: ${e.toString()}');
    }
  }

  // Backup to cloud with comprehensive verification
  Future<bool> backupToCloud() async {
    try {
      print('═══════════════════════════════════════════════');
      print('🚀 BACKUP TO CLOUD - START');
      print('═══════════════════════════════════════════════');

      print('1️⃣ Checking login status...');
      if (!_firebaseService.isLoggedIn) {
        throw Exception('Not logged in to Firebase');
      }

      print('2️⃣ Checking encryption key...');
      if (!EncryptionService.hasKey) {
        await EncryptionService.initialize();
        if (!EncryptionService.hasKey) {
          throw Exception('Encryption key not available. Please login again.');
        }
      }

      print('3️⃣ Getting local passwords...');
      var localPasswords = await _getLocalPasswordsEncrypted();
      print('📊 Found ${localPasswords.length} local passwords');

      if (localPasswords.isEmpty) {
        print('🔄 Local storage empty, recovering from Firebase...');
        await recoverPasswordsFromFirebase();
        localPasswords = await _getLocalPasswordsEncrypted();
        print('📊 After recovery: ${localPasswords.length} passwords');

        if (localPasswords.isEmpty) {
          throw Exception('No passwords to backup');
        }
      }

      print('4️⃣ Verifying encryption before backup...');
      for (var i = 0; i < localPasswords.length; i++) {
        final pwd = localPasswords[i];
        final passwordField = pwd['password']?.toString() ?? '';

        if (passwordField.isNotEmpty &&
            !EncryptionService.isEncrypted(passwordField)) {
          print('🔄 Re-encrypting: ${pwd['title']}');
          final decryptedData = _decryptPasswordData(pwd);
          final reEncryptedData = _encryptPasswordData(decryptedData);
          localPasswords[i] = reEncryptedData;
        }
      }

      print('5️⃣ Creating backup data...');
      final user = _firebaseService.getCurrentUserId();
      final userEmail = _firebaseService.userEmail;

      final backupData = {
        'userId': user,
        'email': userEmail,
        'passwords': localPasswords,
        'totalPasswords': localPasswords.length,
        'backupTimestamp': DateTime.now().millisecondsSinceEpoch,
        'encryptionVersion': 2,
        'deviceInfo': {
          'platform': 'flutter',
          'backupVersion': '2.0',
        },
        'metadata': {
          'categories': _extractCategories(localPasswords),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        }
      };

      print('6️⃣ Calling Firebase backup...');
      await _firebaseService.createBackup(backupData);

      print('7️⃣ Updating local sync timestamp...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_cloudBackupEnabledKey, true);

      print('═══════════════════════════════════════════════');
      print('✅ BACKUP TO CLOUD - SUCCESS');
      print('═══════════════════════════════════════════════');
      return true;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════');
      print('❌ BACKUP TO CLOUD - FAILED');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════');
      throw Exception('Backup failed: ${e.toString()}');
    }
  }

  // Encrypt password data
  Map<String, dynamic> _encryptPasswordData(Map<String, dynamic> passwordData) {
    try {
      final encryptedData = {...passwordData};
      final fieldsToEncrypt = [
        'password',
        'username',
        'title',
        'website',
        'notes',
        'category'
      ];
      bool anyFieldEncrypted = false;

      for (final field in fieldsToEncrypt) {
        if (passwordData[field] != null &&
            passwordData[field].toString().isNotEmpty) {
          final originalValue = passwordData[field].toString();
          if (!EncryptionService.isEncrypted(originalValue)) {
            try {
              final encryptedValue = EncryptionService.encrypt(originalValue);
              encryptedData[field] = encryptedValue;
              anyFieldEncrypted = true;
            } catch (encErr) {
              print('❌ Failed to encrypt field $field: $encErr');
              encryptedData[field] = originalValue;
            }
          } else {
            encryptedData[field] = originalValue;
            anyFieldEncrypted = true;
          }
        }
      }

      encryptedData['isEncrypted'] = anyFieldEncrypted;
      encryptedData['id'] = encryptedData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final uid = _firebaseService.getCurrentUserId();
      if (uid != null) {
        encryptedData['userKey'] = EncryptionService.hash(uid);
      }

      encryptedData['createdAt'] =
          encryptedData['createdAt'] ?? DateTime.now().toIso8601String();

      return encryptedData;
    } catch (e) {
      print('❌ Password data encryption failed: $e');
      return passwordData;
    }
  }

  // Decrypt password data
  Map<String, dynamic> _decryptPasswordData(
      Map<String, dynamic> encryptedData) {
    try {
      final decryptedData = {
        'documentId': encryptedData['documentId'],
        'id': encryptedData['id'] ?? encryptedData['documentId'],
        'title': encryptedData['title'] ?? '',
        'username': encryptedData['username'] ?? '',
        'password': encryptedData['password'] ?? '',
        'website': encryptedData['website'] ?? '',
        'category': encryptedData['category'] ?? 'General',
        'notes': encryptedData['notes'] ?? '',
        'strength': encryptedData['strength'] ?? 'Moderate',
        'created_date': encryptedData['created_date']?.toString() ??
            DateTime.now().toString(),
        'isEncrypted': encryptedData['isEncrypted'] ?? false,
      };

      if (decryptedData['isEncrypted'] == true) {
        if (!EncryptionService.hasKey) {
          decryptedData['locked'] = true;
          decryptedData['password'] = '[Locked - Login Required]';
          decryptedData['username'] = '[Locked]';
          decryptedData['isEncrypted'] = true;
          return decryptedData;
        }

        final fieldsToDecrypt = [
          'password',
          'username',
          'title',
          'website',
          'notes',
          'category'
        ];
        for (final field in fieldsToDecrypt) {
          if (decryptedData[field] != null && decryptedData[field] is String) {
            final encryptedValue = decryptedData[field] as String;
            if (encryptedValue.isNotEmpty &&
                EncryptionService.isEncrypted(encryptedValue)) {
              try {
                final decryptedValue =
                    EncryptionService.decrypt(encryptedValue);
                decryptedData[field] = decryptedValue;
              } catch (e) {
                decryptedData['locked'] = true;
                if (field == 'password') {
                  decryptedData[field] = '[Locked - Re-login Required]';
                }
              }
            }
          }
        }
      }
      return decryptedData;
    } catch (e) {
      print('❌ Decryption error: $e');
      return encryptedData;
    }
  }

  // Extract categories from passwords
  List<String> _extractCategories(List<Map<String, dynamic>> passwords) {
    final categories = <String>{};
    for (final password in passwords) {
      final category = password['category']?.toString();
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    return categories.toList();
  }

  // Manual sync with Firebase
  Future<bool> syncWithFirebase() async {
    try {
      print('🔄 StorageService: Manual sync requested...');

      if (!_firebaseService.isLoggedIn) {
        print('❌ StorageService: Cannot sync - user not logged in');
        return false;
      }

      await recoverPasswordsFromFirebase();
      print('✅ StorageService: Manual sync completed');
      return true;
    } catch (e) {
      print('❌ StorageService: Manual sync failed: $e');
      return false;
    }
  }

  // Fix decryption issues
  Future<bool> fixDecryptionIssues() async {
    try {
      print('🔧 StorageService: Fixing decryption issues...');

      if (!_firebaseService.isLoggedIn) {
        throw Exception('Please login first');
      }

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_passwordsKey);
      await prefs.remove(_migrationCompletedKey);
      print('🗑️ Cleared local storage');

      // Reset encryption keys
      await EncryptionService.clearKeys();
      print('🔑 Cleared encryption keys');

      // Attempt to restore key immediately from secure storage
      try {
        final secureStorage = FlutterSecureStorage();
        final storedPassword =
            await secureStorage.read(key: 'user_encryption_password');
        if (storedPassword != null && storedPassword.isNotEmpty) {
          EncryptionService.setUserPassword(storedPassword);
          print('🔐 Encryption key restored before recovery');
        } else {
          print('⚠️ No stored password found - user must log in to unlock');
        }
      } catch (e) {
        print('⚠️ Failed to restore key automatically: $e');
      }

      // Force recovery from Firebase
      await recoverPasswordsFromFirebase();
      print('📥 Recovered data from Firebase');

      print('✅ Decryption issues fixed!');
      return true;
    } catch (e) {
      print('❌ Failed to fix decryption issues: $e');
      return false;
    }
  }

  // Create backup after changes
  Future<void> _createBackupAfterChange() async {
    try {
      final user = _firebaseService.getCurrentUserId();
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final backupEnabled = prefs.getBool(_cloudBackupEnabledKey) ?? true;

      if (backupEnabled) {
        await Future.delayed(Duration(seconds: 1));
        await backupToCloud();
      }
    } catch (e) {
      // Silent fail for auto-backup
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_passwordsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_encryptionEnabledKey);
      await prefs.remove(_migrationCompletedKey);
      await prefs.remove(_cloudBackupEnabledKey);
      await prefs.remove(_userSessionKey);
      await EncryptionService.clearKeys();

      print('✅ All local data cleared');
    } catch (e) {
      print('❌ Clear all data error: $e');
    }
  }

  // Migrate legacy encrypted data
  Future<void> _migrateLegacyEncryptedData() async {
    print('🔄 StorageService: Starting legacy migration pass...');
    final firebasePasswords = await _firebaseService.getPasswords();
    if (firebasePasswords.isEmpty) {
      print('ℹ️ StorageService: No Firebase passwords to migrate');
      return;
    }

    int migrated = 0;
    for (final pwd in firebasePasswords) {
      try {
        if (pwd['isEncrypted'] == true) {
          final id = pwd['documentId'] ?? pwd['id'];
          if (id == null) continue;

          final fields = [
            'password',
            'username',
            'title',
            'website',
            'notes',
            'category'
          ];
          final decrypted = <String, String>{};
          bool anyEncryptedField = false;

          for (final f in fields) {
            final v = pwd[f];
            if (v is String &&
                v.isNotEmpty &&
                EncryptionService.isEncrypted(v)) {
              anyEncryptedField = true;
              try {
                final plain = EncryptionService.decrypt(v);
                decrypted[f] = plain;
              } catch (_) {
                // skip - will remain locked until user re-saves
              }
            }
          }

          if (anyEncryptedField && decrypted.isNotEmpty) {
            final reEncrypted = <String, dynamic>{};
            decrypted.forEach((key, value) {
              try {
                reEncrypted[key] = EncryptionService.encrypt(value);
              } catch (_) {}
            });

            if (reEncrypted.isNotEmpty) {
              reEncrypted['isEncrypted'] = true;
              reEncrypted['encryptionVersion'] = 2;
              final ok = await _firebaseService.updatePassword(id, reEncrypted);
              if (ok) migrated++;
            }
          }
        }
      } catch (e) {
        print('⚠️ StorageService: Migration skipped for one entry: $e');
      }
    }
    print('✅ StorageService: Legacy migration complete. Migrated: $migrated');
  }

  // Emergency recovery - nuclear option
  Future<bool> emergencyRecovery() async {
    try {
      print('🆘 STORAGE SERVICE: EMERGENCY RECOVERY INITIATED');

      // Clear everything
      await clearAllData();

      // Logout user to force fresh login
      if (_firebaseService.isLoggedIn) {
        await _firebaseService.logout();
      }

      // Reset initialization
      _isInitialized = false;

      print('✅ EMERGENCY RECOVERY COMPLETED - Fresh start ready');
      return true;
    } catch (e) {
      print('❌ EMERGENCY RECOVERY FAILED: $e');
      return false;
    }
  }
}
