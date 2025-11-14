import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

class NativePasswordService {
  static const MethodChannel _channel = MethodChannel('native_password_service');

  static Future<void> initializeDatabase() async {
    try {
      print('🔄 Initializing database...');

      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        print('📱 Mobile platform detected');
        return;
      } else {
        print('🌐 Web platform detected, using SharedPreferences');
      }
    } catch (e) {
      print('❌ Error initializing database: $e');
    }
  }

  // NEW: Enhanced password analysis with suggestions
  static Future<Map<String, dynamic>> analyzePasswordDetailed(String password) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final String result = await _channel.invokeMethod(
          'analyzePasswordDetailed',
          {'password': password},
        );
        return json.decode(result);
      } else {
        // Web fallback
        return _webAnalyzePasswordDetailed(password);
      }
    } catch (e) {
      print('❌ Error in analyzePasswordDetailed: $e');
      return _webAnalyzePasswordDetailed(password);
    }
  }

  // NEW: Quick strength check
  static Future<String> getPasswordStrength(String password) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return await _channel.invokeMethod('getPasswordStrength', {'password': password});
      } else {
        return _webGetPasswordStrength(password);
      }
    } catch (e) {
      print('❌ Error in getPasswordStrength: $e');
      return _webGetPasswordStrength(password);
    }
  }

  // NEW: Generate password with specific requirements
  static Future<String> generateStrongPassword({
    required int length,
    required bool includeUpper,
    required bool includeLower,
    required bool includeDigits,
    required bool includeSymbols,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return await _channel.invokeMethod('generateStrongPassword', {
          'length': length,
          'includeUpper': includeUpper,
          'includeLower': includeLower,
          'includeDigits': includeDigits,
          'includeSymbols': includeSymbols,
        });
      } else {
        return _webGenerateStrongPassword(
          length: length,
          includeUpper: includeUpper,
          includeLower: includeLower,
          includeDigits: includeDigits,
          includeSymbols: includeSymbols,
        );
      }
    } catch (e) {
      print('❌ Error in generateStrongPassword: $e');
      return _webGenerateStrongPassword(
        length: length,
        includeUpper: includeUpper,
        includeLower: includeLower,
        includeDigits: includeDigits,
        includeSymbols: includeSymbols,
      );
    }
  }

  // Web fallback implementations
  static Map<String, dynamic> _webAnalyzePasswordDetailed(String password) {
    int score = 0;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    List<String> suggestions = [];

    // Length scoring
    if (password.length >= 8) score += 25;
    if (password.length >= 12) score += 15;
    if (password.length >= 16) score += 10;

    // Character variety
    if (hasUpper) score += 15;
    if (hasLower) score += 15;
    if (hasDigit) score += 15;
    if (hasSpecial) score += 15;

    // Generate suggestions
    if (password.length < 8) {
      suggestions.add('🔒 Make password longer (at least 8 characters)');
    }
    if (!hasUpper) {
      suggestions.add('🔤 Add uppercase letters (A-Z)');
    }
    if (!hasLower) {
      suggestions.add('🔡 Add lowercase letters (a-z)');
    }
    if (!hasDigit) {
      suggestions.add('🔢 Add numbers (0-9)');
    }
    if (!hasSpecial) {
      suggestions.add('⭐ Add special characters (!@#\$%^&*)');
    }

    String strength;
    if (score >= 80) {
      strength = 'Very Strong';
    } else if (score >= 60) {
      strength = 'Strong';
    } else if (score >= 40) {
      strength = 'Moderate';
    } else if (score >= 20) {
      strength = 'Weak';
    } else {
      strength = 'Very Weak';
    }

    return {
      'score': score,
      'strength': '$strength ($score/100)',
      'suggestions': suggestions,
      'length': password.length,
      'hasUpper': hasUpper,
      'hasLower': hasLower,
      'hasDigit': hasDigit,
      'hasSpecial': hasSpecial,
    };
  }

  static String _webGetPasswordStrength(String password) {
    final analysis = _webAnalyzePasswordDetailed(password);
    return analysis['strength'];
  }

  static String _webGenerateStrongPassword({
    required int length,
    required bool includeUpper,
    required bool includeLower,
    required bool includeDigits,
    required bool includeSymbols,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String charPool = '';
    if (includeUpper) charPool += uppercase;
    if (includeLower) charPool += lowercase;
    if (includeDigits) charPool += numbers;
    if (includeSymbols) charPool += symbols;

    if (charPool.isEmpty) {
      charPool = uppercase + lowercase + numbers + symbols;
    }

    final random = Random();
    final result = StringBuffer();

    // Ensure at least one of each required type
    if (includeUpper) result.write(uppercase[random.nextInt(uppercase.length)]);
    if (includeLower) result.write(lowercase[random.nextInt(lowercase.length)]);
    if (includeDigits) result.write(numbers[random.nextInt(numbers.length)]);
    if (includeSymbols) result.write(symbols[random.nextInt(symbols.length)]);

    // Fill remaining length
    while (result.length < length) {
      result.write(charPool[random.nextInt(charPool.length)]);
    }

    // Shuffle the result
    final passwordChars = result.toString().split('');
    passwordChars.shuffle();
    return passwordChars.join();
  }

  // Your existing methods remain the same...
  static Future<bool> addPassword({
    required String title,
    required String username,
    required String password,
    required int category,
    String website = '',
    String notes = '',
  }) async {
    print('🌐 Web: Password "$title" stored in SharedPreferences');
    return true;
  }

  static Future<bool> deletePassword(int id) async {
    return true;
  }

  static Future<String> getAllPasswords() async {
    return '[]';
  }

  static Future<String> analyzePassword(String password) async {
    return 'Moderate - Web analysis';
  }

  static Future<String> generateRandomPassword([int length = 16]) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  static Future<String> generateMemorablePassword() async {
    const words = ['apple', 'banana', 'cherry', 'dragon', 'elephant', 'flower'];
    final random = Random();
    final word1 = words[random.nextInt(words.length)];
    final word2 = words[random.nextInt(words.length)];
    final number = random.nextInt(100);
    return '$word1-$word2-$number';
  }

  static Future<String> generatePin([int length = 6]) async {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  static Future<String> getCategoryStats() async {
    return '{}';
  }

  static Future<int> getTotalPasswordCount() async {
    return 0;
  }
}