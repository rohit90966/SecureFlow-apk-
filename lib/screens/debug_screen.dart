import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic> _syncStatus = {};
  Map<String, dynamic> _backupInfo = {};
  bool _isLoading = true;
  String _debugLog = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _debugLog = 'Loading debug information...\n';
      });

      final storageService = StorageService();
      final firebaseService = FirebaseService();

      _debugLog += '🔍 Checking Firebase authentication...\n';
      _debugLog += 'Logged in: ${firebaseService.isLoggedIn}\n';
      _debugLog += 'User email: ${firebaseService.userEmail}\n';
      _debugLog += 'User ID: ${firebaseService.getCurrentUserId()}\n\n';

      if (firebaseService.isLoggedIn) {
        _debugLog += '📡 Checking Firebase data...\n';
        final firebasePasswords = await firebaseService.getPasswords();
        _debugLog += 'Passwords in Firebase: ${firebasePasswords.length}\n';

        for (var pwd in firebasePasswords.take(3)) {
          // Show only first 3 to avoid clutter
          _debugLog += ' - ${pwd['title']} (${pwd['id']})\n';
        }
        if (firebasePasswords.length > 3) {
          _debugLog += ' - ... and ${firebasePasswords.length - 3} more\n';
        }
        _debugLog += '\n';
      }

      _debugLog += '💾 Checking local storage...\n';
      final localPasswords = await storageService.loadPasswords();
      _debugLog += 'Passwords in local storage: ${localPasswords.length}\n\n';

      _debugLog += '🔄 Getting sync status...\n';
      _syncStatus = await storageService.getSyncStatus();
      _debugLog += 'Last sync: ${_syncStatus['lastSync'] ?? 'Never'}\n';
      _debugLog += 'Cloud count: ${_syncStatus['cloudCount'] ?? 0}\n';
      _debugLog += 'Local count: ${_syncStatus['localCount'] ?? 0}\n';
      _debugLog +=
          'Encryption: ${_syncStatus['encryptionEnabled'] ?? false}\n\n';

      _debugLog += '☁️ Getting backup info...\n';
      _backupInfo = await storageService.getCloudBackupInfo();
      _debugLog += 'Has backup: ${_backupInfo['hasBackup'] ?? false}\n';
      _debugLog += 'Backup count: ${_backupInfo['count'] ?? 0}\n';
      _debugLog += 'Last backup: ${_backupInfo['lastBackup'] ?? 'Never'}\n';
      if (_backupInfo['error'] != null) {
        _debugLog += 'Backup error: ${_backupInfo['error']}\n';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugLog += '❌ Error: $e\n';
      });
    }
  }

  Future<void> _forceBackup() async {
    try {
      setState(() {
        _isLoading = true;
        _debugLog += '\n🔄 Forcing backup to cloud...\n';
      });

      final storageService = StorageService();
      final success = await storageService.backupToCloud();

      setState(() {
        _isLoading = false;
        _debugLog += success ? '✅ Backup successful!\n' : '❌ Backup failed!\n';
      });

      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugLog += '❌ Backup error: $e\n';
      });
    }
  }

  Future<void> _forceRestore() async {
    try {
      setState(() {
        _isLoading = true;
        _debugLog += '\n🔄 Forcing restore from cloud...\n';
      });

      final storageService = StorageService();
      final success = await storageService.restoreFromCloudBackup();

      setState(() {
        _isLoading = false;
        _debugLog +=
            success ? '✅ Restore successful!\n' : '❌ Restore failed!\n';
      });

      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugLog += '❌ Restore error: $e\n';
      });
    }
  }

  Future<void> _testEncryption() async {
    try {
      setState(() {
        _isLoading = true;
        _debugLog += '\n🔐 Testing encryption...\n';
      });

      final storageService = StorageService();
      final success = await storageService.testEncryption();

      setState(() {
        _isLoading = false;
        _debugLog += success
            ? '✅ Encryption test passed!\n'
            : '❌ Encryption test failed!\n';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugLog += '❌ Encryption test error: $e\n';
      });
    }
  }

  Future<void> _clearAllData() async {
    try {
      setState(() {
        _isLoading = true;
        _debugLog += '\n🗑️ Clearing all data...\n';
      });

      final storageService = StorageService();
      await storageService.clearAllData();

      setState(() {
        _isLoading = false;
        _debugLog += '✅ All data cleared!\n';
      });

      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugLog += '❌ Clear data error: $e\n';
      });
    }
  }

  Future<void> _fixDecryption() async {
    try {
      setState(() {
        _isLoading = true;
        _debugLog += '\n🔧 Fixing decryption issues...\n';
        _debugLog += 'This will:\n';
        _debugLog += '1. Clear local storage\n';
        _debugLog += '2. Reset encryption keys\n';
        _debugLog += '3. Restore from Firebase\n\n';
      });

      final storageService = StorageService();
      final success = await storageService.fixDecryptionIssues();

      setState(() {
        _isLoading = false;
        if (success) {
          _debugLog += '✅ Decryption fixed! All passwords restored.\n';
          _debugLog += '💡 Please restart the app for best results.\n';
        } else {
          _debugLog += '❌ Failed to fix decryption issues.\n';
          _debugLog +=
              '💡 Make sure you are logged in and have a Firebase backup.\n';
        }
      });

      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugLog += '❌ Fix decryption error: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Firebase',
                          _syncStatus['hasCloudConnection'] == true
                              ? 'Connected'
                              : 'Disconnected',
                          _syncStatus['hasCloudConnection'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusCard(
                          'Cloud Data',
                          '${_syncStatus['cloudCount'] ?? 0} items',
                          (_syncStatus['cloudCount'] ?? 0) > 0
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Local Data',
                          '${_syncStatus['localCount'] ?? 0} items',
                          (_syncStatus['localCount'] ?? 0) > 0
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusCard(
                          'Encryption',
                          _syncStatus['encryptionEnabled'] == true
                              ? 'Enabled'
                              : 'Disabled',
                          _syncStatus['encryptionEnabled'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _forceBackup,
                        icon: const Icon(Icons.backup),
                        label: const Text('Force Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _forceRestore,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Force Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _testEncryption,
                        icon: const Icon(Icons.security),
                        label: const Text('Test Encryption'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _fixDecryption,
                        icon: const Icon(Icons.build),
                        label: const Text('Fix Decryption'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearAllData,
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Debug Log
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Log',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            height: 300,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _debugLog,
                                style: const TextStyle(
                                  fontFamily: 'Monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
