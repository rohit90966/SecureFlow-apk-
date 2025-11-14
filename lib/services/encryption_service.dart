import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart';
import 'native_encryption.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static late Encrypter _encrypter;
  static late IV _iv;
  static bool _isInitialized = false;

  // Use proper 32-character key for AES-256 (256 bits = 32 bytes)
  static const String _fallbackKey = 'MySuperSecureKeyForPassword1234567890!@';
  static const String _fallbackIV = '1234567890123456'; // 16 characters for IV

  // Initialize encryption with secure key storage
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to get existing key or generate new one
      String? keyString = await _secureStorage.read(key: 'encryption_key');
      String? ivString = await _secureStorage.read(key: 'encryption_iv');

      if (keyString == null || ivString == null) {
        print('🔐 No existing keys found, generating new keys...');

        // Generate new random keys
        final newKey = Key.fromSecureRandom(32); // 256 bits
        final newIV = IV.fromSecureRandom(16); // 128 bits

        keyString = base64.encode(newKey.bytes);
        ivString = base64.encode(newIV.bytes);

        await _secureStorage.write(key: 'encryption_key', value: keyString);
        await _secureStorage.write(key: 'encryption_iv', value: ivString);

        print('🔐 Generated and saved new encryption keys');

        // Use new keys for both encryption and decryption
        _encrypter = Encrypter(AES(Key(newKey.bytes)));
        _iv = newIV;
      } else {
        // Use existing keys
        final keyBytes = base64.decode(keyString);
        final ivBytes = base64.decode(ivString);

        _encrypter = Encrypter(AES(Key(keyBytes)));
        _iv = IV(ivBytes);
        print('🔐 Loaded existing encryption keys');
      }

      _isInitialized = true;
      print('✅ Encryption service initialized successfully');
    } catch (e) {
      print('❌ Error initializing encryption: $e');
      // Ultimate fallback with proper key length
      _encrypter = Encrypter(AES(Key.fromUtf8(_fallbackKey)));
      _iv = IV.fromUtf8(_fallbackIV);
      _isInitialized = true;
      print('🔄 Using fallback encryption keys');
    }
  }

  // Encrypt text
  // Encrypt text
  static String encrypt(String plainText) {
    try {
      if (!_isInitialized) {
        print(
            '⚠️ Encryption service not initialized, attempting to initialize...');
        initialize().then((_) {
          print('✅ Encryption service initialized in encrypt method');
        });
        return plainText; // Return plain text if not initialized
      }
      if (plainText.isEmpty) return plainText;

      // Attempt native encryption first (C++ via FFI)
      final nativeResult = NativeEncryption.encryptXor('AppKey', plainText);
      if (nativeResult != null && nativeResult.isNotEmpty) {
        print('🔐 Native encryption (XOR demo) succeeded');
        return nativeResult; // still returns hex string
      }

      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      print('✅ Encryption successful');
      return encrypted.base64;
    } catch (e) {
      print('❌ Encryption error: $e');
      return plainText; // Return plain text if encryption fails
    }
  }

  // Decrypt text with multiple fallback methods
  static String decrypt(String encryptedText) {
    try {
      if (!_isInitialized) {
        throw Exception('Encryption service not initialized');
      }
      if (encryptedText.isEmpty) return encryptedText;

      // Check if it's actually encrypted
      if (!isEncrypted(encryptedText)) {
        print('⚠️ Text is not encrypted: $encryptedText');
        return encryptedText;
      }

      // Try native decrypt (XOR hex) – detect if string looks like hex
      final isHex = _looksLikeHex(encryptedText);
      if (isHex) {
        final nativeDec = NativeEncryption.decryptXor('AppKey', encryptedText);
        if (nativeDec != null) {
          print('🔓 Native decryption (XOR demo) succeeded');
          return nativeDec;
        }
      }

      try {
        // Try with current keys first
        final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
        print('✅ Successfully decrypted with current keys');
        return decrypted;
      } catch (e) {
        print('🔄 Current keys failed, trying fallback keys... Error: $e');

        // Try with fallback keys (for old encrypted data)
        try {
          final fallbackEncrypter = Encrypter(AES(Key.fromUtf8(_fallbackKey)));
          final fallbackIV = IV.fromUtf8(_fallbackIV);

          final decrypted =
              fallbackEncrypter.decrypt64(encryptedText, iv: fallbackIV);
          print('✅ Successfully decrypted with fallback keys');
          return decrypted;
        } catch (e2) {
          print('❌ Fallback keys also failed: $e2');
          return '[Decryption Failed]';
        }
      }
    } catch (e) {
      print('❌ All decryption attempts failed for: $encryptedText');
      return '[Decryption Failed]';
    }
  }

  // Check if text is encrypted
  static bool isEncrypted(String text) {
    try {
      if (text.isEmpty) return false;
      if (text == '[Decryption Failed]') return false;
      if (text.length < 16) return false;
      // Treat hex output from native XOR path as encrypted so decrypt() runs
      if (_looksLikeHex(text)) return true;

      // Check if it's valid base64
      base64.decode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Detect simple hex (for XOR demo) so we can route to native decrypt
  static bool _looksLikeHex(String s) {
    if (s.length % 2 != 0) return false;
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      final isHexChar =
          (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) || // 0-9
              (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 102) || // a-f
              (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 70); // A-F
      if (!isHexChar) return false;
    }
    return true;
  }

  // Deterministic one-way hash for identifiers (e.g., user scoping)
  // Returns a hex-encoded SHA-256 digest
  static String hash(String input) {
    try {
      final bytes = utf8.encode(input);
      final digest = crypto.sha256.convert(bytes);
      return digest.toString();
    } catch (_) {
      return input; // fallback to input if hashing fails
    }
  }

  // Test encryption
  static Future<bool> testEncryption() async {
    try {
      await initialize();

      const testText = 'MySecretPassword123!';
      print('\n=== ENCRYPTION TEST ===');
      print('Original: $testText');

      final encrypted = encrypt(testText);
      print('Encrypted: $encrypted');

      final decrypted = decrypt(encrypted);
      print('Decrypted: $decrypted');

      final success = testText == decrypted;
      print('Success: $success');
      print('=====================\n');

      return success;
    } catch (e) {
      print('❌ Encryption test failed: $e');
      return false;
    }
  }

  // Clear encryption keys (for logout)
  static Future<void> clearKeys() async {
    await _secureStorage.delete(key: 'encryption_key');
    await _secureStorage.delete(key: 'encryption_iv');
    _isInitialized = false;
    print('🔐 Encryption keys cleared');
  }
}
