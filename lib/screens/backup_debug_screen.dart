import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

class BackupDebugScreen extends StatefulWidget {
  const BackupDebugScreen({Key? key}) : super(key: key);

  @override
  State<BackupDebugScreen> createState() => _BackupDebugScreenState();
}

class _BackupDebugScreenState extends State<BackupDebugScreen> {
  final StorageService _storageService = StorageService();
  final FirebaseService _firebaseService = FirebaseService();
  String _status = 'Ready to test backup';
  bool _isLoading = false;

  Future<void> _testBackupCreation() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating backup... Check console logs!';
    });

    try {
      print('\n\n═══════════════════════════════════════════════');
      print('🧪 MANUAL BACKUP TEST STARTED');
      print('═══════════════════════════════════════════════\n');

      final success = await _storageService.backupToCloud();

      setState(() {
        _status = success
            ? '✅ Backup created successfully!\nCheck console for details.'
            : '❌ Backup failed!\nCheck console for error details.';
        _isLoading = false;
      });

      print('\n═══════════════════════════════════════════════');
      print(
          '🧪 MANUAL BACKUP TEST COMPLETED: ${success ? "SUCCESS" : "FAILED"}');
      print('═══════════════════════════════════════════════\n\n');
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e\n\nCheck console for full details.';
        _isLoading = false;
      });

      print('\n═══════════════════════════════════════════════');
      print('🧪 MANUAL BACKUP TEST FAILED WITH EXCEPTION');
      print('Error: $e');
      print('═══════════════════════════════════════════════\n\n');
    }
  }

  Future<void> _testBackupRetrieval() async {
    setState(() {
      _isLoading = true;
      _status = 'Retrieving backup... Check console logs!';
    });

    try {
      print('\n\n═══════════════════════════════════════════════');
      print('🧪 MANUAL BACKUP RETRIEVAL TEST STARTED');
      print('═══════════════════════════════════════════════\n');

      final backupInfo = await _firebaseService.getBackupInfo();

      if (backupInfo != null) {
        final passwordCount = (backupInfo['passwords'] as List?)?.length ?? 0;
        setState(() {
          _status =
              '✅ Backup found!\n\nPasswords: $passwordCount\nKeys: ${backupInfo.keys.join(", ")}\n\nCheck console for full details.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status =
              '⚠️ No backup found in Firebase!\n\nCheck console to see where it failed.';
          _isLoading = false;
        });
      }

      print('\n═══════════════════════════════════════════════');
      print(
          '🧪 BACKUP RETRIEVAL TEST COMPLETED: ${backupInfo != null ? "FOUND" : "NOT FOUND"}');
      print('═══════════════════════════════════════════════\n\n');
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e\n\nCheck console for full details.';
        _isLoading = false;
      });

      print('\n═══════════════════════════════════════════════');
      print('🧪 BACKUP RETRIEVAL TEST FAILED WITH EXCEPTION');
      print('Error: $e');
      print('═══════════════════════════════════════════════\n\n');
    }
  }

  Future<void> _testSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Syncing with Firebase... Check console logs!';
    });

    try {
      print('\n\n═══════════════════════════════════════════════');
      print('🧪 MANUAL SYNC TEST STARTED');
      print('═══════════════════════════════════════════════\n');

      final success = await _storageService.syncWithFirebase();

      setState(() {
        _status = success
            ? '✅ Sync completed!\nCheck console to see what was loaded.'
            : '❌ Sync failed!\nCheck console for error details.';
        _isLoading = false;
      });

      print('\n═══════════════════════════════════════════════');
      print('🧪 MANUAL SYNC TEST COMPLETED: ${success ? "SUCCESS" : "FAILED"}');
      print('═══════════════════════════════════════════════\n\n');
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e\n\nCheck console for full details.';
        _isLoading = false;
      });

      print('\n═══════════════════════════════════════════════');
      print('🧪 MANUAL SYNC TEST FAILED WITH EXCEPTION');
      print('Error: $e');
      print('═══════════════════════════════════════════════\n\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Debug Tools'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF34495E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Logged in: ${_firebaseService.isLoggedIn}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Email: ${_firebaseService.userEmail ?? "N/A"}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'UID: ${_firebaseService.getCurrentUserId() ?? "N/A"}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Status Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Test Buttons
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testBackupCreation,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.backup),
                  label: Text('1. Test Backup Creation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testBackupRetrieval,
                  icon: Icon(Icons.download),
                  label: Text('2. Test Backup Retrieval'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSync,
                  icon: Icon(Icons.sync),
                  label: Text('3. Test Full Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B59B6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const Spacer(),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Instructions:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Make sure you have some passwords saved\n'
                        '2. Click "Test Backup Creation"\n'
                        '3. Watch the console output\n'
                        '4. Click "Test Backup Retrieval" to verify\n'
                        '5. Share console logs if it fails',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
