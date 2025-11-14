import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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

  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitialized = false;

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

      return {
        'lastSync': lastSync != null
            ? DateTime.fromMillisecondsSinceEpoch(lastSync).toString()
            : 'Never',
        'cloudCount': firebasePasswords.length,
        'localCount': localPasswords.length,
        'encryptionEnabled': encryptionEnabled,
        'hasCloudConnection': _firebaseService.isLoggedIn,
        'userEmail': _firebaseService.userEmail,
      };
    } catch (e) {
      return {
        'lastSync': 'Error',
        'cloudCount': 0,
        'localCount': 0,
        'encryptionEnabled': false,
        'hasCloudConnection': false,
        'error': e.toString(),
      };
    }
  }

  Future<bool> testEncryption() async {
    try {
      await initialize();

      const testString = 'test_password_123';
      final encrypted = EncryptionService.encrypt(testString);
      final decrypted = EncryptionService.decrypt(encrypted);

      return testString == decrypted;
    } catch (e) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await EncryptionService.initialize();
    _isInitialized = true;
    await _migrateExistingData();

    // Auto-recover passwords from Firebase on initialization if logged in
    if (_firebaseService.isLoggedIn) {
      await recoverPasswordsFromFirebase();
    }
  }

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
        final migratedPasswords = passwords.map((password) {
          return _encryptPasswordData(password);
        }).toList();

        final migratedJsonString = jsonEncode(migratedPasswords);
        await prefs.setString(_passwordsKey, migratedJsonString);
        await prefs.setBool(_encryptionEnabledKey, true);
      }

      await prefs.setBool(_migrationCompletedKey, true);
    } catch (e) {
      // Silent fail
    }
  }

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

      final encryptedPasswordData = _encryptPasswordData(passwordData);

      final saved = await _firebaseService.savePassword(encryptedPasswordData);

      if (saved) {
        final currentPasswords = await _getLocalPasswords();
        final existingIndex = currentPasswords
            .indexWhere((p) => p['id'] == encryptedPasswordData['id']);

        if (existingIndex != -1) {
          currentPasswords[existingIndex] = encryptedPasswordData;
        } else {
          currentPasswords.add(encryptedPasswordData);
        }

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(currentPasswords);
        await prefs.setString(_passwordsKey, jsonString);
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool(_encryptionEnabledKey, true);
        await prefs.setBool(_cloudBackupEnabledKey, true);

        await _createBackupAfterChange();
      }

      return saved;
    } catch (e) {
      throw Exception('Failed to save password: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> loadPasswords() async {
    try {
      await initialize();

      if (_firebaseService.isLoggedIn) {
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
          // Convert any Timestamp fields to milliseconds
          sanitized.forEach((key, value) {
            if (value != null && value.toString().contains('Timestamp')) {
              try {
                final timestamp = value as dynamic;
                sanitized[key] = timestamp.millisecondsSinceEpoch;
              } catch (e) {
                // If conversion fails, remove the field
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
          // Convert Timestamp objects to milliseconds before encoding
          final sanitizedPasswords = backupPasswords.map((pwd) {
            final sanitized = Map<String, dynamic>.from(pwd);
            // Convert any Timestamp fields to milliseconds
            sanitized.forEach((key, value) {
              if (value != null && value.toString().contains('Timestamp')) {
                try {
                  final timestamp = value as dynamic;
                  sanitized[key] = timestamp.millisecondsSinceEpoch;
                } catch (e) {
                  // If conversion fails, remove the field
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
    }
  }

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
      return [];
    }
  }

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
        }

        await _createBackupAfterChange();
      }

      return updated;
    } catch (e) {
      return false;
    }
  }

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
            print('✅ StorageService: Found password - Title: ${pwd['title']}, '
                'id: ${pwd['id']}, documentId: ${pwd['documentId']}');
          }
          return isMatch;
        },
        orElse: () => {},
      );

      if (passwordToDelete.isEmpty) {
        print('❌ StorageService: No password found for ID: $passwordId');
        print('📋 Available passwords:');
        for (var pwd in currentPasswords) {
          print(
              '  - ${pwd['title']}: id=${pwd['id']}, documentId=${pwd['documentId']}');
        }
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
      print(
          '🔥 StorageService: Calling FirebaseService.deletePassword($documentId)');
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
      print('🔄 StorageService: Stack trace: ${e.toString()}');
      return false;
    }
  }

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
      return false;
    }
  }

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
      return false;
    }
  }

  Future<void> refreshFromFirebase() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('Not logged in to Firebase');
      }

      final firebasePasswords = await _firebaseService.getPasswords();

      if (firebasePasswords.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(firebasePasswords);
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

  Future<bool> backupToCloud() async {
    try {
      print('═══════════════════════════════════════════════');
      print('🚀 BACKUP TO CLOUD - START');
      print('═══════════════════════════════════════════════');

      print('1️⃣ Checking login status...');
      if (!_firebaseService.isLoggedIn) {
        print('❌ User not logged in');
        throw Exception('Not logged in to Firebase');
      }
      print('✅ User is logged in');

      print('2️⃣ Getting local passwords...');
      final localPasswords = await _getLocalPasswords();
      print('📊 Found ${localPasswords.length} local passwords');

      if (localPasswords.isEmpty) {
        print('❌ No local data to backup');
        throw Exception('No local data to backup');
      }

      print('3️⃣ Getting user info...');
      final user = _firebaseService.getCurrentUserId();
      final userEmail = _firebaseService.userEmail;
      print('👤 User ID: $user');
      print('📧 User Email: $userEmail');

      if (user == null) {
        print('❌ User ID is null');
        throw Exception('User not found');
      }

      print('4️⃣ Preparing backup data...');
      // Ensure all passwords in backup are encrypted at rest in Firestore
      final encryptedPasswords =
          localPasswords.map((p) => _encryptPasswordData(p)).toList();
      final backupData = {
        'userId': user, // will be encrypted in FirebaseService
        'email': userEmail, // will be encrypted in FirebaseService
        'passwords': encryptedPasswords,
        'totalPasswords': encryptedPasswords.length,
        'deviceInfo': {
          'platform': 'flutter',
          'backupVersion': '1.0',
          'appVersion': '1.0.0',
        },
        'metadata': {
          'categories': _extractCategories(localPasswords),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        }
      };
      print('📦 Backup data prepared:');
      print('   - Total passwords: ${backupData['totalPasswords']}');
      print(
          '   - Categories: ${(backupData['metadata'] as Map?)?['categories']}');
      print('   - Device: ${(backupData['deviceInfo'] as Map?)?['platform']}');

      print('5️⃣ Calling FirebaseService.createBackup()...');
      await _firebaseService.createBackup(backupData);
      print('✅ FirebaseService.createBackup() completed');

      print('6️⃣ Updating local preferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_cloudBackupEnabledKey, true);
      print('✅ Local preferences updated');

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

  Map<String, dynamic> _encryptPasswordData(Map<String, dynamic> passwordData) {
    try {
      final encryptedData = {...passwordData};

      // List of fields to encrypt
      final fieldsToEncrypt = [
        'password',
        'username',
        'title',
        'website',
        'notes',
        'category',
      ];
      bool anyFieldEncrypted = false;

      // Encrypt each sensitive field
      for (final field in fieldsToEncrypt) {
        if (passwordData[field] != null &&
            passwordData[field].toString().isNotEmpty) {
          final originalValue = passwordData[field].toString();

          // Only encrypt if not already encrypted
          if (!EncryptionService.isEncrypted(originalValue)) {
            final encryptedValue = EncryptionService.encrypt(originalValue);
            encryptedData[field] = encryptedValue;
            anyFieldEncrypted = true;
            print('🔐 Encrypted field: $field');
          } else {
            // Already encrypted
            encryptedData[field] = originalValue;
            anyFieldEncrypted = true;
          }
        }
      }

      encryptedData['isEncrypted'] = anyFieldEncrypted;
      encryptedData['id'] = encryptedData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();
      // Do not store plaintext userId locally; store hashed scope key instead
      final uid = _firebaseService.getCurrentUserId();
      if (uid != null) {
        encryptedData['userKey'] = EncryptionService.hash(uid);
      }
      encryptedData['createdAt'] =
          encryptedData['createdAt'] ?? DateTime.now().toIso8601String();

      print('✅ All sensitive fields encrypted for Firebase storage');
      return encryptedData;
    } catch (e) {
      print('❌ Encryption error: $e');
      return {...passwordData, 'isEncrypted': false};
    }
  }

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

      // Decrypt all sensitive fields if data is encrypted
      if (decryptedData['isEncrypted'] == true) {
        final fieldsToDecrypt = [
          'password',
          'username',
          'title',
          'website',
          'notes',
          'category',
        ];

        for (final field in fieldsToDecrypt) {
          if (decryptedData[field] != null && decryptedData[field] is String) {
            try {
              final encryptedValue = decryptedData[field] as String;

              // Only decrypt if it's actually encrypted
              if (encryptedValue.isNotEmpty &&
                  EncryptionService.isEncrypted(encryptedValue)) {
                final decryptedValue =
                    EncryptionService.decrypt(encryptedValue);
                decryptedData[field] = decryptedValue;
                print('🔓 Decrypted field: $field');
              }
            } catch (decryptError) {
              print('❌ Decryption failed for field $field: $decryptError');
              decryptedData[field] = '[Decryption Failed]';
              decryptedData['isEncrypted'] = false;
            }
          }
        }
        print('✅ All sensitive fields decrypted for UI display');
      }

      return decryptedData;
    } catch (e) {
      print('❌ Decryption error: $e');
      return encryptedData;
    }
  }

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

  /// Public method to force sync with Firebase
  /// Call this after login to ensure data is loaded from cloud
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

  Future<void> _createBackupAfterChange() async {
    try {
      print(
          '🔄 StorageService._createBackupAfterChange: Auto-backup triggered');

      final user = _firebaseService.getCurrentUserId();
      if (user == null) {
        print(
            '⚠️ StorageService._createBackupAfterChange: No user ID, skipping backup');
        return;
      }
      print('👤 StorageService._createBackupAfterChange: User ID: $user');

      final prefs = await SharedPreferences.getInstance();
      final backupEnabled = prefs.getBool(_cloudBackupEnabledKey) ?? true;
      print(
          '⚙️ StorageService._createBackupAfterChange: Backup enabled: $backupEnabled');

      if (backupEnabled) {
        print('⏳ StorageService._createBackupAfterChange: Waiting 1 second...');
        await Future.delayed(Duration(seconds: 1));
        print(
            '🚀 StorageService._createBackupAfterChange: Calling backupToCloud()');
        await backupToCloud();
        print(
            '✅ StorageService._createBackupAfterChange: Auto-backup completed');
      } else {
        print(
            '⚠️ StorageService._createBackupAfterChange: Backup disabled, skipping');
      }
    } catch (e, stackTrace) {
      print(
          '❌ StorageService._createBackupAfterChange: Auto-backup failed: $e');
      print(
          '📍 StorageService._createBackupAfterChange: Stack trace: $stackTrace');
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_passwordsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_encryptionEnabledKey);
      await prefs.remove(_migrationCompletedKey);
      await prefs.remove(_cloudBackupEnabledKey);
      await EncryptionService.clearKeys();
    } catch (e) {
      // Silent fail
    }
  }
}
