/// Test file to verify C++ AES-256 encryption is working correctly
/// Run this to ensure encryption/decryption round-trip works

import 'package:flutter/material.dart';
import 'services/encryption_service.dart';

class EncryptionTestScreen extends StatefulWidget {
  const EncryptionTestScreen({Key? key}) : super(key: key);

  @override
  State<EncryptionTestScreen> createState() => _EncryptionTestScreenState();
}

class _EncryptionTestScreenState extends State<EncryptionTestScreen> {
  final List<Map<String, String>> _testResults = [];
  bool _isTesting = false;

  Future<void> _runTests() async {
    setState(() {
      _testResults.clear();
      _isTesting = true;
    });

    // Test 1: Simple string encryption
    await _testEncryptDecrypt(
      'Test 1: Simple String',
      'Hello World',
    );

    // Test 2: Password-like string
    await _testEncryptDecrypt(
      'Test 2: Password',
      'MyP@ssw0rd123!',
    );

    // Test 3: Long string
    await _testEncryptDecrypt(
      'Test 3: Long Text',
      'This is a much longer string with multiple words, special characters !@#\$%^&*(), and numbers 1234567890.',
    );

    // Test 4: Empty string
    await _testEncryptDecrypt(
      'Test 4: Empty String',
      '',
    );

    // Test 5: Unicode characters
    await _testEncryptDecrypt(
      'Test 5: Unicode',
      '你好世界 🔐🔑',
    );

    // Test 6: Special characters
    await _testEncryptDecrypt(
      'Test 6: Special Chars',
      'Test\nNew\tLine\rReturn',
    );

    setState(() {
      _isTesting = false;
    });
  }

  Future<void> _testEncryptDecrypt(String testName, String plaintext) async {
    try {
      print('🧪 Running: $testName');
      print('📝 Input: "$plaintext"');

      // Encrypt
      final encrypted = EncryptionService.encrypt(plaintext);
      print('🔒 Encrypted: $encrypted');

      // Check if encrypted is different from plaintext (unless empty)
      if (plaintext.isNotEmpty && encrypted == plaintext) {
        _addResult(testName, '❌ FAILED', 'Encryption did not change the text');
        return;
      }

      // Check if encrypted is base64
      if (!EncryptionService.isEncrypted(encrypted)) {
        _addResult(testName, '❌ FAILED', 'Encrypted text is not valid base64');
        return;
      }

      // Decrypt
      final decrypted = EncryptionService.decrypt(encrypted);
      print('🔓 Decrypted: "$decrypted"');

      // Verify
      if (decrypted == plaintext) {
        _addResult(testName, '✅ PASSED', 'Round-trip successful');
        print('✅ $testName PASSED\n');
      } else {
        _addResult(
          testName,
          '❌ FAILED',
          'Decrypted text does not match original.\nExpected: "$plaintext"\nGot: "$decrypted"',
        );
        print('❌ $testName FAILED\n');
      }
    } catch (e, stackTrace) {
      _addResult(testName, '❌ ERROR', 'Exception: $e\n$stackTrace');
      print('❌ $testName ERROR: $e\n');
    }
  }

  void _addResult(String testName, String status, String details) {
    setState(() {
      _testResults.add({
        'name': testName,
        'status': status,
        'details': details,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('C++ Encryption Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _runTests,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isTesting ? 'Testing...' : 'Run Encryption Tests'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_isTesting)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_testResults.isNotEmpty) ...[
              Text(
                'Test Results (${_testResults.length} tests)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    final isPassed = result['status']!.contains('✅');
                    return Card(
                      color: isPassed ? Colors.green[50] : Colors.red[50],
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          result['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              result['status']!,
                              style: TextStyle(
                                color: isPassed
                                    ? Colors.green[900]
                                    : Colors.red[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(result['details']!),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
