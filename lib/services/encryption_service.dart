import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static bool _isInitialized = false;
  static String? _userPassword;
  static encrypt_pkg.Key? _encryptionKey;
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static bool get hasKey => _encryptionKey != null;

  static void _ensureInitialized() {
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _restoreEncryptionKey();
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize encryption: $e');
    }
  }

  static Future<void> _restoreEncryptionKey() async {
    try {
      final storedPassword =
          await _secureStorage.read(key: 'user_encryption_password');
      if (storedPassword != null && storedPassword.isNotEmpty) {
        setUserPassword(storedPassword);
      }
    } catch (e) {
      // No stored password - this is normal for first login
    }
  }

  static Future<void> setUserPassword(String password) async {
    _userPassword = password;

    final salt = utf8.encode('SecureVault_Salt_2024');
    final bytes = utf8.encode(password);
    final combined = [...bytes, ...salt];
    final hash = crypto.sha256.convert(combined);

    _encryptionKey = encrypt_pkg.Key(Uint8List.fromList(hash.bytes));

    await _secureStorage.write(
        key: 'user_encryption_password', value: password);
  }

  static String encrypt(String plainText) {
    try {
      _ensureInitialized();

      if (plainText.isEmpty) return plainText;
      if (_encryptionKey == null) {
        throw Exception('Encryption key not set');
      }

      final iv = encrypt_pkg.IV.fromSecureRandom(16);
      final encrypter = encrypt_pkg.Encrypter(
          encrypt_pkg.AES(_encryptionKey!, mode: encrypt_pkg.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
      final encryptedBase64 = base64.encode(combined);

      return encryptedBase64;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  static String decrypt(String encryptedText) {
    try {
      _ensureInitialized();

      if (encryptedText.isEmpty) return encryptedText;
      if (!isEncrypted(encryptedText)) {
        return encryptedText; // Return as-is if not encrypted
      }
      if (_encryptionKey == null) {
        throw Exception('Encryption key not set');
      }

      final combined = base64.decode(encryptedText);
      if (combined.length <= 16) {
        return encryptedText; // Return original if invalid format
      }

      final iv = encrypt_pkg.IV(Uint8List.fromList(combined.sublist(0, 16)));
      final encryptedData =
          encrypt_pkg.Encrypted(Uint8List.fromList(combined.sublist(16)));

      final encrypter = encrypt_pkg.Encrypter(
          encrypt_pkg.AES(_encryptionKey!, mode: encrypt_pkg.AESMode.cbc));

      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      return decrypted;
    } catch (e) {
      return '[Decryption Failed]';
    }
  }

  static bool isEncrypted(String text) {
    try {
      if (text.isEmpty) return false;
      if (text == '[Decryption Failed]') return false;
      if (text.length < 32) return false;

      final decoded = base64.decode(text);
      return decoded.length > 16;
    } catch (e) {
      return false;
    }
  }

  static String hash(String input) {
    try {
      final bytes = utf8.encode(input);
      final digest = crypto.sha256.convert(bytes);
      return digest.toString();
    } catch (_) {
      return input;
    }
  }

  static Future<bool> testEncryption() async {
    try {
      await initialize();
      setUserPassword('TestPassword123!');

      const testText = 'MySecretPassword123!';
      final encrypted = encrypt(testText);
      final decrypted = decrypt(encrypted);

      return testText == decrypted;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearKeys() async {
    _userPassword = null;
    _encryptionKey = null;
    await _secureStorage.delete(key: 'user_encryption_password');
  }
}
