/// Comprehensive diagnostic tool to test backup flow
/// This checks: Encryption → Storage → Firebase → Recovery → Decryption

import 'package:flutter/material.dart';
import 'services/encryption_service.dart';
import 'services/storage_service.dart';
import 'services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupFlowTestScreen extends StatefulWidget {
  const BackupFlowTestScreen({Key? key}) : super(key: key);

  @override
  State<BackupFlowTestScreen> createState() => _BackupFlowTestScreenState();
}

class _BackupFlowTestScreenState extends State<BackupFlowTestScreen> {
  final List<String> _logs = [];
  bool _isTesting = false;
  final StorageService _storage = StorageService();
  final FirebaseService _firebase = FirebaseService();

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  Future<void> _runFullTest() async {
    setState(() {
      _logs.clear();
      _isTesting = true;
    });

    try {
      _log('═══════════════════════════════════════════════');
      _log('🧪 STARTING FULL BACKUP FLOW TEST');
      _log('═══════════════════════════════════════════════');

      // TEST 1: Check encryption initialization
      _log('\n📝 TEST 1: Encryption Initialization');
      await _testEncryption();

      // TEST 2: Check Firebase login status
      _log('\n📝 TEST 2: Firebase Login Status');
      await _testFirebaseLogin();

      // TEST 3: Check local storage
      _log('\n📝 TEST 3: Local Storage');
      await _testLocalStorage();

      // TEST 4: Test backup creation
      _log('\n📝 TEST 4: Backup to Cloud');
      await _testBackup();

      // TEST 5: Check Firebase data
      _log('\n📝 TEST 5: Verify Firebase Data');
      await _testFirebaseData();

      // TEST 6: Test recovery
      _log('\n📝 TEST 6: Recovery from Cloud');
      await _testRecovery();

      _log('\n═══════════════════════════════════════════════');
      _log('✅ ALL TESTS COMPLETED');
      _log('═══════════════════════════════════════════════');
    } catch (e, stackTrace) {
      _log('\n❌ TEST SUITE FAILED');
      _log('Error: $e');
      _log('Stack: $stackTrace');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testEncryption() async {
    try {
      final testText = 'TestPassword123!';
      _log('   Testing: "$testText"');

      final encrypted = EncryptionService.encrypt(testText);
      _log('   🔒 Encrypted: $encrypted');

      if (encrypted == testText) {
        _log('   ❌ FAIL: Encryption did not change text');
        return;
      }

      if (!EncryptionService.isEncrypted(encrypted)) {
        _log('   ❌ FAIL: Not valid base64');
        return;
      }

      final decrypted = EncryptionService.decrypt(encrypted);
      _log('   🔓 Decrypted: $decrypted');

      if (decrypted == testText) {
        _log('   ✅ PASS: C++ encryption working');
      } else {
        _log('   ❌ FAIL: Decryption mismatch');
        _log('      Expected: "$testText"');
        _log('      Got: "$decrypted"');
      }
    } catch (e) {
      _log('   ❌ ERROR: $e');
    }
  }

  Future<void> _testFirebaseLogin() async {
    try {
      final isLoggedIn = _firebase.isLoggedIn;
      final userId = _firebase.getCurrentUserId();
      final userEmail = _firebase.userEmail;

      _log('   Login Status: $isLoggedIn');
      _log('   User ID: $userId');
      _log('   User Email: $userEmail');

      if (!isLoggedIn) {
        _log('   ❌ FAIL: User not logged in');
        _log('   ⚠️  Cannot proceed with backup tests');
      } else {
        _log('   ✅ PASS: User logged in');
      }
    } catch (e) {
      _log('   ❌ ERROR: $e');
    }
  }

  Future<void> _testLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final passwordsJson = prefs.getString('app_passwords');

      if (passwordsJson == null || passwordsJson.isEmpty) {
        _log('   ⚠️  No local passwords found');
        _log('   📝 Note: Add a password first to test backup');
        return;
      }

      // Try to parse
      final passwords = await _storage.loadPasswords();
      _log('   📊 Local passwords count: ${passwords.length}');

      if (passwords.isEmpty) {
        _log('   ❌ FAIL: Could not load local passwords');
      } else {
        _log('   ✅ PASS: Local storage readable');
        _log('   📝 First password title: ${passwords[0]['title']}');

        // Check if encrypted
        final firstPwd = passwords[0];
        final isEnc = firstPwd['isEncrypted'] ?? false;
        _log('   🔐 Is encrypted: $isEnc');

        if (isEnc) {
          final encPassword = firstPwd['password'];
          _log('   🔒 Encrypted password: $encPassword');
          if (EncryptionService.isEncrypted(encPassword)) {
            _log('   ✅ Password field is valid base64');
          } else {
            _log('   ❌ Password field is NOT valid base64');
          }
        }
      }
    } catch (e) {
      _log('   ❌ ERROR: $e');
    }
  }

  Future<void> _testBackup() async {
    try {
      if (!_firebase.isLoggedIn) {
        _log('   ⏭️  SKIP: Not logged in');
        return;
      }

      _log('   🚀 Starting backup...');
      final success = await _storage.backupToCloud();

      if (success) {
        _log('   ✅ PASS: Backup successful');
      } else {
        _log('   ❌ FAIL: Backup returned false');
      }
    } catch (e) {
      _log('   ❌ ERROR: $e');
    }
  }

  Future<void> _testFirebaseData() async {
    try {
      if (!_firebase.isLoggedIn) {
        _log('   ⏭️  SKIP: Not logged in');
        return;
      }

      _log('   🔍 Checking Firebase backup info...');
      final backupInfo = await _firebase.getBackupInfo();

      if (backupInfo == null) {
        _log('   ❌ FAIL: No backup found in Firebase');
        return;
      }

      _log('   ✅ Backup found in Firebase');
      _log('   📦 Keys: ${backupInfo.keys.toList()}');

      final totalPasswords = backupInfo['totalPasswords'];
      _log('   📊 Total passwords in backup: $totalPasswords');

      if (backupInfo['passwords'] != null) {
        final passwords = backupInfo['passwords'] as List;
        _log('   📊 Passwords array length: ${passwords.length}');

        if (passwords.isNotEmpty) {
          final firstPwd = passwords[0] as Map;
          _log('   📝 First password keys: ${firstPwd.keys.toList()}');
          _log('   🔐 Is encrypted: ${firstPwd['isEncrypted']}');

          if (firstPwd['password'] != null) {
            final pwd = firstPwd['password'] as String;
            _log('   🔒 Password field length: ${pwd.length}');
            _log('   🔒 Is base64: ${EncryptionService.isEncrypted(pwd)}');
          }
        }
      } else {
        _log('   ⚠️  No passwords array in backup');
      }

      // Check main passwords collection
      _log('\n   🔍 Checking main passwords collection...');
      final mainPasswords = await _firebase.getPasswords();
      _log('   📊 Main collection count: ${mainPasswords.length}');

      if (mainPasswords.isNotEmpty) {
        _log('   ✅ PASS: Data in Firebase');
      } else if (totalPasswords != null && totalPasswords > 0) {
        _log('   ⚠️  Backup exists but main collection empty');
      } else {
        _log('   ❌ FAIL: No data in Firebase');
      }
    } catch (e) {
      _log('   ❌ ERROR: $e');
    }
  }

  Future<void> _testRecovery() async {
    try {
      if (!_firebase.isLoggedIn) {
        _log('   ⏭️  SKIP: Not logged in');
        return;
      }

      _log('   🔄 Testing recovery...');

      // Get current local count
      final beforePasswords = await _storage.loadPasswords();
      _log('   📊 Before recovery: ${beforePasswords.length} passwords');

      // Try recovery
      await _storage.recoverPasswordsFromFirebase();

      // Check after
      final afterPasswords = await _storage.loadPasswords();
      _log('   📊 After recovery: ${afterPasswords.length} passwords');

      if (afterPasswords.isEmpty) {
        _log('   ❌ FAIL: No passwords after recovery');
      } else {
        _log('   ✅ PASS: Recovery completed');

        // Test decryption
        final firstPwd = afterPasswords[0];
        if (firstPwd['isEncrypted'] == true) {
          _log('   🔓 Testing decryption on recovered data...');
          final title = firstPwd['title'];
          _log('   📝 Title (decrypted): $title');
          if (title == '[Decryption Failed]') {
            _log('   ❌ FAIL: Decryption failed');
          } else {
            _log('   ✅ PASS: Decryption working');
          }
        }
      }
    } catch (e) {
      _log('   ❌ ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Flow Test'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _runFullTest,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isTesting ? 'Testing...' : 'Run Full Test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          if (_isTesting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.white;

                  if (log.contains('✅')) {
                    textColor = Colors.green;
                  } else if (log.contains('❌')) {
                    textColor = Colors.red;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.orange;
                  } else if (log.contains('🧪') || log.contains('═')) {
                    textColor = Colors.cyan;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
